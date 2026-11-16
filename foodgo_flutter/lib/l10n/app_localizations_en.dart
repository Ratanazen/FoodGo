// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FoodGo';

  @override
  String get tagline => 'Order fresh food in Phnom Penh';

  @override
  String get home => 'Home';

  @override
  String get search => 'Search';

  @override
  String get orders => 'Orders';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get login => 'Sign In';

  @override
  String get register => 'Create Account';

  @override
  String get logout => 'Log Out';

  @override
  String get cart => 'Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get deliveryTo => 'Delivery To';

  @override
  String get total => 'Total';

  @override
  String get payWithKhqr => 'Pay with Bakong KHQR';

  @override
  String get payWithCard => 'Pay with Card';

  @override
  String get payWithCod => 'Cash on Delivery';

  @override
  String get retry => 'Try Again';

  @override
  String get emptyStateMessage => 'No items found in this section.';

  @override
  String get errorGeneric =>
      'Something went wrong. Please check your connection.';
}
