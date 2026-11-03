import 'package:flutter/material.dart';

enum AppTextScale {
  small(0.85, 'Small', 'តូច (85%)'),
  standard(1.0, 'Default', 'ធម្មតា (100%)'),
  large(1.15, 'Large', 'ធំ (115%)'),
  extraLarge(1.30, 'Extra Large', 'ធំពិសេស (130%)');

  final double factor;
  final String labelEn;
  final String labelKh;

  const AppTextScale(this.factor, this.labelEn, this.labelKh);

  String label(bool isKhmer) => isKhmer ? labelKh : labelEn;

  static AppTextScale fromName(String? name) {
    switch (name) {
      case 'small':
        return AppTextScale.small;
      case 'large':
        return AppTextScale.large;
      case 'extraLarge':
        return AppTextScale.extraLarge;
      case 'standard':
      default:
        return AppTextScale.standard;
    }
  }
}

class AppTypography {
  // Font Families
  static const String fontFamilyKhmer = 'Kantumruy Pro';
  static const String fontFamilyClassicKhmer = 'Battambang';
  static const String fontFamilyDisplayKhmer = 'Moul';
  static const String fontFamilyBannerKhmer = 'Koulen';
  static const String fontFamilyEnglish = 'Inter';
  static const String fontFamilyNumeric = 'Inter';

  // Fallbacks
  static const List<String> khmerFontFallbacks = [
    fontFamilyKhmer,
    fontFamilyClassicKhmer,
    'Noto Sans Khmer',
    'sans-serif',
  ];

  // Font Sizes
  static const double fontSizeXs = 11.0;
  static const double fontSizeSm = 12.5;
  static const double fontSizeMd = 14.5;
  static const double fontSizeLg = 16.5;
  static const double fontSizeXl = 19.0;
  static const double fontSize2xl = 23.0;
  static const double fontSizeDisplay = 28.0;

  // Line Heights
  static const double lineHeightBody = 1.55;
  static const double lineHeightHeading = 1.35;
  static const double lineHeightTight = 1.25;

  // Font Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  /// Returns clean, locale-aware text style avoiding negative letter-spacing on Khmer text
  static TextStyle getStyle({
    required double fontSize,
    FontWeight fontWeight = fontWeightRegular,
    Color? color,
    double? height,
    double? letterSpacing,
    bool isKhmer = false,
  }) {
    final effectiveHeight = height ?? (fontSize >= fontSizeXl ? lineHeightHeading : lineHeightBody);
    final effectiveLetterSpacing = isKhmer ? 0.0 : letterSpacing;

    return TextStyle(
      fontFamily: isKhmer ? fontFamilyKhmer : fontFamilyEnglish,
      fontFamilyFallback: khmerFontFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: effectiveHeight,
      letterSpacing: effectiveLetterSpacing,
    );
  }
}
