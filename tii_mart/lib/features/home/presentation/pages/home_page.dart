import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/product_options.dart';
import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_providers.dart';
import '../widgets/product_card.dart';

/// หน้าแรกฝั่งลูกค้า: ค้นหา + หมวดหมู่ + รายการสินค้า
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category; // null = ทั้งหมด

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// กรองฝั่งแอพ: ชื่อ/ยี่ห้อ/หมวดหมู่ มีคำค้นอยู่ (ใช้ได้กับภาษาไทย ไม่ต้องตัดคำ)
  List<Product> _filter(List<Product> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_category != null && p.category != _category) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final products = ref.watch(activeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TiiMart'),
        actions: [
          if (user != null && user.isSeller)
            IconButton(
              tooltip: 'จัดการร้านค้า',
              icon: const Icon(Icons.storefront),
              onPressed: () => context.go('/seller'),
            ),
          IconButton(
            tooltip: 'โปรไฟล์',
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้า เช่น โน้ตบุ๊ก, คีย์บอร์ด',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('ทั้งหมด', _category == null, () {
                  setState(() => _category = null);
                }),
                for (final c in productCategories)
                  _chip(c, _category == c, () => setState(() => _category = c)),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Message(
                icon: Icons.error_outline,
                text: errorMessage(e),
                actionLabel: 'ลองใหม่',
                onAction: () => ref.invalidate(activeProductsProvider),
              ),
              data: (all) {
                final list = _filter(all);
                if (all.isEmpty) {
                  return const _Message(
                    icon: Icons.inventory_2_outlined,
                    text: 'ยังไม่มีสินค้าในร้าน',
                  );
                }
                if (list.isEmpty) {
                  return const _Message(
                    icon: Icons.search_off,
                    text: 'ไม่พบสินค้าที่ค้นหา',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return ProductCard(
                      product: p,
                      onTap: () => context.push('/product/${p.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
