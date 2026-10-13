import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../domain/entities/shop_order.dart';
import '../state/order_providers.dart';

/// ออเดอร์ของฉัน (หน้าย่อยของโปรไฟล์) — เลือกกรองตามสถานะ / ไปชำระเงิน / ยกเลิก
class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  OrderStatus? _filter; // null = ทั้งหมด

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('ออเดอร์ของฉัน'),
      ),
      body: orders.when(
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
          return Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('ทั้งหมด (${all.length})'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                    ),
                    for (final s in OrderStatus.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${s.label} (${all.where((o) => o.status == s).length})',
                          ),
                          selected: _filter == s,
                          onSelected: (_) => setState(() => _filter = s),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          all.isEmpty ? 'ยังไม่มีออเดอร์' : 'ไม่มีออเดอร์ในสถานะนี้',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _OrderCard(order: list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.pendingPayment => Colors.orange.shade800,
      OrderStatus.paid => Colors.blue.shade700,
      OrderStatus.shipped => Colors.indigo,
      OrderStatus.completed => Colors.green.shade700,
      OrderStatus.cancelled => Colors.red.shade700,
    };

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยกเลิกออเดอร์นี้?'),
        content: const Text('ถ้าโอนเงินไปแล้ว กรุณาติดต่อร้านค้าเพื่อขอคืนเงิน'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ไม่ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยกเลิกออเดอร์')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRemoteDataSourceProvider).cancelByCustomer(order.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final shortId = order.id.length > 6 ? order.id.substring(0, 6) : order.id;
    final pending = order.status == OrderStatus.pendingPayment;

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
            const Divider(height: 20),
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: it.imageUrl.isEmpty
                            ? const ColoredBox(color: Color(0xFFEFEFEF))
                            : Image.network(
                                it.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFFEFEFEF)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        it.variantLabel.isEmpty ? it.name : '${it.name} (${it.variantLabel})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('x${it.qty}'),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ยอดรวม'),
                Text('฿${formatBaht(order.total)}', style: textTheme.titleMedium),
              ],
            ),
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(context, ref),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.push('/payment/${order.id}'),
                      child: const Text('ชำระเงิน'),
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
