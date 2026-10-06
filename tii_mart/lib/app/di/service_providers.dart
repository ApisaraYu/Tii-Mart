import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_config.dart';
import '../../core/services/cloudinary_image_service.dart';
import '../../core/services/firebase_storage_image_service.dart';
import '../../core/services/image_upload_service.dart';

/// ตัวอัพโหลดรูป เลือก backend ได้ที่ AppConfig.imageBackend
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  switch (AppConfig.imageBackend) {
    case ImageBackend.cloudinary:
      return CloudinaryImageService();
    case ImageBackend.firebaseStorage:
      return FirebaseStorageImageService(FirebaseStorage.instance);
  }
});
