import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgo_flutter/app/theme/app_theme.dart';
import 'package:foodgo_flutter/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:foodgo_flutter/features/dashboard/presentation/driver_dashboard_screen.dart';
import 'package:foodgo_flutter/features/dashboard/presentation/restaurant_dashboard_screen.dart';
import 'package:foodgo_flutter/features/explore/presentation/explore_screen.dart';
import 'package:foodgo_flutter/features/orders/presentation/orders_screen.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';
import 'package:foodgo_flutter/features/payment/screens/qr_payment_screen.dart';
import 'package:foodgo_flutter/features/payment/services/payment_service.dart';
import 'package:foodgo_flutter/features/settings/presentation/settings_screen.dart';
import 'package:foodgo_flutter/features/wallet/presentation/wallet_screen.dart';
import 'package:foodgo_flutter/providers/admin_provider.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/currency_provider.dart';
import 'package:foodgo_flutter/providers/favorites_provider.dart';
import 'package:foodgo_flutter/providers/locale_provider.dart';
import 'package:foodgo_flutter/providers/restaurant_provider.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/services/api_service.dart';
import 'package:foodgo_flutter/widgets/glass/animated_pressable.dart';

class _TestAdminProvider extends AdminProvider {
  @override
  Map<String, dynamic>? get analytics => {
    'period': 'all',
    'metrics': {
      'total_revenue_usd': '487.49',
      'total_revenue_khr': '1,998,709 ៛',
      'total_orders': 49,
      'completed_orders': 3,
      'active_drivers': 6,
      'total_drivers': 6,
      'active_customers': 13,
      'total_customers': 13,
    },
    'system_health': {
      'database': 'healthy',
      'database_engine': 'SQLite',
      'daphne_asgi': 'running',
    },
    'order_status_distribution': {'pending': 9, 'delivered': 3},
    'recent_orders': [],
  };

  @override
  List<dynamic> get orders => [
    {
      'id': 101,
      'reference_id': 'FG-20261113-0101',
      'status': 'pending',
      'total_amount': '18.50',
      'customer_name': 'Sokha Chan',
      'restaurant_name': 'Glass Burger',
      'payment_status': 'PAID',
      'payment_method': 'KHQR',
      'delivery_address': 'Street 240, Phnom Penh',
      'delivery_address_snapshot': 'Street 240, Phnom Penh',
      'customer_info': {
        'username': 'sokha_customer',
        'email': 'sokha@example.com',
      },
      'created_at': '2026-11-13T08:00:00Z',
    },
  ];

  @override
  List<dynamic> get payments => [
    {
      'id': 501,
      'order_id': 101,
      'order_reference': 'FG-20261113-0101',
      'status': 'COMPLETED',
      'method': 'KHQR',
      'provider': 'BAKONG',
      'amount': '18.50',
      'currency': 'USD',
      'user_username': 'sokha_customer',
      'customer_username': 'sokha_customer',
      'created_at': '2026-11-13T08:01:00Z',
    },
  ];

  @override
  List<dynamic> get users => [
    {
      'id': 10,
      'username': 'sokha_customer',
      'email': 'sokha@example.com',
      'role': 'customer',
      'is_active': true,
      'full_name': 'Sokha Chan',
    },
  ];

  @override
  Future<void> fetchAnalytics({String? period}) async {}
  @override
  Future<void> fetchOrders({String? status, String? search}) async {}
  @override
  Future<void> fetchPayments({String? status, String? search}) async {}
  @override
  Future<void> fetchUsers({String? role, String? search}) async {}
  @override
  Future<void> fetchRestaurants({String? search}) async {}
  @override
  Future<void> fetchAuditLogs({int page = 1}) async {}
  @override
  Future<void> fetchDrivers({String? filter, String? search}) async {}
}

class _TestRestaurantProvider extends RestaurantProvider {
  @override
  bool get isLoading => false;

  @override
  List<dynamic> get restaurants => [];

  @override
  Future<void> fetchRestaurants() async {}
}

class _TestPaymentService extends FlutterPaymentService {
  @override
  Stream<PaymentModel> subscribePaymentStatus(
    int paymentId, {
    String? customWsUrl,
  }) => const Stream.empty();

