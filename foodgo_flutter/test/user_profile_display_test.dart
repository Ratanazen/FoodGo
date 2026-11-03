import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProvider Display and Initials Resolution Tests', () {
    test('formats_full_name_when_first_and_last_name_present', () {
      final provider = UserProvider();
      provider.setUser({
        'id': 5,
        'username': 'customer1',
        'email': 'customer@foodgo.com',
        'first_name': 'Bob',
        'last_name': 'Vann',
        'role': 'customer',
      });

      expect(provider.displayName, 'Bob Vann');
      expect(provider.initials, 'BV');
    });

    test('formats_display_name_from_email_when_names_are_empty', () {
      final provider = UserProvider();
      provider.setUser({
        'id': 8,
        'username': 'adb_user_123456',
        'email': 'thansombathboraratt23@gmail.com',
        'first_name': '',
        'last_name': '',
        'role': 'customer',
      });

      expect(provider.displayName, 'Thansombathboraratt23');
      expect(provider.initials, 'T');
    });

    test('uses_clean_username_when_email_and_names_are_empty', () {
      final provider = UserProvider();
      provider.setUser({
        'id': 8,
        'username': 'rat',
        'email': '',
        'first_name': '',
        'last_name': '',
        'role': 'customer',
      });

      expect(provider.displayName, 'rat');
      expect(provider.initials, 'R');
    });

    test('falls_back_to_foodie_when_user_is_null', () {
      final provider = UserProvider();
      provider.clearUser();

      expect(provider.displayName, 'Foodie');
      expect(provider.initials, 'F');
    });
  });
}
