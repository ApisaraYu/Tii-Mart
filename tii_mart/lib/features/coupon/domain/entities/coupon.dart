enum DiscountType {
  percent, // ลดเป็น % ของค่าสินค้า
  fixed, // ลดเป็นบาท
  freeShipping; // ส่งฟรี: value = ลดค่าส่งสูงสุดกี่บาท (0 = ฟรีเต็มจำนวน)

  static DiscountType fromString(String? v) => switch (v) {
        'fixed' => DiscountType.fixed,
        'freeShipping' => DiscountType.freeShipping,
        _ => DiscountType.percent,
      };
}

/// โค้ดส่วนลดของร้าน
class Coupon {
  const Coupon({
    this.id = '',
    required this.ownerId,
    required this.code,
    this.description = '',
    required this.type,
    required this.value,
    this.minSpend = 0,
    required this.quantity,
    this.used = 0,
    this.isActive = true,
    this.expiresAt,
    this.createdAt,
  });

  final String id; // ว่าง = ยังไม่บันทึก
  final String ownerId;
  final String code; // ตัวพิมพ์ใหญ่ เช่น TII50
  final String description;
  final DiscountType type;
  final int value; // percent: 1-100 / fixed: บาท
  final int minSpend; // ยอดซื้อขั้นต่ำ (บาท) 0 = ไม่มี
  final int quantity; // จำนวนโค้ดทั้งหมด
  final int used; // ใช้ไปแล้ว
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isFreeShipping => type == DiscountType.freeShipping;

  /// ข้อความส่วนลดสั้นๆ ใช้โชว์ในการ์ด
  String get discountLabel => switch (type) {
        DiscountType.percent => 'ลด $value%',
        DiscountType.fixed => 'ลด ฿$value',
        DiscountType.freeShipping =>
          value > 0 ? 'ส่งฟรี\n(ไม่เกิน ฿$value)' : 'ส่งฟรี',
      };

  /// จำนวนโค้ดที่เหลือ
  int get remaining => (quantity - used).clamp(0, quantity);

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// ใช้งานได้จริง = เปิดอยู่ ไม่หมดอายุ และยังมีโค้ดเหลือ
  bool get isUsable => isActive && !isExpired && remaining > 0;
}
