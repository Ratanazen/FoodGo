import 'package:flutter/material.dart';

class GlassTheme {
  static const Color backgroundLight = Color(0xFFF3F6F4);
  static const Color backgroundDark = Color(0xFF0E1511);
  
  static const Color primaryGreen = Color(0xFF35B86B);
  static const Color primaryGreenDark = Color(0xFF289A57);
  
  static const Color textDark = Color(0xFF17201B);
  static const Color textMuted = Color(0xFF7B857F);
  
  static const Color textLight = Color(0xFFF3F6F4);
  static const Color textMutedLight = Color(0xFFA5ACA7);

  static const double radius = 24.0;
  static const double blurSigma = 15.0;
  
  static const Color glassWhite = Color(0xAAFFFFFF); // ~66% opacity
  static const Color glassWhiteLight = Color(0x77FFFFFF); // ~46% opacity
  
  static const Color glassDark = Color(0xAA1E1E1E); // ~66% opacity
  static const Color glassDarkLight = Color(0x771E1E1E); // ~46% opacity

  static const Color borderLight = Color(0x66FFFFFF); // 40% opacity
  static const Color borderDark = Color(0x66FFFFFF);
  
  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(16.0);

  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 15,
    spreadRadius: 0,
    offset: const Offset(0, 5),
  );
}

class AppRadius {
  static const double small = 12.0;
  static const double medium = 18.0;
  static const double large = 26.0;
  static const double pill = 999.0;
}
