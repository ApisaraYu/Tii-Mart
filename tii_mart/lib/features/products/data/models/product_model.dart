import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';

/// แปลง Product/Variant <-> Firestore
/// products/{id}                 ข้อมูลสินค้า
/// products/{id}/variants/{vid}  ตัวเลือกย่อย (สี/ขนาด + ราคา + สต๊อก)
class ProductModel {
  static int _int(Object? v) => v is num ? v.toInt() : 0;
  static String _str(Object? v) => v is String ? v : '';

  static Product fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<Variant> variants = const [],
  }) {
    final d = doc.data() ?? <String, dynamic>{};
    final specs = (d['specs'] as Map<String, dynamic>?) ?? const {};
    final createdAt = d['createdAt'];

    return Product(
      id: doc.id,
      ownerId: _str(d['ownerId']),
      shopId: _str(d['shopId']),
      name: _str(d['name']),
      description: _str(d['description']),
      category: _str(d['category']),
      brand: _str(d['brand']),
      specs: ProductSpecs(
        cpu: _str(specs['cpu']),
        ram: _str(specs['ram']),
        storage: _str(specs['storage']),
        os: _str(specs['os']),
        ports: ((specs['ports'] as List?) ?? const []).whereType<String>().toList(),
      ),
      images: ((d['images'] as List?) ?? const []).whereType<String>().toList(),
      variants: variants,
      minPrice: _int(d['minPrice']),
      totalStock: _int(d['totalStock']),
      isActive: d['isActive'] as bool? ?? true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  /// ข้อมูลสินค้าที่เขียนลง Firestore (ไม่รวม createdAt/updatedAt ซึ่งใส่ตอนบันทึก)
  static Map<String, dynamic> toMap(Product p) {
    return {
      'ownerId': p.ownerId,
      'shopId': p.shopId,
      'name': p.name.trim(),
      'description': p.description.trim(),
      'category': p.category,
      'brand': p.brand.trim(),
      'specs': {
        'cpu': p.specs.cpu.trim(),
        'ram': p.specs.ram.trim(),
        'storage': p.specs.storage.trim(),
        'os': p.specs.os,
        'ports': p.specs.ports,
      },
      'images': p.images,
      'minPrice': p.minPrice,
      'totalStock': p.totalStock,
      'isActive': p.isActive,
      'keywords': buildKeywords(p.name, p.brand, p.category),
    };
  }

  static Variant variantFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Variant(
      id: doc.id,
      color: _str(d['color']),
      size: _str(d['size']),
      price: _int(d['price']),
      stock: _int(d['stock']),
    );
  }

  static int variantOrder(DocumentSnapshot<Map<String, dynamic>> doc) =>
      _int((doc.data() ?? const {})['order']);

  static Map<String, dynamic> variantToMap(Variant v, String ownerId, int order) {
    return {
      'ownerId': ownerId,
      'color': v.color.trim(),
      'size': v.size.trim(),
      'price': v.price,
      'stock': v.stock,
      'order': order,
    };
  }

  /// คำสำหรับค้นหาแบบขึ้นต้นด้วยคำ (Firestore ไม่มี full-text search / ภาษาไทยไม่มีเว้นวรรค)
  /// เก็บ "ทุกคำนำหน้า" ของชื่อ ยี่ห้อ หมวดหมู่ แล้วค้นด้วย array-contains
  static List<String> buildKeywords(String name, String brand, String category) {
    final result = <String>{};

    void addPrefixes(String text) {
      final t = text.trim().toLowerCase();
      for (var i = 1; i <= t.length && i <= 30; i++) {
        result.add(t.substring(0, i));
      }
    }

    addPrefixes(name);
    for (final word in name.toLowerCase().split(RegExp(r'\s+'))) {
      if (word.isNotEmpty) addPrefixes(word);
    }
    addPrefixes(brand);
    addPrefixes(category);
    return result.toList();
  }
}
