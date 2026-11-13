import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// User-selectable accessibility text size (Settings > Text Size).
///
/// The effective scale is always clamped to [AppTypography.minTextScale] and
/// [AppTypography.maxTextScale] in `main.dart` so layouts never break.
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

/// Single source of truth for FoodGo typography (Customer, Driver,
/// Restaurant Portal and Admin).
///
/// * Headings / titles: Plus Jakarta Sans, line height 1.3, letter-spacing -0.2
/// * Body / labels: Inter, line height 1.5, letter-spacing 0
/// * Khmer: Kantumruy Pro (bundled) with Noto Sans Khmer as fallback, and
///   never negative letter-spacing (prevents clipped subscripts / vowels).
///
/// Widgets should read styles through `Theme.of(context).textTheme` (or the
/// `context.textTheme` shortcut below) instead of building inline
/// `TextStyle(fontSize: ...)` objects.
class AppTypography {
  AppTypography._();

  // ---------------------------------------------------------------------------
  // Font families
  // ---------------------------------------------------------------------------
  static const String fontFamilyHeading = 'Plus Jakarta Sans';
  static const String fontFamilyBody = 'Inter';
  static const String fontFamilyKhmer = 'Kantumruy Pro';
  static const String fontFamilyClassicKhmer = 'Battambang';
  static const String fontFamilyDisplayKhmer = 'Moul';
  static const String fontFamilyBannerKhmer = 'Koulen';
  static const String fontFamilyNotoKhmer = 'Noto Sans Khmer';

  /// Kept for backwards compatibility with older widgets.
  static const String fontFamilyEnglish = fontFamilyBody;
  static const String fontFamilyNumeric = fontFamilyBody;

  /// Static fallback chain used where google_fonts cannot be resolved.
  static const List<String> khmerFontFallbacks = [
    fontFamilyKhmer,
    fontFamilyNotoKhmer,
    fontFamilyClassicKhmer,
    'sans-serif',
  ];

  /// Runtime fallback chain. Kantumruy Pro is bundled (works offline); Noto
  /// Sans Khmer is registered through google_fonts as a secondary fallback.
  static List<String> get fontFallback {
    final noto = _safeGoogleFamily(() => GoogleFonts.notoSansKhmer());
    return [
      fontFamilyKhmer,
      ?noto,
      fontFamilyNotoKhmer,
      fontFamilyClassicKhmer,
      'sans-serif',
    ];
  }

  // ---------------------------------------------------------------------------
  // Type scale (logical pixels)
  // ---------------------------------------------------------------------------
  static const double sizeDisplayLarge = 28;
  static const double sizeDisplayMedium = 26;
  static const double sizeDisplaySmall = 24;
  static const double sizeHeadlineLarge = 24;
  static const double sizeHeadlineMedium = 22;
  static const double sizeHeadlineSmall = 20;
  static const double sizeTitleLarge = 18;
  static const double sizeTitleMedium = 16;
  static const double sizeTitleSmall = 14;
  static const double sizeBodyLarge = 15;
  static const double sizeBodyMedium = 14;
  static const double sizeBodySmall = 12;
  static const double sizeLabelLarge = 14;
  static const double sizeLabelMedium = 12;
  static const double sizeLabelSmall = 11;

  // Legacy size aliases (mapped onto the scale above).
  static const double fontSizeXs = sizeLabelSmall;
  static const double fontSizeSm = sizeBodySmall;
  static const double fontSizeMd = sizeBodyMedium;
  static const double fontSizeLg = sizeTitleMedium;
  static const double fontSizeXl = sizeTitleLarge;
  static const double fontSize2xl = sizeHeadlineMedium;
  static const double fontSizeDisplay = sizeDisplayLarge;

  // Line heights & tracking
  static const double lineHeightHeading = 1.3;
  static const double lineHeightBody = 1.5;
  static const double lineHeightTight = 1.3;
  static const double letterSpacingHeading = -0.2;

  // Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Text scaling limits (applied globally in main.dart)
  static const double minTextScale = 0.9;
  static const double maxTextScale = 1.2;

  // ---------------------------------------------------------------------------
  // Readable text colors (WCAG AA >= 4.5:1)
  // ---------------------------------------------------------------------------
  /// Titles / primary text on light & glass-light surfaces (14.7:1 on white).
  static const Color textPrimaryLight = Color(0xFF1F2937);

  /// Secondary text on light & glass-light surfaces (4.8:1 on white).
  static const Color textSecondaryLight = Color(0xFF6B7280);

  /// Primary text on dark surfaces.
  static const Color textPrimaryDark = Color(0xFFF3F6F4);

  /// Secondary text on dark surfaces (>= 7:1 on #0F172A).
  static const Color textSecondaryDark = Color(0xFFA5ACA7);

