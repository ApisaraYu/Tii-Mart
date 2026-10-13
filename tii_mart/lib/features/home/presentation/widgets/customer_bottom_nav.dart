import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/state/auth_providers.dart';
import '../../../chat/presentation/widgets/chat_nav_icon.dart';

/// แถบเมนูล่างฝั่งลูกค้า (ตาม wireframe: bottom navbar) — หน้าแรก / รถเข็น / โค้ด / แชท / โปรไฟล์
/// ผู้เยี่ยมชมที่ยังไม่ล็อกอิน: รถเข็น/โปรไฟล์ จะพาไปหน้าเข้าสู่ระบบ
class CustomerBottomNav extends ConsumerWidget {
  const CustomerBottomNav({super.key, this.index = 0});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(currentUserProvider) != null;

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/');
          case 1:
            if (!loggedIn) {
              context.push('/login');
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('ระบบรถเข็นจะเพิ่มในขั้นถัดไป')),
              );
          case 2:
            context.push(loggedIn ? '/coupons' : '/login');
          case 3:
            context.push(loggedIn ? '/chats' : '/login');
          case 4:
            context.push(loggedIn ? '/profile' : '/login');
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'หน้าแรก',
        ),
        const NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'รถเข็น',
        ),
        const NavigationDestination(
          icon: Icon(Icons.local_offer_outlined),
          selectedIcon: Icon(Icons.local_offer),
          label: 'โค้ด',
        ),
        const NavigationDestination(
          icon: ChatNavIcon(),
          selectedIcon: ChatNavIcon(selected: true),
          label: 'แชท',
        ),
        NavigationDestination(
          icon: Icon(loggedIn ? Icons.person_outline : Icons.login),
          selectedIcon: const Icon(Icons.person),
          label: loggedIn ? 'โปรไฟล์' : 'เข้าสู่ระบบ',
        ),
      ],
    );
  }
}
