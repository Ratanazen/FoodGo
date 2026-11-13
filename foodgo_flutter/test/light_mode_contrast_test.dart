import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgo_flutter/app/theme/app_theme.dart';
import 'package:foodgo_flutter/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:foodgo_flutter/features/explore/presentation/explore_screen.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';
import 'package:foodgo_flutter/features/payment/screens/qr_payment_screen.dart';
import 'package:foodgo_flutter/features/payment/services/payment_service.dart';
import 'package:foodgo_flutter/providers/admin_provider.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/currency_provider.dart';
import 'package:foodgo_flutter/providers/favorites_provider.dart';
import 'package:foodgo_flutter/providers/locale_provider.dart';
import 'package:foodgo_flutter/providers/restaurant_provider.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';

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
}
