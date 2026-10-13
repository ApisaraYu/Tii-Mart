import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/product_options.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_providers.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/product_card.dart';

/// หน้าแรกฝั่งลูกค้า ตาม wireframe (main page):
/// โลโก้ → แบนเนอร์ → ปุ่มหมวดหมู่ + ช่องค้นหา → รายการสินค้า → bottom navbar
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

  Future<void> _pickCategory() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('ทั้งหมด'),
              trailing: _category == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final c in productCategories)
              ListTile(
                title: Text(c),
                trailing: _category == c ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (result == null) return; // ปิดเมนูโดยไม่เลือก
    setState(() => _category = result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final products = ref.watch(activeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () => context.push('/login'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('เข้าสู่ระบบ'),
            ),
          if (user != null && user.isSeller)
            IconButton(
              tooltip: 'จัดการร้านค้า',
              icon: const Icon(Icons.store_mall_directory_outlined),
              onPressed: () => context.go('/seller'),
            ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(index: 0),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Banner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: OutlinedButton.icon(
                      onPressed: _pickCategory,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.tune, size: 20),
                      label: Text(
                        _category ?? 'หมวดหมู่',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาสินค้า',
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
                ],
              ),
            ),
          ),
          ...products.when<List<Widget>>(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Message(
                  icon: Icons.error_outline,
                  text: errorMessage(e),
                  actionLabel: 'ลองใหม่',
                  onAction: () => ref.invalidate(activeProductsProvider),
                ),
              ),
            ],
            data: (all) {
              final list = _filter(all);
              if (all.isEmpty || list.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: all.isEmpty
                          ? Icons.inventory_2_outlined
                          : Icons.search_off,
                      text: all.isEmpty
                          ? 'ยังไม่มีสินค้าในร้าน'
                          : 'ไม่พบสินค้าที่ค้นหา',
                    ),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                      );
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// แบนเนอร์ (ยังเป็นข้อความบนพื้นไล่สี — ภายหลังเปลี่ยนเป็นรูปโปรโมชันได้)
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.navbar, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'อุปกรณ์ไอที ใช้กับเครื่องคุณได้ไหม?',
              style: AppTheme.heading(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ดูสเปกและความเข้ากันได้ Windows / Mac ก่อนซื้อ',
              style: AppTheme.body(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
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
