import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../home/presentation/widgets/customer_bottom_nav.dart';
import '../../domain/entities/cart_item.dart';
import '../state/cart_providers.dart';
import '../../../../app/theme/app_theme.dart';

/// หน้ารถเข็น (ตาม wireframe: cart)
/// รายการสินค้า (รูป/ชื่อ/ตัวเลือก/จำนวน/ติ๊กเลือก/ราคา) → แถบเลือกคูปอง → ราคาทั้งหมด → ปุ่มไปหน้าชำระเงิน
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartItemsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('รถเข็น'),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: AppLogo()),
        ],
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorMessage(e), textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyCart();
          return Column(
            children: [
              Expanded(child: _CartList(items: items)),
              const _SummaryBar(),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(index: 1),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('รถเข็นยังว่างอยู่'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('ไปเลือกสินค้า'),
          ),
        ],
      ),
    );
  }
}

class _CartList extends ConsumerWidget {
  const _CartList({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(cartSelectionProvider);

    // จัดกลุ่มตามร้าน (คงลำดับตามสินค้าที่เพิ่มล่าสุด)
    final shops = <String, List<CartItem>>{};
    for (final i in items) {
      shops.putIfAbsent(i.sellerId, () => []).add(i);
    }
    var shopNo = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        for (final entry in shops.entries) ...[
          () {
            shopNo++;
            final allOn = entry.value.every((i) => selected.contains(i.id));
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: allOn,
                    onChanged: (_) => ref
                        .read(cartSelectionProvider.notifier)
                        .toggleShop(entry.key, items),
                  ),
                  const Icon(Icons.storefront_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text('ร้านที่ $shopNo', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            );
          }(),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartRow(item: item, all: items),
            ),
          const SizedBox(height: 6),
        ],
        Text(
          'ชำระเงินได้ครั้งละ 1 ร้าน — ติ๊กเลือกสินค้าของร้านที่ต้องการชำระก่อน',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({required this.item, required this.all});

  final CartItem item;
  final List<CartItem> all;

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _setQty(BuildContext context, WidgetRef ref, int qty) async {
    try {
      await ref.read(cartDataSourceProvider).setQty(item.id, qty);
    } catch (e) {
      if (context.mounted) _snack(context, errorMessage(e));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    ref.read(cartSelectionProvider.notifier).remove(item.id);
    try {
      await ref.read(cartDataSourceProvider).remove(item.id);
    } catch (e) {
      if (context.mounted) _snack(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final checked = ref.watch(cartSelectionProvider.select((s) => s.contains(item.id)));

    // กดเพิ่มซ้ำจนเกินสต๊อก → ปรับกลับเป็นจำนวนสูงสุดที่มี
    if (item.qty > item.maxQty && item.maxQty > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _setQty(context, ref, item.maxQty);
      });
    }

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _remove(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: checked ? Border.all(color: primary, width: 1.5) : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.imageUrl.isEmpty
                    ? ColoredBox(
 color: context.placeholder(const Color(0xFFEFEFEF)),
                        child: Icon(Icons.image_not_supported_outlined),
                      )
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
 color: context.placeholder(const Color(0xFFEFEFEF)),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                  if (item.variantLabel.isNotEmpty)
                    Text(item.variantLabel, style: textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        onTap: item.qty > 1 ? () => _setQty(context, ref, item.qty - 1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${item.qty}', style: textTheme.titleSmall),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        onTap: item.qty < item.maxQty
                            ? () => _setQty(context, ref, item.qty + 1)
                            : () => _snack(context, 'มีสินค้าในสต๊อก ${item.maxQty} ชิ้น'),
                      ),
                      const Spacer(),
                      Text(
                        '฿${formatBaht(item.lineTotal)}',
                        style: textTheme.titleSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (_) =>
                  ref.read(cartSelectionProvider.notifier).toggle(item, all),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(
            color: onTap == null ? context.ink12 : context.ink38,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? context.ink26 : null),
      ),
    );
  }
}

/// แถบล่าง: เลือกคูปอง > ราคาทั้งหมด > ปุ่มไปหน้าชำระเงิน (ตาม wireframe)
class _SummaryBar extends ConsumerWidget {
  const _SummaryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCartItemsProvider);
    final coupon = ref.watch(selectedCouponProvider);
    final totals = ref.watch(cartTotalsProvider);
    final textTheme = Theme.of(context).textTheme;
    final hasSelection = selected.isNotEmpty;
    final problem = totals.couponProblemText;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            enabled: hasSelection,
            leading: const Icon(Icons.local_offer_outlined),
            title: Text(
              coupon == null
                  ? 'เลือกคูปองส่วนลด'
                  : problem == null
                      ? 'ใช้โค้ด ${coupon.code}'
                      : 'โค้ด ${coupon.code} ใช้ไม่ได้',
            ),
            subtitle: coupon == null
                ? null
                : problem != null
                    ? Text(problem, style: TextStyle(color: context.tone(Colors.red.shade700)))
                    : coupon.isFreeShipping
                        ? const Text('ส่งฟรี — หักค่าส่งในหน้าชำระเงิน')
                        : Text('ลดไป ฿${formatBaht(totals.discount)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: hasSelection ? () => context.push('/cart/coupons') : null,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ราคาทั้งหมด', style: textTheme.titleSmall),
                Text(
                  '฿${formatBaht(totals.afterDiscount)}',
                  style: textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: hasSelection ? () => context.push('/checkout') : null,
              child: Text(
                hasSelection ? 'ไปหน้าชำระเงิน (${selected.length})' : 'เลือกสินค้าที่ต้องการชำระ',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
