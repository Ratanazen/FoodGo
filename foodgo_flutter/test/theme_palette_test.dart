import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/app/theme/app_theme.dart';
import 'package:foodgo_flutter/core/theme/app_palette.dart';
import 'package:foodgo_flutter/core/theme/glass_theme.dart';
import 'package:foodgo_flutter/core/theme/theme_styles.dart';
import 'package:foodgo_flutter/features/settings/presentation/theme_center_screen.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/widgets/snowfall_effect.dart';
import 'package:foodgo_flutter/widgets/glass/themed_skin_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Theme & Color Palette Tests', () {
    test(
      'PaletteData defines 29 complete brand, cultural, and seasonal palettes',
      () {
        expect(PaletteData.allPalettes.length, 29);

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
          expect(palette.backdropStyle, isNotNull);
          expect(palette.backdropNameEn.isNotEmpty, isTrue);
          expect(palette.backdropNameKh.isNotEmpty, isTrue);
        }

        // Verify festive count vs non-festive count
        final festive = PaletteData.allPalettes
            .where((p) => p.isFestive)
            .toList();
        final nonFestive = PaletteData.allPalettes
            .where((p) => !p.isFestive)
            .toList();
        expect(festive.length, 15);
        expect(nonFestive.length, 14);
      },
    );

    test(
      'PaletteData fromId and fromString serialization for all 9 themes',
      () {
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
        expect(
          PaletteData.fromString('smaltBlue').id,
          AppColorPalette.smaltBlue,
        );
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
        expect(PaletteData.fromString('pchumBen').id, AppColorPalette.pchumBen);
        expect(
          PaletteData.fromString('angkorHeritage').id,
          AppColorPalette.angkorHeritage,
        );
        expect(
          PaletteData.fromString('unknown').id,
          AppColorPalette.modernFoodGo,
        );
      },
    );

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
        expect(xmasDark.scaffoldBackgroundColor, const Color(0xFF0C1410));

        final waterDark = AppTheme.getDarkTheme(AppColorPalette.waterFestival);
        expect(waterDark.colorScheme.primary, const Color(0xFF0284C7));
        expect(waterDark.scaffoldBackgroundColor, const Color(0xFF081524));

        final pchumDark = AppTheme.getDarkTheme(AppColorPalette.pchumBen);
        expect(pchumDark.colorScheme.primary, const Color(0xFFD946EF));
        expect(pchumDark.scaffoldBackgroundColor, const Color(0xFF180E1C));

        final angkorDark = AppTheme.getDarkTheme(
          AppColorPalette.angkorHeritage,
        );
        expect(angkorDark.colorScheme.primary, const Color(0xFFEA580C));
        expect(angkorDark.scaffoldBackgroundColor, const Color(0xFF17110E));
      },
    );

    test(
      'ThemeProvider manages and notifies on festive palette changes',
      () async {
        final provider = ThemeProvider();
        expect(provider.currentPalette, AppColorPalette.modernFoodGo);
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
      },
    );

    test(
      'ThemeStyles provides greetings, subtitles, and dynamic styling helpers',
      () {
        final kny = PaletteData.fromId(AppColorPalette.khmerNewYear);
        expect(
          ThemeStyles.getFestivalGreeting(kny),
          contains('សួស្តីឆ្នាំថ្មី'),
        );
        expect(
          ThemeStyles.getFestivalSubtitleKh(kny),
          contains('ទេវតាឆ្នាំថ្មី'),
        );

        final xmas = PaletteData.fromId(AppColorPalette.christmas);
        expect(
          ThemeStyles.getFestivalGreeting(xmas),
          contains('Merry Christmas'),
        );

        final water = PaletteData.fromId(AppColorPalette.waterFestival);
        expect(
          ThemeStyles.getFestivalGreeting(water),
          contains('ព្រះរាជពិធីបុណ្យអុំទូក'),
        );

        final pchum = PaletteData.fromId(AppColorPalette.pchumBen);
        expect(
          ThemeStyles.getFestivalGreeting(pchum),
          contains('ពិធីបុណ្យភ្ជុំបិណ្ឌ'),
        );

        final angkor = PaletteData.fromId(AppColorPalette.angkorHeritage);
        expect(
          ThemeStyles.getFestivalGreeting(angkor),
          contains('Angkor Heritage'),
        );
      },
    );

    testWidgets('FestivalThemeBanner renders active theme greeting and badge', (
      tester,
    ) async {
      GlassTheme.setActivePalette(AppColorPalette.khmerNewYear);

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FestivalThemeBanner(onTap: () => tapped = true)),
        ),
      );

      expect(find.textContaining('សួស្តីឆ្នាំថ្មី'), findsOneWidget);
      expect(find.text('ចូលឆ្នាំខ្មែរ'), findsOneWidget);

      await tester.tap(find.byType(FestivalThemeBanner));
      expect(tapped, isTrue);
    });

    test('PaletteData supports 7 new modern and cultural palettes', () {
      expect(
        PaletteData.fromId(AppColorPalette.khmerHeritage).nameEn,
        contains('Khmer Heritage'),
      );
      expect(
        PaletteData.fromId(AppColorPalette.modernFoodGo).nameEn,
        contains('Modern FoodGo'),
      );
      expect(
        PaletteData.fromId(AppColorPalette.darkPremium).nameEn,
        contains('Dark Premium'),
      );
      expect(
        PaletteData.fromId(AppColorPalette.softMinimal).nameEn,
        contains('Soft Minimal'),
      );
      expect(
        PaletteData.fromId(AppColorPalette.songkranNewYear).nameEn,
        contains('Songkran'),
      );
      expect(
        PaletteData.fromId(AppColorPalette.monochrome).nameEn,
        contains('Monochrome'),
      );
      expect(
        PaletteData.fromId(AppColorPalette.highContrast).nameEn,
        contains('High Contrast'),
      );

      expect(
        PaletteData.fromString('khmerHeritage').id,
        AppColorPalette.khmerHeritage,
      );
      expect(
        PaletteData.fromString('modernFoodGo').id,
        AppColorPalette.modernFoodGo,
      );
      expect(
        PaletteData.fromString('darkPremium').id,
        AppColorPalette.darkPremium,
      );
      expect(
        PaletteData.fromString('softMinimal').id,
        AppColorPalette.softMinimal,
      );
      expect(
        PaletteData.fromString('songkranNewYear').id,
        AppColorPalette.songkranNewYear,
      );
      expect(
        PaletteData.fromString('monochrome').id,
        AppColorPalette.monochrome,
      );
      expect(
        PaletteData.fromString('highContrast').id,
        AppColorPalette.highContrast,
      );
    });

    test(
      'All 18 Advanced Seasonal & Cultural Themes exist and serialize properly',
      () {
        final requiredThemes = [
          AppColorPalette.christmasWonderland,
          AppColorPalette.newYearCelebration,
          AppColorPalette.halloweenNight,
          AppColorPalette.valentinesDay,
          AppColorPalette.easterSpring,
          AppColorPalette.summerTropical,
          AppColorPalette.lunarNewYear,
          AppColorPalette.blackFridayCyber,
          AppColorPalette.ramadanEid,
          AppColorPalette.khmerNewYear,
          AppColorPalette.pchumBen,
          AppColorPalette.waterFestival,
          AppColorPalette.monochrome,
          AppColorPalette.natureOrganic,
          AppColorPalette.glassmorphism,
          AppColorPalette.minimalPremium,
          AppColorPalette.retroPop,
          AppColorPalette.neonNight,
        ];

        expect(requiredThemes.length, 18);

        for (final id in requiredThemes) {
          final palette = PaletteData.fromId(id);
          expect(palette.nameEn.isNotEmpty, isTrue);
          expect(palette.nameKh.isNotEmpty, isTrue);
          expect(palette.descriptionEn.isNotEmpty, isTrue);
          expect(palette.descriptionKh.isNotEmpty, isTrue);
          expect(palette.primary, isNotNull);
          expect(palette.headerGradient.colors.length, 3);

          // Serialization roundtrip
          final fromStr = PaletteData.fromString(id.name);
          expect(fromStr.id, id);
        }
      },
    );

    test(
      'PaletteData.isSeasonallyActiveAt correctly computes calendar schedules',
      () {
        final xmas = PaletteData.fromId(AppColorPalette.christmasWonderland);
        expect(xmas.isSeasonallyActiveAt(DateTime(2026, 12, 25)), isTrue);
        expect(xmas.isSeasonallyActiveAt(DateTime(2026, 6, 15)), isFalse);

        final newYear = PaletteData.fromId(AppColorPalette.newYearCelebration);
        expect(newYear.isSeasonallyActiveAt(DateTime(2026, 12, 31)), isTrue);
        expect(newYear.isSeasonallyActiveAt(DateTime(2027, 1, 1)), isTrue);
        expect(newYear.isSeasonallyActiveAt(DateTime(2026, 8, 1)), isFalse);

        final halloween = PaletteData.fromId(AppColorPalette.halloweenNight);
        expect(halloween.isSeasonallyActiveAt(DateTime(2026, 10, 31)), isTrue);
        expect(halloween.isSeasonallyActiveAt(DateTime(2026, 11, 1)), isFalse);

        final valentines = PaletteData.fromId(AppColorPalette.valentinesDay);
        expect(valentines.isSeasonallyActiveAt(DateTime(2026, 2, 14)), isTrue);
        expect(valentines.isSeasonallyActiveAt(DateTime(2026, 3, 1)), isFalse);

        final kny = PaletteData.fromId(AppColorPalette.khmerNewYear);
        expect(kny.isSeasonallyActiveAt(DateTime(2026, 4, 14)), isTrue);
        expect(kny.isSeasonallyActiveAt(DateTime(2026, 5, 1)), isFalse);
      },
    );

    testWidgets(
      'SnowfallEffect renders canvas only when Christmas is active and enabled',
      (tester) async {
        final provider = ThemeProvider();
        provider.setPalette(AppColorPalette.christmasWonderland);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: const MaterialApp(home: Scaffold(body: SnowfallEffect())),
          ),
        );

        await tester.pump();
        final snowPainter = find.descendant(
          of: find.byType(SnowfallEffect),
          matching: find.byType(CustomPaint),
        );
        expect(snowPainter, findsOneWidget);

        // Disable snowfall
        provider.setSnowfallEnabled(false);
        await tester.pump();
        expect(snowPainter, findsNothing);

        // Re-enable but enable reducedMotion
        provider.setSnowfallEnabled(true);
        provider.setReducedMotion(true);
        await tester.pump();
        expect(snowPainter, findsNothing);

        // Reset reducedMotion, switch to another theme e.g. Modern FoodGo
        provider.setReducedMotion(false);
        provider.setPalette(AppColorPalette.modernFoodGo);
        await tester.pump();
        expect(snowPainter, findsNothing);
      },
    );

    test(
      'ThemeProvider supports setThemeMode, seasonal toggle, snowfall toggle, and resetToDefaults',
      () {
        final provider = ThemeProvider();

        provider.setThemeMode(ThemeMode.light);
        expect(provider.themeMode, ThemeMode.light);
        expect(provider.isDarkMode, isFalse);

        provider.setThemeMode(ThemeMode.dark);
        expect(provider.themeMode, ThemeMode.dark);
        expect(provider.isDarkMode, isTrue);

        provider.setSeasonalDecorationsEnabled(false);
        expect(provider.seasonalDecorationsEnabled, isFalse);

        provider.setReducedMotion(true);
        expect(provider.reducedMotion, isTrue);

        provider.setSnowfallEnabled(false);
        expect(provider.snowfallEnabled, isFalse);

        provider.resetToDefaults();
        expect(provider.themeMode, ThemeMode.system);
        expect(provider.currentPalette, AppColorPalette.modernFoodGo);
        expect(provider.seasonalDecorationsEnabled, isTrue);
        expect(provider.reducedMotion, isFalse);
        expect(provider.snowfallEnabled, isTrue);
      },
    );

    test('Every palette exposes an AA-contrast onPrimary colour', () {
      for (final palette in PaletteData.allPalettes) {
        final ratio = PaletteData.contrastRatio(
          palette.primary,
          palette.onPrimary,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${palette.nameEn} primary/onPrimary contrast is '
              '${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    testWidgets('SnowfallEffect respects platform reduced-motion settings', (
      tester,
    ) async {
      final provider = ThemeProvider();
      provider.setPalette(AppColorPalette.christmasWonderland);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const Scaffold(body: SnowfallEffect()),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(SnowfallEffect),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    test(
      'Restores palette, mode and motion preferences from storage',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_color_palette': 'highContrast',
          'theme_mode': 'dark',
          'seasonal_decorations_enabled': false,
          'reduced_motion': true,
          'snowfall_enabled': false,
        });

        final provider = ThemeProvider();
        await pumpEventQueue();

        expect(provider.currentPalette, AppColorPalette.highContrast);
        expect(provider.themeMode, ThemeMode.dark);
        expect(provider.seasonalDecorationsEnabled, isFalse);
        expect(provider.reducedMotion, isTrue);
        expect(provider.snowfallEnabled, isFalse);
      },
    );

    testWidgets('ThemeCenterScreen fits a narrow 320px phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const MaterialApp(home: ThemeCenterScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Theme Center'), findsOneWidget);
    });

    testWidgets(
      'ThemeCenterScreen renders title, live preview, appearance modes, and theme gallery',
      (tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: const MaterialApp(home: ThemeCenterScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Theme Center'), findsOneWidget);
        expect(find.text('មជ្ឈមណ្ឌលរចនាបថ និងរូបរាង'), findsOneWidget);
        expect(find.text('Appearance Mode'), findsOneWidget);
        expect(find.text('System'), findsOneWidget);
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('Theme & Cultural Palettes'), findsOneWidget);

        // Verify some of the themes render in the list
        expect(find.text('Khmer New Year (Sangkran)'), findsOneWidget);
        expect(find.text('Modern FoodGo'), findsOneWidget);
      },
    );

    testWidgets(
      'ThemedSkinBackdrop renders custom backdrop painters across styles',
      (tester) async {
        final stylesToTest = [
          PaletteData.modernFoodGo,
          PaletteData.blackFridayCyber,
          PaletteData.angkorHeritage,
          PaletteData.darkGold,
          PaletteData.waterFestival,
          PaletteData.pchumBen,
        ];

        for (final pal in stylesToTest) {
          await tester.pumpWidget(
            MaterialApp(
              home: ThemedSkinBackdrop(
                customPalette: pal,
                child: const Text('Backdrop Content'),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('Backdrop Content'), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);
        }
      },
    );
  });
}
