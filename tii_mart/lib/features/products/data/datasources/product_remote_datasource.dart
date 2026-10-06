import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

/// ส่วนที่คุยกับ Firestore (collection: products + subcollection: variants)
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  static const _timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// ไม่ใช้ orderBy ใน query เพื่อเลี่ยงการต้องสร้าง composite index — เรียงฝั่งแอพแทน
  Stream<List<Product>> watchByOwner(String ownerId) {
    return _products
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => ProductModel.fromDoc(d)).toList();
          final now = DateTime.now();
          // สินค้าที่เพิ่งบันทึก (createdAt ยังเป็น null) ถือว่าใหม่สุด
          list.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
          );
          return list;
        })
        .transform(
          StreamTransformer<List<Product>, List<Product>>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(toFailure(error), stackTrace);
            },
          ),
        );
  }

  Future<Product> get(String id) {
    return guardFirebase(() async {
      final ref = _products.doc(id);
      final snap = await ref.get();
      if (!snap.exists) {
        throw const Failure('ไม่พบสินค้านี้ (อาจถูกลบไปแล้ว)');
      }
      final variantSnap = await ref.collection('variants').get();
      final docs = variantSnap.docs.toList()
        ..sort(
          (a, b) =>
              ProductModel.variantOrder(a).compareTo(ProductModel.variantOrder(b)),
        );
      return ProductModel.fromDoc(
        snap,
        variants: docs.map(ProductModel.variantFromDoc).toList(),
      );
    });
  }

  /// บันทึกสินค้า + ตัวเลือกย่อยใน batch เดียว (สำเร็จทั้งหมดหรือไม่สำเร็จเลย)
  Future<String> save(Product p) {
    return guardFirebase(() async {
      final isNew = p.id.isEmpty;
      final ref = isNew ? _products.doc() : _products.doc(p.id);
      final batch = _db.batch();

      final data = ProductModel.toMap(p);
      if (isNew) {
        batch.set(ref, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(ref, {...data, 'updatedAt': FieldValue.serverTimestamp()});
      }

      // ลบตัวเลือกย่อยที่ถูกเอาออกตอนแก้ไข
      if (!isNew) {
        final keepIds = p.variants.map((v) => v.id).where((id) => id.isNotEmpty).toSet();
        final existing = await ref.collection('variants').get();
        for (final doc in existing.docs) {
          if (!keepIds.contains(doc.id)) batch.delete(doc.reference);
        }
      }

      // เพิ่ม/แก้ตัวเลือกย่อย
      for (var i = 0; i < p.variants.length; i++) {
        final v = p.variants[i];
        final vRef = v.id.isEmpty
            ? ref.collection('variants').doc()
            : ref.collection('variants').doc(v.id);
        batch.set(vRef, ProductModel.variantToMap(v, p.ownerId, i));
      }

      await batch.commit().timeout(_timeout);
      return ref.id;
    });
  }

  Future<void> delete(String id) {
    return guardFirebase(() async {
      final ref = _products.doc(id);
      final variants = await ref.collection('variants').get();
      final batch = _db.batch();
      for (final doc in variants.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(ref);
      await batch.commit().timeout(_timeout);
    });
  }
}
