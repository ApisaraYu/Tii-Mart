import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../address/presentation/state/address_providers.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../orders/domain/entities/shipping_option.dart';
import '../../../orders/presentation/state/order_providers.dart';
import '../../domain/entities/cart_item.dart';
import '../state/cart_providers.dart';
import '../../../../app/theme/app_theme.dart';

/// ยืนยัน / เลือกที่จัดส่ง (ตาม wireframe: confirm page)
/// ที่อยู่ → สินค้า → ประเภทจัดส่ง → โค้ดที่ใช้ → ช่องทางชำระเงิน → สรุปราคา → ยืนยัน
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  ShippingOption _shipping = ShippingOption.normal;
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirm(List<CartItem> items, int discount, int shippingDiscount) async {
    final me = ref.read(currentUserProvider);
    final address = ref.read(checkoutAddressProvider);
    if (me == null) return;
    if (address == null) {
      _snack('กรุณาเพิ่มที่อยู่จัดส่งก่อน');
      return;
    }
    setState(() => _busy = true);
    try {
      final coupon = ref.read(selectedCouponProvider);
      final orderId = await ref.read(checkoutDataSourceProvider).placeOrder(
            customerId: me.uid,
            items: items,
            address: address,
            shipping: _shipping,
            discount: discount,
            shippingDiscount: shippingDiscount,
            couponId: (discount > 0 || shippingDiscount > 0) ? coupon?.id : null,
          );
      ref.read(cartSelectionProvider.notifier).clear();
      ref.read(selectedCouponProvider.notifier).set(null);
      if (mounted) context.go('/payment/$orderId');
    } catch (e) {
      _snack(errorMessage(e));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(selectedCartItemsProvider);
    final totals = ref.watch(cartTotalsProvider);
    final coupon = ref.watch(selectedCouponProvider);
    final address = ref.watch(checkoutAddressProvider);
    final addressesLoading = ref.watch(addressesProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final shipDiscount = totals.shippingDiscount(_shipping.fee);
    final total = totals.afterDiscount + _shipping.fee - shipDiscount;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ยืนยัน / เลือกที่จัดส่ง')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ยังไม่ได้เลือกสินค้า'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/cart'),
                child: const Text('กลับไปรถเข็น'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยัน / เลือกที่จัดส่ง')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- ที่อยู่ ----
          _Card(
            onTap: () => context.push('/addresses/pick'),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: addressesLoading
                      ? const Text('กำลังโหลดที่อยู่...')
                      : address == null
                          ? Text(
                              'ยังไม่มีที่อยู่จัดส่ง — แตะเพื่อเพิ่ม',
                              style: TextStyle(color: context.tone(Colors.red.shade700)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${address.recipientName} • ${address.phone}',
                                  style: textTheme.titleSmall,
                                ),
                                Text(address.fullText, style: textTheme.bodySmall),
                              ],
                            ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- สินค้า ----
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  _ItemRow(item: items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- ประเภทการจัดส่ง ----
          Text('ประเภทการจัดส่ง', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final opt in ShippingOption.values)
                  RadioListTile<ShippingOption>(
                    value: opt,
                    groupValue: _shipping,
                    onChanged: (v) => setState(() => _shipping = v!),
                    title: Text(opt.label),
                    secondary: Text('฿${opt.fee}', style: textTheme.titleSmall),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- โค้ดที่ใช้ ----
          _Card(
            onTap: () => context.push('/cart/coupons'),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, color: primary),
                const SizedBox(width: 10),
                const Expanded(child: Text('โค้ดที่ถูกใช้')),
                Flexible(
                  child: Text(
                    totals.couponProblemText != null
                        ? '${coupon?.code} ใช้ไม่ได้'
                        : coupon == null
                            ? 'ไม่ได้ใช้'
                            : coupon.isFreeShipping
                                ? '${coupon.code} (ส่งฟรี)'
                                : '${coupon.code} (-฿${formatBaht(totals.discount)})',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.end,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- ช่องทางชำระเงิน ----
          Text('ช่องทางการชำระเงิน', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _Card(
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: primary),
                const SizedBox(width: 10),
                const Expanded(child: Text('QR พร้อมเพย์')),
                Icon(Icons.check_circle, color: primary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- สรุปราคา ----
          _Card(
            child: Column(
              children: [
                _SumRow('ค่าสินค้า (ก่อนหักส่วนลด)', '฿${formatBaht(totals.subtotal)}'),
                _SumRow(
                  'ค่าสินค้า (หลังหักส่วนลด)',
                  '฿${formatBaht(totals.afterDiscount)}',
                ),
                _SumRow('ค่าส่ง (${_shipping.label})', '฿${formatBaht(_shipping.fee)}'),
                if (shipDiscount > 0)
                  _SumRow('ส่วนลดค่าส่ง', '-฿${formatBaht(shipDiscount)}'),
                const Divider(),
                _SumRow('ทั้งหมด', '฿${formatBaht(total)}', bold: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _busy || address == null
                  ? null
                  : () => _confirm(items, totals.discount, shipDiscount),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('ยืนยัน ฿${formatBaht(total)}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 64,
            child: item.imageUrl.isEmpty
                ? ColoredBox(
 color: context.placeholder(const Color(0xFFEFEFEF)))
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
 color: context.placeholder(const Color(0xFFEFEFEF))),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
              if (item.variantLabel.isNotEmpty)
                Text(item.variantLabel, style: textTheme.bodySmall),
              Text('x${item.qty}', style: textTheme.bodySmall),
            ],
          ),
        ),
        Text('฿${formatBaht(item.lineTotal)}', style: textTheme.titleSmall),
      ],
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            )
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}
