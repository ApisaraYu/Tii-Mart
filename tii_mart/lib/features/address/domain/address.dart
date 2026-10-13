/// ที่อยู่จัดส่งของลูกค้า
class Address {
  const Address({
    this.id = '',
    required this.uid,
    this.label = '',
    required this.recipientName,
    required this.phone,
    required this.line1,
    this.subdistrict = '',
    this.district = '',
    required this.province,
    required this.postalCode,
    this.isDefault = false,
  });

  final String id; // ว่าง = ยังไม่บันทึก
  final String uid;
  final String label; // เช่น บ้าน / ที่ทำงาน
  final String recipientName;
  final String phone;
  final String line1; // บ้านเลขที่ ถนน ซอย
  final String subdistrict;
  final String district;
  final String province;
  final String postalCode;
  final bool isDefault;

  /// ที่อยู่แบบบรรทัดเดียว
  String get fullText => [
        line1,
        if (subdistrict.isNotEmpty) subdistrict,
        if (district.isNotEmpty) district,
        province,
        postalCode,
      ].join(' ');

  /// สำเนาที่ใส่ในออเดอร์ (ที่อยู่แก้ภายหลัง ออเดอร์เก่าต้องไม่เปลี่ยน)
  Map<String, dynamic> toSnapshot() => {
        'recipientName': recipientName,
        'phone': phone,
        'line1': line1,
        'subdistrict': subdistrict,
        'district': district,
        'province': province,
        'postalCode': postalCode,
      };
}
