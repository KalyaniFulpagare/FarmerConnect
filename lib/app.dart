import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

import 'features/marketplace/presentation/home_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/marketplace/presentation/add_product_screen.dart';
import 'features/marketplace/presentation/my_listings_screen.dart';
import 'features/marketplace/presentation/browse_products_screen.dart';
import 'features/marketplace/presentation/product_detail_screen.dart';
import 'features/marketplace/presentation/wishlist_screen.dart';

import 'features/orders/presentation/order_cart_page.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/orders/presentation/seller_orders_screen.dart';

import 'features/analytics/presentation/buyer_analytics_screen.dart';
import 'features/analytics/presentation/seller_analytics_screen.dart';

import 'features/notifications/presentation/notifications_screen.dart';
import 'features/price_alerts/presentation/price_alerts_screen.dart';

import 'core/utils/go_router_refresh_stream.dart';
import 'core/theme/app_theme.dart';

Page<void> _fadeSlidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final profileState = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',

    refreshListenable: GoRouterRefreshStream(
      ref.watch(firebaseAuthProvider).authStateChanges(),
    ),

    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/login' || location == '/register';

      if (authState.isLoading) {
        return null;
      }

      final user = authState.value;
      final isLoggedIn = user != null;

      // Not logged in ? authentication pages only.
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Logged in ? wait for Firestore profile.
      if (profileState.isLoading) {
        return null;
      }

      final profile = profileState.value;
      final role = profile?.role;

      // Logged-in account has no valid profile.
      // IMPORTANT: allow login/register instead of redirecting back home.
      if (role != 'buyer' &&
          role != 'seller' &&
          role != 'both') {
        return isAuthRoute ? null : '/login';
      }

      // Valid profile ? don't show auth screens.
      if (isAuthRoute) {
        return '/';
      }

      final isSeller = role == 'seller' || role == 'both';
      final isBuyer = role == 'buyer' || role == 'both';

      const sellerRoutes = {
        '/my-listings',
        '/add-product',
        '/seller-orders',
        '/seller-analytics',
      };

      const buyerRoutes = {
        '/browse',
        '/cart',
        '/orders',
        '/wishlist',
        '/buyer-analytics',
        '/price-alerts',
      };

      if (sellerRoutes.contains(location) && !isSeller) {
        return '/';
      }

      if (buyerRoutes.contains(location) && !isBuyer) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => _fadeSlidePage(
          const HomeScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => _fadeSlidePage(
          const LoginScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (c, s) => _fadeSlidePage(
          const RegisterScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/my-listings',
        pageBuilder: (c, s) => _fadeSlidePage(
          const MyListingsScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/add-product',
        pageBuilder: (c, s) => _fadeSlidePage(
          const AddProductScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/browse',
        pageBuilder: (c, s) => _fadeSlidePage(
          const BrowseProductsScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (c, s) => _fadeSlidePage(
          ProductDetailScreen(
            productId: s.pathParameters['id']!,
          ),
          s,
        ),
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (c, s) => _fadeSlidePage(
          const CartScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (c, s) => _fadeSlidePage(
          const OrdersScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/wishlist',
        pageBuilder: (c, s) => _fadeSlidePage(
          const WishlistScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/seller-orders',
        pageBuilder: (c, s) => _fadeSlidePage(
          const SellerOrdersScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (c, s) => _fadeSlidePage(
          const ProfileScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/buyer-analytics',
        pageBuilder: (c, s) => _fadeSlidePage(
          const BuyerAnalyticsScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/seller-analytics',
        pageBuilder: (c, s) => _fadeSlidePage(
          const SellerAnalyticsScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (c, s) => _fadeSlidePage(
          const NotificationsScreen(),
          s,
        ),
      ),
      GoRoute(
        path: '/price-alerts',
        pageBuilder: (c, s) => _fadeSlidePage(
          const PriceAlertsScreen(),
          s,
        ),
      ),
    ],
  );
});

class FarmerConnectApp extends ConsumerWidget {
  const FarmerConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FarmerConnect',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}






