import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_provider.dart';
import '../theme/app_typography.dart';
import 'app_locale.dart';

import 'app_translations.dart';

extension LocalizationContextExtension on BuildContext {
  /// Reactive localized string lookup using [LocaleProvider]
  String tr(String key, {Map<String, dynamic>? args, String? fallback}) {
    try {
      final provider = watch<LocaleProvider>();
      return provider.translate(key, args: args, fallback: fallback);
    } catch (_) {
      // Fallback to default English translation dictionary if called outside Provider tree (e.g. existing unit/widget test suites)
      return AppTranslations.get(key, 'en', args: args, fallback: fallback);
    }
  }

  /// Whether current active locale is Khmer
  bool get isKhmer {
    try {
      return watch<LocaleProvider>().isKhmer;
    } catch (_) {
      return false;
    }
  }

  /// Active [AppLanguage]
  AppLanguage get appLanguage {
    try {
      return watch<LocaleProvider>().language;
    } catch (_) {
      return AppLanguage.english;
    }
  }

  /// Active [Locale]
  Locale get currentLocale {
    try {
      return watch<LocaleProvider>().locale;
    } catch (_) {
      return const Locale('en', 'US');
    }
  }

  /// Active [AppTextScale]
  AppTextScale get currentTextScale {
    try {
      return watch<LocaleProvider>().textScale;
    } catch (_) {
      return AppTextScale.standard;
    }
  }

  /// Active text scale multiplier factor (e.g. 0.85, 1.00, 1.15, 1.30)
  double get textScaleFactor {
    try {
      return watch<LocaleProvider>().scaleFactor;
    } catch (_) {
      return 1.0;
    }
  }

  /// Quick access to [LocaleProvider] read
  LocaleProvider get localeProvider => read<LocaleProvider>();
}
