import '../entities/product.dart';

/// interface ของสินค้า — ผิดพลาดจะ throw Failure (ข้อความไทย)
abstract class ProductRepository {
  /// สินค้าทั้งหมดของเจ้าของร้านคนนี้ (อัพเดตสด, ใหม่สุดก่อน; ยังไม่โหลด variants)
  Stream<List<Product>> watchProductsByOwner(String ownerId);

  /// สินค้าที่เปิดขายทั้งหมด สำหรับหน้าลูกค้า (อัพเดตสด, ใหม่สุดก่อน; ยังไม่โหลด variants)
  Stream<List<Product>> watchActiveProducts();

  /// สินค้า 1 ชิ้นพร้อมตัวเลือกย่อยครบ
  Future<Product> getProduct(String id);

  /// สร้าง (id ว่าง) หรือแก้ไข (มี id) พร้อมตัวเลือกย่อย แล้วคืน id
  Future<String> saveProduct(Product product);

  /// ลบสินค้าพร้อมตัวเลือกย่อย
  Future<void> deleteProduct(String id);
}
