/// สถานะคำสั่งซื้อ (ตามโฟลว์: ลูกค้าชำระเงิน → ร้านจัดส่ง → สำเร็จ)
enum OrderStatus {
  pendingPayment,
  paid,
  shipped,
  completed,
  cancelled;

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pendingPayment,
    );
  }

  String get label => switch (this) {
        OrderStatus.pendingPayment => 'รอชำระเงิน',
        OrderStatus.paid => 'ชำระแล้ว รอจัดส่ง',
        OrderStatus.shipped => 'จัดส่งแล้ว',
        OrderStatus.completed => 'สำเร็จ',
        OrderStatus.cancelled => 'ยกเลิก',
      };

  /// นับเป็นยอดขายหรือไม่ (ชำระเงินแล้วและไม่ถูกยกเลิก)
  bool get countsAsSale =>
      this == OrderStatus.paid ||
      this == OrderStatus.shipped ||
      this == OrderStatus.completed;

  /// ร้านค้ากดเปลี่ยนไปสถานะถัดไปได้ (null = ไม่มีขั้นถัดไป)
  OrderStatus? get next => switch (this) {
        OrderStatus.paid => OrderStatus.shipped,
        OrderStatus.shipped => OrderStatus.completed,
        _ => null,
      };

  String? get nextActionLabel => switch (this) {
        OrderStatus.paid => 'ยืนยันจัดส่งแล้ว',
        OrderStatus.shipped => 'ลูกค้าได้รับแล้ว',
        _ => null,
      };

  bool get canCancel =>
      this == OrderStatus.pendingPayment || this == OrderStatus.paid;
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    this.variantLabel = '',
    required this.price,
    required this.qty,
    this.imageUrl = '',
  });

  final String productId;
  final String name;
  final String variantLabel;
  final int price; // ราคาต่อชิ้น (บาท) ณ ตอนสั่งซื้อ
  final int qty;
  final String imageUrl;
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.sellerId,
    required this.customerId,
    this.customerName = '',
    required this.items,
    required this.total,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String sellerId;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final DateTime? createdAt;
}
