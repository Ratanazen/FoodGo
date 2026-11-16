import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgo_flutter/app/router/app_router.dart';
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
      await prefs.setString('app_language', 'en');
      AppConfig.resetEdgeFallback();

      final previousOnError = FlutterError.onError;
      try {
        await app.main();
        FlutterError.onError = previousOnError;
        await tester.pump(const Duration(milliseconds: 300));

        // Verify effective emulator / local API & WS config resolves cleanly
        expect(
          AppConfig.apiBaseUrl,
          anyOf(
            contains('10.0.2.2:8000/api/'),
            contains('127.0.0.1:8000/api/'),
          ),
        );
        expect(
          AppConfig.wsBaseUrl,
          anyOf(
            equals('ws://10.0.2.2:8000/ws/tracking/'),
            equals('ws://127.0.0.1:8000/ws/tracking/'),
          ),
        );

        // 1. Verify live Django endpoints directly from app network
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
          'Username or Email',
        );
        final passwordFinder = find.widgetWithText(TextFormField, 'Password');
        await _pumpUntil(
          tester,
          () =>
              usernameFinder.evaluate().isNotEmpty &&
              passwordFinder.evaluate().isNotEmpty,
          timeout: const Duration(seconds: 25),
        );

        // 3. Sign in with seeded demo customer account
        await tester.enterText(usernameFinder, 'customer1');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.enterText(passwordFinder, 'customer123');
        FocusManager.instance.primaryFocus?.unfocus();
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }

        final loginBtn = find.widgetWithText(ElevatedButton, 'Sign In').first;
        await tester.ensureVisible(loginBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(loginBtn, warnIfMissed: false);

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

        // 5. Verify protected endpoints carry JWT Bearer header from app
        final me = await api.get('me/');
        expect(me, isA<Map>());
        expect(me['username'], equals('customer1'));

        final phoneStatus = await api.get('auth/phone/status/');
        expect(phoneStatus, isA<Map>());
        expect(phoneStatus.containsKey('is_phone_verified'), isTrue);

        final wallet = await api.get('wallets/my_wallet/');
        expect(wallet, isA<Map>());
        expect(wallet.containsKey('balance'), isTrue);

        // 6. Pick Glass Burger (owned by demo `owner`) & its first available food item
        final restList = restaurants.cast<Map>();
        final targetRest = restList.firstWhere(
          (r) =>
              r['name'] == 'Glass Burger' &&
              (r['food_categories'] is List) &&
              (r['food_categories'] as List).any(
                (c) =>
                    c is Map &&
                    c['items'] is List &&
                    (c['items'] as List).isNotEmpty,
              ),
          orElse: () => restList.firstWhere(
            (r) =>
                (r['food_categories'] is List) &&
                (r['food_categories'] as List).any(
                  (c) =>
                      c is Map &&
                      c['items'] is List &&
                      (c['items'] as List).isNotEmpty,
                ),
          ),
        );
        final int restId = int.parse(targetRest['id'].toString());
        final firstCat = (targetRest['food_categories'] as List)
            .cast<Map>()
            .firstWhere(
              (c) => c['items'] is List && (c['items'] as List).isNotEmpty,
            );
        final int foodId = int.parse(
          ((firstCat['items'] as List).first as Map)['id'].toString(),
        );

        // 7. Test Bakong KHQR Payment Generation Flow (and clean cancellation)
        final khqrOrder = await api.post('orders/', {
          'restaurant': restId,
          'items': [
            {'food_item': foodId, 'quantity': 1},
          ],
          'special_instructions': 'E2E Bakong KHQR verification',
        });
        final int khqrOrderId = int.parse(khqrOrder['id'].toString());
        final khqrPay = await api.post('payments/create/', {
          'order_id': khqrOrderId,
          'provider': 'BAKONG',
          'currency': 'USD',
        });
        expect(khqrPay['provider'], equals('BAKONG'));
        expect(khqrPay['method'], equals('KHQR'));
        expect(khqrPay['status'], equals('PENDING'));
        expect(khqrPay['qr_payload']?.toString(), startsWith('000201'));
        await api.post('payments/${khqrPay['id']}/cancel/', {});
        final khqrCancelled = await api.get('orders/$khqrOrderId/');
        expect(khqrCancelled['status'], equals('cancelled'));

        // 8. Customer places delivery order & pays via Wallet
        Future<Dio> clientFor(String username, String password) async {
          final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
          final loginRes = await dio.post(
            'token/',
            data: {'username': username, 'password': password},
          );
          final access = loginRes.data['access'].toString();
          dio.options.headers['Authorization'] = 'Bearer $access';
          return dio;
        }

        final ownerDio = await clientFor('owner', 'owner123');
        final driverDio = await clientFor('driver1', 'driver123');
        final driverMeRes = await driverDio.get('drivers/me/');
        final int driverId = int.parse(driverMeRes.data['id'].toString());
        await driverDio.post(
          'drivers/toggle-online/',
          data: {'is_online': true},
        );

        final createdOrder = await api.post('orders/', {
          'restaurant': restId,
          'driver_id': driverId,
          'items': [
            {'food_item': foodId, 'quantity': 1},
          ],
          'special_instructions': 'E2E live map + QR delivery test',
        });
        final int orderId = int.parse(createdOrder['id'].toString());

        final walletPay = await api.post('payments/create/', {
          'order_id': orderId,
          'provider': 'WALLET',
          'currency': 'USD',
        });
        expect(walletPay['status'], equals('PAID'));

        // 9. Restaurant owner & Driver act via independent JWT sessions (keeping customer1 logged in UI)
        await ownerDio.post('orders/$orderId/restaurant-accept/', data: {});
        await ownerDio.post('orders/$orderId/start-preparing/', data: {});
        await ownerDio.post('orders/$orderId/ready-for-pickup/', data: {});

        await driverDio.post('drivers/orders/$orderId/accept/', data: {});
        await driverDio.post(
          'drivers/orders/$orderId/arrive-restaurant/',
          data: {},
        );
        await driverDio.post('drivers/orders/$orderId/pickup/', data: {});
        final gpsRes = await driverDio.post(
          'drivers/location/',
          data: {
            'lat': 11.5592,
            'lng': 104.9255,
            'speed': 34.0,
            'bearing': 70.0,
          },
        );
        expect(gpsRes.statusCode, equals(200));

        // 10. Customer verifies live GPS tracking data & opens Customer MapScreen
        final track = await api.get('orders/$orderId/track/');
        expect(track, isA<Map>());
        expect(track['driver_assigned'], isTrue);
        expect(track['is_picked_up'], isTrue);
        expect(
          double.parse(track['driver_location']['lat'].toString()),
          closeTo(11.5592, 0.001),
        );

        appRouter.push('/map/$orderId');
        await _pumpUntil(
          tester,
          () =>
              find.byType(FlutterMap).evaluate().isNotEmpty &&
              find.text('Order #$orderId').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 20),
        );
        await _pumpUntil(
          tester,
          () => find.text('On the way to you').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 15),
        );

        // Pop Customer Map cleanly before opening Driver Map mode
        appRouter.pop();
        for (int i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        // 11. Open Driver MapScreen mode on the same device and verify render
        appRouter.push('/map/$orderId?isDriver=true');
        await _pumpUntil(
          tester,
          () =>
              find.byType(FlutterMap).evaluate().isNotEmpty &&
              find.text('Delivery #$orderId').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 20),
        );

        // Return to Home cleanly so MapScreen timers/controllers dispose before teardown
        appRouter.go('/home');
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        // 12. Driver arrives -> Customer generates delivery QR/PIN -> Driver confirms delivery
        await driverDio.post(
          'drivers/orders/$orderId/arrive-customer/',
          data: {},
        );

        final qrRes = await api.post(
          'orders/$orderId/customer_delivery_qr/',
          {},
        );
        expect(qrRes, isA<Map>());
        final token = qrRes['token']?.toString() ?? '';
        expect(token, isNotEmpty);
        expect(
          qrRes['qr_payload']?.toString(),
          startsWith('FOODGO:DELIVERY:CONFIRM:v1'),
        );
        expect(qrRes['verification_pin']?.toString().length, equals(6));

        final confirmRes = await driverDio.post(
          'orders/$orderId/confirm_delivery/',
          data: {'token': token},
        );
        expect(confirmRes.data['order_status'], equals('delivered'));

        final finalTrack = await api.get('orders/$orderId/track/');
        expect(finalTrack['status'], equals('delivered'));

        // 13. Verify new Customer registration, Driver Busy toggle, and Driver buying food
        final suffix = DateTime.now().millisecondsSinceEpoch;
        final custUsername = 'e2e_cust_$suffix';
        final anonDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
        final regRes = await anonDio.post(
          'register/',
          data: {
            'username': custUsername,
            'email': '$custUsername@foodgo.kh',
            'password': 'Password123!',
            'first_name': 'Sokha',
            'last_name': 'E2E',
            'phone': '+855 12 456 789',
            'role': 'customer',
          },
        );
        expect(regRes.statusCode, equals(201));

        final newCustDio = await clientFor(custUsername, 'Password123!');
        final newCustWallet = await newCustDio.get('wallets/my_wallet/');
        expect(newCustWallet.statusCode, equals(200));
        expect(newCustWallet.data['balance'], isNotNull);
        await newCustDio.delete('auth/delete-account/');

        final busyRes = await driverDio.post(
          'drivers/set-status/',
          data: {'operational_status': 'busy'},
        );
        expect(busyRes.data['operational_status'], equals('busy'));
        final availRes = await driverDio.post(
          'drivers/set-status/',
          data: {'operational_status': 'available'},
        );
        expect(availRes.data['operational_status'], equals('available'));

        final driverBuyRes = await driverDio.post(
          'orders/',
          data: {
            'restaurant': restId,
            'items': [
              {'food_item': foodId, 'quantity': 1},
            ],
            'special_instructions': 'Driver meal order E2E',
          },
        );
        expect(driverBuyRes.statusCode, equals(201));
        final driverBuyId = driverBuyRes.data['id'];
        await driverDio.post(
          'orders/$driverBuyId/cancel/',
          data: {'reason': 'E2E test cleanup'},
        );

        // Assert zero uncaught Flutter framework/overflow exceptions
        expect(tester.takeException(), isNull);
      } finally {
        FlutterError.onError = previousOnError;
      }
    },
  );
}
