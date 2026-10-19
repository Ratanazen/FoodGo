import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/core/utils/khmer_currency.dart';
import 'package:foodgo_flutter/providers/currency_provider.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'foodgo_preferred_currency': 'usd',
    });
    KhmerCurrency.updateRate(4100.0, 'National Bank of Cambodia (NBC)');
  });

  group('KhmerCurrency Utility Tests', () {
    test('Converts USD to KHR accurately with standard 4100 rate', () {
      expect(KhmerCurrency.khrPerUsd, 4100.0);
      expect(KhmerCurrency.toKhr(1.0), 4100);
      expect(KhmerCurrency.toKhr(10.0), 41000);
      expect(KhmerCurrency.toKhr(2.5), 10250);
    });

    test('Converts KHR to USD accurately', () {
      expect(KhmerCurrency.toUsd(4100), 1.0);
      expect(KhmerCurrency.toUsd(8200), 2.0);
    });

    test(
      'Formats USD and KHR strings with proper currency symbols and commas',
      () {
        expect(KhmerCurrency.formatUsd(15.5), r'$15.50');
        expect(KhmerCurrency.formatKhr(15.5), '៛63,550');
        expect(KhmerCurrency.formatDual(10.0), r'$10.00 (៛41,000)');
        expect(KhmerCurrency.formatDualApprox(10.0), r'$10.00 ≈ ៛41,000');
      },
    );

    test('Dynamically updates exchange rate and propagates calculations', () {
      KhmerCurrency.updateRate(4125.0, 'NBC Customary Daily');
      expect(KhmerCurrency.khrPerUsd, 4125.0);
      expect(KhmerCurrency.toKhr(2.0), 8250);
      expect(KhmerCurrency.formatKhr(2.0), '៛8,250');

      // Reset
      KhmerCurrency.updateRate(4100.0);
    });
  });

  group('CurrencyProvider Unit Tests', () {
    test('Initializes with USD default and correct symbols', () {
      final provider = CurrencyProvider();
      expect(provider.currency, DisplayCurrency.usd);
      expect(provider.currencySymbol, r'$');
      expect(provider.isUsd, true);
      expect(provider.isKhr, false);
      expect(provider.isDual, false);
    });

    test('toggleCurrency cycles through USD -> KHR -> DUAL -> USD', () {
      final provider = CurrencyProvider();
      expect(provider.currency, DisplayCurrency.usd);

      provider.toggleCurrency();
      expect(provider.currency, DisplayCurrency.khr);
      expect(provider.currencySymbol, '៛');

      provider.toggleCurrency();
      expect(provider.currency, DisplayCurrency.dual);
      expect(provider.currencySymbol, r'$ / ៛');

      provider.toggleCurrency();
      expect(provider.currency, DisplayCurrency.usd);
    });

    test('format method delegates based on active display mode', () {
      final provider = CurrencyProvider();

      // USD mode
      provider.setCurrency(DisplayCurrency.usd);
      expect(provider.format(10.0), r'$10.00');

      // KHR mode
      provider.setCurrency(DisplayCurrency.khr);
      expect(provider.format(10.0), '៛41,000');

      // Dual mode
      provider.setCurrency(DisplayCurrency.dual);
      expect(provider.format(10.0), r'$10.00 (៛41,000)');
    });
  });

  group('SettingsScreen Currency Switcher Widget Tests', () {
    testWidgets('Renders Currency tile and opens modal sheet', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider(),
            ),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Currency settings tile
      expect(find.text('Display Currency'), findsOneWidget);
      expect(find.byIcon(Icons.currency_exchange), findsOneWidget);

      // Tap Currency settings tile
      await tester.tap(find.text('Display Currency'));
      await tester.pumpAndSettle();

      // Verify bottom sheet modal opened
      expect(find.text(r'USD ($)'), findsOneWidget);
      expect(find.text('KHR (៛)'), findsOneWidget);
      expect(find.text(r'Dual Currency ($ / ៛)'), findsOneWidget);

      // Tap KHR option
      await tester.tap(find.text('KHR (៛)'));
      await tester.pumpAndSettle();
    });
  });
}
