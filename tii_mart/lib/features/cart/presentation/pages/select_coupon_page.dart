import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../coupon/domain/entities/coupon.dart';
import '../../../coupon/presentation/state/coupon_providers.dart';
import '../state/cart_providers.dart';

/// เลือกโค้ดส่วนลด (ตาม wireframe: select coupon) — ใช้ได้ 1 โค้ดต่อการชำระเงิน
/// แสดงเฉพาะโค้ดของร้านที่ติ๊กเลือกสินค้าอยู่ โค้ดที่ยอดไม่ถึงขั้นต่ำจะกดไม่ได้
class SelectCouponPage extends ConsumerStatefulWidget {
  const SelectCouponPage({super.key});

  @override
  ConsumerState<SelectCouponPage> createState() => _SelectCouponPageState();
}

class _SelectCouponPageState extends ConsumerState<SelectCouponPage> {
  late String? _pickedId = ref.read(selectedCouponProvider)?.id;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(selectedCartItemsProvider);
    final sellerId = items.isEmpty ? null : items.first.sellerId;
    final subtotal = ref.watch(cartTotalsProvider).subtotal;
    final coupons = ref.watch(availableCouponsProvider);
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกโค้ดส่วนลด')),
      body: coupons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorMessage(e))),
        data: (all) {
          final list = all.where((c) => c.ownerId == sellerId).toList();
          if (list.isEmpty) {
            return const Center(child: Text('ร้านนี้ยังไม่มีโค้ดส่วนลดที่ใช้ได้'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final c = list[i];
              final ok = subtotal >= c.minSpend;
              final picked = _pickedId == c.id;
              final discountText = c.discountLabel;
              return Opacity(
                opacity: ok ? 1 : 0.5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: ok ? () => setState(() => _pickedId = picked ? null : c.id) : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: picked ? Border.all(color: primary, width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            discountText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.code, style: textTheme.titleSmall),
                              if (c.description.isNotEmpty)
                                Text(c.description, style: textTheme.bodySmall),
                              Text(
                                ok
                                    ? 'จำนวนโค้ดที่เหลือ ${c.remaining}'
                                    : 'ซื้อขั้นต่ำ ฿${formatBaht(c.minSpend)} (ยอดตอนนี้ ฿${formatBaht(subtotal)})',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: picked,
                          onChanged: ok
                              ? (_) => setState(() => _pickedId = picked ? null : c.id)
                              : null,
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final all = ref.read(availableCouponsProvider).value ?? const <Coupon>[];
                final chosen = all.where((c) => c.id == _pickedId).firstOrNull;
                ref.read(selectedCouponProvider.notifier).set(chosen);
                context.pop();
              },
              child: const Text('ยืนยัน'),
            ),
          ),
        ),
      ),
    );
  }
}
