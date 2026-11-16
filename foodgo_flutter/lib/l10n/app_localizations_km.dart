// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'FoodGo';

  @override
  String get tagline => 'កុម្ម៉ង់អាហារឆ្ងាញ់ៗនៅរាជធានីភ្នំពេញ';

  @override
  String get home => 'ទំព័រដើម';

  @override
  String get search => 'ស្វែងរក';

  @override
  String get orders => 'ការកុម្ម៉ង់';

  @override
  String get favorites => 'ចំណូលចិត្ត';

  @override
  String get profile => 'គណនី';

  @override
  String get login => 'ចូលគណនី';

  @override
  String get register => 'ចុះឈ្មោះ';

  @override
  String get logout => 'ចាកចេញ';

  @override
  String get cart => 'កន្ត្រកទំនិញ';

  @override
  String get checkout => 'ទូទាត់ប្រាក់';

  @override
  String get deliveryTo => 'ដឹកជញ្ជូនទៅកាន់';

  @override
  String get total => 'សរុប';

  @override
  String get payWithKhqr => 'ទូទាត់តាមបាគង KHQR';

  @override
  String get payWithCard => 'ទូទាត់តាមកាត';

  @override
  String get payWithCod => 'ទូទាត់ពេលដឹកដល់ (COD)';

  @override
  String get retry => 'ព្យាយាមម្ដងទៀត';

  @override
  String get emptyStateMessage => 'មិនមានមុខម្ហូបនៅក្នុងផ្នែកនេះទេ';

  @override
  String get errorGeneric =>
      'មានបញ្ហាបច្ចេកទេស។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត។';
}
