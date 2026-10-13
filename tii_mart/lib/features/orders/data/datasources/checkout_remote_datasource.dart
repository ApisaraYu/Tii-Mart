import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../address/domain/address.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/shipping_option.dart';

/// สร้างออเดอร์ + รายการชำระเงิน + เคลียร์รถเข็น ใน batch เดียว (สำเร็จทั้งหมดหรือไม่สำเร็จเลย)
class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);

  /// คืน orderId — ยอดทั้งหมดคำนวณในแอพ (แพ็กเกจ Spark ไม่มี Cloud Functions ให้ตรวจฝั่งเซิร์ฟเวอร์)
  Future<String> placeOrder({
    required String customerId,
    required List<CartItem> items,
    required Address address,
    required ShippingOption shipping,
    required int discount,
    int shippingDiscount = 0,
    String? couponId,
  }) {
    return guardFirebase(() async {
      if (items.isEmpty) throw const Failure('ยังไม่ได้เลือกสินค้า');
      final sellerId = items.first.sellerId;
      if (items.any((i) => i.sellerId != sellerId)) {
        throw const Failure('ชำระเงินได้ครั้งละ 1 ร้าน กรุณาเลือกสินค้าจากร้านเดียวกัน');
      }

      final subtotal = items.fold<int>(0, (s, i) => s + i.lineTotal);
      final shippingFee = shipping.fee - shippingDiscount; // ค่าส่งที่จ่ายจริง
      final total = subtotal - discount + shippingFee;

      final orderRef = _db.collection('orders').doc();
      final batch = _db.batch();

      batch.set(orderRef, {
        'sellerId': sellerId,
        'customerId': customerId,
        'items': [
          for (final i in items)
            {
              'productId': i.productId,
              'variantId': i.variantId,
              'name': i.name,
              'variantLabel': i.variantLabel,
              'price': i.price,
              'qty': i.qty,
              'imageUrl': i.imageUrl,
            },
        ],
        'shippingAddress': address.toSnapshot(),
        'shipping': {'type': shipping.name, 'label': shipping.label},
        'shippingFee': shippingFee,
        'shippingDiscount': shippingDiscount,
        'couponId': couponId ?? '',
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'status': 'pendingPayment',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // id รายการชำระเงิน = id ออเดอร์
      batch.set(_db.collection('payments').doc(orderRef.id), {
        'orderId': orderRef.id,
        'method': 'promptpay',
        'status': 'pending',
        'amount': total,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final i in items) {
        batch.delete(_db.collection('carts').doc(i.id));
      }

      await batch.commit().timeout(_timeout);
      return orderRef.id;
    });
  }

  Stream<Payment?> watchPayment(String orderId) {
    return _db
        .collection('payments')
        .doc(orderId)
        .snapshots()
        .map((d) {
          if (!d.exists) return null;
          final m = d.data()!;
          return Payment(
            orderId: orderId,
            method: (m['method'] ?? '') as String,
            status: (m['status'] ?? 'pending') as String,
            amount: (m['amount'] as num?)?.toInt() ?? 0,
            slipUrl: m['slipUrl'] as String?,
          );
        })
        .transform(
          StreamTransformer<Payment?, Payment?>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(toFailure(error), stackTrace),
          ),
        );
  }

  /// แนบสลิปการโอน (ลูกค้าแก้ได้เฉพาะ slipUrl ตาม firestore.rules)
  Future<void> attachSlip(String orderId, String url) {
    return guardFirebase(() async {
      await _db
          .collection('payments')
          .doc(orderId)
          .update({'slipUrl': url}).timeout(_timeout);
    });
  }
}
