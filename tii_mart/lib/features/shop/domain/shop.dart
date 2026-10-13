/// ร้านค้า (เอกสาร shops/{uid เจ้าของ})
class Shop {
  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    this.promptPayId = '',
  });

  final String id;
  final String ownerId;
  final String name;
  final String promptPayId; // เบอร์มือถือ 10 หลัก หรือเลขบัตร 13 หลัก ใช้รับเงินผ่าน QR
}
