import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../data/datasources/coupon_remote_datasource.dart';
import '../../data/repositories/coupon_repository_impl.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../../domain/usecases/coupon_usecases.dart';

final couponRemoteDataSourceProvider = Provider<CouponRemoteDataSource>((ref) {
  return CouponRemoteDataSource(ref.watch(firestoreProvider));
});

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepositoryImpl(ref.watch(couponRemoteDataSourceProvider));
});

/// โค้ดส่วนลดของร้านที่ล็อกอินอยู่ (อัพเดตสด)
final sellerCouponsProvider = StreamProvider<List<Coupon>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<Coupon>>.value(const []);
  return WatchSellerCoupons(ref.watch(couponRepositoryProvider))(uid);
});

/// ตัวสั่งงาน: สร้าง/แก้ไข/เปิด-ปิด/ลบ (คืน true เมื่อสำเร็จ)
class CouponManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  CouponRepository get _repo => ref.read(couponRepositoryProvider);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> save(Coupon coupon, {required bool isNew}) =>
      _run(() => SaveCoupon(_repo)(coupon, isNew: isNew));

  Future<bool> setActive(String id, bool value) =>
      _run(() => SetCouponActive(_repo)(id, value));

  Future<bool> delete(String id) => _run(() => DeleteCoupon(_repo)(id));
}

final couponManagementControllerProvider =
    AsyncNotifierProvider<CouponManagementController, void>(
  CouponManagementController.new,
);
