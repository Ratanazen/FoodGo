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
  static const Color backgroundLight = Color(0xFFF4F6FC);
  static const Color backgroundDark = Color(0xFF0C1220);
  static const Color outerBackground = Color(0xFF080C16);

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

  // Liquid Glass Design System
  static const double radius = 24.0;
  static const double blurSigma = 20.0;
  static const double liquidBlurSigma = 24.0;

  static const Color glassWhite = Color(
    0xD9FFFFFF,
  ); // ~85% opacity frosted white
  static const Color glassWhiteLight = Color(
    0xA6F4F6FC,
  ); // ~65% opacity pale smalt liquid

  static const Color glassDark = Color(
    0xD8162244,
  ); // ~85% opacity liquid smalt deep
  static const Color glassDarkLight = Color(
    0x991F2D5A,
  ); // ~60% opacity liquid smalt shadow

  static const Color borderLight = Color(
    0x80FFFFFF,
  ); // 50% opacity specular edge
  static const Color borderDark = Color(
    0x40A9B7E1,
  ); // 25% opacity smalt tint specular edge

  static const LinearGradient liquidGlassBorderDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x66A9B7E1), // smaltTint highlight
      Color(0x20BBC6EC), // paleSmalt subtle
      Color(0x102A52BE), // royalSmalt whisper
      Color(0x4D3B4AB5), // stormySmalt reflection
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  static const LinearGradient liquidGlassBorderLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x99FFFFFF), // crisp specular highlight
      Color(0x4DFFFFFF),
      Color(0x33A9B7E1),
      Color(0x80FFFFFF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient liquidSurfaceDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xE01F2847), // inkSmalt liquid top
      Color(0xC81A2653), // midnightSmalt body
      Color(0xD0202E5F), // smaltShadow base
    ],
  );

  static const LinearGradient liquidSurfaceLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF2FFFFFF), Color(0xD8F4F6FC), Color(0xE6E8EDF9)],
  );

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
    color: smaltShadow.withValues(alpha: 0.12),
    blurRadius: 18,
    spreadRadius: 0,
    offset: const Offset(0, 6),
  );

  static BoxShadow get pillCardShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 16,
    spreadRadius: 1,
    offset: const Offset(0, 4),
  );

  static BoxShadow get liquidShadow => BoxShadow(
    color: const Color(0xFF080C16).withValues(alpha: 0.32),
    blurRadius: 24,
    spreadRadius: -2,
    offset: const Offset(0, 10),
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

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets modalPadding = EdgeInsets.all(lg);
}

class AppShadows {
  static List<BoxShadow> card(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF1E2847).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> floating(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.45)
          : const Color(0xFF1E2847).withValues(alpha: 0.14),
      blurRadius: 24,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> button(Color baseColor) => [
    BoxShadow(
      color: baseColor.withValues(alpha: 0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
