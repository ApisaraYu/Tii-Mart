import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/shop_order.dart';

/// collection: orders
/// { sellerId, customerId, customerName, items: [{productId,name,variantLabel,price,qty,imageUrl}],
///   total, status, createdAt, updatedAt }
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// ไม่ใช้ orderBy เพื่อเลี่ยง composite index — เรียงฝั่งแอพแทน
  Stream<List<ShopOrder>> watchBySeller(String sellerId) {
    return _orders
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(fromDoc).toList();
          final now = DateTime.now();
          list.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
          );
          return list;
        })
        .transform(
          StreamTransformer<List<ShopOrder>, List<ShopOrder>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(toFailure(error), stackTrace);
            },
          ),
        );
  }

  /// คำสั่งซื้อของลูกค้าคนนี้ (ใหม่สุดก่อน)
  Stream<List<ShopOrder>> watchByCustomer(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(fromDoc).toList();
          final now = DateTime.now();
          list.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
          );
          return list;
        })
        .transform(
          StreamTransformer<List<ShopOrder>, List<ShopOrder>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(toFailure(error), stackTrace);
            },
          ),
        );
  }

  /// ลูกค้ายกเลิกเอง — firestore.rules อนุญาตเฉพาะตอนสถานะยังเป็น pendingPayment
  Future<void> cancelByCustomer(String orderId) {
    return guardFirebase(() async {
      await _orders.doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        'cancelReason': 'ลูกค้ายกเลิก',
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    });
  }

  /// ลูกค้ากดยืนยันว่าได้รับสินค้าแล้ว — firestore.rules อนุญาตเฉพาะ shipped -> completed
  Future<void> confirmReceived(String orderId) {
    return guardFirebase(() async {
      await _orders.doc(orderId).update({
        'status': OrderStatus.completed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    });
  }

  /// ออเดอร์เดียวแบบสด (ใช้ในหน้าชำระเงินของลูกค้า)
  Stream<ShopOrder?> watchById(String orderId) {
    return _orders
        .doc(orderId)
        .snapshots()
        .map((d) => d.exists ? fromDoc(d) : null)
        .transform(
          StreamTransformer<ShopOrder?, ShopOrder?>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(toFailure(error), stackTrace),
          ),
        );
  }

  /// เปลี่ยนสถานะออเดอร์ (ฝั่งร้านค้า)
///  - รอชำระเงิน → ชำระแล้ว : ตัดสต๊อก + บันทึก stockMovements + นับจำนวนที่ใช้โค้ด (ทั้งหมดใน transaction เดียว)
///  - ชำระแล้ว → ยกเลิก      : คืนสต๊อก + คืนจำนวนโค้ด
///  อ่านสถานะล่าสุดจากเซิร์ฟเวอร์ใน transaction จึงกดซ้ำ/สองเครื่องพร้อมกันก็ไม่ตัดสต๊อกซ้ำ
  Future<void> updateStatus(String orderId, OrderStatus status) {
    return guardFirebase(() async {
      final orderRef = _orders.doc(orderId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(orderRef);
        if (!snap.exists) throw const Failure('ไม่พบออเดอร์นี้');
        final order = fromDoc(snap);
        final from = order.status;
        if (from == status) return; // มีคนเปลี่ยนไปแล้ว

        final deduct =
            from == OrderStatus.pendingPayment && status == OrderStatus.paid;
        final restore = from == OrderStatus.paid && status == OrderStatus.cancelled;

        if (deduct || restore) {
          final sign = deduct ? -1 : 1; // ตัด = ลบ / คืน = บวก

          // ---- อ่านทั้งหมดก่อน (กติกา transaction: อ่านก่อนเขียน) ----
          final variantRefs = <OrderItem, DocumentReference<Map<String, dynamic>>>{};
          final variantSnaps = <OrderItem, DocumentSnapshot<Map<String, dynamic>>>{};
          for (final it in order.items) {
            if (it.productId.isEmpty || it.variantId.isEmpty) continue;
            final ref = _db
                .collection('products')
                .doc(it.productId)
                .collection('variants')
                .doc(it.variantId);
            variantRefs[it] = ref;
            variantSnaps[it] = await tx.get(ref);
          }
          DocumentSnapshot<Map<String, dynamic>>? couponSnap;
          DocumentReference<Map<String, dynamic>>? couponRef;
          if (order.couponId != null) {
            couponRef = _db.collection('coupons').doc(order.couponId);
            couponSnap = await tx.get(couponRef);
          }

          if (deduct) {
            for (final e in variantSnaps.entries) {
              if (!e.value.exists) continue;
              final stock = _i(e.value.data()?['stock']);
              if (stock < e.key.qty) {
                throw Failure(
                  'สต๊อกไม่พอ: ${e.key.name}'
                  '${e.key.variantLabel.isEmpty ? '' : ' (${e.key.variantLabel})'} '
                  'เหลือ $stock ชิ้น แต่ลูกค้าสั่ง ${e.key.qty} ชิ้น',
                );
              }
            }
          }

          // ---- เขียน ----
          final perProduct = <String, int>{};
          for (final e in variantSnaps.entries) {
            if (!e.value.exists) continue; // ตัวเลือกถูกลบไปแล้ว ข้าม
            final it = e.key;
            tx.update(variantRefs[it]!, {'stock': FieldValue.increment(sign * it.qty)});
            perProduct.update(it.productId, (v) => v + it.qty, ifAbsent: () => it.qty);
            tx.set(_db.collection('stockMovements').doc(), {
              'variantId': it.variantId,
              'productId': it.productId,
              'ownerId': order.sellerId,
              'orderId': orderId,
              'delta': sign * it.qty,
              'reason': deduct ? 'ขายสินค้า' : 'คืนสต๊อก (ยกเลิกออเดอร์)',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          for (final e in perProduct.entries) {
            tx.update(_db.collection('products').doc(e.key), {
              'totalStock': FieldValue.increment(sign * e.value),
              'soldCount': FieldValue.increment(-sign * e.value),
            });
          }
          if (couponRef != null && couponSnap != null && couponSnap.exists) {
            tx.update(couponRef, {'used': FieldValue.increment(deduct ? 1 : -1)});
          }
        }

        tx.update(orderRef, {
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
          if (status == OrderStatus.cancelled) 'cancelReason': 'ร้านค้ายกเลิก',
        });
      }).timeout(_timeout);

      // อัพเดตรายการชำระเงิน (ถ้ามี) — ไม่สำเร็จก็ไม่เป็นไร ออเดอร์เปลี่ยนสถานะไปแล้ว
      if (status == OrderStatus.paid || status == OrderStatus.cancelled) {
        try {
          await _db.collection('payments').doc(orderId).update({
            'status': status == OrderStatus.paid ? 'paid' : 'cancelled',
            if (status == OrderStatus.paid) 'paidAt': FieldValue.serverTimestamp(),
          }).timeout(_timeout);
        } catch (_) {}
      }
    });
  }

  static String _s(Object? v) => v is String ? v : '';
  static int _i(Object? v) => v is num ? v.toInt() : 0;

  static ShopOrder fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final raw = d['items'];
    final items = <OrderItem>[
      if (raw is List)
        for (final m in raw.whereType<Map>())
          OrderItem(
            productId: _s(m['productId']),
            variantId: _s(m['variantId']),
            name: _s(m['name']),
            variantLabel: _s(m['variantLabel']),
            price: _i(m['price']),
            qty: _i(m['qty']),
            imageUrl: _s(m['imageUrl']),
          ),
    ];
    final ts = d['createdAt'];
    final addr = d['shippingAddress'] is Map
        ? Map<String, dynamic>.from(d['shippingAddress'] as Map)
        : const <String, dynamic>{};
    final ship = d['shipping'] is Map
        ? Map<String, dynamic>.from(d['shipping'] as Map)
        : const <String, dynamic>{};
    final addressText = [
      _s(addr['line1']),
      _s(addr['subdistrict']),
      _s(addr['district']),
      _s(addr['province']),
      _s(addr['postalCode']),
    ].where((e) => e.isNotEmpty).join(' ');
    final coupon = _s(d['couponId']);
    return ShopOrder(
      id: doc.id,
      sellerId: _s(d['sellerId']),
      customerId: _s(d['customerId']),
      // ER ไม่เก็บ customerName แล้ว → ใช้ชื่อผู้รับจากสำเนาที่อยู่แทน
      customerName: _s(d['customerName']).isNotEmpty
          ? _s(d['customerName'])
          : _s(addr['recipientName']),
      items: items,
      total: _i(d['total']),
      status: OrderStatus.fromString(_s(d['status'])),
      createdAt: ts is Timestamp ? ts.toDate() : null,
      subtotal: _i(d['subtotal']),
      discount: _i(d['discount']),
      shippingFee: _i(d['shippingFee']),
      shippingDiscount: _i(d['shippingDiscount']),
      shippingLabel: _s(ship['label']),
      couponId: coupon.isEmpty ? null : coupon,
      recipientName: _s(addr['recipientName']),
      recipientPhone: _s(addr['phone']),
      addressText: addressText,
    );
  }
}
