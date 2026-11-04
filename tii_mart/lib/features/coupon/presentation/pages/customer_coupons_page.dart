import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/format.dart';
import '../../../home/presentation/widgets/customer_bottom_nav.dart';
import '../../domain/entities/coupon.dart';
import '../state/coupon_providers.dart';

/// หน้าดูโค้ดส่วนลดฝั่งลูกค้า (ดู + คัดลอกรหัส — การใช้โค้ดจริงจะอยู่ตอนชำระเงิน)
class CustomerCouponsPage extends ConsumerWidget {
  const CustomerCouponsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(availableCouponsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('โค้ดส่วนลด')),
      bottomNavigationBar: const CustomerBottomNav(index: 2),
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
            return const Center(child: Text('ยังไม่มีโค้ดส่วนลดในตอนนี้'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CouponCard(coupon: list[i]),
          );
        },
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});

  final Coupon coupon;

  String get _discountText => coupon.discountLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 96,
              color: primary,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Text(
                _discountText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.code, style: textTheme.titleMedium),
                    if (coupon.description.isNotEmpty)
                      Text(coupon.description, style: textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (coupon.minSpend > 0)
                          'ขั้นต่ำ ฿${formatBaht(coupon.minSpend)}',
                        'เหลือ ${coupon.remaining} สิทธิ์',
                        if (coupon.expiresAt != null)
                          'หมดอายุ ${formatDate(coupon.expiresAt!)}',
                      ].join(' • '),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'คัดลอกโค้ด',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: coupon.code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('คัดลอกโค้ด ${coupon.code} แล้ว')),
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
