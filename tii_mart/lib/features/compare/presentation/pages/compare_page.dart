import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../home/presentation/widgets/customer_bottom_nav.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_providers.dart';
import '../state/compare_providers.dart';
import '../../../../app/theme/app_theme.dart';

/// เปรียบเทียบสินค้า 2 ชิ้นแบบเคียงข้างกัน (ราคา สเปก พอร์ต) แถวที่ต่างกันจะไฮไลต์
class ComparePage extends ConsumerWidget {
  const ComparePage({super.key});

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    int slot,
    List<Product> all,
    List<String> selected,
  ) async {
    // เสนอสินค้าหมวดเดียวกับอีกช่องก่อน
    final otherId = selected[1 - slot];
    final other = all.where((p) => p.id == otherId).firstOrNull;
    final options = all.where((p) => p.id != otherId).toList()
      ..sort((a, b) {
        final sa = other != null && a.category == other.category ? 0 : 1;
        final sb = other != null && b.category == other.category ? 0 : 1;
        return sa.compareTo(sb);
      });

    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: options.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('ไม่มีสินค้าอื่นให้เลือก'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in options)
                      ListTile(
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [if (p.brand.isNotEmpty) p.brand, p.category].join(' • '),
                        ),
                        trailing: Text('฿${formatBaht(p.minPrice)}'),
                        onTap: () => Navigator.pop(ctx, p.id),
                      ),
                  ],
                ),
        ),
      ),
    );
    if (id != null) ref.read(compareSelectionProvider.notifier).setAt(slot, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(compareSelectionProvider);
    final productsAsync = ref.watch(activeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เปรียบเทียบสินค้า'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(compareSelectionProvider.notifier).clear(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('ล้าง'),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(index: 0),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (all) {
          Product? find(String id) => all.where((p) => p.id == id).firstOrNull;
          final a = find(selected[0]);
          final b = find(selected[1]);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Slot(
                      product: a,
                      onPick: () => _pick(context, ref, 0, all, selected),
                      onOpen: a == null ? null : () => context.push('/product/${a.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Slot(
                      product: b,
                      onPick: () => _pick(context, ref, 1, all, selected),
                      onOpen: b == null ? null : () => context.push('/product/${b.id}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (a == null || b == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('เลือกสินค้าให้ครบ 2 ชิ้นเพื่อเริ่มเปรียบเทียบ')),
                )
              else
                _Table(a: a, b: b),
            ],
          );
        },
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.product, required this.onPick, this.onOpen});

  final Product? product;
  final VoidCallback onPick;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: p == null
          ? InkWell(
              onTap: onPick,
              child: const SizedBox(
                height: 190,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 36),
                      SizedBox(height: 8),
                      Text('เลือกสินค้า'),
                    ],
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onOpen,
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: p.images.isEmpty
                        ? ColoredBox(
 color: context.placeholder(const Color(0xFFEAEAEA)),
                            child: Icon(Icons.image_outlined, size: 36),
                          )
                        : Image.network(
                            p.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
 color: context.placeholder(const Color(0xFFEAEAEA)),
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ),
                TextButton(onPressed: onPick, child: const Text('เปลี่ยนสินค้า')),
              ],
            ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.a, required this.b});

  final Product a;
  final Product b;

  @override
  Widget build(BuildContext context) {
    String dash(String s) => s.trim().isEmpty ? '-' : s.trim();
    String ports(Product p) => p.specs.ports.isEmpty ? '-' : p.specs.ports.join(', ');
    String stock(Product p) => p.totalStock <= 0 ? 'หมด' : '${p.totalStock} ชิ้น';

    // พอร์ตที่มีเฉพาะฝั่งใดฝั่งหนึ่ง (ช่วยเช็กความเข้ากันได้ เช่น ต้องมี HDMI)
    final pa = a.specs.ports.toSet();
    final pb = b.specs.ports.toSet();
    final onlyA = pa.difference(pb).join(', ');
    final onlyB = pb.difference(pa).join(', ');

    final cheaper = a.minPrice == b.minPrice ? null : (a.minPrice < b.minPrice ? 0 : 1);

    final rows = <_Row>[
      _Row('ราคาเริ่มต้น', '฿${formatBaht(a.minPrice)}', '฿${formatBaht(b.minPrice)}',
          good: cheaper),
      _Row('แบรนด์', dash(a.brand), dash(b.brand)),
      _Row('หมวดหมู่', dash(a.category), dash(b.category)),
      _Row('CPU', dash(a.specs.cpu), dash(b.specs.cpu)),
      _Row('RAM', dash(a.specs.ram), dash(b.specs.ram)),
      _Row('พื้นที่เก็บข้อมูล', dash(a.specs.storage), dash(b.specs.storage)),
      _Row('ระบบปฏิบัติการ', dash(a.specs.os), dash(b.specs.os)),
      _Row('พอร์ต', ports(a), ports(b)),
      _Row('พอร์ตที่มีเฉพาะชิ้นนี้', dash(onlyA), dash(onlyB)),
      _Row('สต๊อก', stock(a), stock(b)),
    ];

    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) _line(context, rows[i], i),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, _Row r, int i) {
    final diff = r.a != r.b;
    final textTheme = Theme.of(context).textTheme;
    Widget cell(String text, bool good) => Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: good ? FontWeight.w700 : null,
              color: good ? context.tone(Colors.green.shade800) : null,
            ),
          ),
        );
    return Container(
      color: diff
          ? (context.isDark ? const Color(0x33FFC107) : const Color(0xFFFFF6D9))
          : null,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.label, style: textTheme.labelMedium),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cell(r.a, r.good == 0),
              const SizedBox(width: 12),
              cell(r.b, r.good == 1),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.a, this.b, {this.good});
  final String label;
  final String a;
  final String b;
  final int? good; // 0 / 1 = ฝั่งที่ดีกว่า (เช่น ราคาถูกกว่า)
}
