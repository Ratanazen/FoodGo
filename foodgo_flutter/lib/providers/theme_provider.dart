import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/glass_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppColorPalette _palette = AppColorPalette.orangeCoral;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppColorPalette get currentPalette => _palette;
  PaletteData get paletteData => PaletteData.fromId(_palette);

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', _themeMode.toString());
  }

  void setPalette(AppColorPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    GlassTheme.setActivePalette(palette);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('app_color_palette', palette.name);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme');
    final savedPalette = prefs.getString('app_color_palette');

    if (savedTheme != null) {
      _themeMode = savedTheme == ThemeMode.light.toString()
          ? ThemeMode.light
          : ThemeMode.dark;
    }

    if (savedPalette != null) {
      _palette = PaletteData.fromString(savedPalette).id;
      GlassTheme.setActivePalette(_palette);
    } else {
      GlassTheme.setActivePalette(_palette);
    }

    notifyListeners();
  }
}
