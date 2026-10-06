import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../errors/error_mapper.dart';
import 'image_upload_service.dart';

/// อัพโหลดรูปไป Firebase Storage (ต้องใช้แผน Blaze)
class FirebaseStorageImageService implements ImageUploadService {
  FirebaseStorageImageService(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> upload(Uint8List bytes, {required String folder}) {
    return guardFirebase(() async {
      final ref = _storage.ref('$folder/${DateTime.now().microsecondsSinceEpoch}.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    });
  }
}
