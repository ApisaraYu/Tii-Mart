import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_config.dart';
import '../../../core/errors/failure.dart';
import '../domain/entities/chat.dart';

/// อัพโหลดรูป/วิดีโอแชทไป Cloudinary (unsigned preset เดียวกับรูปสินค้า)
/// ใช้ endpoint /auto/upload เพื่อให้รับได้ทั้งรูปและวิดีโอ
class ChatMediaUploader {
  /// วิดีโอใหญ่สุด 50 MB (แพ็กเกจฟรีของ Cloudinary จำกัดไฟล์วิดีโอที่ 100 MB)
  static const maxVideoBytes = 50 * 1024 * 1024;

  Future<String> upload(
    Uint8List bytes, {
    required MessageType type,
    required String chatId,
  }) async {
    if (AppConfig.cloudinaryCloudName.startsWith('YOUR_') ||
        AppConfig.cloudinaryUploadPreset.startsWith('YOUR_')) {
      throw const Failure(
        'ยังไม่ได้ตั้งค่า Cloudinary ในไฟล์ lib/core/constants/app_config.dart',
      );
    }
    if (type == MessageType.video && bytes.length > maxVideoBytes) {
      throw const Failure('วิดีโอใหญ่เกินไป (ส่งได้ไม่เกิน 50 MB)');
    }

    final isVideo = type == MessageType.video;
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/auto/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = 'chats/$chatId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: isVideo ? 'chat.mp4' : 'chat.jpg',
        ),
      );

    try {
      final streamed = await request
          .send()
          .timeout(Duration(minutes: isVideo ? 5 : 1));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Failure(
          'อัพโหลดไม่สำเร็จ (${response.statusCode}) ตรวจสอบ upload preset ของ Cloudinary',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url == null) throw const Failure('อัพโหลดไม่สำเร็จ ไม่ได้รับลิงก์กลับมา');
      return url;
    } on Failure {
      rethrow;
    } on TimeoutException {
      throw const Failure('อัพโหลดนานเกินไป กรุณาตรวจสอบอินเทอร์เน็ต');
    } catch (_) {
      throw const Failure('อัพโหลดไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
    }
  }

  /// ภาพตัวอย่างของวิดีโอ: Cloudinary สร้างให้เมื่อเปลี่ยนนามสกุลลิงก์เป็น .jpg
  static String videoThumbnail(String videoUrl) =>
      videoUrl.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '.jpg');
}
