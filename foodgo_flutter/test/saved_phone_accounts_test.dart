import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/auth/presentation/login_screen.dart';
import 'package:foodgo_flutter/widgets/svg_icon.dart';

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

  group('Normal Clean Login UI Tests', () {
    testWidgets(
      'Login screen is clean: no intrusive accounts list, no Google sign-in, and no API URL dialog',
      (tester) async {
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

        // 3. Verify Saved Accounts on Phone list is NOT displayed on main screen (clean/normal UI)
        expect(find.text('Saved Accounts on Phone'), findsNothing);
        expect(find.text('Auto Add All'), findsNothing);

        // 4. Verify API Server URL dialog is NOT displayed and long press does not open it
        final logo = find.byType(FoodGoLogo);
        expect(logo, findsOneWidget);
        await tester.longPress(logo);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('API Server URL'), findsNothing);
      },
    );
  });

  group('UserProvider Full Name Resolution Tests', () {
    test(
      'fullName and displayName both return combined first and last name',
      () {
        final userProvider = UserProvider();
        userProvider.setUser({
          'username': 'admin',
          'first_name': 'FoodGo',
          'last_name': 'Admin',
          'role': 'admin',
        });

        expect(userProvider.displayName, 'FoodGo Admin');
        expect(userProvider.fullName, 'FoodGo Admin');
      },
    );

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
