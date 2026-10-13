import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../data/shop_remote_datasource.dart';
import '../../domain/shop.dart';

final shopDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  return ShopRemoteDataSource(ref.watch(firestoreProvider));
});

/// ร้านตาม id (= uid เจ้าของร้าน) — ใครก็อ่านได้
final shopProvider = StreamProvider.family<Shop?, String>((ref, shopId) {
  return ref.watch(shopDataSourceProvider).watch(shopId);
});
