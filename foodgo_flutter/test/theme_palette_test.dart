import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/app/theme/app_theme.dart';
import 'package:foodgo_flutter/core/theme/app_palette.dart';
import 'package:foodgo_flutter/core/theme/glass_theme.dart';
import 'package:foodgo_flutter/core/theme/theme_styles.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Theme & Color Palette Tests', () {
    test('PaletteData defines 9 complete brand and festival color palettes', () {
      expect(PaletteData.allPalettes.length, 9);

      for (final palette in PaletteData.allPalettes) {
        expect(palette.nameEn.isNotEmpty, isTrue);
        expect(palette.nameKh.isNotEmpty, isTrue);
        expect(palette.headerGradient.colors.length, 3);
        expect(palette.primary, isNotNull);
        expect(palette.primaryDark, isNotNull);
        expect(palette.backgroundLight, isNotNull);
        expect(palette.backgroundDark, isNotNull);
        expect(palette.icon, isNotNull);
        expect(palette.categoryEn.isNotEmpty, isTrue);
        expect(palette.categoryKh.isNotEmpty, isTrue);
      }

      // Verify festive count vs signature count
      final festive = PaletteData.allPalettes.where((p) => p.isFestive).toList();
      final signature = PaletteData.allPalettes.where((p) => !p.isFestive).toList();
      expect(festive.length, 5); // Khmer New Year, Christmas, Water Festival, Pchum Ben, Angkor
      expect(signature.length, 4); // Organic Green, Warm Coral, Smalt Blue, Dark Gold
    });

    test('PaletteData fromId and fromString serialization for all 9 themes', () {
      // Signature themes
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

      // Khmer & Seasonal Festival themes
      expect(
        PaletteData.fromId(AppColorPalette.khmerNewYear).id,
        AppColorPalette.khmerNewYear,
      );
      expect(
        PaletteData.fromId(AppColorPalette.christmas).id,
        AppColorPalette.christmas,
      );
      expect(
        PaletteData.fromId(AppColorPalette.waterFestival).id,
        AppColorPalette.waterFestival,
      );
      expect(
        PaletteData.fromId(AppColorPalette.pchumBen).id,
        AppColorPalette.pchumBen,
      );
      expect(
        PaletteData.fromId(AppColorPalette.angkorHeritage).id,
        AppColorPalette.angkorHeritage,
      );

      // String lookups
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
      expect(
        PaletteData.fromString('khmerNewYear').id,
        AppColorPalette.khmerNewYear,
      );
      expect(
        PaletteData.fromString('christmas').id,
        AppColorPalette.christmas,
      );
      expect(
        PaletteData.fromString('waterFestival').id,
        AppColorPalette.waterFestival,
      );
      expect(
        PaletteData.fromString('pchumBen').id,
        AppColorPalette.pchumBen,
      );
      expect(
        PaletteData.fromString('angkorHeritage').id,
        AppColorPalette.angkorHeritage,
      );
      expect(
        PaletteData.fromString('unknown').id,
        AppColorPalette.emeraldGreen,
      );
    });

    test('GlassTheme responds to setActivePalette for festive themes', () {
      GlassTheme.setActivePalette(AppColorPalette.khmerNewYear);
      expect(GlassTheme.activePalette.primary, const Color(0xFFE5A910));
      expect(GlassTheme.activePalette.primaryDark, const Color(0xFFB87A04));
      expect(GlassTheme.activePalette.badgeText, 'ចូលឆ្នាំខ្មែរ');

      GlassTheme.setActivePalette(AppColorPalette.christmas);
      expect(GlassTheme.activePalette.primary, const Color(0xFFDC2626));
      expect(GlassTheme.activePalette.badgeText, 'CHRISTMAS');

      GlassTheme.setActivePalette(AppColorPalette.waterFestival);
      expect(GlassTheme.activePalette.primary, const Color(0xFF0284C7));
      expect(GlassTheme.activePalette.badgeText, 'បុណ្យអុំទូក');

      GlassTheme.setActivePalette(AppColorPalette.pchumBen);
      expect(GlassTheme.activePalette.primary, const Color(0xFFD946EF));
      expect(GlassTheme.activePalette.badgeText, 'ភ្ជុំបិណ្ឌ');

      GlassTheme.setActivePalette(AppColorPalette.angkorHeritage);
      expect(GlassTheme.activePalette.primary, const Color(0xFFEA580C));
      expect(GlassTheme.activePalette.badgeText, 'អង្គរវត្ត');
    });

    testWidgets(
      'AppTheme.getLightTheme and getDarkTheme generate correct ThemeData for festival palettes',
      (tester) async {
        final knyLight = AppTheme.getLightTheme(AppColorPalette.khmerNewYear);
        expect(knyLight.colorScheme.primary, const Color(0xFFE5A910));
        expect(knyLight.useMaterial3, isTrue);

        final xmasDark = AppTheme.getDarkTheme(AppColorPalette.christmas);
        expect(xmasDark.colorScheme.primary, const Color(0xFFDC2626));
        expect(xmasDark.scaffoldBackgroundColor, const Color(0xFF0F1712));

        final waterDark = AppTheme.getDarkTheme(AppColorPalette.waterFestival);
        expect(waterDark.colorScheme.primary, const Color(0xFF0284C7));
        expect(waterDark.scaffoldBackgroundColor, const Color(0xFF081524));

        final pchumDark = AppTheme.getDarkTheme(AppColorPalette.pchumBen);
        expect(pchumDark.colorScheme.primary, const Color(0xFFD946EF));
        expect(pchumDark.scaffoldBackgroundColor, const Color(0xFF180E1C));

        final angkorDark = AppTheme.getDarkTheme(AppColorPalette.angkorHeritage);
        expect(angkorDark.colorScheme.primary, const Color(0xFFEA580C));
        expect(angkorDark.scaffoldBackgroundColor, const Color(0xFF17110E));
      },
    );

    test('ThemeProvider manages and notifies on festive palette changes', () async {
      final provider = ThemeProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPalette(AppColorPalette.khmerNewYear);
      expect(provider.currentPalette, AppColorPalette.khmerNewYear);
      expect(provider.paletteData.primary, const Color(0xFFE5A910));
      expect(provider.paletteData.nameEn, 'Khmer New Year (Sangkran)');
      expect(notified, isTrue);

      notified = false;
      provider.setPalette(AppColorPalette.christmas);
      expect(provider.currentPalette, AppColorPalette.christmas);
      expect(provider.paletteData.primary, const Color(0xFFDC2626));
      expect(notified, isTrue);
    });

    test('ThemeStyles provides greetings, subtitles, and dynamic styling helpers', () {
      final kny = PaletteData.fromId(AppColorPalette.khmerNewYear);
      expect(ThemeStyles.getFestivalGreeting(kny), contains('សួស្តីឆ្នាំថ្មី'));
      expect(ThemeStyles.getFestivalSubtitleKh(kny), contains('ទេវតាឆ្នាំថ្មី'));

      final xmas = PaletteData.fromId(AppColorPalette.christmas);
      expect(ThemeStyles.getFestivalGreeting(xmas), contains('Merry Christmas'));

      final water = PaletteData.fromId(AppColorPalette.waterFestival);
      expect(ThemeStyles.getFestivalGreeting(water), contains('ព្រះរាជពិធីបុណ្យអុំទូក'));

      final pchum = PaletteData.fromId(AppColorPalette.pchumBen);
      expect(ThemeStyles.getFestivalGreeting(pchum), contains('ពិធីបុណ្យភ្ជុំបិណ្ឌ'));

      final angkor = PaletteData.fromId(AppColorPalette.angkorHeritage);
      expect(ThemeStyles.getFestivalGreeting(angkor), contains('Angkor Heritage'));
    });

    testWidgets('FestivalThemeBanner renders active theme greeting and badge', (tester) async {
      GlassTheme.setActivePalette(AppColorPalette.khmerNewYear);

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FestivalThemeBanner(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('សួស្តីឆ្នាំថ្មី'), findsOneWidget);
      expect(find.text('ចូលឆ្នាំខ្មែរ'), findsOneWidget);

      await tester.tap(find.byType(FestivalThemeBanner));
      expect(tapped, isTrue);
    });
  });
}

