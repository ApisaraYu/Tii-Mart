import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/shop.dart';

/// collection: shops/{ownerUid}  { ownerId, name, promptPayId, createdAt, updatedAt }
class ShopRemoteDataSource {
  ShopRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);

  DocumentReference<Map<String, dynamic>> _ref(String id) =>
      _db.collection('shops').doc(id);

  Stream<Shop?> watch(String shopId) {
    return _ref(shopId)
        .snapshots()
        .map((d) {
          if (!d.exists) return null;
          final m = d.data()!;
          return Shop(
            id: d.id,
            ownerId: (m['ownerId'] ?? '') as String,
            name: (m['name'] ?? '') as String,
            promptPayId: (m['promptPayId'] ?? '') as String,
          );
        })
        .transform(
          StreamTransformer<Shop?, Shop?>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(toFailure(error), stackTrace),
          ),
        );
  }

  /// สร้างหรืออัพเดตร้านของเจ้าของ (id = uid)
  Future<void> save({
    required String ownerId,
    required String name,
    required String promptPayId,
    required bool isNew,
  }) {
    return guardFirebase(() async {
      await _ref(ownerId).set(
        {
          'ownerId': ownerId,
          'name': name,
          'promptPayId': promptPayId,
          'updatedAt': FieldValue.serverTimestamp(),
          if (isNew) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).timeout(_timeout);
    });
  }
}
