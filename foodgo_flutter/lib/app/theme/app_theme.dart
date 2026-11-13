import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/glass_theme.dart';

class AppTheme {
  static Color get primaryColor => GlassTheme.primaryGreen;
  static Color get primaryDark => GlassTheme.primaryGreenDark;
  static const Color accentColor = GlassTheme.ratingAmber;

  // Standard font families for Khmer script support
  static const String khmerPrimaryFont = 'Kantumruy Pro';
  static const String khmerClassicFont = 'Battambang';
  static const String khmerDisplayFont = 'Moul';
  static const String khmerBannerFont = 'Koulen';

  static const List<String> khmerFontFallbacks =
      AppTypography.khmerFontFallbacks;

  /// Traditional Khmer display font style (Moul) for festive titles and headers
  static TextStyle khmerMoulStyle({
    double fontSize = 20,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.5,
  }) {
    return TextStyle(
      fontFamily: khmerDisplayFont,
      fontFamilyFallback: khmerFontFallbacks,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// Tall Khmer banner font style (Koulen) for promotional tags and badges
  static TextStyle khmerKoulenStyle({
    double fontSize = 16,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.35,
    double letterSpacing = 0.5,
  }) {
    return TextStyle(
      fontFamily: khmerBannerFont,
      fontFamilyFallback: khmerFontFallbacks,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Modern, highly readable Khmer body font style (Kantumruy Pro)
  static TextStyle khmerBodyStyle({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: khmerPrimaryFont,
      fontFamilyFallback: khmerFontFallbacks,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// App-wide text theme. Delegates to the centralized [AppTypography] scale
  /// (Plus Jakarta Sans headings, Inter body, Khmer fallbacks).
  static TextTheme _buildTextTheme(Brightness brightness, [Locale? locale]) {
    return AppTypography.textTheme(brightness, locale: locale);
  }

  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  static ThemeData getLightTheme([AppColorPalette? palette, Locale? locale]) {
    final active = palette != null
        ? PaletteData.fromId(palette)
        : GlassTheme.activePalette;
    final primary = active.primary;
    final textTheme = _buildTextTheme(Brightness.light, locale);

    return ThemeData(
      useMaterial3: true,
      fontFamilyFallback: khmerFontFallbacks,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: active.secondary,
        error: GlassTheme.discountRed,
        brightness: Brightness.light,
        surface: active.backgroundLight,
      ).copyWith(onPrimary: active.onPrimary),
      scaffoldBackgroundColor: active.backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTypography.textPrimaryLight,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: active.onPrimary,
          elevation: 0,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(88, 48),
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: GlassTheme.borderRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: active.surfaceDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GlassTheme.borderLight,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassTheme.glassWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: GlassTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: GlassTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(
            color: GlassTheme.discountRed,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme([AppColorPalette? palette, Locale? locale]) {
    final active = palette != null
        ? PaletteData.fromId(palette)
        : GlassTheme.activePalette;
    final primary = active.primary;
    final textTheme = _buildTextTheme(Brightness.dark, locale);

    return ThemeData(
      useMaterial3: true,
      fontFamilyFallback: khmerFontFallbacks,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: active.secondary,
        error: GlassTheme.discountRed,
        brightness: Brightness.dark,
        surface: active.backgroundDark,
      ).copyWith(onPrimary: active.onPrimary),
      scaffoldBackgroundColor: active.backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: active.onPrimary,
          elevation: 0,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: GlassTheme.borderRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: active.dialogDark,
        shape: RoundedRectangleBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: active.surfaceDark,
        modalBackgroundColor: active.surfaceDark,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: active.surfaceDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(color: active.borderDark, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassTheme.glassDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: BorderSide(color: active.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: BorderSide(color: active.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(
            color: GlassTheme.discountRed,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
