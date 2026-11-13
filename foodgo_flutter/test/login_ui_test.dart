import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class MockUserProviderForLogin extends UserProvider {
  @override
  Future<void> fetchUser() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginScreen Brand Logo & Clean Production Login Widget Tests', () {
    testWidgets(
      'Renders FoodGo Brand Logo, Welcome Back, and Form Fields without Demo Accounts',
      (tester) async {
        final mockAuth = MockAuthProviderForLogin();
        final userProvider = MockUserProviderForLogin();

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
        final userProvider = MockUserProviderForLogin();

        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Destination')),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: MaterialApp.router(routerConfig: router),
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
        await tester.pump(const Duration(milliseconds: 300));

        expect(mockAuth.lastUsername, 'myuser');
        expect(mockAuth.lastPassword, 'mypassword123');
        expect(find.text('Home Destination'), findsOneWidget);
      },
    );

    testWidgets(
      'Interactive login buttons: Password visibility toggle, Remember Me, Forgot Password, Phone OTP, and Sign Up',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockAuth = MockAuthProviderForLogin()..shouldSucceed = false;
        final userProvider = MockUserProviderForLogin();

        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/forgot-password',
              builder: (context, state) =>
                  const Scaffold(body: Text('Forgot Password Screen')),
            ),
            GoRoute(
              path: '/phone-login',
              builder: (context, state) =>
                  const Scaffold(body: Text('Phone OTP Screen')),
            ),
            GoRoute(
              path: '/register',
              builder: (context, state) =>
                  const Scaffold(body: Text('Register Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // 1. Empty form validation check on Sign In button tap
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        expect(
          find.text('Please enter your username or email'),
          findsOneWidget,
        );
        expect(find.text('Please enter your password'), findsOneWidget);

        // 2. Password show/hide button toggle
        expect(find.byTooltip('Show password'), findsOneWidget);
        await tester.tap(find.byTooltip('Show password'));
        await tester.pump();
        expect(find.byTooltip('Hide password'), findsOneWidget);

        // 3. Remember Me checkbox button toggle
        final checkboxFinder = find.byType(Checkbox);
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
        await tester.tap(checkboxFinder);
        await tester.pump();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

        // 4. Failed login displays error banner
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username or Email'),
          'wronguser',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpass',
        );
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.textContaining('Login failed. Please check your credentials'),
          findsOneWidget,
        );

        // 5. Forgot Password button navigation
        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();
        expect(find.text('Forgot Password Screen'), findsOneWidget);
        router.go('/login');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // 6. Phone OTP button navigation
        await tester.tap(find.text('Sign in with Phone (SMS OTP)'));
        await tester.pumpAndSettle();
        expect(find.text('Phone OTP Screen'), findsOneWidget);
        router.go('/login');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // 7. Sign Up button navigation
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expect(find.text('Register Screen'), findsOneWidget);
      },
    );
  });
}
