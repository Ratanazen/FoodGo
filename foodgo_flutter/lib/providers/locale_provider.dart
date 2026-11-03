import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_locale.dart';
import '../core/localization/app_translations.dart';
import '../core/theme/app_typography.dart';

class LocaleProvider with ChangeNotifier {
  static const String _prefLanguageKey = 'app_language';
  static const String _prefTextScaleKey = 'app_text_scale';

  AppLanguage _language = AppLanguage.english;
  AppTextScale _textScale = AppTextScale.standard;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  bool get isKhmer => _language == AppLanguage.khmer;
  AppTextScale get textScale => _textScale;
  double get scaleFactor => _textScale.factor;

  LocaleProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var changed = false;
      final savedLang = prefs.getString(_prefLanguageKey);
      if (savedLang != null) {
        final parsed = AppLanguage.fromCode(savedLang);
        if (_language != parsed) {
          _language = parsed;
          changed = true;
        }
      }
      final savedScale = prefs.getString(_prefTextScaleKey);
      if (savedScale != null) {
        final parsedScale = AppTextScale.fromName(savedScale);
        if (_textScale != parsedScale) {
          _textScale = parsedScale;
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, lang.code);
    } catch (_) {}
  }

  Future<void> setLocale(Locale loc) async {
    final lang = AppLanguage.fromCode(loc.languageCode);
    await setLanguage(lang);
  }

  Future<void> toggleLanguage() async {
    final next = _language == AppLanguage.english
        ? AppLanguage.khmer
        : AppLanguage.english;
    await setLanguage(next);
  }

  Future<void> setTextScale(AppTextScale scale) async {
    if (_textScale == scale) return;
    _textScale = scale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTextScaleKey, scale.name);
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    _language = AppLanguage.english;
    _textScale = AppTextScale.standard;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, AppLanguage.english.code);
      await prefs.setString(_prefTextScaleKey, AppTextScale.standard.name);
    } catch (_) {}
  }

  String translate(String key, {Map<String, dynamic>? args, String? fallback}) {
    return AppTranslations.get(
      key,
      _language.code,
      args: args,
      fallback: fallback,
    );
  }
}
