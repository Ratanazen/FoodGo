import 'package:flutter/material.dart';

class GlassTheme {
  // App Backgrounds
  static const Color backgroundLight = Color(0xFFF3F6F4);
  static const Color backgroundDark = Color(0xFF0E1511);
  static const Color outerBackground = Color(0xFF070B09);

  // Brand Greens
  static const Color primaryGreen = Color(0xFF35B86B);
  static const Color primaryGreenDark = Color(0xFF289A57);
  static const Color primaryGreenAccent = Color(0xFF7FFFB3);

  // Modern Food Delivery (Foodpanda & Grab) Accents
  static const Color foodpandaPink = Color(0xFFD70F64);
  static const Color accentOrange = Color(0xFFFF6A00);
  static const Color ratingAmber = Color(0xFFFFB800);
  static const Color discountRed = Color(0xFFE53935);

  // Surfaces, Cards & Sheets
  static const Color surfaceDark = Color(0xFF141F18);
  static const Color surfaceCardDark = Color(0xFF141C17);
  static const Color cardDark = Color(0xFF161F1A);
  static const Color badgeTagDark = Color(0xFF1B2620);
  static const Color dialogDark = Color(0xFF161F1A);
  static const Color dropdownDark = Color(0xFF1A261D);

  // Banking, KHQR & Payment Providers
  static const Color bakongRed = Color(0xFFE41E26);
  static const Color khqrBannerRed = Color(0xFFE41E26);
  static const Color abaBlue = Color(0xFF005A87);
  static const Color acledaNavy = Color(0xFF16325C);
  static const Color codAmber = Color(0xFFFFC107);

  // External Provider & Promotional Accents
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color promoBlue = Color(0xFF2979FF);
  static const Color offlineRed = Color(0xFFD32F2F);

  // Map & Navigation Accents
  static const Color mapBlue = Color(0xFF1976D2);
  static const Color mapRed = Color(0xFFE53935);
  static const Color mapDriverBike = Color(0xFF1E88E5);

  // Status Indicators
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusConfirmed = Color(0xFF2196F3);
  static const Color statusPreparing = Color(0xFF2196F3);
  static const Color statusOnDelivery = Color(0xFF9C27B0);
  static const Color statusDelivered = primaryGreen;
  static const Color statusCancelled = Color(0xFFE53935);

  // Text Colors
  static const Color textDark = Color(0xFF17201B);
  static const Color textMuted = Color(0xFF7B857F);
  static const Color textLight = Color(0xFFF3F6F4);
  static const Color textMutedLight = Color(0xFFA5ACA7);

  // Glassmorphic Opacities & Dimensions
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

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
