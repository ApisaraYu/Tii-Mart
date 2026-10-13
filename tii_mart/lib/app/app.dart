import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/presentation/widgets/chat_notification_host.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TiiMartApp extends ConsumerWidget {
  const TiiMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TiiMart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // แบนเนอร์แจ้งเตือนข้อความใหม่ ครอบทุกหน้า
      builder: (context, child) =>
          ChatNotificationHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
