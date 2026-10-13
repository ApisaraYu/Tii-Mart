import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../chat/presentation/widgets/chat_nav_icon.dart';

/// โครงหน้าฝั่งร้านค้า: แถบเมนูล่างของตัวเอง (แยกจากฝั่งลูกค้า)
/// แดชบอร์ด / สินค้า / ออเดอร์ / แชท / โค้ดส่วนลด
class SellerShell extends StatelessWidget {
  const SellerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          // กดแท็บเดิมซ้ำ = กลับไปหน้าแรกของแท็บนั้น
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'แดชบอร์ด',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'สินค้า',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'ออเดอร์',
          ),
          NavigationDestination(
            icon: ChatNavIcon(),
            selectedIcon: ChatNavIcon(selected: true),
            label: 'แชท',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'โค้ดส่วนลด',
          ),
        ],
      ),
    );
  }
}
