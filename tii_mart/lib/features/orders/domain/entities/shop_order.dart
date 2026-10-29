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
        OrderStatus.pendingPayment => OrderStatus.paid,
        OrderStatus.paid => OrderStatus.shipped,
        OrderStatus.shipped => OrderStatus.completed,
        _ => null,
      };

  String? get nextActionLabel => switch (this) {
        OrderStatus.pendingPayment => 'ยืนยันรับชำระเงิน',
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
    this.variantId = '',
    required this.name,
    this.variantLabel = '',
    required this.price,
    required this.qty,
    this.imageUrl = '',
  });

  final String productId;
  final String variantId;
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
    this.subtotal = 0,
    this.discount = 0,
    this.shippingFee = 0,
    this.shippingDiscount = 0,
    this.shippingLabel = '',
    this.couponId,
    this.recipientName = '',
    this.recipientPhone = '',
    this.addressText = '',
  });

  final String id;
  final String sellerId;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final int total;
  final OrderStatus status;
  final DateTime? createdAt;
  final int subtotal; // ราคาสินค้ารวมก่อนหักส่วนลด
  final int discount;
  final int shippingFee; // ค่าส่งที่ลูกค้าจ่ายจริง (หลังหักส่วนลดค่าส่งแล้ว)
  final int shippingDiscount; // ส่วนลดค่าส่งจากโค้ดส่งฟรี
  final String shippingLabel; // เช่น "เร็ว" / "ปกติ"
  final String? couponId;
  final String recipientName; // จากสำเนาที่อยู่ในออเดอร์
  final String recipientPhone;
  final String addressText;
}
