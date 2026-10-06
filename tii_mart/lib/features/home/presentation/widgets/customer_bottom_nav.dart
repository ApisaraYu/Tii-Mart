import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// แถบเมนูล่างฝั่งลูกค้า (ตาม wireframe: bottom navbar)
class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({super.key, this.index = 0});

  final int index;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/');
          case 1:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('ระบบรถเข็นจะเพิ่มในขั้นถัดไป')),
              );
          case 2:
            context.push('/profile');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'หน้าแรก',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'รถเข็น',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'โปรไฟล์',
        ),
      ],
    );
  }
}
