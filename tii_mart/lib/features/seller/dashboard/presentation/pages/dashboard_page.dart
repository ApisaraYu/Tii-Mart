import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/format.dart';
import '../../../../auth/presentation/state/auth_providers.dart';
import '../../../../orders/domain/entities/shop_order.dart';
import '../../../../orders/presentation/state/order_providers.dart';
import '../../../../products/domain/entities/product.dart';
import '../../../../products/presentation/state/product_providers.dart';

/// สินค้าที่เหลือไม่เกินค่านี้ถือว่า "ใกล้หมด"
const _lowStockThreshold = 5;

/// แดชบอร์ดร้านค้า: สรุปการขาย + สถานะสินค้า + ทางลัด
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final products = ref.watch(sellerProductsProvider);
    final orders = ref.watch(sellerOrdersProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดร้านค้า'),
        actions: [
          IconButton(
            tooltip: 'สลับไปโหมดลูกค้า',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.go('/'),
          ),
          IconButton(
            tooltip: 'โปรไฟล์',
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('สวัสดี ${user?.fullName ?? ''}', style: textTheme.titleLarge),
          const SizedBox(height: 16),

          // ---------- สถานะการขาย ----------
          Text('สถานะการขาย', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          orders.when(
            loading: () => const _Loading(),
            error: (e, _) => _ErrorText(errorMessage(e)),
            data: (list) {
              final sales = list.where((o) => o.status.countsAsSale);
              final revenue = sales.fold<int>(0, (s, o) => s + o.total);
              int count(OrderStatus s) =>
                  list.where((o) => o.status == s).length;
              return Column(
                children: [
                  Row(
                    children: [
                      _StatTile(
                        label: 'ยอดขายรวม',
                        value: '฿${formatBaht(revenue)}',
                        icon: Icons.payments_outlined,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        label: 'ออเดอร์ทั้งหมด',
                        value: '${list.length}',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatTile(
                        label: 'รอจัดส่ง',
                        value: '${count(OrderStatus.paid)}',
                        icon: Icons.local_shipping_outlined,
                        highlight: count(OrderStatus.paid) > 0,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        label: 'รอชำระเงิน',
                        value: '${count(OrderStatus.pendingPayment)}',
                        icon: Icons.hourglass_empty,
                      ),
                    ],
                  ),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('ยังไม่มีคำสั่งซื้อ ตัวเลขจะขึ้นเมื่อลูกค้าสั่งซื้อ'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ---------- สถานะสินค้า ----------
          Text('สถานะสินค้า', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          products.when(
            loading: () => const _Loading(),
            error: (e, _) => _ErrorText(errorMessage(e)),
            data: (list) {
              final low = list
                  .where((p) => p.totalStock > 0 && p.totalStock <= _lowStockThreshold)
                  .toList();
              final out = list.where((p) => p.totalStock <= 0).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatTile(
                        label: 'สินค้าทั้งหมด',
                        value: '${list.length}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        label: 'ใกล้หมด / หมด',
                        value: '${low.length} / ${out.length}',
                        icon: Icons.warning_amber_rounded,
                        highlight: low.isNotEmpty || out.isNotEmpty,
                      ),
                    ],
                  ),
                  if (low.isNotEmpty || out.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.white,
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final p in [...out, ...low].take(5))
                            _StockRow(product: p),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ---------- ทางลัด ----------
          Text('ทางลัด', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/seller/products/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มสินค้า'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/seller/coupons/new'),
                  icon: const Icon(Icons.local_offer_outlined),
                  label: const Text('สร้างโค้ด'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: highlight ? Colors.orange[800] : primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: highlight ? Colors.orange[800] : primary,
                ),
              ),
              Text(label, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final out = product.totalStock <= 0;
    return ListTile(
      dense: true,
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        out ? 'หมด' : 'เหลือ ${product.totalStock}',
        style: TextStyle(
          color: out ? Colors.red[700] : Colors.orange[800],
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => context.push('/seller/products/${product.id}/edit'),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: TextStyle(color: Colors.red[700])),
      );
}