  @override
  Future<PaymentModel> getPaymentStatus(
    int paymentId, {
    bool simulate = false,
    String? qrPayload,
  }) async => PaymentModel(
    id: paymentId,
    orderId: 38,
    amount: 16.99,
    currency: 'USD',
    provider: 'BAKONG',
    method: 'KHQR',
    status: 'PENDING',
    orderReference: 'FG-20261112-01D649',
    restaurantName: 'Crystal Pizza',
    qrPayload: '00020101021229300012bakong@aclb6304A9F2',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapLight(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<RestaurantProvider>(
          create: (_) => _TestRestaurantProvider(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => _TestAdminProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.getLightTheme(),
        themeMode: ThemeMode.light,
        home: Scaffold(body: child),
      ),
    );
  }

  void expectDarkReadableText(WidgetTester tester, String label) {
    final finder = find.text(label);
    expect(finder, findsWidgets, reason: 'Expected "$label" to be rendered');
    final textWidget = tester.widget<Text>(finder.first);
    final color = textWidget.style?.color;
    expect(
      color,
      isNotNull,
      reason: '"$label" should declare an explicit contrast-safe color',
    );
    expect(
      color!.computeLuminance(),
      lessThan(0.35),
      reason:
          '"$label" has light color ($color) that is unreadable on Light background',
    );
  }

  testWidgets('ExploreScreen renders readable dark text in Light Mode', (
    tester,
  ) async {
    await tester.pumpWidget(wrapLight(const ExploreScreen()));
    await tester.pumpAndSettle();

    expectDarkReadableText(tester, 'Explore Food & Spots');
    expectDarkReadableText(tester, 'Hot Deals');
    expectDarkReadableText(tester, 'No restaurants available right now');
  });

  testWidgets('AdminDashboardScreen renders readable dark text in Light Mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrapLight(const AdminDashboardScreen()));
    await tester.pumpAndSettle();

    expectDarkReadableText(tester, 'System & Core Health');
    expectDarkReadableText(tester, '\$487.49');
    expectDarkReadableText(tester, 'Order Status Breakdown');
    expectDarkReadableText(tester, 'Live Delivery & Courier Fleet');
  });

  testWidgets('QRPaymentScreen renders readable dark text in Light Mode', (
    tester,
  ) async {
    final payment = PaymentModel(
      id: 38,
      orderId: 38,
      amount: 16.99,
      currency: 'USD',
      provider: 'BAKONG',
      method: 'KHQR',
      status: 'PENDING',
      orderReference: 'FG-20261112-01D649',
      restaurantName: 'Crystal Pizza',
      qrPayload: '00020101021229300012bakong@aclb6304A9F2',
    );
    await tester.pumpWidget(
      wrapLight(
        QRPaymentScreen(
          payment: payment,
          paymentService: _TestPaymentService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expectDarkReadableText(tester, 'Order #FG-20261112-01D649');
    expectDarkReadableText(tester, 'Crystal Pizza');
    expectDarkReadableText(tester, 'Bakong KHQR (NBC Open API)');
  });

  testWidgets(
    'AdminDashboardScreen Orders, Payments, and Users tabs render readable dark text in Light Mode',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapLight(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'Restaurant: Glass Burger');
      expectDarkReadableText(tester, 'Deliver to: Street 240, Phnom Penh');
      expectDarkReadableText(tester, 'Total: \$18.50');

      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'Payment #501 · BAKONG');
      expectDarkReadableText(tester, 'FG-20261113-0101 · sokha_customer');
      expectDarkReadableText(tester, 'USD 18.50');

      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'sokha_customer');
    },
  );

