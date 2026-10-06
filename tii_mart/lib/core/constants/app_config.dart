/// ที่เก็บรูปสินค้า
enum ImageBackend { cloudinary, firebaseStorage }

class AppConfig {
  /// แผน Spark (ฟรี) ใช้ Firebase Storage ไม่ได้ (ต้องอัพเกรดเป็น Blaze) จึงใช้ Cloudinary แทน
  /// ถ้าอัพเกรดเป็น Blaze ภายหลัง เปลี่ยนเป็น ImageBackend.firebaseStorage ได้ทันที
  static const imageBackend = ImageBackend.cloudinary;

  // ===== ตั้งค่า Cloudinary (ดูวิธีหาค่าในไฟล์ README_PRODUCT.txt) =====
  static const cloudinaryCloudName = 'dc7uvelzr';
  static const cloudinaryUploadPreset = 'tiimart_unsigned';
}
