import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/format.dart';
import '../../../../products/domain/entities/product.dart';
import '../../../../products/presentation/state/product_providers.dart';
import '../state/product_management_controller.dart';
import '../../../../../app/theme/app_theme.dart';

/// รายการสินค้าของร้าน (Read) + ปุ่มเพิ่ม (Create) / แก้ไข (Update) / ลบ (Delete)
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบสินค้า'),
        content: Text('ต้องการลบ "${product.name}" ใช่หรือไม่?\nลบแล้วกู้คืนไม่ได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(productManagementControllerProvider.notifier)
        .delete(product.id);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสินค้าเรียบร้อย')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(productManagementControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(next.error))));
      }
    });
    final busy = ref.watch(productManagementControllerProvider).isLoading;
    final products = ref.watch(sellerProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('สินค้าของฉัน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => context.push('/seller/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
      ),
      body: Stack(
        children: [
          products.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(errorMessage(e), textAlign: TextAlign.center),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'ยังไม่มีสินค้าในร้าน\nกดปุ่ม "เพิ่มสินค้า" เพื่อเริ่มต้น',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return _ProductCard(
                    product: p,
                    onEdit: () => context.push('/seller/products/${p.id}/edit'),
                    onDelete: () => _confirmDelete(context, ref, p),
                  );
                },
              );
            },
          ),
          if (busy)
            const ModalBarrier(dismissible: false, color: Colors.black26),
          if (busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final image = product.images.isEmpty ? null : product.images.first;

    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 60,
            height: 60,
            child: image == null
                ? ColoredBox(
 color: context.placeholder(const Color(0xFFE6E6E6)),
                    child: Icon(Icons.image_outlined),
                  )
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${product.category}\nเริ่มต้น ${formatBaht(product.minPrice)} บาท  •  คงเหลือ ${product.totalStock} ชิ้น',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
            PopupMenuItem(value: 'delete', child: Text('ลบ')),
          ],
        ),
      ),
    );
  }
}
