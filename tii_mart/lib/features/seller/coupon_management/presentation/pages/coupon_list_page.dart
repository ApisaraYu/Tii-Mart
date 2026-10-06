import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/utils/format.dart';
import '../../../../coupon/domain/entities/coupon.dart';
import '../../../../coupon/presentation/state/coupon_providers.dart';

/// โค้ดส่วนลดของร้าน: ดูจำนวนที่เหลือ เปิด/ปิด แก้ไข ลบ
class CouponListPage extends ConsumerWidget {
  const CouponListPage({super.key});

  static String discountLabel(Coupon c) => c.type == DiscountType.percent
      ? 'ลด ${c.value}%'
      : 'ลด ฿${formatBaht(c.value)}';

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Coupon c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบโค้ดส่วนลด'),
        content: Text('ต้องการลบโค้ด ${c.code} ใช่หรือไม่?'),
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
    if (ok != true) return;
    await ref.read(couponManagementControllerProvider.notifier).delete(c.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(couponManagementControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(next.error))));
      }
    });
    final busy = ref.watch(couponManagementControllerProvider).isLoading;
    final coupons = ref.watch(sellerCouponsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('โค้ดส่วนลด')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => context.push('/seller/coupons/new'),
        icon: const Icon(Icons.add),
        label: const Text('สร้างโค้ด'),
      ),
      body: coupons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorMessage(e), textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ยังไม่มีโค้ดส่วนลด\nกดปุ่ม "สร้างโค้ด" เพื่อเริ่มต้น',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final c = list[i];
              final note = c.isExpired
                  ? 'หมดอายุแล้ว'
                  : c.remaining == 0
                      ? 'โค้ดหมดแล้ว'
                      : null;
              return Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/seller/coupons/edit', extra: c),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.code, style: textTheme.titleMedium),
                              if (c.description.isNotEmpty)
                                Text(c.description, style: textTheme.bodySmall),
                              const SizedBox(height: 6),
                              Text(
                                '${discountLabel(c)}'
                                '${c.minSpend > 0 ? ' • ขั้นต่ำ ฿${formatBaht(c.minSpend)}' : ''}',
                              ),
                              Text(
                                'จำนวนโค้ดที่เหลือ ${c.remaining}/${c.quantity}',
                                style: textTheme.bodySmall,
                              ),
                              if (c.expiresAt != null)
                                Text(
                                  'หมดอายุ ${formatDate(c.expiresAt!)}',
                                  style: textTheme.bodySmall,
                                ),
                              if (note != null)
                                Text(
                                  note,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Switch(
                              value: c.isActive,
                              onChanged: busy
                                  ? null
                                  : (v) => ref
                                      .read(couponManagementControllerProvider.notifier)
                                      .setActive(c.id, v),
                            ),
                            IconButton(
                              tooltip: 'ลบ',
                              icon: const Icon(Icons.delete_outline),
                              onPressed:
                                  busy ? null : () => _confirmDelete(context, ref, c),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
