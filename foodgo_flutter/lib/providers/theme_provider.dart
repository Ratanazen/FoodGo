import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/glass_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppColorPalette _palette = AppColorPalette.emeraldGreen;
  bool _seasonalDecorationsEnabled = true;
  bool _reducedMotion = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppColorPalette get currentPalette => _palette;
  PaletteData get paletteData => PaletteData.fromId(_palette);
  bool get seasonalDecorationsEnabled => _seasonalDecorationsEnabled;
  bool get reducedMotion => _reducedMotion;

  ThemeProvider() {
    _loadTheme();
  }

  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.name);
      await prefs.setString('theme', mode.toString());
    } catch (_) {}
  }

  void toggleTheme() async {
    final nextMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    setThemeMode(nextMode);
  }

  void setPalette(AppColorPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    GlassTheme.setActivePalette(palette);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_color_palette', palette.name);
    } catch (_) {}
  }

  void setSeasonalDecorationsEnabled(bool enabled) async {
    if (_seasonalDecorationsEnabled == enabled) return;
    _seasonalDecorationsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seasonal_decorations_enabled', enabled);
    } catch (_) {}
  }

  void setReducedMotion(bool enabled) async {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reduced_motion', enabled);
    } catch (_) {}
  }

  void resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _palette = AppColorPalette.modernFoodGo;
    _seasonalDecorationsEnabled = true;
    _reducedMotion = false;
    GlassTheme.setActivePalette(_palette);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', ThemeMode.system.name);
      await prefs.setString('theme', ThemeMode.system.toString());
      await prefs.setString('app_color_palette', AppColorPalette.modernFoodGo.name);
      await prefs.setBool('seasonal_decorations_enabled', true);
      await prefs.setBool('reduced_motion', false);
    } catch (_) {}
  }

  void _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString('theme_mode');
      final legacyTheme = prefs.getString('theme');
      final savedPalette = prefs.getString('app_color_palette');
      final savedSeasonal = prefs.getBool('seasonal_decorations_enabled');
      final savedMotion = prefs.getBool('reduced_motion');

      if (savedThemeMode != null) {
        if (savedThemeMode == ThemeMode.light.name) {
          _themeMode = ThemeMode.light;
        } else if (savedThemeMode == ThemeMode.dark.name) {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
      } else if (legacyTheme != null) {
        if (legacyTheme == ThemeMode.light.toString()) {
          _themeMode = ThemeMode.light;
        } else if (legacyTheme == ThemeMode.dark.toString()) {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
      }

      if (savedPalette != null) {
        _palette = PaletteData.fromString(savedPalette).id;
      }
      GlassTheme.setActivePalette(_palette);

      if (savedSeasonal != null) {
        _seasonalDecorationsEnabled = savedSeasonal;
      }
      if (savedMotion != null) {
        _reducedMotion = savedMotion;
      }
    } catch (_) {
      GlassTheme.setActivePalette(_palette);
    }

    notifyListeners();
  }
}
