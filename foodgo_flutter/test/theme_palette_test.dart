import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/app/theme/app_theme.dart';
import 'package:foodgo_flutter/core/theme/app_palette.dart';
import 'package:foodgo_flutter/core/theme/glass_theme.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Theme & Color Palette Tests', () {
    test('PaletteData defines 4 complete brand color palettes', () {
      expect(PaletteData.allPalettes.length, 4);

      for (final palette in PaletteData.allPalettes) {
        expect(palette.nameEn.isNotEmpty, isTrue);
        expect(palette.nameKh.isNotEmpty, isTrue);
        expect(palette.headerGradient.colors.length, 3);
        expect(palette.primary, isNotNull);
        expect(palette.primaryDark, isNotNull);
        expect(palette.backgroundLight, isNotNull);
        expect(palette.backgroundDark, isNotNull);
      }
    });

    test('PaletteData fromId and fromString serialization', () {
      expect(
        PaletteData.fromId(AppColorPalette.orangeCoral).id,
        AppColorPalette.orangeCoral,
      );
      expect(
        PaletteData.fromId(AppColorPalette.emeraldGreen).id,
        AppColorPalette.emeraldGreen,
      );
      expect(
        PaletteData.fromId(AppColorPalette.smaltBlue).id,
        AppColorPalette.smaltBlue,
      );
      expect(
        PaletteData.fromId(AppColorPalette.darkGold).id,
        AppColorPalette.darkGold,
      );

      expect(
        PaletteData.fromString('orangeCoral').id,
        AppColorPalette.orangeCoral,
      );
      expect(
        PaletteData.fromString('emeraldGreen').id,
        AppColorPalette.emeraldGreen,
      );
      expect(PaletteData.fromString('smaltBlue').id, AppColorPalette.smaltBlue);
      expect(PaletteData.fromString('darkGold').id, AppColorPalette.darkGold);
      expect(PaletteData.fromString('unknown').id, AppColorPalette.orangeCoral);
    });

    test('GlassTheme responds to setActivePalette', () {
      GlassTheme.setActivePalette(AppColorPalette.emeraldGreen);
      expect(GlassTheme.activePalette.primary, const Color(0xFF00A86B));
      expect(GlassTheme.activePalette.primaryDark, const Color(0xFF007A4D));
      expect(GlassTheme.activePalette.backgroundDark, const Color(0xFF0A1610));

      GlassTheme.setActivePalette(AppColorPalette.darkGold);
      expect(GlassTheme.activePalette.primary, const Color(0xFFD4AF37));
      expect(GlassTheme.activePalette.backgroundDark, const Color(0xFF14120B));

      GlassTheme.setActivePalette(AppColorPalette.orangeCoral);
      expect(GlassTheme.activePalette.primary, const Color(0xFFFF5722));
      expect(GlassTheme.activePalette.backgroundDark, const Color(0xFF16100E));
    });

    testWidgets(
      'AppTheme.getLightTheme and getDarkTheme generate correct ThemeData',
      (tester) async {
        final coralLight = AppTheme.getLightTheme(AppColorPalette.orangeCoral);
        expect(coralLight.colorScheme.primary, const Color(0xFFFF5722));
        expect(coralLight.useMaterial3, isTrue);

        final emeraldDark = AppTheme.getDarkTheme(AppColorPalette.emeraldGreen);
        expect(emeraldDark.colorScheme.primary, const Color(0xFF00A86B));
        expect(emeraldDark.scaffoldBackgroundColor, const Color(0xFF0A1610));

        final goldDark = AppTheme.getDarkTheme(AppColorPalette.darkGold);
        expect(goldDark.colorScheme.primary, const Color(0xFFD4AF37));
        expect(goldDark.scaffoldBackgroundColor, const Color(0xFF14120B));
      },
    );

    test('ThemeProvider manages and notifies on palette changes', () async {
      final provider = ThemeProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPalette(AppColorPalette.emeraldGreen);
      expect(provider.currentPalette, AppColorPalette.emeraldGreen);
      expect(provider.paletteData.primary, const Color(0xFF00A86B));
      expect(notified, isTrue);
    });
  });
}
