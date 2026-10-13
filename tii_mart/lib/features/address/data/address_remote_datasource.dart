import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/address.dart';

/// collection: addresses/{auto}
///   { uid, label, recipientName, phone, line1, subdistrict, district, province, postalCode, isDefault, createdAt }
class AddressRemoteDataSource {
  AddressRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('addresses');

  Stream<List<Address>> watch(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(_fromDoc).toList();
          // ค่าเริ่มต้นขึ้นก่อน
          list.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
          return list;
        })
        .transform(
          StreamTransformer<List<Address>, List<Address>>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(toFailure(error), stackTrace),
          ),
        );
  }

  /// บันทึก (ใหม่/แก้ไข) — ถ้าตั้งเป็นค่าเริ่มต้น จะปลดค่าเริ่มต้นของอันอื่นใน batch เดียวกัน
  Future<void> save(Address a, {required List<Address> existing}) {
    return guardFirebase(() async {
      final ref = a.id.isEmpty ? _col.doc() : _col.doc(a.id);
      final batch = _db.batch();
      final makeDefault = a.isDefault || existing.isEmpty;
      if (makeDefault) {
        for (final other in existing) {
          if (other.id != a.id && other.isDefault) {
            batch.update(_col.doc(other.id), {'isDefault': false});
          }
        }
      }
      batch.set(
        ref,
        {
          'uid': a.uid,
          'label': a.label,
          'recipientName': a.recipientName,
          'phone': a.phone,
          'line1': a.line1,
          'subdistrict': a.subdistrict,
          'district': a.district,
          'province': a.province,
          'postalCode': a.postalCode,
          'isDefault': makeDefault,
          if (a.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit().timeout(_timeout);
    });
  }

  Future<void> delete(String id) {
    return guardFirebase(() async {
      await _col.doc(id).delete().timeout(_timeout);
    });
  }

  static Address _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    String s(String k) => d[k] is String ? d[k] as String : '';
    return Address(
      id: doc.id,
      uid: s('uid'),
      label: s('label'),
      recipientName: s('recipientName'),
      phone: s('phone'),
      line1: s('line1'),
      subdistrict: s('subdistrict'),
      district: s('district'),
      province: s('province'),
      postalCode: s('postalCode'),
      isDefault: d['isDefault'] == true,
    );
  }
}
