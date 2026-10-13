/// ตัวเลือกจัดส่ง (ตาม wireframe: เร็ว 50 บาท / ปกติ 12 บาท)
enum ShippingOption {
  fast('เร็ว', 50),
  normal('ปกติ', 12);

  const ShippingOption(this.label, this.fee);
  final String label;
  final int fee;
}
