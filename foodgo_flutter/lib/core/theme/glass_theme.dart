import 'package:flutter/material.dart';

class GlassTheme {
  // 21 Smalt Blue Palette Tokens (from reference media_1792722551337.png)
  static const Color paleSmalt = Color(0xFFBBC6EC);
  static const Color smaltTint = Color(0xFFA9B7E1);
  static const Color smaltBlueMist = Color(0xFFA2B2D5);
  static const Color smaltPowder = Color(0xFFA5ADD4);
  static const Color frostedSmalt = Color(0xFF92A3CE);
  static const Color fadedSmalt = Color(0xFF6479B2);
  static const Color dustyCobalt = Color(0xFF5B6CA8);

  static const Color slateSmalt = Color(0xFF4D5D9E);
  static const Color mutedSmaltBlue = Color(0xFF3C4D8B);
  static const Color stormySmalt = Color(0xFF3B4AB5);
  static const Color royalSmalt = Color(0xFF2A52BE);
  static const Color cobaltSmalt = Color(0xFF0047AB);
  static const Color vividSmalt = Color(0xFF1D3FA4);
  static const Color trueSmalt = Color(0xFF003399);

  static const Color smaltIndigo = Color(0xFF3B4E9C);
  static const Color deepSmalt = Color(0xFF223C7A);
  static const Color vintageSmalt = Color(0xFF2C3874);
  static const Color twilightSmalt = Color(0xFF1F336B);
  static const Color inkSmalt = Color(0xFF1F2847);
  static const Color smaltShadow = Color(0xFF202E5F);
  static const Color midnightSmalt = Color(0xFF1A2653);

  // App Backgrounds (Smalt Blue Dark Theme)
  static const Color backgroundLight = Color(0xFFF3F5FC);
  static const Color backgroundDark = Color(0xFF101626);
  static const Color outerBackground = Color(0xFF0A0E1A);

  // Brand Smalt Blue (Rebound across all 500+ widget references seamlessly)
  static const Color primarySmalt = royalSmalt; // 0xFF2A52BE
  static const Color primaryGreen = royalSmalt; // 0xFF2A52BE
  static const Color primaryGreenDark = cobaltSmalt; // 0xFF0047AB
  static const Color primaryGreenAccent = smaltTint; // 0xFFA9B7E1

  // TikTok Reference Delivery Tokens
  static const Color headerGreenStart = Color(0xFF236E31);
  static const Color headerGreenMid = Color(0xFF2E7D32);
  static const Color headerGreenEnd = Color(0xFF388E3C);
  static const Color lightGreenSurface = Color(0xFFE8F5E9);
  static const Color lightGreenText = Color(0xFF2E7D32);
  static const Color lightGreenBorder = Color(0xFFC8E6C9);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [twilightSmalt, deepSmalt, royalSmalt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Modern Vibrant Lime Delivery Accents (New Reference Design)
  static const Color limeAccent = Color(0xFFCCFF00);
  static const Color limeAccentMuted = Color(0xFFD4E157);
  static const Color limeAccentBright = Color(0xFFD7FB00);
  static const Color limeSurface = Color(0xFFF9FBE7);
  static const Color heroDarkCard = Color(0xFF1E1E20);

  // Modern Auth Blue Design Tokens (Reference Mockup media_1792405659354.png)
  static const Color authBlue = Color(0xFF1B64F2);
  static const Color authBlueDark = Color(0xFF1351CA);
  static const Color authBlueLight = Color(0xFFEFF4FF);
  static const Color authTitleDark = Color(0xFF1E293B);
  static const Color authSubtitle = Color(0xFF64748B);
  static const Color authInputFill = Color(0xFFF8FAFC);
  static const Color authInputBorder = Color(0xFFE2E8F0);

  // Modern Food Delivery Accents
  static const Color foodpandaPink = Color(0xFFD70F64);
  static const Color accentOrange = Color(0xFFFF6A00);
  static const Color ratingAmber = Color(0xFFFFB800);
  static const Color discountRed = Color(0xFFE53935);

  // Surfaces, Cards & Sheets (Smalt Dark Surface Architecture)
  static const Color surfaceDark = midnightSmalt; // 0xFF1A2653
  static const Color surfaceCardDark = smaltShadow; // 0xFF202E5F
  static const Color cardDark = inkSmalt; // 0xFF1F2847
  static const Color badgeTagDark = deepSmalt; // 0xFF223C7A
  static const Color dialogDark = inkSmalt; // 0xFF1F2847
  static const Color dropdownDark = smaltShadow; // 0xFF202E5F

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
  static BorderRadius get borderRadiusMedium =>
      BorderRadius.circular(AppRadius.medium);
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

  static BoxShadow get pillCardShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 16,
    spreadRadius: 1,
    offset: const Offset(0, 4),
  );

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Shimmer Skeleton Colors
  static const Color shimmerBaseDark = inkSmalt;
  static const Color shimmerHighlightDark = vintageSmalt;
  static const Color shimmerBaseLight = Color(0xFFE2E7F5);
  static const Color shimmerHighlightLight = Color(0xFFEFF3FD);
}

class AppRadius {
  static const double small = 12.0;
  static const double medium = 18.0;
  static const double large = 26.0;
  static const double pill = 999.0;
}
