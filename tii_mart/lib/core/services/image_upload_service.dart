import 'dart:typed_data';

/// อัพโหลดรูป 1 รูป แล้วคืน URL ที่เปิดดูได้
/// (มีหลาย backend: Cloudinary / Firebase Storage — เลือกที่ AppConfig.imageBackend)
abstract class ImageUploadService {
  Future<String> upload(Uint8List bytes, {required String folder});
}
