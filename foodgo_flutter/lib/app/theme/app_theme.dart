import 'package:flutter/material.dart';
import '../../core/theme/glass_theme.dart';

class AppTheme {
  static const Color primaryColor = GlassTheme.primaryGreen;
  static const Color primaryDark = GlassTheme.primaryGreenDark;
  static const Color accentColor = GlassTheme.ratingAmber;

  static ThemeData get lightTheme {
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: GlassTheme.textDark),
        bodyMedium: TextStyle(color: GlassTheme.textDark),
        titleLarge: TextStyle(color: GlassTheme.textDark, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: GlassTheme.borderRadius,
        ),
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
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: GlassTheme.borderLight,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassTheme.glassWhite,
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
      ),
    );
  }

  static ThemeData get darkTheme {
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: GlassTheme.textLight),
        bodyMedium: TextStyle(color: GlassTheme.textLight),
        titleLarge: TextStyle(color: GlassTheme.textLight, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: GlassTheme.borderRadiusSmall,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: GlassTheme.borderRadius,
        ),
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
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: GlassTheme.borderDark,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassTheme.glassDark,
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
      ),
    );
  }
}