  static Color primaryTextColor(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color secondaryTextColor(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  // ---------------------------------------------------------------------------
  // Theme integration
  // ---------------------------------------------------------------------------

  /// Builds the app-wide [TextTheme] wired into `ThemeData.textTheme`.
  static TextTheme textTheme(Brightness brightness, {Locale? locale}) {
    final isKhmer = locale?.languageCode == 'km';
    final primary = primaryTextColor(brightness);
    final secondary = secondaryTextColor(brightness);
    final fallback = fontFallback;

    TextStyle heading(double size, FontWeight weight) => _style(
      heading: true,
      isKhmer: isKhmer,
      fallback: fallback,
      fontSize: size,
      fontWeight: weight,
      color: primary,
    );

    TextStyle body(double size, FontWeight weight, Color color) => _style(
      heading: false,
      isKhmer: isKhmer,
      fallback: fallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

    return TextTheme(
      displayLarge: heading(sizeDisplayLarge, fontWeightBold),
      displayMedium: heading(sizeDisplayMedium, fontWeightBold),
      displaySmall: heading(sizeDisplaySmall, fontWeightBold),
      headlineLarge: heading(sizeHeadlineLarge, fontWeightBold),
      headlineMedium: heading(sizeHeadlineMedium, fontWeightBold),
      headlineSmall: heading(sizeHeadlineSmall, fontWeightBold),
      titleLarge: heading(sizeTitleLarge, fontWeightSemibold),
      titleMedium: heading(sizeTitleMedium, fontWeightSemibold),
      titleSmall: heading(sizeTitleSmall, fontWeightSemibold),
      bodyLarge: body(sizeBodyLarge, fontWeightRegular, primary),
      bodyMedium: body(sizeBodyMedium, fontWeightRegular, primary),
      bodySmall: body(sizeBodySmall, fontWeightRegular, secondary),
      labelLarge: body(sizeLabelLarge, fontWeightSemibold, primary),
      labelMedium: body(sizeLabelMedium, fontWeightSemibold, primary),
      labelSmall: body(sizeLabelSmall, fontWeightMedium, secondary),
    );
  }

  static TextStyle _style({
    required bool heading,
    required bool isKhmer,
    required List<String> fallback,
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final effectiveHeight =
        height ?? (heading ? lineHeightHeading : lineHeightBody);
    // Khmer script must never use negative tracking.
    final effectiveSpacing = isKhmer
        ? 0.0
        : (letterSpacing ?? (heading ? letterSpacingHeading : 0.0));

    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: effectiveHeight,
      letterSpacing: effectiveSpacing,
    );

    if (isKhmer) {
      return base.copyWith(
        fontFamily: fontFamilyKhmer,
        fontFamilyFallback: fallback,
      );
    }

    final googleStyle = _safeGoogleStyle(
      () => heading
          ? GoogleFonts.plusJakartaSans(textStyle: base)
          : GoogleFonts.inter(textStyle: base),
    );
    return (googleStyle ??
            base.copyWith(
              fontFamily: heading ? fontFamilyHeading : fontFamilyBody,
            ))
        .copyWith(fontFamilyFallback: fallback);
  }

  static TextStyle? _safeGoogleStyle(TextStyle Function() build) {
    if (!GoogleFonts.config.allowRuntimeFetching) return null;
    try {
      return build();
    } catch (_) {
      return null;
    }
  }

  static String? _safeGoogleFamily(TextStyle Function() build) =>
      _safeGoogleStyle(build)?.fontFamily;

  // ---------------------------------------------------------------------------
  // Legacy static helpers (prefer Theme.of(context).textTheme in new code)
  // ---------------------------------------------------------------------------

  /// Returns a locale-aware style on the shared scale. Khmer text never gets
  /// negative letter-spacing.
  static TextStyle getStyle({
    required double fontSize,
    FontWeight fontWeight = fontWeightRegular,
    Color? color,
    double? height,
    double? letterSpacing,
    bool isKhmer = false,
  }) {
    return _style(
      heading: fontSize >= sizeTitleMedium,
      isKhmer: isKhmer,
      fallback: fontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle headlineLarge({
    Color? color,
    FontWeight fontWeight = fontWeightBold,
  }) => getStyle(
    fontSize: sizeDisplayLarge,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle titleLarge({
    Color? color,
    FontWeight fontWeight = fontWeightSemibold,
  }) =>
      getStyle(fontSize: sizeTitleLarge, fontWeight: fontWeight, color: color);

  static TextStyle titleMedium({
    Color? color,
    FontWeight fontWeight = fontWeightSemibold,
  }) =>
      getStyle(fontSize: sizeTitleMedium, fontWeight: fontWeight, color: color);

  static TextStyle titleSmall({
    Color? color,
    FontWeight fontWeight = fontWeightSemibold,
  }) => _style(
    heading: true,
    isKhmer: false,
    fallback: fontFallback,
    fontSize: sizeTitleSmall,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle bodyLarge({
    Color? color,
    FontWeight fontWeight = fontWeightRegular,
  }) => _body(sizeBodyLarge, fontWeight, color);

  static TextStyle bodyMedium({
    Color? color,
    FontWeight fontWeight = fontWeightRegular,
  }) => _body(sizeBodyMedium, fontWeight, color);

  static TextStyle bodySmall({
    Color? color,
    FontWeight fontWeight = fontWeightRegular,
  }) => _body(sizeBodySmall, fontWeight, color);

  static TextStyle labelLarge({
    Color? color,
    FontWeight fontWeight = fontWeightSemibold,
  }) => _body(sizeLabelLarge, fontWeight, color);

  static TextStyle labelMedium({
    Color? color,
    FontWeight fontWeight = fontWeightSemibold,
  }) => _body(sizeLabelMedium, fontWeight, color);

  static TextStyle labelSmall({
    Color? color,
    FontWeight fontWeight = fontWeightMedium,
  }) => _body(sizeLabelSmall, fontWeight, color);

  static TextStyle caption({
    Color? color,
    FontWeight fontWeight = fontWeightRegular,
  }) => _body(sizeLabelSmall, fontWeight, color);

  static TextStyle _body(double size, FontWeight weight, Color? color) =>
      _style(
        heading: false,
        isKhmer: false,
        fallback: fontFallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}

/// Shortcut: `context.textTheme.titleMedium`.
extension AppTextThemeContext on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
