import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/glass_theme.dart';

class AppTheme {
  static const Color primaryColor = GlassTheme.primaryGreen;
  static const Color primaryDark = GlassTheme.primaryGreenDark;
  static const Color accentColor = GlassTheme.ratingAmber;

  // Standard font family fallbacks for Khmer script support
  static const List<String> khmerFontFallbacks = [
    'Kantumruy Pro',
    'Battambang',
    'Noto Sans Khmer',
    'sans-serif',
  ];

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

    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.25,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
        color: primaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
        color: secondaryTextColor,
        fontFamilyFallback: khmerFontFallbacks,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: GlassTheme.discountRed,
        brightness: Brightness.light,
        surface: GlassTheme.backgroundLight,
      ),
      scaffoldBackgroundColor: GlassTheme.backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: GlassTheme.textDark,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
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
          foregroundColor: primaryColor,
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: primaryColor, width: 1.5),
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
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GlassTheme.surfaceDark,
        contentTextStyle: TextStyle(
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
          borderSide: const BorderSide(color: primaryColor, width: 2),
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

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: GlassTheme.discountRed,
        brightness: Brightness.dark,
        surface: GlassTheme.backgroundDark,
      ),
      scaffoldBackgroundColor: GlassTheme.backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
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
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: GlassTheme.surfaceDark,
        modalBackgroundColor: GlassTheme.surfaceDark,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GlassTheme.surfaceDark,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GlassTheme.borderDark,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassTheme.glassDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: GlassTheme.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: GlassTheme.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: GlassTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: primaryColor, width: 2),
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
