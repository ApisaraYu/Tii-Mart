import 'package:flutter_test/flutter_test.dart';
import 'package:tii_mart/features/cart/domain/entities/cart_item.dart';
import 'package:tii_mart/features/cart/presentation/state/cart_providers.dart';
import 'package:tii_mart/features/coupon/domain/entities/coupon.dart';

Coupon _coupon({
  DiscountType type = DiscountType.percent,
  int value = 10,
  int minSpend = 0,
  int quantity = 10,
  int used = 0,
  bool isActive = true,
  DateTime? expiresAt,
  String ownerId = 'shopA',
}) =>
    Coupon(
      ownerId: ownerId,
      code: 'TII',
      type: type,
      value: value,
      minSpend: minSpend,
      quantity: quantity,
      used: used,
      isActive: isActive,
      expiresAt: expiresAt,
    );

void main() {
  group('CartItem', () {
    test('lineTotal = ราคา x จำนวน', () {
      const item = CartItem(
        id: 'u_v',
        uid: 'u',
        productId: 'p',
        variantId: 'v',
        sellerId: 's',
        name: 'x',
        price: 250,
        qty: 3,
      );
      expect(item.lineTotal, 750);
    });
    test('id ของรถเข็น = uid_variantId', () {
      expect(CartItem.idFor('u1', 'v9'), 'u1_v9');
    });
  });

  group('Coupon', () {
    test('remaining ไม่ติดลบ และ isUsable ตรวจสิทธิ์ครบ', () {
      expect(_coupon(quantity: 5, used: 8).remaining, 0);
      expect(_coupon(quantity: 5, used: 5).isUsable, isFalse);
      expect(_coupon().isUsable, isTrue);
    });
    test('โค้ดหมดอายุ / ถูกปิด ใช้ไม่ได้', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(_coupon(expiresAt: past).isUsable, isFalse);
      expect(_coupon(isActive: false).isUsable, isFalse);
    });
    test('ข้อความส่วนลด', () {
      expect(_coupon(type: DiscountType.percent, value: 15).discountLabel, 'ลด 15%');
      expect(_coupon(type: DiscountType.fixed, value: 50).discountLabel, 'ลด ฿50');
      expect(
        _coupon(type: DiscountType.freeShipping, value: 0).discountLabel,
        'ส่งฟรี',
      );
    });
    test('fromString ค่าที่ไม่รู้จักใช้ percent', () {
      expect(DiscountType.fromString('fixed'), DiscountType.fixed);
      expect(DiscountType.fromString('freeShipping'), DiscountType.freeShipping);
      expect(DiscountType.fromString('???'), DiscountType.percent);
    });
  });

  group('couponProblem', () {
    test('ใช้ได้ คืน null', () {
      expect(couponProblem(_coupon(), 'shopA', 1000), isNull);
    });
    test('คนละร้าน / ไม่ได้เลือกสินค้า', () {
      expect(couponProblem(_coupon(), 'shopB', 1000), isNotNull);
      expect(couponProblem(_coupon(), null, 1000), isNotNull);
    });
    test('ยอดไม่ถึงขั้นต่ำ', () {
      expect(
        couponProblem(_coupon(minSpend: 500), 'shopA', 499),
        'ยอดซื้อยังไม่ถึงขั้นต่ำ ฿500',
      );
      expect(couponProblem(_coupon(minSpend: 500), 'shopA', 500), isNull);
    });
  });

  group('discountFor (ส่วนลดค่าสินค้า)', () {
    test('เปอร์เซ็นต์: 10% ของ 1000 = 100', () {
      expect(discountFor(_coupon(value: 10), 'shopA', 1000), 100);
    });
    test('จำนวนเงิน: ลดไม่เกินยอดสินค้า', () {
      final c = _coupon(type: DiscountType.fixed, value: 300);
      expect(discountFor(c, 'shopA', 1000), 300);
      expect(discountFor(c, 'shopA', 200), 200);
    });
    test('ใช้ไม่ได้ ส่วนลดเป็น 0', () {
      expect(discountFor(_coupon(minSpend: 5000), 'shopA', 1000), 0);
      expect(discountFor(null, 'shopA', 1000), 0);
    });
    test('โค้ดส่งฟรีไม่ลดค่าสินค้า', () {
      final c = _coupon(type: DiscountType.freeShipping, value: 0);
      expect(discountFor(c, 'shopA', 1000), 0);
    });
  });

  group('shippingDiscountFor (ส่วนลดค่าส่ง)', () {
    test('value = 0 ฟรีเต็มจำนวน', () {
      final c = _coupon(type: DiscountType.freeShipping, value: 0);
      expect(shippingDiscountFor(c, 'shopA', 1000, 50), 50);
    });
    test('value > 0 ลดไม่เกิน value และไม่เกินค่าส่งจริง', () {
      final c20 = _coupon(type: DiscountType.freeShipping, value: 20);
      final c80 = _coupon(type: DiscountType.freeShipping, value: 80);
      expect(shippingDiscountFor(c20, 'shopA', 1000, 50), 20);
      expect(shippingDiscountFor(c80, 'shopA', 1000, 50), 50);
    });
    test('โค้ดส่วนลดปกติไม่ลดค่าส่ง', () {
      expect(shippingDiscountFor(_coupon(), 'shopA', 1000, 50), 0);
    });
  });

  group('CartTotals', () {
    test('afterDiscount และ couponApplied', () {
      final c = _coupon(value: 10);
      final t = CartTotals(subtotal: 1000, discount: 100, coupon: c, sellerId: 'shopA');
      expect(t.afterDiscount, 900);
      expect(t.couponApplied, isTrue);
      expect(t.couponProblemText, isNull);
    });
    test('โค้ดใช้ไม่ได้ มีข้อความเหตุผล และ couponApplied = false', () {
      final c = _coupon(minSpend: 2000);
      final t = CartTotals(subtotal: 1000, discount: 0, coupon: c, sellerId: 'shopA');
      expect(t.couponApplied, isFalse);
      expect(t.couponProblemText, isNotNull);
    });
    test('ไม่ได้เลือกโค้ด ไม่มีข้อความปัญหา', () {
      const t = CartTotals(subtotal: 500, discount: 0, coupon: null, sellerId: 'shopA');
      expect(t.couponProblemText, isNull);
      expect(t.couponApplied, isFalse);
    });
  });
}
