import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'glass_theme.dart';
import 'theme_styles.dart';

/// Extension on [BuildContext] providing clean, reactive shortcuts to the active
/// brand color palette, Material 3 colorScheme, and glassmorphic styling tokens.
extension ThemeContextExtensions on BuildContext {
  /// The current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// The active [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The active brand primary color from [ColorScheme.primary].
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// The active palette primary dark color for gradients and shadows.
  Color get primaryDark => GlassTheme.activePalette.primaryDark;

  /// The active palette accent color for highlights, badges, and glows.
  Color get accentColor => GlassTheme.activePalette.primaryAccent;

  /// The active palette surface dark color.
  Color get surfaceDark => GlassTheme.activePalette.surfaceDark;

  /// The active palette border color.
  Color get borderDark => GlassTheme.activePalette.borderDark;

  /// The complete [PaletteData] currently selected by the user.
  PaletteData get palette => GlassTheme.activePalette;

  /// The brand header gradient for hero sections and app bars.
  LinearGradient get headerGradient => GlassTheme.activePalette.headerGradient;

  /// The ambient aura color for liquid glass background lighting.
  Color get auraColor => GlassTheme.activePalette.auraColor;

  /// Whether the current theme brightness is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Whether the active theme is a seasonal / cultural festival theme.
  bool get isFestive => GlassTheme.activePalette.isFestive;

  /// Festival greeting message for the active theme.
  String get festivalGreeting =>
      ThemeStyles.getFestivalGreeting(GlassTheme.activePalette);

  /// Festival subtitle / blessing in Khmer script.
  String get festivalSubtitleKh =>
      ThemeStyles.getFestivalSubtitleKh(GlassTheme.activePalette);

  /// Active theme badge text (e.g. 'ចូលឆ្នាំខ្មែរ', 'CHRISTMAS', 'បុណ្យអុំទូក').
  String get festivalBadge => GlassTheme.activePalette.badgeText;

  /// Active theme icon.
  IconData get festivalIcon => GlassTheme.activePalette.icon;

  /// Dynamic themed card decoration.
  BoxDecoration themedCardDecoration({
    bool isGlass = true,
    double borderRadius = 20,
    double borderWidth = 1.2,
    bool glow = false,
  }) => ThemeStyles.cardDecoration(
    this,
    isGlass: isGlass,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    glow: glow,
  );

  /// Dynamic themed pill badge decoration.
  BoxDecoration themedPillBadgeDecoration({
    Color? customColor,
    double radius = 12,
  }) => ThemeStyles.pillBadgeDecoration(
    this,
    customColor: customColor,
    radius: radius,
  );

  /// Dynamic themed primary button style.
  ButtonStyle themedPrimaryButtonStyle({
    double radius = 16,
    EdgeInsetsGeometry? padding,
  }) => ThemeStyles.primaryButtonStyle(this, radius: radius, padding: padding);
}
