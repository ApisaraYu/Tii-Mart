import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/firebase_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../data/address_remote_datasource.dart';
import '../../domain/address.dart';

final addressDataSourceProvider = Provider<AddressRemoteDataSource>((ref) {
  return AddressRemoteDataSource(ref.watch(firestoreProvider));
});

final addressesProvider = StreamProvider<List<Address>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream<List<Address>>.value(const []);
  return ref.watch(addressDataSourceProvider).watch(uid);
});

/// ที่อยู่ที่ลูกค้าเลือกใช้ตอนชำระเงิน (null = ใช้ที่อยู่เริ่มต้น/อันแรก)
class SelectedAddressId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final selectedAddressIdProvider =
    NotifierProvider<SelectedAddressId, String?>(SelectedAddressId.new);

/// ที่อยู่ที่จะใช้จริง: อันที่เลือก → อันเริ่มต้น → อันแรก → null (ยังไม่มีที่อยู่)
final checkoutAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesProvider).value ?? const <Address>[];
  if (list.isEmpty) return null;
  final id = ref.watch(selectedAddressIdProvider);
  for (final a in list) {
    if (a.id == id) return a;
  }
  return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
});
