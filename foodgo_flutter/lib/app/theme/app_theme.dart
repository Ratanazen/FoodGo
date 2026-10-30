import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static const List<String> khmerFontFallbacks = [
    'Kantumruy Pro',
    'Battambang',
    'Noto Sans Khmer',
    'sans-serif',
  ];

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

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final primaryTextColor = brightness == Brightness.dark
        ? GlassTheme.textLight
        : GlassTheme.textDark;

    final secondaryTextColor = brightness == Brightness.dark
        ? GlassTheme.textMutedLight
        : GlassTheme.textMuted;

    final inter = GoogleFonts.interTextTheme(base);

    // Derive every style from the Inter base and pair with Kantumruy Pro & Khmer fallbacks
    return inter.copyWith(
      displayLarge: inter.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.25,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      displayMedium: inter.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.25,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      displaySmall: inter.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.3,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      headlineLarge: inter.headlineLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.35,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.25,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.25,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.25,
        color: secondaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
    );
  }

  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();

  static ThemeData getLightTheme([AppColorPalette? palette]) {
    final active = palette != null
        ? PaletteData.fromId(palette)
        : GlassTheme.activePalette;
    final primary = active.primary;
    final textTheme = _buildTextTheme(Brightness.light);

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
        foregroundColor: GlassTheme.textDark,
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
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
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
        contentTextStyle: const TextStyle(
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

  static ThemeData getDarkTheme([AppColorPalette? palette]) {
    final active = palette != null
        ? PaletteData.fromId(palette)
        : GlassTheme.activePalette;
    final primary = active.primary;
    final textTheme = _buildTextTheme(Brightness.dark);

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
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
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
        contentTextStyle: const TextStyle(
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
