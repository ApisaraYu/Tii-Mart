import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/product_usecases.dart';

// ---------- dependency injection ----------

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSource(ref.watch(firestoreProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider));
});

// ---------- ข้อมูล ----------

/// สินค้าทั้งหมดของเจ้าของร้านที่ล็อกอินอยู่ (อัพเดตสด)
final sellerProductsProvider = StreamProvider<List<Product>>((ref) {
  // select เฉพาะ uid เพื่อไม่ให้เริ่มดึงข้อมูลใหม่ทุกครั้งที่แก้โปรไฟล์
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<Product>>.value(const []);
  return WatchSellerProducts(ref.watch(productRepositoryProvider))(uid);
});
