import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/snowfall_effect.dart';
import 'widgets/glass/themed_skin_backdrop.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FoodGo Global Error: ${details.exception}');
  };
  await AppConfig.init();
  await FirebaseService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp.router(
          title: 'FoodGo',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US'), Locale('km', 'KH')],
          themeMode: themeProvider.themeMode,
          theme: AppTheme.getLightTheme(
            themeProvider.currentPalette,
            localeProvider.locale,
          ),
          darkTheme: AppTheme.getDarkTheme(
            themeProvider.currentPalette,
            localeProvider.locale,
          ),
          themeAnimationDuration: themeProvider.reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeOutCubic,
          routerConfig: appRouter,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final rawScale =
                media.textScaler.scale(1.0) * localeProvider.scaleFactor;
            final clampedScale = rawScale.clamp(0.85, 1.40);
            final effectiveMedia = media.copyWith(
              disableAnimations: themeProvider.reducedMotion,
              textScaler: TextScaler.linear(clampedScale),
            );

            return MediaQuery(
              data: effectiveMedia,
              child: ThemedSkinBackdrop(
                child: ConnectivityBanner(
                  child: Stack(children: [child!, const SnowfallEffect()]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
