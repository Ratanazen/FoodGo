import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'providers/address_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'widgets/connectivity_banner.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FoodGo Global Error: ${details.exception}');
  };
  await AppConfig.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => RestaurantProvider()..fetchRestaurants(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..fetchUser()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(
          create: (_) => AddressProvider()..fetchAddresses(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..fetchNotifications(),
        ),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const FoodGoApp(),
    ),
  );
}

class FoodGoApp extends StatelessWidget {
  const FoodGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final palette = themeProvider.paletteData;
        final isDark = themeProvider.isDarkMode;

        return MaterialApp.router(
          title: 'FoodGo',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.getLightTheme(themeProvider.currentPalette),
          darkTheme: AppTheme.getDarkTheme(themeProvider.currentPalette),
          routerConfig: appRouter,
          builder: (context, child) {
            return Container(
              color: isDark ? palette.backgroundDark : palette.backgroundLight,
              child: ConnectivityBanner(child: child!),
            );
          },
        );
      },
    );
  }
}
