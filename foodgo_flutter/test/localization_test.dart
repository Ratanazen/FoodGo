import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/core/localization/app_locale.dart';
import 'package:foodgo_flutter/core/localization/app_translations.dart';
import 'package:foodgo_flutter/core/theme/app_typography.dart';
import 'package:foodgo_flutter/providers/locale_provider.dart';
import 'package:foodgo_flutter/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Key Parity & Missing Key Detector', () {
    test(
      'AppTranslations.en and AppTranslations.km have identical key sets (100% Parity)',
      () {
        final enKeys = AppTranslations.en.keys.toSet();
        final kmKeys = AppTranslations.km.keys.toSet();

        final missingInKm = enKeys.difference(kmKeys);
        final missingInEn = kmKeys.difference(enKeys);

        expect(
          missingInKm,
          isEmpty,
          reason: 'Keys defined in English but missing in Khmer: $missingInKm',
        );
        expect(
          missingInEn,
          isEmpty,
          reason: 'Keys defined in Khmer but missing in English: $missingInEn',
        );
        expect(enKeys.length, kmKeys.length);
        expect(enKeys.length, greaterThanOrEqualTo(100));
      },
    );

    test('No translation strings in EN or KM are empty or whitespace-only', () {
      for (final entry in AppTranslations.en.entries) {
        expect(
          entry.value.trim(),
          isNotEmpty,
          reason: 'English key "${entry.key}" has an empty value',
        );
      }
      for (final entry in AppTranslations.km.entries) {
        expect(
          entry.value.trim(),
          isNotEmpty,
          reason: 'Khmer key "${entry.key}" has an empty value',
        );
      }
    });

    test('Domain coverage includes all essential app modules', () {
      final domains = [
        'common.',
        'nav.',
        'auth.',
        'home.',
        'restaurant.',
        'cart.',
        'checkout.',
        'payment.',
        'orders.',
        'driver.',
        'admin.',
        'settings.',
        'errors.',
      ];

      for (final domain in domains) {
        final enDomainKeys = AppTranslations.en.keys.where(
          (k) => k.startsWith(domain),
        );
        final kmDomainKeys = AppTranslations.km.keys.where(
          (k) => k.startsWith(domain),
        );

        expect(
          enDomainKeys,
          isNotEmpty,
          reason: 'Domain $domain has no English translation keys',
        );
        expect(
          kmDomainKeys,
          isNotEmpty,
          reason: 'Domain $domain has no Khmer translation keys',
        );
      }
    });
  });

  group('LocaleProvider Reactivity & State', () {
    test('Initializes with English as default', () {
      final provider = LocaleProvider();
      expect(provider.language, AppLanguage.english);
      expect(provider.locale.languageCode, 'en');
      expect(provider.isKhmer, isFalse);
    });

    test('setLanguage switches to Khmer and notifies listeners', () async {
      final provider = LocaleProvider();
      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      await provider.setLanguage(AppLanguage.khmer);

      expect(provider.language, AppLanguage.khmer);
      expect(provider.locale.languageCode, 'km');
      expect(provider.isKhmer, isTrue);
      expect(notificationCount, 1);
    });

    test('toggleLanguage alternates between English and Khmer', () async {
      final provider = LocaleProvider();
      expect(provider.language, AppLanguage.english);

      await provider.toggleLanguage();
      expect(provider.language, AppLanguage.khmer);

      await provider.toggleLanguage();
      expect(provider.language, AppLanguage.english);
    });

    test('translate resolves keys dynamically per current language', () async {
      final provider = LocaleProvider();

      // English
      expect(provider.translate('nav.home'), 'Home');
      expect(provider.translate('payment.qrTitle'), 'Scan to Pay');

      // Switch to Khmer
      await provider.setLanguage(AppLanguage.khmer);
      expect(provider.translate('nav.home'), 'ទំព័រដើម');
      expect(provider.translate('payment.qrTitle'), 'ទូទាត់ប្រាក់តាម KHQR');
    });

    test('translate returns fallback or key when translation missing', () {
      final provider = LocaleProvider();
      expect(
        provider.translate('unknown.key', fallback: 'Default Fallback'),
        'Default Fallback',
      );
      expect(provider.translate('unknown.key'), 'unknown.key');
    });
  });

  group('SharedPreferences Persistence', () {
    test('Persists language change to SharedPreferences', () async {
      final provider = LocaleProvider();
      await provider.setLanguage(AppLanguage.khmer);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'km');

      await provider.setLanguage(AppLanguage.english);
      expect(prefs.getString('app_language'), 'en');
    });

    test('Loads saved Khmer language preference on startup', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'km'});

      final provider = LocaleProvider();
      // Allow async _loadPreferences() to complete
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.language, AppLanguage.khmer);
      expect(provider.isKhmer, isTrue);
    });

    test('resetToDefaults restores English and standard text scale', () async {
      final provider = LocaleProvider();
      await provider.setLanguage(AppLanguage.khmer);
      await provider.setTextScale(AppTextScale.extraLarge);

      await provider.resetToDefaults();

      expect(provider.language, AppLanguage.english);
      expect(provider.textScale, AppTextScale.standard);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'en');
      expect(prefs.getString('app_text_scale'), 'standard');
    });
  });

  group('Khmer Script & Theme Integration', () {
    test(
      'Khmer translations contain valid Khmer Unicode characters (U+1780 to U+17FF)',
      () {
        final khmerRegex = RegExp(r'[\u1780-\u17FF]');
        final sampleKhmerKeys = [
          'common.save',
          'nav.home',
          'auth.login',
          'payment.qrTitle',
          'orders.title',
        ];

        for (final key in sampleKhmerKeys) {
          final text = AppTranslations.km[key]!;
          expect(
            khmerRegex.hasMatch(text),
            isTrue,
            reason: 'Key "$key" should contain Khmer Unicode characters',
          );
        }
      },
    );

    test(
      'AppTheme.getLightTheme configures Kantumruy Pro with zero negative letterSpacing for Khmer',
      () {
        final lightKhmerTheme = AppTheme.getLightTheme(
          null,
          const Locale('km'),
        );
        final bodyLarge = lightKhmerTheme.textTheme.bodyLarge;

        expect(bodyLarge, isNotNull);
        expect(bodyLarge?.fontFamily, 'Kantumruy Pro');
        expect(bodyLarge?.letterSpacing ?? 0.0, greaterThanOrEqualTo(0.0));
        expect(bodyLarge?.height, greaterThanOrEqualTo(1.4));
      },
    );

    test('AppTheme.getDarkTheme configures Kantumruy Pro for Khmer', () {
      final darkKhmerTheme = AppTheme.getDarkTheme(null, const Locale('km'));
      final titleMedium = darkKhmerTheme.textTheme.titleMedium;

      expect(titleMedium, isNotNull);
      expect(titleMedium?.fontFamily, 'Kantumruy Pro');
      expect(titleMedium?.letterSpacing ?? 0.0, greaterThanOrEqualTo(0.0));
    });
  });
}
