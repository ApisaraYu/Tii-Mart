import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/entities/cart_item.dart';

/// collection: carts/{uid_variantId}
///   { uid, productId, variantId, sellerId, name, variantLabel, price, qty, maxQty, imageUrl, addedAt }
class CartRemoteDataSource {
  CartRemoteDataSource(this._db);

  final FirebaseFirestore _db;
  static const _timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> get _carts => _db.collection('carts');

  Stream<List<CartItem>> watch(String uid) {
    return _carts
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          final now = DateTime.now();
          DateTime at(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              (d.data()['addedAt'] as Timestamp?)?.toDate() ?? now;
          docs.sort((a, b) => at(b).compareTo(at(a))); // ใหม่สุดอยู่บน
          return docs.map(_fromDoc).toList();
        })
        .transform(
          StreamTransformer<List<CartItem>, List<CartItem>>.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(toFailure(error), stackTrace),
          ),
        );
  }

  /// หยิบใส่รถเข็น: ถ้ามีตัวเลือกนี้แล้วให้บวกจำนวน (ไม่เกิน maxQty)
    Future<void> add(CartItem item) {
    return guardFirebase(() async {
      await _carts.doc(item.id).set(
        {
          'uid': item.uid,
          'productId': item.productId,
          'variantId': item.variantId,
          'sellerId': item.sellerId,
          'name': item.name,
          'variantLabel': item.variantLabel,
          'price': item.price,
          'qty': FieldValue.increment(item.qty),
          'maxQty': item.maxQty,
          'imageUrl': item.imageUrl,
          'addedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ).timeout(_timeout);
    });
  }

  Future<void> setQty(String id, int qty) {
    return guardFirebase(() async {
      await _carts.doc(id).update({'qty': qty}).timeout(_timeout);
    });
  }

  Future<void> remove(String id) {
    return guardFirebase(() async {
      await _carts.doc(id).delete().timeout(_timeout);
    });
  }

  static CartItem _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    String s(String k) => d[k] is String ? d[k] as String : '';
    int i(String k, int fallback) => d[k] is num ? (d[k] as num).toInt() : fallback;
    return CartItem(
      id: doc.id,
      uid: s('uid'),
      productId: s('productId'),
      variantId: s('variantId'),
      sellerId: s('sellerId'),
      name: s('name'),
      variantLabel: s('variantLabel'),
      price: i('price', 0),
      qty: i('qty', 1),
      maxQty: i('maxQty', 99),
      imageUrl: s('imageUrl'),
    );
  }
}
