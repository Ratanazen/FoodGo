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
  group('LoginScreen Brand Logo & Clean Production Login Widget Tests', () {
    testWidgets(
      'Renders FoodGo Brand Logo, Welcome Back, and Form Fields without Demo Accounts',
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

        // 2. Verify Quick Demo Accounts section is removed
        expect(find.text('Quick Demo Accounts'), findsNothing);
        expect(find.text('Tap to autofill'), findsNothing);

        // 3. Verify Form Fields and Sign In Button
        expect(
          find.widgetWithText(TextFormField, 'Username or Email'),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
    );

    testWidgets(
      'Submitting login form invokes auth provider with entered credentials',
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

        // Enter username and password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username or Email'),
          'myuser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'mypassword123',
        );
        await tester.pump();

        // Tap Sign In button
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        expect(mockAuth.lastUsername, 'myuser');
        expect(mockAuth.lastPassword, 'mypassword123');
      },
    );
  });
}
