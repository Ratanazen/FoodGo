import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/auth/presentation/login_screen.dart';
import 'package:foodgo_flutter/widgets/svg_icon.dart';

class MockAuthProviderForLogin extends AuthProvider {
  String? lastUsername;
  String? lastPassword;
  bool shouldSucceed = true;

  @override
  Future<bool> login(String username, String password) async {
    lastUsername = username;
    lastPassword = password;
    return shouldSucceed;
  }
}

void main() {
  group('LoginScreen Brand Logo & Quick Demo Accounts Widget Tests', () {
    testWidgets(
      'Renders FoodGo Brand Logo, Welcome Back, and Quick Demo Accounts',
      (tester) async {
        final mockAuth = MockAuthProviderForLogin();
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

        // 1. Verify Brand Logo and Tagline
        expect(find.byType(FoodGoLogo), findsOneWidget);
        expect(find.text('Fast Delivery • Fresh Meals'), findsOneWidget);
        expect(find.text('Welcome Back'), findsOneWidget);

        // 2. Verify Quick Demo Accounts section
        expect(find.text('Quick Demo Accounts'), findsOneWidget);
        expect(find.text('Tap to autofill'), findsOneWidget);
        expect(find.text('Customer'), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
        expect(find.text('Driver'), findsOneWidget);
        expect(find.text('Owner'), findsOneWidget);

        // 3. Verify Form Fields
        expect(
          find.widgetWithText(TextFormField, 'Username or Email'),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping demo account chips autofills username and password fields',
      (tester) async {
        final mockAuth = MockAuthProviderForLogin();
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

        // Tap 'Admin' demo chip
        await tester.tap(find.text('Admin'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('admin'), findsWidgets);
        expect(find.text('admin123'), findsOneWidget);

        // Tap 'Customer' demo chip
        await tester.tap(find.text('Customer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('customer1'), findsWidgets);
        expect(find.text('customer123'), findsOneWidget);

        // Tap 'Driver' demo chip
        await tester.tap(find.text('Driver'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('driver1'), findsWidgets);
        expect(find.text('driver123'), findsOneWidget);

        // Tap 'Owner' demo chip
        await tester.tap(find.text('Owner'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('owner'), findsWidgets);
        expect(find.text('owner123'), findsOneWidget);
      },
    );
  });
}
