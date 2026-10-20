import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/profile/presentation/profile_screen.dart';

class TestUserProvider extends UserProvider {
  final Map<String, dynamic>? _mockUser;
  TestUserProvider(this._mockUser);

  @override
  Map<String, dynamic>? get user => _mockUser;

  @override
  Future<void> fetchUser() async {}
}

class TestAuthProvider extends AuthProvider {
  @override
  Future<void> logout() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Map<String, dynamic>? userData) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => TestAuthProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => TestUserProvider(userData),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(),
        ),
      ),
    );
  }

  group('ProfileScreen Wallet Removal & Payment Methods Tests', () {
    testWidgets(
      'Profile header card displays Addresses, Orders, and My KHQR quick actions',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget({
            'username': 'ratana_test',
            'first_name': 'Ratana',
            'last_name': 'Zen',
            'email': 'ratana@foodgo.app',
            'role': 'customer',
          }),
        );
        await tester.pumpAndSettle();

        // Quick action shortcuts
        expect(find.text('Addresses'), findsOneWidget);
        expect(find.text('Orders'), findsOneWidget);
        expect(find.text('My KHQR'), findsOneWidget);

        // Verify Wallet is NOT present in shortcuts or options
        expect(find.text('Wallet'), findsNothing);
        expect(find.text('Digital Wallet & KHQR Top-Up'), findsNothing);
      },
    );

    testWidgets(
      'Account options list renders My Orders and Payment Methods, with zero wallet options',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget({
            'username': 'sokha_customer',
            'first_name': 'Sokha',
            'last_name': 'Chan',
            'email': 'sokha@foodgo.app',
            'role': 'customer',
          }),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('Payment Methods'), findsOneWidget);
        expect(find.text('Saved Addresses'), findsOneWidget);
        expect(find.text('My KHQR (Pay Me / ទទួលប្រាក់)'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);

        // Zero wallet occurrences
        expect(find.textContaining('Wallet'), findsNothing);
      },
    );

    testWidgets(
      'Tapping Payment Methods displays modal with Bakong KHQR, ABA, ACLEDA, and COD',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget({
            'username': 'sokha_customer',
            'role': 'customer',
          }),
        );
        await tester.pumpAndSettle();

        // Tap Payment Methods
        final paymentMethodsTile = find.text('Payment Methods');
        expect(paymentMethodsTile, findsOneWidget);
        await tester.tap(paymentMethodsTile);
        await tester.pumpAndSettle();

        // Modal should open with all payment rails
        expect(
          find.text('Bakong KHQR (National Bank of Cambodia)'),
          findsOneWidget,
        );
        expect(find.text('ABA Mobile KHQR / PayWay'), findsOneWidget);
        expect(find.text('ACLEDA Bank KHQR / x-Pay'), findsOneWidget);
        expect(find.text('Cash on Delivery (COD)'), findsOneWidget);
        expect(find.text('View Orders & Receipts'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);

        // Tap Close to dismiss
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      },
    );
  });
}
