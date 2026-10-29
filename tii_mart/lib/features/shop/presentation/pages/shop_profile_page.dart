import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../chat/domain/entities/chat.dart';
import '../../../home/presentation/widgets/customer_bottom_nav.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../products/presentation/state/product_providers.dart';
import '../state/shop_providers.dart';

/// ชื่อร้านที่แสดงให้ลูกค้า (ร้านที่ยังไม่ตั้งชื่อ = "ร้านค้า")
String shopDisplayName(String? name) =>
    (name == null || name.trim().isEmpty) ? 'ร้านค้า' : name.trim();

/// หน้าข้อมูลร้าน: ชื่อร้าน + หมวดที่ขาย + สินค้าทั้งหมดของร้าน (เฉพาะที่เปิดขาย)
class ShopProfilePage extends ConsumerStatefulWidget {
  const ShopProfilePage({super.key, required this.shopId});

  final String shopId; // = uid เจ้าของร้าน

  @override
  ConsumerState<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends ConsumerState<ShopProfilePage> {
  String? _category;

  void _chat() {
    final me = ref.read(currentUserProvider);
    if (me == null) {
      context.push('/login?from=${Uri.encodeComponent('/shop/${widget.shopId}')}');
      return;
    }
    if (me.uid == widget.shopId) return;
    context.push('/chat/${ChatThread.idFor(me.uid, widget.shopId)}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shop = ref.watch(shopProvider(widget.shopId)).value;
    final name = shopDisplayName(shop?.name);
    final productsAsync = ref.watch(activeProductsProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: AppLogo()),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(index: 0),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (all) {
          final mine = all.where((p) => p.ownerId == widget.shopId).toList();
          final cats = <String>{for (final p in mine) p.category}.toList()..sort();
          final list = _category == null
              ? mine
              : mine.where((p) => p.category == _category).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(name.characters.first.toUpperCase()),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text('สินค้าที่เปิดขาย ${mine.length} รายการ',
                                style: textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (me?.uid != widget.shopId) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _chat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('แชทกับร้านค้า'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              if (cats.length > 1) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('ทั้งหมด'),
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null),
                        ),
                      ),
                      for (final c in cats)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('ร้านนี้ยังไม่มีสินค้าที่เปิดขาย')),
                )
              else
                for (final p in list)
                  ProductCard(
                    product: p,
                    onTap: () => context.push('/product/${p.id}'),
                  ),
            ],
          );
        },
      ),
    );
  }
}
