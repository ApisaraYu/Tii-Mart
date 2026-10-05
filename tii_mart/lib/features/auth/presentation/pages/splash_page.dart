import 'package:flutter/material.dart';

/// หน้ารอระหว่างเช็กว่าผู้ใช้เคยล็อกอินค้างไว้หรือไม่
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
