import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/state/auth_providers.dart';
import '../../features/coupon/domain/entities/coupon.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/product_specs_page.dart';
import '../../features/seller/coupon_management/presentation/pages/coupon_form_page.dart';
import '../../features/seller/coupon_management/presentation/pages/coupon_list_page.dart';
import '../../features/seller/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/seller/order_management/presentation/pages/seller_orders_page.dart';
import '../../features/seller/product_management/presentation/pages/product_form_page.dart';
import '../../features/seller/product_management/presentation/pages/product_list_page.dart';
import '../../features/seller/shell/presentation/pages/seller_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

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
    navigatorKey: _rootNavigatorKey,
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
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailPage(productId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'specs',
            builder: (_, state) => ProductSpecsPage(extra: state.extra),
          ),
        ],
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      // ---------- ฝั่งร้านค้า: มี shell + แถบเมนูล่างของตัวเอง ----------
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            SellerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/seller', builder: (_, __) => const DashboardPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/products',
                builder: (_, __) => const ProductListPage(),
                routes: [
                  // หน้าฟอร์มเปิดทับเต็มจอ (ซ่อนแถบเมนูล่าง)
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, __) => const ProductFormPage(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) =>
                        ProductFormPage(productId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/orders',
                builder: (_, __) => const SellerOrdersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/seller/coupons',
                builder: (_, __) => const CouponListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, __) => const CouponFormPage(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => CouponFormPage(
                      coupon: state.extra is Coupon ? state.extra as Coupon : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
