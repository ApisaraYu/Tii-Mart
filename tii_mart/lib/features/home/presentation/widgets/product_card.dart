import 'package:flutter/material.dart';

import '../../../../core/utils/format.dart';
import '../../../products/domain/entities/product.dart';

/// การ์ดสินค้าในหน้า Home (รูป ชื่อ ยี่ห้อ ราคาเริ่มต้น)
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = product.totalStock <= 0;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.images.isEmpty)
                    const ColoredBox(
                      color: Color(0xFFEAEAEA),
                      child: Icon(Icons.image_outlined, size: 40),
                    )
                  else
                    Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEAEAEA),
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
                  if (soldOut)
                    const ColoredBox(
                      color: Colors.black45,
                      child: Center(
                        child: Text(
                          'สินค้าหมด',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '฿${formatBaht(product.minPrice)}',
                    style: textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
