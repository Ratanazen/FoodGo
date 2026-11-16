import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgo_flutter/core/config/app_config.dart';
import 'package:foodgo_flutter/core/storage/secure_storage.dart';
import 'package:foodgo_flutter/main.dart' as app;
import 'package:foodgo_flutter/services/api_service.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 25),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (predicate()) return;
  }
  throw TestFailure('Timed out waiting for condition after $timeout');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android Emulator E2E: local backend API + Login -> HomeScreen live menu + protected auth/phone/status',
    (tester) async {
      // Ensure deterministic start from unauthenticated Splash -> Login
      await SecureStorage().clearTokens();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('custom_api_url');
      await prefs.remove('custom_ws_url');
      await prefs.remove('cached_user_profile');
      AppConfig.resetEdgeFallback();

      final previousOnError = FlutterError.onError;
      app.main();
      FlutterError.onError = previousOnError;
      await tester.pump(const Duration(milliseconds: 300));

      // Verify effective emulator API/WS config resolves cleanly
      expect(AppConfig.apiBaseUrl, contains('10.0.2.2:8000/api/'));
      expect(AppConfig.wsBaseUrl, equals('ws://10.0.2.2:8000/ws/tracking/'));

      // 1. Verify live Django endpoints directly from Android Emulator network
      final api = ApiService();
      final health = await api.get('health/');
      expect(health, isA<Map>());
      expect(health['status'], equals('healthy'));

      final restaurants = await api.get('restaurants/');
      expect(restaurants, isA<List>());
      expect((restaurants as List).isNotEmpty, isTrue);

      final currencyRates = await api.get('currency/rates/');
      expect(currencyRates, isA<Map>());

      final paymentMethods = await api.get('payments/methods/');
      expect(paymentMethods, isA<List>());

      // 2. Wait for SplashScreen to transition cleanly to LoginScreen
      final usernameFinder = find.widgetWithText(
        TextFormField,
        'e.g. customer1 or user@foodgo.com',
      );
      final passwordFinder = find.widgetWithText(
        TextFormField,
        'Enter your password',
      );
      await _pumpUntil(
        tester,
        () =>
            usernameFinder.evaluate().isNotEmpty &&
            passwordFinder.evaluate().isNotEmpty,
        timeout: const Duration(seconds: 20),
      );

      // 3. Sign in with seeded demo customer account
      await tester.enterText(usernameFinder, 'customer1');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(passwordFinder, 'customer123');
      await tester.pump(const Duration(milliseconds: 100));

      final loginBtn = find.byType(ElevatedButton).first;
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);

      // 4. Verify navigation into authenticated HomeScreen and live restaurant render
      await _pumpUntil(
        tester,
        () => find.textContaining('Glass Burger').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 25),
      );

      // Pump a few stability frames cleanly without waiting forever on repeat animations
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // 5. Verify protected endpoints carry JWT Bearer header from emulator
      final me = await api.get('me/');
      expect(me, isA<Map>());
      expect(me['username'], equals('customer1'));

      final phoneStatus = await api.get('auth/phone/status/');
      expect(phoneStatus, isA<Map>());
      expect(phoneStatus.containsKey('is_phone_verified'), isTrue);

      final wallet = await api.get('wallets/my_wallet/');
      expect(wallet, isA<Map>());
      expect(wallet.containsKey('balance'), isTrue);

      // Assert zero uncaught Flutter framework/overflow exceptions
      expect(tester.takeException(), isNull);
    },
  );
}
