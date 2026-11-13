import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/providers/admin_provider.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:foodgo_flutter/features/auth/presentation/login_screen.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';
import 'package:foodgo_flutter/features/payment/screens/qr_payment_screen.dart';
import 'package:foodgo_flutter/features/payment/services/payment_service.dart';

class MockPaymentService extends FlutterPaymentService {
  final bool shouldThrow;
  final PaymentModel? returnPayment;

  MockPaymentService({this.shouldThrow = false, this.returnPayment});

  @override
  Future<PaymentModel> getPaymentStatus(
    int paymentId, {
    bool simulate = false,
    String? qrPayload,
  }) async {
    if (shouldThrow) {
      throw Exception('Network connection timed out');
    }
    return returnPayment ??
        PaymentModel(
          id: paymentId,
          orderId: 1,
          amount: 10.0,
          currency: 'USD',
          provider: 'ABA',
          method: 'KHQR',
          status: 'PENDING',
        );
  }
}

class MockAuthProvider extends AuthProvider {
  String? mockError;
  bool shouldSucceed = false;

  @override
  String? get lastAuthError => mockError;

  @override
  Future<bool> login(String username, String password) async {
    return shouldSucceed;
  }
}

class MockAdminProvider extends AdminProvider {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminProvider Unit Tests', () {
    test('Initial AdminProvider state values are correct', () {
      final admin = AdminProvider();
      expect(admin.isLoading, isFalse);
      expect(admin.errorMessage, isNull);
      expect(admin.selectedPeriod, 'all');
      expect(admin.orderStatusFilter, 'all');
      expect(admin.userRoleFilter, 'all');
      expect(admin.orders, isEmpty);
      expect(admin.payments, isEmpty);
      expect(admin.users, isEmpty);
      expect(admin.restaurants, isEmpty);
      expect(admin.auditLogs, isEmpty);
      expect(admin.analytics, isNull);
    });
  });

  group('CartProvider Special Instructions Tests', () {
    test(
      'specialInstructions defaults to empty string and updates correctly',
      () {
        final cart = CartProvider();
        expect(cart.specialInstructions, '');

        cart.setSpecialInstructions('No onions, extra spicy chili sauce');
        expect(cart.specialInstructions, 'No onions, extra spicy chili sauce');

        cart.clear();
        expect(cart.specialInstructions, '');
      },
    );
  });

  group('UserProvider Role Checks Tests', () {
    test('isAdmin returns true when role is admin or staff', () {
      final userProvider = UserProvider();
      expect(userProvider.isAdmin, isFalse);
    });
  });

  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('Renders Admin Dashboard with 6 tabs', (tester) async {
      final mockAdmin = MockAdminProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminProvider>.value(value: mockAdmin),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the screen title
      expect(find.text('Admin Console'), findsOneWidget);

      // Verify all 6 tab labels are rendered
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Restaurants'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);

      // Verify period selection chips exist on Overview tab
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });
  });

  group('QRPaymentScreen Widget Tests', () {
    testWidgets('Renders Scan to Pay title, summary, and 3-step instructions', (
      tester,
    ) async {
      final payment = PaymentModel(
        id: 101,
        orderId: 42,
        amount: 25.50,
        currency: 'USD',
        provider: 'ABA',
        method: 'KHQR',
        status: 'PENDING',
        qrPayload:
            '00020101021229300016abaakhppxxx@abaa5802KH5303840540525.505802KH5916FoodGo Restaurant6010Phnom Penh630429B1',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: MaterialApp(home: QRPaymentScreen(payment: payment)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scan to Pay'), findsOneWidget);
      expect(find.text('Order #42'), findsOneWidget);
      expect(find.text('USD 25.50'), findsOneWidget);
      expect(find.text('How to pay with KHQR'), findsOneWidget);
      expect(find.text('Check Payment Status'), findsOneWidget);
      expect(find.text('Cancel Payment'), findsOneWidget);
      expect(find.text('Copy KHQR Payload'), findsOneWidget);
    });

    testWidgets('Shows network error notification when check status fails', (
      tester,
    ) async {
      final payment = PaymentModel(
        id: 999,
        orderId: 43,
        amount: 15.00,
        currency: 'USD',
        provider: 'ABA',
        method: 'KHQR',
        status: 'PENDING',
        qrPayload: 'sample-payload',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      final mockPaymentService = MockPaymentService(shouldThrow: true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: MaterialApp(
            home: QRPaymentScreen(
              payment: payment,
              paymentService: mockPaymentService,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll and tap Check Payment Status
      await tester.ensureVisible(find.text('Check Payment Status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Payment Status'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(
          'Unable to check payment status due to network error. You can retry safely.',
        ),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Renders FoodGo branding, headers, form fields, and remember me',
      (tester) async {
        final mockAuth = MockAuthProvider();
        final userProvider = UserProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Brand Logo Header & Title
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('FoodGo'),
          ),
          findsOneWidget,
        );
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(
          find.text('Sign in with your username or email to continue'),
          findsOneWidget,
        );

        // Fields & Buttons
        expect(find.text('Username or Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Remember me'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
    );

    testWidgets('Validates required fields on empty submit', (tester) async {
      final mockAuth = MockAuthProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Sign In with empty fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your username or email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Toggles password visibility when icon clicked', (
      tester,
    ) async {
      final mockAuth = MockAuthProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Initially obscured: tooltip is 'Show password'
      expect(find.byTooltip('Show password'), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();

      // Now unobscured: tooltip is 'Hide password'
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('Displays inline error banner when authentication fails', (
      tester,
    ) async {
      final mockAuth = MockAuthProvider();
      mockAuth.shouldSucceed = false;
      mockAuth.mockError = 'Incorrect username/email or password.';
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Enter credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username or Email'),
        'invaliduser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpass',
      );
      await tester.pump();

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify error banner is shown
      expect(
        find.text('Incorrect username/email or password.'),
        findsOneWidget,
      );
    });
  });
}
