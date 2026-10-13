import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/format.dart';
import '../../../../orders/domain/entities/shop_order.dart';
import '../../../../orders/presentation/state/order_providers.dart';

/// ออเดอร์ของร้าน: กรองตามสถานะ + เปลี่ยนสถานะ (จัดส่ง / สำเร็จ / ยกเลิก)
class SellerOrdersPage extends ConsumerStatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  ConsumerState<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends ConsumerState<SellerOrdersPage> {
  OrderStatus? _filter; // null = ทั้งหมด

  Future<void> _change(ShopOrder order, OrderStatus status) async {
    if (status == OrderStatus.cancelled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ยกเลิกคำสั่งซื้อ'),
          content: const Text('ต้องการยกเลิกคำสั่งซื้อนี้ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ไม่'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ยกเลิกออเดอร์'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final done = await ref
        .read(orderManagementControllerProvider.notifier)
        .updateStatus(order.id, status);
    if (done && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('เปลี่ยนสถานะเป็น "${status.label}" แล้ว')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(orderManagementControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(next.error))));
      }
    });
    final busy = ref.watch(orderManagementControllerProvider).isLoading;
    final orders = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ออเดอร์')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip('ทั้งหมด', _filter == null, () => setState(() => _filter = null)),
                for (final s in OrderStatus.values)
                  _chip(s.label, _filter == s, () => setState(() => _filter = s)),
              ],
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(errorMessage(e), textAlign: TextAlign.center),
                ),
              ),
              data: (all) {
                final list = _filter == null
                    ? all
                    : all.where((o) => o.status == _filter).toList();
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty
                          ? 'ยังไม่มีคำสั่งซื้อ'
                          : 'ไม่มีออเดอร์ในสถานะนี้',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _OrderCard(
                    order: list[i],
                    busy: busy,
                    onChange: (s) => _change(list[i], s),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.busy,
    required this.onChange,
  });

  final ShopOrder order;
  final bool busy;
  final void Function(OrderStatus) onChange;

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pendingPayment => Colors.orange.shade800,
        OrderStatus.paid => Colors.blue.shade800,
        OrderStatus.shipped => Colors.indigo.shade700,
        OrderStatus.completed => Colors.green.shade800,
        OrderStatus.cancelled => Colors.red.shade700,
      };

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final next = order.status.next;
    final shortId = order.id.length > 6 ? order.id.substring(0, 6) : order.id;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('#${shortId.toUpperCase()}', style: textTheme.titleSmall),
                ),
                Text(
                  order.status.label,
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (order.createdAt != null)
              Text(formatDateTime(order.createdAt!), style: textTheme.bodySmall),
            if (order.customerName.isNotEmpty)
              Text(
                'ผู้รับ: ${order.customerName}'
                '${order.recipientPhone.isEmpty ? '' : ' • ${order.recipientPhone}'}',
                style: textTheme.bodySmall,
              ),
            if (order.addressText.isNotEmpty)
              Text('ที่อยู่: ${order.addressText}', style: textTheme.bodySmall),
            const Divider(height: 20),
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        it.variantLabel.isEmpty
                            ? it.name
                            : '${it.name} (${it.variantLabel})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('x${it.qty}'),
                  ],
                ),
              ),
            const Divider(height: 20),
            if (order.subtotal > 0) ...[
              _line('ค่าสินค้า', '฿${formatBaht(order.subtotal)}'),
              if (order.discount > 0)
                _line('ส่วนลด', '-฿${formatBaht(order.discount)}'),
              _line(
                'ค่าส่ง${order.shippingLabel.isEmpty ? '' : ' (${order.shippingLabel})'}',
                '฿${formatBaht(order.shippingFee + order.shippingDiscount)}',
              ),
              if (order.shippingDiscount > 0)
                _line('ส่วนลดค่าส่ง', '-฿${formatBaht(order.shippingDiscount)}'),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ยอดรวม'),
                Text('฿${formatBaht(order.total)}', style: textTheme.titleMedium),
              ],
            ),
            if (next != null || order.status.canCancel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.status.canCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            busy ? null : () => onChange(OrderStatus.cancelled),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                  if (order.status.canCancel && next != null)
                    const SizedBox(width: 12),
                  if (next != null)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: busy ? null : () => onChange(next),
                        child: Text(order.status.nextActionLabel ?? 'ถัดไป'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
