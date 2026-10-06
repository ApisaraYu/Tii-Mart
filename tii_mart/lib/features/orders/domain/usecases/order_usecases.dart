import '../entities/shop_order.dart';
import '../repositories/order_repository.dart';

class WatchSellerOrders {
  const WatchSellerOrders(this._repo);
  final OrderRepository _repo;

  Stream<List<ShopOrder>> call(String sellerId) =>
      _repo.watchOrdersBySeller(sellerId);
}

class UpdateOrderStatus {
  const UpdateOrderStatus(this._repo);
  final OrderRepository _repo;

  Future<void> call(String orderId, OrderStatus status) =>
      _repo.updateStatus(orderId, status);
}
