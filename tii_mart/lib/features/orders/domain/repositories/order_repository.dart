import '../entities/shop_order.dart';

abstract class OrderRepository {
  /// คำสั่งซื้อของร้านนี้ (อัพเดตสด, ใหม่สุดก่อน)
  Stream<List<ShopOrder>> watchOrdersBySeller(String sellerId);

  /// เปลี่ยนสถานะคำสั่งซื้อ
  Future<void> updateStatus(String orderId, OrderStatus status);
}
