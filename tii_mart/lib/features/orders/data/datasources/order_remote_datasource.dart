import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
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

  Future<void> updateStatus(String orderId, OrderStatus status) {
    return guardFirebase(() async {
      await _orders.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
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
