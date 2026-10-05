import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/state/auth_providers.dart';

/// หน้าแรกฝั่งลูกค้า (ชั่วคราว) — ภายหลังใส่แบนเนอร์ หมวดหมู่ รายการสินค้า
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TiiMart'),
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
              'สวัสดี ${user?.fullName ?? ''}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('หน้าแรกฝั่งลูกค้า (รอใส่รายการสินค้า)'),
            if (user != null && user.isSeller) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/seller'),
                child: const Text('กลับไปจัดการร้านค้า'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
