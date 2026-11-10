import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/auth/presentation/login_screen.dart';

class MockAuthProviderForSavedAccs extends AuthProvider {
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

class MockUserProviderForSavedAccs extends UserProvider {
  @override
  Future<void> fetchUser() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Saved Accounts on Phone & Google Removal Tests', () {
    testWidgets('Google sign-in is removed and Saved Accounts on Phone header exists', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuthProviderForSavedAccs();
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

      // 1. Verify Google Sign-In button is completely removed
      expect(find.text('Google'), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);

      // 2. Verify Phone OTP button is present
      expect(find.text('Sign in with Phone (SMS OTP)'), findsOneWidget);

      // 3. Verify Saved Accounts on Phone & Auto Add All are present
      expect(find.text('Saved Accounts on Phone'), findsOneWidget);
      expect(find.text('Auto Add All'), findsOneWidget);
    });

    testWidgets('Tapping Auto Add All saves all 6 preset accounts to phone and populates cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuthProviderForSavedAccs();
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
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap Auto Add All
      await tester.ensureVisible(find.text('Auto Add All'));
      await tester.tap(find.text('Auto Add All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify all 6 preset accounts are visible on phone
      expect(find.text('FoodGo Admin'), findsOneWidget);
      expect(find.text('@admin'), findsOneWidget);
      expect(find.text('Bob Rider (Driver)'), findsOneWidget);
      expect(find.text('@driver1'), findsOneWidget);
      expect(find.text('Sophea Swift (Driver)'), findsOneWidget);
      expect(find.text('@driver2'), findsOneWidget);
      expect(find.text('Alice Smith (Customer)'), findsOneWidget);
      expect(find.text('@customer1'), findsOneWidget);
      expect(find.text('Ratana Zen (Customer)'), findsOneWidget);
      expect(find.text('@Ratana'), findsOneWidget);
      expect(find.text('Restaurant Owner'), findsOneWidget);
      expect(find.text('@owner'), findsOneWidget);

      // Verify account count badge shows 6
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('Tapping a saved account card fills username and password into form', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuthProviderForSavedAccs();
      final userProvider = MockUserProviderForSavedAccs();

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/driver-dashboard',
            builder: (context, state) =>
                const Scaffold(body: Text('Driver Dashboard')),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('Home Screen')),
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
      await tester.pump(const Duration(milliseconds: 1000));

      // Add all accounts
      await tester.ensureVisible(find.text('Auto Add All'));
      await tester.tap(find.text('Auto Add All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap on Delivery driver card (Bob Rider)
      await tester.ensureVisible(find.text('Bob Rider (Driver)'));
      await tester.tap(find.text('Bob Rider (Driver)'));
      await tester.pump();

      // Check form fields filled
      final usernameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Username or Email'),
      );
      expect(usernameField.controller?.text, 'driver1');

      final passwordField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Password'),
      );
      expect(passwordField.controller?.text, 'driver123');

      // Now tap Sign In
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockAuth.lastUsername, 'driver1');
      expect(mockAuth.lastPassword, 'driver123');
    });

    testWidgets('Removing a saved account deletes it from the list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockAuth = MockAuthProviderForSavedAccs();
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
      await tester.pump(const Duration(milliseconds: 1000));

      // Auto add all
      await tester.ensureVisible(find.text('Auto Add All'));
      await tester.tap(find.text('Auto Add All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('FoodGo Admin'), findsOneWidget);

      // Tap remove icon on the first card
      final removeButtons = find.byTooltip('Remove from phone');
      expect(removeButtons, findsNWidgets(6));
      await tester.tap(removeButtons.first);
      await tester.pump();

      // FoodGo Admin should now be removed
      expect(find.text('FoodGo Admin'), findsNothing);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('UserProvider Full Name Resolution Tests', () {
    test('fullName and displayName both return combined first and last name', () {
      final userProvider = UserProvider();
      userProvider.setUser({
        'username': 'admin',
        'first_name': 'FoodGo',
        'last_name': 'Admin',
        'role': 'admin',
      });

      expect(userProvider.displayName, 'FoodGo Admin');
      expect(userProvider.fullName, 'FoodGo Admin');
    });

    test('fullName falls back to full_name field when first_name is empty', () {
      final userProvider = UserProvider();
      userProvider.setUser({
        'username': 'driver1',
        'full_name': 'Bob Rider',
        'role': 'driver',
      });

      expect(userProvider.displayName, 'Bob Rider');
      expect(userProvider.fullName, 'Bob Rider');
    });
  });
}
