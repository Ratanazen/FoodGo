import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/auth/presentation/register_screen.dart';
import 'package:foodgo_flutter/widgets/svg_icon.dart';

class MockAuthProviderForRegister extends AuthProvider {
  String? registeredUsername;
  String? registeredEmail;
  String? registeredPassword;
  String? registeredFirstName;
  String? registeredLastName;
  String? registeredPhone;
  String? registeredRole;
  bool shouldSucceed = true;

  @override
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
  }) async {
    registeredUsername = username;
    registeredEmail = email;
    registeredPassword = password;
    registeredFirstName = firstName;
    registeredLastName = lastName;
    registeredPhone = phone;
    registeredRole = role;
    return shouldSucceed;
  }
}

class MockUserProviderForRegister extends UserProvider {
  @override
  Future<void> fetchUser() async {
    // No-op for unit test
  }
}

void main() {
  group('RegisterScreen 3D Modern UI Widget Tests', () {
    testWidgets(
      'Renders 3D Logo, Form Fields, Role Selector, and Create Account button',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockAuth = MockAuthProviderForRegister();
        final userProvider = MockUserProviderForRegister();

        final router = GoRouter(
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
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

        // 1. Verify 3D Logo and Title
        expect(find.byType(FoodGoLogo), findsOneWidget);
        expect(find.text('Create Account'), findsNWidgets(2));
        expect(
          find.text('Fill your details below to register'),
          findsOneWidget,
        );

        // 2. Verify all inputs exist
        expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Email Address'),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

        // 3. Verify Role selector chips
        expect(find.text('Customer'), findsOneWidget);
        expect(find.text('Driver'), findsOneWidget);

        // 4. Verify Buttons (Phone SMS OTP replaces removed Google mock picker)
        expect(
          find.widgetWithText(ElevatedButton, 'Create Account'),
          findsOneWidget,
        );
        expect(find.text('Sign up with Google'), findsNothing);
        expect(find.text('Sign in with Phone (SMS OTP)'), findsOneWidget);
        expect(find.text('Already have an account? '), findsOneWidget);
      },
    );

    testWidgets(
      'Submitting register form validates, sends payload, and navigates to /home',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockAuth = MockAuthProviderForRegister();
        final userProvider = MockUserProviderForRegister();

        final router = GoRouter(
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Customer Home Screen')),
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

        // Type in full name -> auto fills username
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'),
          'David Kim',
        );
        await tester.pump();

        // Customise username
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'david_kim2026',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'),
          'david2026@foodgo.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'securepass123',
        );
        await tester.pump();

        final buttonFinder = find.widgetWithText(
          ElevatedButton,
          'Create Account',
        );
        await tester.ensureVisible(buttonFinder);
        await tester.pump();

        // Submit form
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(mockAuth.registeredUsername, 'david_kim2026');
        expect(mockAuth.registeredEmail, 'david2026@foodgo.com');
        expect(mockAuth.registeredPassword, 'securepass123');
        expect(mockAuth.registeredFirstName, 'David');
        expect(mockAuth.registeredLastName, 'Kim');
        expect(mockAuth.registeredRole, 'customer');

        // Confirm navigated to Customer Home Screen
        expect(find.text('Customer Home Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Driver role selection reveals optional vehicle fields and optional phone is forwarded',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockAuth = MockAuthProviderForRegister();
        final userProvider = MockUserProviderForRegister();

        final router = GoRouter(
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Customer Home Screen')),
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

        // Phone optional field exists immediately
        expect(
          find.widgetWithText(TextFormField, 'Phone Number (Optional)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'Vehicle Type (Optional)'),
          findsNothing,
        );

        // Select Driver role -> vehicle & plate inputs appear
        await tester.tap(find.text('Driver'));
        await tester.pump();
        expect(
          find.widgetWithText(TextFormField, 'Vehicle Type (Optional)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'License Plate (Optional)'),
          findsOneWidget,
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'),
          'driver_sombath',
        );
        // Entering Khmer full name must not erase non-empty ASCII username
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'),
          'សម្បត្តិ',
        );
        await tester.pump();
        final usernameField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Username'),
        );
        expect(usernameField.controller?.text, 'driver_sombath');

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'),
          'sombath@foodgo.kh',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'securepass123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone Number (Optional)'),
          '+855 12 345 678',
        );
        await tester.pump();

        final buttonFinder = find.widgetWithText(
          ElevatedButton,
          'Create Account',
        );
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(mockAuth.registeredUsername, 'driver_sombath');
        expect(mockAuth.registeredPhone, '+855 12 345 678');
        expect(mockAuth.registeredRole, 'driver');
      },
    );

    testWidgets(
      'S22 384x823.5 portrait layout submits Customer registration without overflow or missed tap',
      (tester) async {
        final prevFatal = WidgetController.hitTestWarningShouldBeFatal;
        WidgetController.hitTestWarningShouldBeFatal = true;
        tester.view.physicalSize = const Size(384, 823.5);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          WidgetController.hitTestWarningShouldBeFatal = prevFatal;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockAuth = MockAuthProviderForRegister();
        final userProvider = MockUserProviderForRegister();

        final router = GoRouter(
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Customer Home Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(padding: const EdgeInsets.only(top: 36, bottom: 20)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Sokha Customer');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(fields.at(1), 'e2e_ui_cust_12345');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(fields.at(2), 'e2e_ui_cust_12345@foodgo.kh');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(fields.at(3), 'Password123!');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(fields.at(4), '+855 12 311 222');
        await tester.pump(const Duration(milliseconds: 100));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.ensureVisible(find.text('Customer').first);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('Customer').first);
        await tester.pump(const Duration(milliseconds: 300));

        final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
        await tester.ensureVisible(createBtn.first);
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(createBtn.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(mockAuth.registeredUsername, 'e2e_ui_cust_12345');
        expect(mockAuth.registeredRole, 'customer');
        expect(find.text('Customer Home Screen'), findsOneWidget);
      },
    );
  });
}
