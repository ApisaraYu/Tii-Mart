/// สินค้า 1 รายการในรถเข็น (เก็บสำเนาชื่อ/ราคา/รูปไว้แสดงเร็ว ไม่ต้องดึงสินค้าใหม่)
class CartItem {
  const CartItem({
    required this.id,
    required this.uid,
    required this.productId,
    required this.variantId,
    required this.sellerId,
    required this.name,
    this.variantLabel = '',
    required this.price,
    required this.qty,
    this.maxQty = 99,
    this.imageUrl = '',
  });

  /// id = {uid}_{variantId} → เพิ่มตัวเลือกเดิมซ้ำ = บวกจำนวน ไม่เกิดแถวซ้ำ
  final String id;
  final String uid;
  final String productId;
  final String variantId;
  final String sellerId; // uid เจ้าของร้าน (= orders.sellerId)
  final String name;
  final String variantLabel;
  final int price; // ราคาต่อชิ้น ณ ตอนหยิบใส่รถเข็น
  final int qty;
  final int maxQty; // สต๊อกตอนหยิบใส่รถเข็น ใช้จำกัดจำนวนที่กดเพิ่มได้
  final String imageUrl;

  int get lineTotal => price * qty;

  static String idFor(String uid, String variantId) => '${uid}_$variantId';
}
