import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../data/datasources/checkout_remote_datasource.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/shop_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order_usecases.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSource(ref.watch(firestoreProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderRemoteDataSourceProvider));
});

final checkoutDataSourceProvider = Provider<CheckoutRemoteDataSource>((ref) {
  return CheckoutRemoteDataSource(ref.watch(firestoreProvider));
});

/// ออเดอร์เดียวแบบสด (หน้าชำระเงิน)
final orderByIdProvider = StreamProvider.family<ShopOrder?, String>((ref, id) {
  return ref.watch(orderRemoteDataSourceProvider).watchById(id);
});

final paymentProvider = StreamProvider.family<Payment?, String>((ref, orderId) {
  return ref.watch(checkoutDataSourceProvider).watchPayment(orderId);
});

/// คำสั่งซื้อของฉันในฐานะลูกค้า (อัพเดตสด)
final myOrdersProvider = StreamProvider<List<ShopOrder>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<ShopOrder>>.value(const []);
  return ref.watch(orderRemoteDataSourceProvider).watchByCustomer(uid);
});

/// คำสั่งซื้อของร้านที่ล็อกอินอยู่ (อัพเดตสด)
final sellerOrdersProvider = StreamProvider<List<ShopOrder>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<ShopOrder>>.value(const []);
  return WatchSellerOrders(ref.watch(orderRepositoryProvider))(uid);
});

/// ตัวสั่งงาน: เปลี่ยนสถานะคำสั่งซื้อ (คืน true เมื่อสำเร็จ)
class OrderManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateStatus(String orderId, OrderStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await UpdateOrderStatus(ref.read(orderRepositoryProvider))(orderId, status);
    });
    return !state.hasError;
  }
}

final orderManagementControllerProvider =
    AsyncNotifierProvider<OrderManagementController, void>(
  OrderManagementController.new,
);
