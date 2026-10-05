import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/state/auth_providers.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/seller/dashboard/presentation/pages/dashboard_page.dart';

/// เส้นทางหน้าจอ + ตัวป้องกันตามบทบาท (role)
///  - ยังไม่ล็อกอิน        → เข้าได้เฉพาะ /login และ /signup
///  - ล็อกอินแล้ว (ลูกค้า)   → ไปหน้า / ; เข้า /seller ไม่ได้
///  - ล็อกอินแล้ว (เจ้าของร้าน) → ไปหน้า /seller (สลับไป / ได้)
final routerProvider = Provider<GoRouter>((ref) {
  // ให้ router เช็ก redirect ใหม่ทุกครั้งที่สถานะผู้ใช้เปลี่ยน
  final refresh = ValueNotifier<int>(0);
  ref.listen(authUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authUserProvider);
      final loc = state.matchedLocation;
      final isAuthPage = loc == '/login' || loc == '/signup';

      // ยังไม่รู้สถานะ (กำลังโหลดครั้งแรก)
      if (!auth.hasValue && !auth.hasError) {
        return loc == '/splash' ? null : '/splash';
      }

      final user = auth.hasValue ? auth.value : null;

      if (user == null) {
        return isAuthPage ? null : '/login';
      }

      final home = user.isSeller ? '/seller' : '/';
      if (isAuthPage || loc == '/splash') return home;
      if (loc.startsWith('/seller') && !user.isSeller) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/seller', builder: (_, __) => const DashboardPage()),
    ],
  );
});
