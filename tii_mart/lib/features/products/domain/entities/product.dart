/// ตัวเลือกย่อยของสินค้า เช่น สีดำ / 16GB (แต่ละตัวมีราคาและสต๊อกของตัวเอง)
class Variant {
  const Variant({
    this.id = '',
    this.color = '',
    this.size = '',
    required this.price,
    required this.stock,
  });

  final String id; // ว่าง = ยังไม่เคยบันทึก
  final String color;
  final String size;
  final int price; // บาท (จำนวนเต็ม)
  final int stock;

  /// ข้อความแสดงตัวเลือก เช่น "ดำ / 16GB" (ถ้าไม่มีทั้งสีและขนาด = "มาตรฐาน")
  String get label {
    final parts = [color, size].where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'มาตรฐาน' : parts.join(' / ');
  }
}

/// สเปกสินค้า (จุดเด่นของแอพ: ใช้เปรียบเทียบและเช็กความเข้ากันได้)
class ProductSpecs {
  const ProductSpecs({
    this.cpu = '',
    this.ram = '',
    this.storage = '',
    this.os = '',
    this.ports = const [],
  });

  final String cpu;
  final String ram;
  final String storage;
  final String os;
  final List<String> ports;
}

class Product {
  const Product({
    required this.id,
    required this.ownerId,
    required this.shopId,
    required this.name,
    this.description = '',
    required this.category,
    this.brand = '',
    this.specs = const ProductSpecs(),
    this.images = const [],
    this.variants = const [],
    required this.minPrice,
    required this.totalStock,
    this.isActive = true,
    this.createdAt,
  });

  final String id; // ว่าง = สินค้าใหม่ที่ยังไม่บันทึก
  final String ownerId;
  final String shopId;
  final String name;
  final String description;
  final String category;
  final String brand;
  final ProductSpecs specs;
  final List<String> images; // URL
  final List<Variant> variants; // โหลดเฉพาะตอนเปิดดู/แก้ไขรายละเอียด
  final int minPrice; // ราคาต่ำสุดของตัวเลือกทั้งหมด (ใช้โชว์ในรายการ)
  final int totalStock; // สต๊อกรวมทุกตัวเลือก
  final bool isActive;
  final DateTime? createdAt;

  Product copyWith({List<String>? images}) {
    return Product(
      id: id,
      ownerId: ownerId,
      shopId: shopId,
      name: name,
      description: description,
      category: category,
      brand: brand,
      specs: specs,
      images: images ?? this.images,
      variants: variants,
      minPrice: minPrice,
      totalStock: totalStock,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
