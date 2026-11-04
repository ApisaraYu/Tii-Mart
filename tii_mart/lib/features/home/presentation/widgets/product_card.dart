import 'package:flutter/material.dart';

import '../../../../core/utils/format.dart';
import '../../../products/domain/entities/product.dart';
import '../../../../app/theme/app_theme.dart';

/// แถวสินค้าในหน้า Home ตาม wireframe: รูปซ้าย / ชื่อ + คำอธิบาย + ราคา ขวา
/// (เป็นแถวความสูงยืดตามเนื้อหา จึงไม่เกิด bottom overflow เหมือนแบบกริด)
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = product.totalStock <= 0;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = product.description.isNotEmpty
        ? product.description
        : [if (product.brand.isNotEmpty) product.brand, product.category]
            .join(' • ');

    return Card(
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.images.isEmpty)
                    ColoredBox(
 color: context.placeholder(const Color(0xFFEAEAEA)),
                      child: Icon(Icons.image_outlined, size: 36),
                    )
                  else
                    Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
 color: context.placeholder(const Color(0xFFEAEAEA)),
                        child: Icon(Icons.broken_image_outlined, size: 36),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '฿${formatBaht(product.minPrice)}',
                      style: textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
