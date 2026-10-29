import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/state/auth_providers.dart';
import '../../features/address/domain/address.dart';
import '../../features/address/presentation/pages/address_form_page.dart';
import '../../features/address/presentation/pages/addresses_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/pages/checkout_page.dart';
import '../../features/cart/presentation/pages/payment_page.dart';
import '../../features/cart/presentation/pages/select_coupon_page.dart';
import '../../features/chat/domain/entities/chat.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/coupon/domain/entities/coupon.dart';
import '../../features/coupon/presentation/pages/customer_coupons_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/widgets/customer_bottom_nav.dart';
import '../../features/orders/presentation/pages/my_orders_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/product_specs_page.dart';
import '../../features/seller/coupon_management/presentation/pages/coupon_form_page.dart';
import '../../features/seller/coupon_management/presentation/pages/coupon_list_page.dart';
import '../../features/seller/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/seller/order_management/presentation/pages/seller_orders_page.dart';
import '../../features/seller/product_management/presentation/pages/product_form_page.dart';
import '../../features/seller/product_management/presentation/pages/product_list_page.dart';
import '../../features/seller/shell/presentation/pages/seller_shell.dart';
import '../../features/compare/presentation/pages/compare_page.dart';
import '../../features/shop/presentation/pages/shop_profile_page.dart';
import '../../features/shop/presentation/pages/shop_settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// เส้นทางหน้าจอ + ตัวป้องกันตามบทบาท (role)
///  - ยังไม่ล็อกอิน        → ดูหน้าแรก / และหน้าสินค้า /product/... ได้ (ผู้เยี่ยมชม)
///                           หน้าอื่นส่งไป /login
///  - ล็อกอินแล้ว (ลูกค้า)   → ไปหน้า / ; เข้า /seller ไม่ได้
///  - ล็อกอินแล้ว (เจ้าของร้าน) → ไปหน้า /seller (สลับไป / ได้)
final routerProvider = Provider<GoRouter>((ref) {
  // ให้ router เช็ก redirect ใหม่ทุกครั้งที่สถานะผู้ใช้เปลี่ยน
  final refresh = ValueNotifier<int>(0);
  ref.listen(authUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authUserProvider);
      final loc = state.matchedLocation;
      final isAuthPage = loc == '/login' || loc == '/signup';
      // หน้าที่ผู้เยี่ยมชมที่ยังไม่ล็อกอินเปิดดูได้
      final isPublic = loc == '/' || loc.startsWith('/product/') ||
          loc.startsWith('/shop/') ||
          loc == '/compare';

      // ยังไม่รู้สถานะ (กำลังโหลดครั้งแรก)
      if (!auth.hasValue && !auth.hasError) {
        return loc == '/splash' ? null : '/splash';
      }

      final user = auth.hasValue ? auth.value : null;

      if (user == null) {
        if (loc == '/splash') return '/'; // เปิดแอพมาเจอหน้าแรกก่อน
        return (isAuthPage || isPublic) ? null : '/login';
      }

      final home = user.isSeller ? '/seller' : '/';
      if (isAuthPage) {
        // ล็อกอินสำเร็จ: ถ้ามาจากหน้าสินค้า (?from=/product/..) ให้กลับไปหน้านั้น
        final from = state.uri.queryParameters['from'];
        final valid = from != null &&
            !user.isSeller &&
            (from.startsWith('/product/') ||
                from.startsWith('/shop/') ||
                from == '/compare' ||
                from == '/');
        return valid ? from : home;
      }
      if (loc == '/splash') return home;
      if (loc.startsWith('/seller') && !user.isSeller) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/shop/:id',
        builder: (_, state) =>
            ShopProfilePage(shopId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/compare', builder: (_, __) => const ComparePage()),
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
      GoRoute(path: '/orders', builder: (_, __) => const MyOrdersPage()),
      // ---------- รถเข็น / ชำระเงิน (ลูกค้า) ----------
      GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
      GoRoute(path: '/cart/coupons', builder: (_, __) => const SelectCouponPage()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
      GoRoute(
        path: '/addresses',
        builder: (_, __) => const AddressesPage(),
      ),
      GoRoute(
        path: '/addresses/pick',
        builder: (_, __) => const AddressesPage(pick: true),
      ),
      GoRoute(path: '/addresses/new', builder: (_, __) => const AddressFormPage()),
      GoRoute(
        path: '/addresses/edit',
        builder: (_, state) => AddressFormPage(
          address: state.extra is Address ? state.extra as Address : null,
        ),
      ),
      GoRoute(
        path: '/payment/:id',
        builder: (_, state) => PaymentPage(orderId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'done',
            builder: (_, state) =>
                PaymentDonePage(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
      // ตั้งค่าร้าน (เจ้าของร้าน) เปิดเต็มจอทับ shell
      GoRoute(
        path: '/seller/shop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ShopSettingsPage(),
      ),
      // ---------- แชท (ลูกค้า + ร้านค้าใช้ห้องเดียวกัน) ----------
      GoRoute(path: '/coupons', builder: (_, __) => const CustomerCouponsPage()),
      GoRoute(
        path: '/chats',
        builder: (_, __) => const ChatListPage(
          bottomNavigationBar: CustomerBottomNav(index: 3),
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ChatRoomPage(
          chatId: state.pathParameters['id']!,
          initial: state.extra is ChatThread ? state.extra as ChatThread : null,
        ),
      ),
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
                path: '/seller/chats',
                builder: (_, __) => const ChatListPage(),
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

  // สั่งให้ router เช็ก redirect ใหม่ทันทีที่สถานะล็อกอินเปลี่ยน (กันกรณี refreshListenable ไม่ทำงาน)
  ref.listen(authUserProvider, (_, __) => router.refresh());
  return router;
});
