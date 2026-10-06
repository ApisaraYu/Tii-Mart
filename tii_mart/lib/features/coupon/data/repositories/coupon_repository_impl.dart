import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../datasources/coupon_remote_datasource.dart';

class CouponRepositoryImpl implements CouponRepository {
  CouponRepositoryImpl(this._remote);

  final CouponRemoteDataSource _remote;

  @override
  Stream<List<Coupon>> watchCouponsByOwner(String ownerId) =>
      _remote.watchByOwner(ownerId);

  @override
  Future<void> saveCoupon(Coupon coupon, {required bool isNew}) =>
      _remote.save(coupon, isNew: isNew);

  @override
  Future<void> setActive(String couponId, bool isActive) =>
      _remote.setActive(couponId, isActive);

  @override
  Future<void> deleteCoupon(String couponId) => _remote.delete(couponId);
}
