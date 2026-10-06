import '../../domain/entities/shop_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Stream<List<ShopOrder>> watchOrdersBySeller(String sellerId) =>
      _remote.watchBySeller(sellerId);

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) =>
      _remote.updateStatus(orderId, status);
}
