import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/state/auth_providers.dart';

/// Dashboard เจ้าของร้าน (ชั่วคราว) — ภายหลังใส่ยอดขาย ออเดอร์ใหม่ สินค้าใกล้หมด
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการร้านค้า'),
        actions: [
          IconButton(
            tooltip: 'โปรไฟล์',
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ยินดีต้อนรับ ${user?.fullName ?? ''}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Dashboard ร้านค้า (รอใส่ยอดขาย/ออเดอร์/สินค้า)'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('สลับไปโหมดลูกค้า'),
            ),
          ],
        ),
      ),
    );
  }
}
