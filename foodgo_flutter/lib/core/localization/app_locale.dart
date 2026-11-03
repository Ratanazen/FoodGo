import 'package:flutter/material.dart';

enum AppLanguage {
  english(code: 'en', country: 'US', label: 'English', nativeName: 'English'),
  khmer(code: 'km', country: 'KH', label: 'Khmer', nativeName: 'ភាសាខ្មែរ');

  final String code;
  final String country;
  final String label;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.country,
    required this.label,
    required this.nativeName,
  });

  Locale get locale => Locale(code, country);

  static AppLanguage fromCode(String? code) {
    if (code == 'km') return AppLanguage.khmer;
    return AppLanguage.english;
  }
}
