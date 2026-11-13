import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

/// Authentication state notifier for router guard
class RouterAuthNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setAuthenticated(bool value) {
    state = value;
  }
}

/// Authentication state provider for router guard
final routerAuthStateProvider = NotifierProvider<RouterAuthNotifier, bool>(
  RouterAuthNotifier.new,
);

/// Global navigation key for root navigator
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Typed Riverpod Provider for GoRouter with Auth Redirect Guard
final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(routerAuthStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Redirect unauthenticated users to login if accessing protected routes
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Redirect authenticated users away from login
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});