  testWidgets(
    'DriverDashboardScreen renders Light Mode tabs without 360px overflow or modal disposal crash',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapLight(
          const DriverDashboardScreen(
            initialLoading: false,
            initialProfile: {
              'driver_name': 'Dara Driver',
              'vehicle_type': 'Motorbike',
              'license_plate': 'PP-1A-9999',
              'phone': '+855 12 345 678',
              'rating': '4.9',
              'is_online': true,
            },
            initialActive: [
              {
                'id': 202,
                'status': 'on_the_way',
                'total_amount': '14.50',
                'delivery_fee': '2.50',
                'restaurant_name': 'Pho Phnom Penh',
                'customer_name': 'Maly',
                'delivery_address': 'BKK1, Phnom Penh',
                'items': [
                  {'food_name': 'Beef Pho', 'quantity': 2},
                ],
              },
            ],
            initialAvailable: [
              {
                'id': 101,
                'status': 'preparing',
                'total_amount': '12.00',
                'delivery_fee': '3.00',
                'restaurant_name': 'Burger Hub',
                'delivery_address': 'Daun Penh',
                'items': [
                  {'food_name': 'Combo', 'quantity': 1},
                ],
              },
            ],
            initialHistory: [
              {
                'id': 88,
                'status': 'delivered',
                'total_amount': '20.00',
                'delivery_fee': '3.50',
                'restaurant_name': 'Kulen Kitchen',
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectDarkReadableText(tester, 'Pickup: Pho Phnom Penh');

      await tester.ensureVisible(find.text('Report Issue or Reassign'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Issue or Reassign'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep Delivery'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Available (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Available (1)'));
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'Burger Hub');
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      await tester.ensureVisible(find.text('Earnings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'Order #88 · Kulen Kitchen');

      await tester.ensureVisible(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'PP-1A-9999');

      await tester.scrollUntilVisible(
        find.text('Edit Vehicle / Phone Info'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Vehicle / Phone Info'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'OrdersScreen renders Track Order and safely disposes Rating dialog in Light Mode',
    (tester) async {
      await tester.pumpWidget(
        wrapLight(
          const OrdersScreen(
            initialOrders: [
              {
                'id': 301,
                'status': 'preparing',
                'total_amount': '12.50',
                'restaurant_name': 'Crystal Pizza',
                'payment_status': 'PAID',
                'items': [
                  {'food_name': 'Margherita', 'quantity': 1, 'price': '12.50'},
                ],
              },
              {
                'id': 302,
                'status': 'delivered',
                'total_amount': '9.00',
                'restaurant_name': 'Amok House',
                'payment_status': 'PAID',
                'items': [
                  {'food_name': 'Fish Amok', 'quantity': 1, 'price': '9.00'},
                ],
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectDarkReadableText(tester, 'Track Order');
      expectDarkReadableText(tester, 'View Bill');

      final rateText = find.text('Rate').first;
      await tester.ensureVisible(rateText);
      await tester.pumpAndSettle();
      final rateTapTarget = find
          .ancestor(of: rateText, matching: find.byType(AnimatedPressable))
          .first;
      await tester.tap(rateTapTarget);
      await tester.pumpAndSettle();
      expectDarkReadableText(tester, 'Rate Order #302');

      await tester.enterText(find.byType(TextField).first, 'Great food!');
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'WalletScreen renders readable balance card and validation in Light Mode',
    (tester) async {
      await tester.pumpWidget(
        wrapLight(
          const WalletScreen(
            initialLoading: false,
            initialWallet: {'balance': '25.00', 'transactions': []},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expectDarkReadableText(tester, 'Total Available Balance');
      expectDarkReadableText(tester, '\$25.00');
      expectDarkReadableText(tester, 'Add Money to Account');
      expectDarkReadableText(tester, 'Transaction History');

      await tester.enterText(find.byType(TextField).first, '');
      await tester.ensureVisible(find.text('Add Money'));
      await tester.tap(find.text('Add Money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets(
    'AddFoodItemBottomSheet and SettingsScreen dialogs support Light Mode and clean disposal',
    (tester) async {
      await tester.pumpWidget(
        wrapLight(
          AddFoodItemBottomSheet(
            restaurantId: 1,
            categories: const [
              {'id': 1, 'name': 'Signature Burgers'},
            ],
            api: ApiService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectDarkReadableText(tester, 'Add Food Item');
      expectDarkReadableText(tester, 'Create New Category');
      expect(find.text('+ Create New Category'), findsNothing);

      await tester.pumpWidget(wrapLight(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Delete Account'), 200);
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'DELETE');
      await tester.pump();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
    },
  );
}
