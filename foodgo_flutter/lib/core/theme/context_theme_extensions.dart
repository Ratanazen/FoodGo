import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'glass_theme.dart';

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
}
