import 'package:flutter/material.dart';

/// โลโก้ชั่วคราว (ไอคอน + ชื่อแอพ) — ภายหลังเปลี่ยนเป็นรูปโลโก้จริงได้ที่นี่ที่เดียว
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.storefront_rounded),
        SizedBox(width: 8),
        Text('TiiMart'),
      ],
    );
  }
}
