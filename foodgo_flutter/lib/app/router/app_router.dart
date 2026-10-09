import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Auth & Onboarding
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/phone_login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';

// Main features
import '../../features/home/presentation/home_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

// Secondary screens
import '../../features/search/presentation/search_screen.dart';
import '../../features/restaurants/presentation/restaurant_details_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/checkout/presentation/order_success_screen.dart';
import '../../features/payment/screens/qr_payment_screen.dart';
import '../../features/payment/models/payment_model.dart';
import '../../features/profile/presentation/notifications_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../screens/map_screen.dart';
import '../../features/dashboard/presentation/restaurant_dashboard_screen.dart';
import '../../features/dashboard/presentation/driver_dashboard_screen.dart';

// Widgets
import '../../widgets/glass/glass_bottom_navigation.dart';
import '../../widgets/responsive_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

enum PageTransitionType {
  fade,
  slideRight,
  slideUp,
  fadeScale,
}

Page<dynamic> _buildPage({
  required GoRouterState state,
  required Widget child,
  PageTransitionType type = PageTransitionType.slideRight,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (type) {
        case PageTransitionType.fade:
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        case PageTransitionType.slideRight:
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.2, 0.0), end: Offset.zero).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        case PageTransitionType.slideUp:
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        case PageTransitionType.fadeScale:
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
      }
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPage(state: state, child: const SplashScreen(), type: PageTransitionType.fade),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildPage(state: state, child: const OnboardingScreen(), type: PageTransitionType.fade),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPage(state: state, child: const LoginScreen(), type: PageTransitionType.fadeScale),
    ),
    GoRoute(
      path: '/phone-login',
      pageBuilder: (context, state) => _buildPage(state: state, child: const PhoneLoginScreen(), type: PageTransitionType.fadeScale),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildPage(state: state, child: const RegisterScreen(), type: PageTransitionType.fadeScale),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _buildPage(state: state, child: const ForgotPasswordScreen(), type: PageTransitionType.fadeScale),
    ),
    GoRoute(
      path: '/restaurant-dashboard',
      pageBuilder: (context, state) => _buildPage(state: state, child: const RestaurantDashboardScreen(), type: PageTransitionType.slideRight),
    ),
    GoRoute(
      path: '/driver-dashboard',
      pageBuilder: (context, state) => _buildPage(state: state, child: const DriverDashboardScreen(), type: PageTransitionType.slideRight),
    ),
    GoRoute(
      path: '/restaurant/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'];
        return _buildPage(state: state, child: RestaurantDetailsScreen(id: id), type: PageTransitionType.slideRight);
      },
    ),
    GoRoute(
      path: '/checkout',
      pageBuilder: (context, state) => _buildPage(state: state, child: const CheckoutScreen(), type: PageTransitionType.slideRight),
    ),
    GoRoute(
      path: '/qr-payment',
      pageBuilder: (context, state) {
        final payment = state.extra as PaymentModel;
        return _buildPage(state: state, child: QRPaymentScreen(payment: payment), type: PageTransitionType.slideRight);
      },
    ),
    GoRoute(
      path: '/order-success',
      pageBuilder: (context, state) {
        final orderId = state.extra is int
            ? state.extra as int
            : int.tryParse(state.uri.queryParameters['orderId'] ?? '');
        return _buildPage(state: state, child: OrderSuccessScreen(orderId: orderId), type: PageTransitionType.fadeScale);
      },
    ),
    GoRoute(
      path: '/map',
      pageBuilder: (context, state) => _buildPage(state: state, child: const MapScreen(orderId: ''), type: PageTransitionType.slideRight),
    ),
    GoRoute(
      path: '/map/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _buildPage(state: state, child: MapScreen(orderId: id), type: PageTransitionType.slideRight);
      },
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _buildPage(state: state, child: const NotificationsScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) => _buildPage(state: state, child: const EditProfileScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) => _buildPage(state: state, child: const FavoritesScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/addresses',
      pageBuilder: (context, state) => _buildPage(state: state, child: const AddressesScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/wallet',
      pageBuilder: (context, state) => _buildPage(state: state, child: const WalletScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/payments',
      pageBuilder: (context, state) => _buildPage(state: state, child: const WalletScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _buildPage(state: state, child: const SettingsScreen(), type: PageTransitionType.slideUp),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _buildPage(state: state, child: const SearchScreen(), type: PageTransitionType.slideRight),
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScreenShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _buildPage(state: state, child: const HomeScreen(), type: PageTransitionType.fade),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => _buildPage(state: state, child: const ExploreScreen(), type: PageTransitionType.fade),
        ),
        GoRoute(
          path: '/cart',
          pageBuilder: (context, state) => _buildPage(state: state, child: const CartScreen(), type: PageTransitionType.fade),
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => _buildPage(state: state, child: const OrdersScreen(), type: PageTransitionType.fade),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildPage(state: state, child: const ProfileScreen(), type: PageTransitionType.fade),
        ),
      ],
    ),
  ],
);

class MainScreenShell extends StatelessWidget {
  final Widget child;

  const MainScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveBreakpoints.isWide(context);
    final selectedIdx = _calculateSelectedIndex(context);

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            WebHeaderNavBar(
              selectedIndex: selectedIdx,
              onDestinationSelected: (int idx) => _onItemTapped(idx, context),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: GlassBottomNavigation(
        selectedIndex: selectedIdx,
        onDestinationSelected: (int idx) => _onItemTapped(idx, context),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/explore'); break;
      case 2: context.go('/cart'); break;
      case 3: context.go('/orders'); break;
      case 4: context.go('/profile'); break;
    }
  }
}
