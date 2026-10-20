import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/app/router/app_router.dart';
import 'package:foodgo_flutter/features/cart/presentation/cart_screen.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/currency_provider.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('CartScreen renders on compact mobile without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final cartProvider = CartProvider();
    cartProvider.addItem(
      1,
      'Cheeseburger Deluxe',
      10.0,
      '',
      restaurantId: 1,
      restaurantName: 'Burger Joint',
    );

    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainScreenShell(child: child),
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(),
            ),
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const Scaffold(),
            ),
            GoRoute(
              path: '/explore',
              builder: (context, state) => const Scaffold(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ChangeNotifierProvider<CurrencyProvider>(
            create: (_) => CurrencyProvider(),
          ),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Your Cart'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
  });
}
