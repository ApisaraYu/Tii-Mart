import 'package:flutter_test/flutter_test.dart';
import 'package:tii_mart/features/orders/domain/entities/shop_order.dart';

void main() {
  group('OrderStatus', () {
    test('fromString: ค่าที่ไม่รู้จักถือเป็นรอชำระเงิน', () {
      expect(OrderStatus.fromString('shipped'), OrderStatus.shipped);
      expect(OrderStatus.fromString(null), OrderStatus.pendingPayment);
      expect(OrderStatus.fromString('pending'), OrderStatus.pendingPayment);
    });
    test('ลำดับสถานะถัดไป รอชำระ -> ชำระแล้ว -> จัดส่ง -> สำเร็จ', () {
      expect(OrderStatus.pendingPayment.next, OrderStatus.paid);
      expect(OrderStatus.paid.next, OrderStatus.shipped);
      expect(OrderStatus.shipped.next, OrderStatus.completed);
    });
    test('สถานะปลายทางไม่มีขั้นถัดไป', () {
      expect(OrderStatus.completed.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);
    });
    test('ยกเลิกได้เฉพาะตอนรอชำระเงินหรือชำระแล้ว', () {
      expect(OrderStatus.pendingPayment.canCancel, isTrue);
      expect(OrderStatus.paid.canCancel, isTrue);
      expect(OrderStatus.shipped.canCancel, isFalse);
      expect(OrderStatus.cancelled.canCancel, isFalse);
    });
    test('นับเป็นยอดขายเมื่อชำระแล้วและไม่ถูกยกเลิก', () {
      expect(OrderStatus.pendingPayment.countsAsSale, isFalse);
      expect(OrderStatus.paid.countsAsSale, isTrue);
      expect(OrderStatus.completed.countsAsSale, isTrue);
      expect(OrderStatus.cancelled.countsAsSale, isFalse);
    });
  });
}
