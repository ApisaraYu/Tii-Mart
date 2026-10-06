import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/di/service_providers.dart';
import '../../../../products/domain/entities/product.dart';
import '../../../../products/domain/usecases/product_usecases.dart';
import '../../../../products/presentation/state/product_providers.dart';

/// ตัวสั่งงานฝั่งร้าน: บันทึก (อัพโหลดรูป + บันทึกสินค้า) และลบสินค้า
/// state = AsyncLoading ตอนกำลังทำงาน, AsyncError(Failure) ถ้าผิดพลาด
/// ทุกเมธอดคืนค่า true เมื่อสำเร็จ
class ProductManagementController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> save({
    required Product draft,
    required List<Uint8List> newImages,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1) อัพโหลดรูปใหม่ทีละรูป ต่อท้ายรูปเดิมที่ยังเก็บไว้
      final uploader = ref.read(imageUploadServiceProvider);
      final urls = [...draft.images];
      for (final bytes in newImages) {
        urls.add(await uploader.upload(bytes, folder: 'products/${draft.ownerId}'));
      }
      // 2) บันทึกสินค้า + ตัวเลือกย่อย
      final repo = ref.read(productRepositoryProvider);
      await SaveProduct(repo)(draft.copyWith(images: urls));
    });
    return !state.hasError;
  }

  Future<bool> delete(String productId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await DeleteProduct(ref.read(productRepositoryProvider))(productId);
    });
    return !state.hasError;
  }
}

final productManagementControllerProvider =
    AsyncNotifierProvider<ProductManagementController, void>(
  ProductManagementController.new,
);
