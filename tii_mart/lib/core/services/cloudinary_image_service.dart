import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import '../errors/failure.dart';
import 'image_upload_service.dart';

/// อัพโหลดรูปไป Cloudinary แบบ unsigned preset (ไม่ต้องมีความลับในแอพ)
class CloudinaryImageService implements ImageUploadService {
  @override
  Future<String> upload(Uint8List bytes, {required String folder}) async {
    if (AppConfig.cloudinaryCloudName.startsWith('YOUR_') ||
        AppConfig.cloudinaryUploadPreset.startsWith('YOUR_')) {
      throw const Failure(
        'ยังไม่ได้ตั้งค่า Cloudinary ในไฟล์ lib/core/constants/app_config.dart',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'product.jpg'),
      );

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Failure(
          'อัพโหลดรูปไม่สำเร็จ (${response.statusCode}) ตรวจสอบ cloud name และ upload preset',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url == null) throw const Failure('อัพโหลดรูปไม่สำเร็จ ไม่ได้รับลิงก์รูปกลับมา');
      return url;
    } on Failure {
      rethrow;
    } on TimeoutException {
      throw const Failure('อัพโหลดรูปนานเกินไป กรุณาตรวจสอบอินเทอร์เน็ต');
    } catch (_) {
      throw const Failure('อัพโหลดรูปไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
    }
  }
}
