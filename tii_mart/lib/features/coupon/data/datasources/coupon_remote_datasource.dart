import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/coupon.dart';

/// collection: coupons — id เอกสาร = "{ownerId}_{CODE}" จึงสร้างรหัสซ้ำในร้านเดียวกันไม่ได้
class CouponRemoteDataSource {
  CouponRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> get _coupons =>
      _db.collection('coupons');

  Stream<List<Coupon>> watchByOwner(String ownerId) {
    return _coupons
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(_fromDoc).toList();
          final now = DateTime.now();
          list.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
          );
          return list;
        })
        .transform(
          StreamTransformer<List<Coupon>, List<Coupon>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(toFailure(error), stackTrace);
            },
          ),
        );
  }

  /// โค้ดที่เปิดใช้งานทั้งหมด (ไม่ใช้ orderBy เพื่อเลี่ยง composite index)
  Stream<List<Coupon>> watchActive() {
    return _coupons
        .where('isActive', isEqualTo: true)
        .limit(200)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(_fromDoc).toList();
          final now = DateTime.now();
          list.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
          );
          return list;
        })
        .transform(
          StreamTransformer<List<Coupon>, List<Coupon>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(toFailure(error), stackTrace);
            },
          ),
        );
  }

  Future<void> save(Coupon c, {required bool isNew}) {
    return guardFirebase(() async {
      final code = c.code.trim().toUpperCase();
      final ref = _coupons.doc(isNew ? '${c.ownerId}_$code' : c.id);

      if (isNew) {
        final exists = (await ref.get()).exists;
        if (exists) throw Failure('มีโค้ด $code อยู่แล้ว กรุณาใช้รหัสอื่น');
        await ref.set({
          'ownerId': c.ownerId,
          'code': code,
          ..._editableFields(c),
          'used': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      } else {
        await ref.update({
          ..._editableFields(c),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(_timeout);
      }
    });
  }

  Future<void> setActive(String id, bool isActive) {
    return guardFirebase(() async {
      await _coupons.doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    });
  }

  Future<void> delete(String id) {
    return guardFirebase(() async {
      await _coupons.doc(id).delete().timeout(_timeout);
    });
  }

  static Map<String, dynamic> _editableFields(Coupon c) => {
        'description': c.description,
        'type': c.type.name,
        'value': c.value,
        'minSpend': c.minSpend,
        'quantity': c.quantity,
        'isActive': c.isActive,
        'expiresAt':
            c.expiresAt == null ? null : Timestamp.fromDate(c.expiresAt!),
      };

  static String _s(Object? v) => v is String ? v : '';
  static int _i(Object? v) => v is num ? v.toInt() : 0;

  static Coupon _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final exp = d['expiresAt'];
    final created = d['createdAt'];
    return Coupon(
      id: doc.id,
      ownerId: _s(d['ownerId']),
      code: _s(d['code']),
      description: _s(d['description']),
      type: DiscountType.fromString(_s(d['type'])),
      value: _i(d['value']),
      minSpend: _i(d['minSpend']),
      quantity: _i(d['quantity']),
      used: _i(d['used']),
      isActive: d['isActive'] != false,
      expiresAt: exp is Timestamp ? exp.toDate() : null,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
