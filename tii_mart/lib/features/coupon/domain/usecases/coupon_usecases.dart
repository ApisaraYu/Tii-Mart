import '../entities/coupon.dart';
import '../repositories/coupon_repository.dart';

class WatchSellerCoupons {
  const WatchSellerCoupons(this._repo);
  final CouponRepository _repo;

  Stream<List<Coupon>> call(String ownerId) =>
      _repo.watchCouponsByOwner(ownerId);
}

class WatchAvailableCoupons {
  const WatchAvailableCoupons(this._repo);
  final CouponRepository _repo;

  Stream<List<Coupon>> call() => _repo.watchActiveCoupons();
}

class SaveCoupon {
  const SaveCoupon(this._repo);
  final CouponRepository _repo;

  Future<void> call(Coupon coupon, {required bool isNew}) =>
      _repo.saveCoupon(coupon, isNew: isNew);
}

class SetCouponActive {
  const SetCouponActive(this._repo);
  final CouponRepository _repo;

  Future<void> call(String couponId, bool isActive) =>
      _repo.setActive(couponId, isActive);
}

class DeleteCoupon {
  const DeleteCoupon(this._repo);
  final CouponRepository _repo;

  Future<void> call(String couponId) => _repo.deleteCoupon(couponId);
}
