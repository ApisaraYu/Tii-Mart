import '../entities/coupon.dart';

/// ผิดพลาดจะ throw Failure (ข้อความไทย)
abstract class CouponRepository {
  Stream<List<Coupon>> watchCouponsByOwner(String ownerId);

  /// โค้ดที่ร้านเปิดใช้งานอยู่ทั้งหมด (ให้ลูกค้าดู) — กรองหมดอายุ/หมดโควต้าฝั่งแอพ
  Stream<List<Coupon>> watchActiveCoupons();

  /// สร้างใหม่ (isNew = true; ถ้ามีรหัสซ้ำในร้านจะ throw Failure) หรือแก้ไข
  Future<void> saveCoupon(Coupon coupon, {required bool isNew});

  Future<void> setActive(String couponId, bool isActive);

  Future<void> deleteCoupon(String couponId);
}
