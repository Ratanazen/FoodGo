import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgo_flutter/app/router/app_router.dart';
import 'package:foodgo_flutter/core/config/app_config.dart';
import 'package:foodgo_flutter/core/storage/secure_storage.dart';
import 'package:foodgo_flutter/features/restaurants/presentation/restaurant_details_screen.dart';
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

        // Helper for vertical scrolling + safe tapping inside real scrollable screens
        Future<void> scrollUntilFound(
          Finder finder, {
          Duration timeout = const Duration(seconds: 20),
          double stepY = -180,
          bool avoidBottomOverlay = false,
        }) async {
          final verticalScrollable = find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                w.axisDirection == AxisDirection.down &&
                w.restorationId != 'editable',
          );
          final deadline = DateTime.now().add(timeout);
          while (DateTime.now().isBefore(deadline)) {
            if (finder.evaluate().isNotEmpty) {
              await tester.ensureVisible(finder.first);
              await tester.pump(const Duration(milliseconds: 250));
              if (avoidBottomOverlay &&
                  verticalScrollable.evaluate().isNotEmpty &&
                  finder.evaluate().first.renderObject is RenderBox) {
                final h =
                    tester.view.physicalSize.height /
                    tester.view.devicePixelRatio;
                final dy = tester.getCenter(finder.first).dy;
                if (dy > h * 0.52) {
                  await tester.drag(
                    verticalScrollable.last,
                    const Offset(0, -180),
                  );
                  await tester.pump(const Duration(milliseconds: 250));
                } else if (dy < h * 0.22) {
                  await tester.drag(
                    verticalScrollable.last,
                    const Offset(0, 140),
                  );
                  await tester.pump(const Duration(milliseconds: 250));
                }
              }
              return;
            }
            if (verticalScrollable.evaluate().isNotEmpty) {
              await tester.drag(verticalScrollable.last, Offset(0, stepY));
            }
            await tester.pump(const Duration(milliseconds: 250));
          }
          throw TestFailure('Could not scroll to $finder within $timeout');
        }

        Future<void> loginViaUi(String username, String password) async {
          await _pumpUntil(
            tester,
            () =>
                find.byType(TextFormField).evaluate().length >= 2 &&
                find
                    .widgetWithText(ElevatedButton, 'Sign In')
                    .evaluate()
                    .isNotEmpty,
          );
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), username);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(fields.at(1), password);
          await tester.pump(const Duration(milliseconds: 100));
          FocusManager.instance.primaryFocus?.unfocus();
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 150));
          }
          final signInBtn = find
              .widgetWithText(ElevatedButton, 'Sign In')
              .first;
          await tester.ensureVisible(signInBtn);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.tap(signInBtn);
        }

        Future<void> logoutFromHomeProfile() async {
          final verticalScrollable = find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                w.axisDirection == AxisDirection.down &&
                w.restorationId != 'editable',
          );
          final deadline = DateTime.now().add(const Duration(seconds: 25));
          while (DateTime.now().isBefore(deadline) &&
              find.byTooltip('Profile').evaluate().isEmpty) {
            if (find.text('Profile').evaluate().isNotEmpty) break;
            if (verticalScrollable.evaluate().isNotEmpty) {
              await tester.drag(verticalScrollable.first, const Offset(0, 260));
            }
            await tester.pump(const Duration(milliseconds: 250));
          }
          if (find.byTooltip('Profile').evaluate().isNotEmpty) {
            await tester.ensureVisible(find.byTooltip('Profile').first);
            await tester.pump(const Duration(milliseconds: 150));
            await tester.tap(find.byTooltip('Profile').first);
          } else if (find.text('Profile').evaluate().isNotEmpty) {
            await tester.tap(find.text('Profile').last);
          } else {
            throw TestFailure('Profile button not found on HomeScreen');
          }
          await _pumpUntil(
            tester,
            () => find.text('Edit Profile').evaluate().isNotEmpty,
          );
          await scrollUntilFound(find.text('Logout'), avoidBottomOverlay: true);
          await tester.tap(find.text('Logout').last);
          await _pumpUntil(
            tester,
            () => find.text('Log Out').evaluate().isNotEmpty,
          );
          await tester.tap(find.text('Log Out').last);
          await _pumpUntil(
            tester,
            () => find
                .widgetWithText(ElevatedButton, 'Sign In')
                .evaluate()
                .isNotEmpty,
          );
        }

        Future<Dio> apiSessionFor(String username, String password) async {
          final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
          final login = await dio.post(
            'auth/login/',
            data: {'username': username, 'password': password},
          );
          dio.options.headers['Authorization'] =
              'Bearer ${login.data['access']}';
          return dio;
        }

        // 14. Full Customer UI -> COD Checkout + Pick Driver -> Logout -> Driver Login & Confirm UI
        appRouter.go('/home');
        await tester.pump(const Duration(milliseconds: 400));
        await logoutFromHomeProfile();

        // A. Customer logs in via LoginScreen UI
        await loginViaUi('customer1', 'customer123');
        await _pumpUntil(
          tester,
          () => find.byTooltip('Profile').evaluate().isNotEmpty,
        );
        await tester.pump(const Duration(milliseconds: 1000));

        // B. Open Glass Burger from HomeScreen -> Add menu item -> View Cart -> Checkout
        final homeGlassBurgerFinder = find.descendant(
          of: find.byKey(const Key('home_restaurant_grid')),
          matching: find.text('Glass Burger'),
        );
        await scrollUntilFound(homeGlassBurgerFinder, avoidBottomOverlay: true);
        debugPrint(
          'E2E tapping Glass Burger at ${tester.getCenter(homeGlassBurgerFinder.first)}',
        );
        await tester.tap(homeGlassBurgerFinder.first);
        await tester.pump(const Duration(milliseconds: 600));
        debugPrint(
          'E2E after Glass Burger tap uri=${appRouter.routerDelegate.currentConfiguration.uri}',
        );

        await _pumpUntil(
          tester,
          () => find.byType(RestaurantDetailsScreen).evaluate().isNotEmpty,
        );
        await _pumpUntil(
          tester,
          () =>
              find.text('All').evaluate().isNotEmpty ||
              find.text('Restaurant not found').evaluate().isNotEmpty,
        );
        expect(find.text('Restaurant not found'), findsNothing);

        await scrollUntilFound(
          find.text('Classic Double Smash Cheeseburger'),
          avoidBottomOverlay: true,
        );
        await tester.tap(find.text('Classic Double Smash Cheeseburger').first);
        await tester.pump(const Duration(milliseconds: 500));

        await _pumpUntil(
          tester,
          () => find.textContaining('Add to Cart').evaluate().isNotEmpty,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.ensureVisible(find.textContaining('Add to Cart').first);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.textContaining('Add to Cart').first);
        await tester.pump(const Duration(milliseconds: 350));

        await _pumpUntil(
          tester,
          () => find.text('View your cart').evaluate().isNotEmpty,
        );
        // Wait for default 4s SnackBar to clear cleanly before tapping FloatingMiniCartBar
        for (var i = 0; i < 18; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.tap(find.text('View your cart').first);
        await tester.pump(const Duration(milliseconds: 500));

        await _pumpUntil(
          tester,
          () => find.text('Proceed to Checkout').evaluate().isNotEmpty,
        );
        await scrollUntilFound(
          find.text('Proceed to Checkout'),
          avoidBottomOverlay: true,
        );
        await tester.tap(find.text('Proceed to Checkout').first);
        await tester.pump(const Duration(milliseconds: 600));

        // C. CheckoutScreen: pick driver Bob Rider + choose COD -> Place Order (COD)
        await _pumpUntil(
          tester,
          () => find.text('Choose Delivery Driver').evaluate().isNotEmpty,
        );
        await _pumpUntil(
          tester,
          () => find.text('Bob Rider').evaluate().isNotEmpty,
        );
        await scrollUntilFound(
          find.text('Bob Rider'),
          avoidBottomOverlay: true,
        );
        await tester.tap(find.text('Bob Rider').first);
        await tester.pump(const Duration(milliseconds: 250));

        await scrollUntilFound(
          find.text('Cash on Delivery / COD (ទូទាត់ពេលដឹកដល់)'),
          avoidBottomOverlay: true,
        );
        await tester.tap(
          find.text('Cash on Delivery / COD (ទូទាត់ពេលដឹកដល់)').first,
        );
        await tester.pump(const Duration(milliseconds: 250));
        await _pumpUntil(
          tester,
          () => find.textContaining('Place Order (COD)').evaluate().isNotEmpty,
        );
        final placeCodBtn = find.textContaining('Place Order (COD)').first;
        await tester.ensureVisible(placeCodBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(placeCodBtn);

        await _pumpUntil(
          tester,
          () => find.text('Order Placed!').evaluate().isNotEmpty,
        );

        final codCustomerDio = await apiSessionFor('customer1', 'customer123');
        final custOrdersRes = await codCustomerDio.get('orders/?mine=true');
        expect(custOrdersRes.statusCode, equals(200));
        final rawOrders = custOrdersRes.data is List
            ? custOrdersRes.data as List
            : (custOrdersRes.data['results'] as List? ?? []);
        expect(rawOrders, isNotEmpty);
        final custOrders =
            rawOrders
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
              ..sort(
                (a, b) =>
                    ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0),
              );
        final codOrder = custOrders.first;
        final codOrderId = codOrder['id'];
        expect(codOrder['payment_info']?['provider'], equals('COD'));
        expect(codOrder['payment_status'], equals('PENDING'));
        expect(codOrder['assigned_driver']?['name'], equals('Bob Rider'));

        // D. Customer returns Home -> Profile -> Logs Out via UI
        await _pumpUntil(
          tester,
          () => find.text('Back to Home').evaluate().isNotEmpty,
        );
        await tester.ensureVisible(find.text('Back to Home').first);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Back to Home').first);
        await logoutFromHomeProfile();

        // E. Driver logs in via LoginScreen UI -> DriverDashboardScreen
        await loginViaUi('driver1', 'driver123');
        final codCardFinder = find.byKey(
          ValueKey('driver_order_card_$codOrderId'),
        );
        await _pumpUntil(
          tester,
          () =>
              find.text('Driver Portal').evaluate().isNotEmpty &&
              codCardFinder.evaluate().isNotEmpty,
        );
        expect(
          find.descendant(
            of: codCardFinder,
            matching: find.text('CASH DUE ON DELIVERY'),
          ),
          findsOneWidget,
        );

        Future<void> bringDriverActionIntoView(Finder target) async {
          await _pumpUntil(tester, () => target.evaluate().isNotEmpty);
          final h =
              tester.view.physicalSize.height / tester.view.devicePixelRatio;
          final verticalScrollable = find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                w.axisDirection == AxisDirection.down &&
                w.restorationId != 'editable',
          );
          for (var i = 0; i < 20; i++) {
            if (target.evaluate().isEmpty) break;
            final dy = tester.getCenter(target.first).dy;
            if (dy >= 180 && dy <= h - 160) {
              return;
            }
            final enclosing = find.ancestor(
              of: target.first,
              matching: verticalScrollable,
            );
            final scroller = enclosing.evaluate().isNotEmpty
                ? enclosing.first
                : (verticalScrollable.evaluate().isNotEmpty
                      ? verticalScrollable.last
                      : null);
            if (scroller == null) break;
            final totalDelta = dy > h - 160 ? -100.0 : 100.0;
            final gesture = await tester.startGesture(
              tester.getCenter(scroller),
            );
            for (var s = 0; s < 4; s++) {
              await gesture.moveBy(Offset(0, totalDelta / 4));
              await tester.pump(const Duration(milliseconds: 30));
            }
            await tester.pump(const Duration(milliseconds: 180));
            await gesture.up();
            await tester.pump(const Duration(milliseconds: 200));
          }
          final finalDy = tester.getCenter(target.first).dy;
          expect(
            finalDy,
            inInclusiveRange(140.0, h - 100.0),
            reason:
                'Driver action button remained out of safe viewport (dy=$finalDy)',
          );
        }

        Future<void> tapOrderStepButton(
          String buttonLabel,
          String nextLabel,
        ) async {
          final btnFinder = find.descendant(
            of: codCardFinder,
            matching: find.text(buttonLabel),
          );
          await bringDriverActionIntoView(btnFinder);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.tap(btnFinder.first);
          final nextFinder = find.descendant(
            of: codCardFinder,
            matching: find.text(nextLabel),
          );
          await _pumpUntil(tester, () => nextFinder.evaluate().isNotEmpty);
        }

        await tapOrderStepButton(
          'Arrived at Restaurant',
          'Confirm Food Picked Up',
        );
        await tapOrderStepButton(
          'Confirm Food Picked Up',
          'Arrived at Customer',
        );
        await tapOrderStepButton(
          'Arrived at Customer',
          'Complete Delivery Handover',
        );

        final completeBtn = find.descendant(
          of: codCardFinder,
          matching: find.text('Complete Delivery Handover'),
        );
        await bringDriverActionIntoView(completeBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(completeBtn.first);

        await _pumpUntil(
          tester,
          () =>
              find
                  .text('Complete Delivery #$codOrderId')
                  .evaluate()
                  .isNotEmpty &&
              find.text('Payment Due Upon Delivery').evaluate().isNotEmpty,
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.ensureVisible(find.text('Direct Handover Confirmation'));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('Direct Handover Confirmation'));

        await _pumpUntil(
          tester,
          () =>
              find.text('Confirm delivery #$codOrderId').evaluate().isNotEmpty,
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(
          find.text('I collected the cash payment from the customer'),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(
          find.text('I collected the cash payment from the customer'),
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.ensureVisible(find.text('Confirm delivered'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Confirm delivered'));

        await _pumpUntil(tester, () => codCardFinder.evaluate().isEmpty);

        // Verify final persisted state in backend DB after driver COD confirmation
        final verifiedOrderRes = await codCustomerDio.get(
          'orders/$codOrderId/',
        );
        expect(verifiedOrderRes.statusCode, equals(200));
        expect(verifiedOrderRes.data['status'], equals('delivered'));
        expect(verifiedOrderRes.data['payment_status'], equals('PAID'));

        // 15. Driver Logs Out -> Real UI Create Account (Customer + Driver) & Restaurant Owner API Registration
        Future<void> logoutFromDriverPortal() async {
          await _pumpUntil(
            tester,
            () => find.byTooltip('Log Out').evaluate().isNotEmpty,
          );
          await tester.tap(find.byTooltip('Log Out').first);
          await _pumpUntil(
            tester,
            () =>
                find.text('Driver Log Out').evaluate().isNotEmpty &&
                find
                    .widgetWithText(ElevatedButton, 'Log Out')
                    .evaluate()
                    .isNotEmpty,
          );
          await tester.tap(
            find.widgetWithText(ElevatedButton, 'Log Out').first,
          );
          await _pumpUntil(
            tester,
            () => find
                .widgetWithText(ElevatedButton, 'Sign In')
                .evaluate()
                .isNotEmpty,
          );
        }

        Future<void> registerViaUi({
          required String fullName,
          required String username,
          required String email,
          required String password,
          required String phone,
          required String roleLabel,
          String? vehicleType,
          String? licensePlate,
        }) async {
          await _pumpUntil(
            tester,
            () =>
                find
                    .widgetWithText(ElevatedButton, 'Sign In')
                    .evaluate()
                    .isNotEmpty &&
                find.text('Sign Up').evaluate().isNotEmpty,
          );
          if (find.byType(Scaffold).evaluate().isNotEmpty) {
            ScaffoldMessenger.maybeOf(
              tester.element(find.byType(Scaffold).first),
            )?.clearSnackBars();
            await tester.pump(const Duration(milliseconds: 300));
          }
          await scrollUntilFound(
            find.text('Sign Up'),
            avoidBottomOverlay: true,
          );
          await tester.tap(find.text('Sign Up').first);

          await _pumpUntil(
            tester,
            () =>
                find
                    .widgetWithText(ElevatedButton, 'Sign In')
                    .evaluate()
                    .isEmpty &&
                find
                    .widgetWithText(ElevatedButton, 'Create Account')
                    .evaluate()
                    .isNotEmpty &&
                find
                    .widgetWithText(TextFormField, 'Full Name')
                    .evaluate()
                    .isNotEmpty &&
                find
                    .widgetWithText(TextFormField, 'Password')
                    .evaluate()
                    .isNotEmpty,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Full Name'),
            fullName,
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Username'),
            username,
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email Address'),
            email,
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            password,
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Phone Number (Optional)'),
            phone,
          );
          await tester.pump(const Duration(milliseconds: 100));
          FocusManager.instance.primaryFocus?.unfocus();
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 150));
          }

          await scrollUntilFound(find.text(roleLabel));
          await tester.tap(find.text(roleLabel).first);
          await tester.pump(const Duration(milliseconds: 300));

          if (roleLabel == 'Driver') {
            await _pumpUntil(
              tester,
              () =>
                  find
                      .widgetWithText(TextFormField, 'Vehicle Type (Optional)')
                      .evaluate()
                      .isNotEmpty &&
                  find
                      .widgetWithText(TextFormField, 'License Plate (Optional)')
                      .evaluate()
                      .isNotEmpty,
            );
            if (vehicleType != null) {
              final vehicleField = find.widgetWithText(
                TextFormField,
                'Vehicle Type (Optional)',
              );
              await tester.ensureVisible(vehicleField);
              await tester.pump(const Duration(milliseconds: 150));
              await tester.enterText(vehicleField, vehicleType);
              await tester.pump(const Duration(milliseconds: 100));
            }
            if (licensePlate != null) {
              final plateField = find.widgetWithText(
                TextFormField,
                'License Plate (Optional)',
              );
              await tester.ensureVisible(plateField);
              await tester.pump(const Duration(milliseconds: 150));
              await tester.enterText(plateField, licensePlate);
              await tester.pump(const Duration(milliseconds: 100));
            }
            FocusManager.instance.primaryFocus?.unfocus();
            for (var i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 150));
            }
          }

          final createBtn = find.widgetWithText(
            ElevatedButton,
            'Create Account',
          );
          await scrollUntilFound(createBtn);
          await tester.tap(createBtn.first);
        }

        await logoutFromDriverPortal();

        final regTs = DateTime.now().millisecondsSinceEpoch;
        final uiCustUser = 'e2e_ui_cust_$regTs';
        await registerViaUi(
          fullName: 'Sokha Customer',
          username: uiCustUser,
          email: '$uiCustUser@foodgo.kh',
          password: 'Password123!',
          phone: '+855 12 311 222',
          roleLabel: 'Customer',
        );
        await _pumpUntil(
          tester,
          () => find.byTooltip('Profile').evaluate().isNotEmpty,
        );
        await scrollUntilFound(
          find.descendant(
            of: find.byKey(const Key('home_restaurant_grid')),
            matching: find.text('Glass Burger'),
          ),
          avoidBottomOverlay: true,
        );
        final uiCustDio = await apiSessionFor(uiCustUser, 'Password123!');
        final uiCustMe = await uiCustDio.get('me/');
        expect(uiCustMe.statusCode, equals(200));
        expect(uiCustMe.data['username'], equals(uiCustUser));
        expect(uiCustMe.data['role'], equals('customer'));
        await scrollUntilFound(find.byTooltip('Profile'), stepY: 320);
        await logoutFromHomeProfile();
        await uiCustDio.delete('auth/delete-account/');

        final uiDriverUser = 'e2e_ui_drv_$regTs';
        await registerViaUi(
          fullName: 'Rithy Driver',
          username: uiDriverUser,
          email: '$uiDriverUser@foodgo.kh',
          password: 'Password123!',
          phone: '+855 12 411 333',
          roleLabel: 'Driver',
          vehicleType: 'Honda Click 125i',
          licensePlate: 'PP-9E-2026',
        );
        await _pumpUntil(
          tester,
          () =>
              find.text('Driver Portal').evaluate().isNotEmpty &&
              find.byTooltip('Log Out').evaluate().isNotEmpty,
        );
        final uiDrvDio = await apiSessionFor(uiDriverUser, 'Password123!');
        final uiDrvMe = await uiDrvDio.get('me/');
        expect(uiDrvMe.statusCode, equals(200));
        expect(uiDrvMe.data['username'], equals(uiDriverUser));
        expect(uiDrvMe.data['role'], equals('driver'));
        await logoutFromDriverPortal();
        await uiDrvDio.delete('auth/delete-account/');

        final regAnonDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
        final regOwnerUser = 'e2e_owner_$regTs';
        final regOwnerRes = await regAnonDio.post(
          'register/',
          data: {
            'username': regOwnerUser,
            'email': '$regOwnerUser@foodgo.kh',
            'password': 'Password123!',
            'first_name': 'Bopha',
            'last_name': 'Owner',
            'phone': '+855 12 511 444',
            'role': 'restaurant_owner',
          },
        );
        expect(regOwnerRes.statusCode, equals(201));
        final regOwnerDio = await apiSessionFor(regOwnerUser, 'Password123!');
        final regOwnerMe = await regOwnerDio.get('me/');
        expect(regOwnerMe.statusCode, equals(200));
        expect(regOwnerMe.data['role'], equals('restaurant_owner'));
        await regOwnerDio.delete('auth/delete-account/');

        // Assert zero uncaught Flutter framework/overflow exceptions
        expect(tester.takeException(), isNull);
      } finally {
        FlutterError.onError = previousOnError;
      }
    },
  );
}
