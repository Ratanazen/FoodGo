import 'package:flutter/material.dart';

enum AppColorPalette {
  orangeCoral,
  emeraldGreen,
  smaltBlue,
  darkGold,
  khmerNewYear,
  christmas,
  waterFestival,
  pchumBen,
  angkorHeritage,
  khmerHeritage,
  modernFoodGo,
  darkPremium,
  softMinimal,
  songkranNewYear,
  monochrome,
  highContrast,
  // 18 Seasonal & Cultural Expansion additions
  christmasWonderland,
  newYearCelebration,
  halloweenNight,
  valentinesDay,
  easterSpring,
  summerTropical,
  lunarNewYear,
  blackFridayCyber,
  ramadanEid,
  natureOrganic,
  glassmorphism,
  minimalPremium,
  retroPop,
  neonNight,
}

enum SkinBackdropStyle {
  liquidMesh,
  warmGlow,
  botanicalAurora,
  oceanicWaves,
  luxuryStardust,
  khmerLattice,
  festivePetals,
  lanternRiver,
  sacredLotus,
  winterConstellation,
  fireworksGlitter,
  mysticFog,
  romanticPetals,
  springMeadow,
  tropicalBreeze,
  orientalClouds,
  cyberGrid,
  celestialCrescent,
  forestCanopy,
  liquidGlassPrism,
  retroMemphis,
  architecturalMinimal,
}

class PaletteData {
  final AppColorPalette id;
  final String nameEn;
  final String nameKh;
  final String descriptionEn;
  final String descriptionKh;

  // Primary brand colors
  final Color primary;
  final Color primaryDark;
  final Color primaryAccent;
  final Color secondary;
  final Color ratingAccent;

  // Backgrounds & Surfaces
  final Color backgroundLight;
  final Color backgroundDark;
  final Color surfaceDark;
  final Color surfaceCardDark;
  final Color cardDark;
  final Color dialogDark;

  // Specular borders & highlights
  final Color borderLight;
  final Color borderDark;
  final LinearGradient liquidGlassBorderDark;
  final LinearGradient headerGradient;

  // Aura & Accents
  final Color auraColor;
  final Color pillCardShadowColor;

  // Cultural & Festive Metadata
  final IconData icon;
  final String categoryEn;
  final String categoryKh;
  final String badgeText;
  final bool isFestive;

  // Themed Skin Backdrop Style
  final SkinBackdropStyle backdropStyle;

  const PaletteData({
    required this.id,
    required this.nameEn,
    required this.nameKh,
    required this.descriptionEn,
    required this.descriptionKh,
    required this.primary,
    required this.primaryDark,
    required this.primaryAccent,
    required this.secondary,
    required this.ratingAccent,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.surfaceDark,
    required this.surfaceCardDark,
    required this.cardDark,
    required this.dialogDark,
    required this.borderLight,
    required this.borderDark,
    required this.liquidGlassBorderDark,
    required this.headerGradient,
    required this.auraColor,
    required this.pillCardShadowColor,
    this.icon = Icons.palette_outlined,
    this.categoryEn = 'Signature Brand',
    this.categoryKh = 'រចនាបថដើម',
    this.badgeText = '',
    this.isFestive = false,
    this.backdropStyle = SkinBackdropStyle.liquidMesh,
  });

  String get backdropNameEn {
    switch (backdropStyle) {
      case SkinBackdropStyle.liquidMesh:
        return 'Liquid Glass Mesh';
      case SkinBackdropStyle.warmGlow:
        return 'Warm Hearth Glow';
      case SkinBackdropStyle.botanicalAurora:
        return 'Botanical Aurora Wave';
      case SkinBackdropStyle.oceanicWaves:
        return 'Oceanic Cobalt Waves';
      case SkinBackdropStyle.luxuryStardust:
        return 'Imperial Gold Stardust';
      case SkinBackdropStyle.khmerLattice:
        return 'Angkor Lotus Lattice';
      case SkinBackdropStyle.festivePetals:
        return 'Jasmine Blossom Petals';
      case SkinBackdropStyle.lanternRiver:
        return 'Tonle Sap Lantern River';
      case SkinBackdropStyle.sacredLotus:
        return 'Sacred Candlelight & Lotus';
      case SkinBackdropStyle.winterConstellation:
        return 'Winter Constellation & Snow';
      case SkinBackdropStyle.fireworksGlitter:
        return 'Midnight Fireworks & Glitter';
      case SkinBackdropStyle.mysticFog:
        return 'Twilight Mist & Mystic Nebula';
      case SkinBackdropStyle.romanticPetals:
        return 'Romantic Rose Blush Nebula';
      case SkinBackdropStyle.springMeadow:
        return 'Sunlit Blossom Meadow';
      case SkinBackdropStyle.tropicalBreeze:
        return 'Turquoise Surf & Palm Shade';
      case SkinBackdropStyle.orientalClouds:
        return 'Auspicious Clouds & Lanterns';
      case SkinBackdropStyle.cyberGrid:
        return 'Cyberpunk Laser Grid';
      case SkinBackdropStyle.celestialCrescent:
        return 'Starlight Crescent & Arabesque';
      case SkinBackdropStyle.forestCanopy:
        return 'Forest Canopy & Sunlight Motes';
      case SkinBackdropStyle.liquidGlassPrism:
        return 'Prismatic Glass Caustics';
      case SkinBackdropStyle.retroMemphis:
        return '80s Memphis Geometric Confetti';
      case SkinBackdropStyle.architecturalMinimal:
        return 'Architectural Studio Dot Grid';
    }
  }

  String get backdropNameKh {
    switch (backdropStyle) {
      case SkinBackdropStyle.liquidMesh:
        return 'ផ្ទៃកញ្ចក់រាវ Liquid Mesh';
      case SkinBackdropStyle.warmGlow:
        return 'ពន្លឺកម្ដៅចង្ក្រានបាយ';
      case SkinBackdropStyle.botanicalAurora:
        return 'រលកពន្លឺធម្មជាតិអូរ៉ូរ៉ា';
      case SkinBackdropStyle.oceanicWaves:
        return 'រលកសមុទ្រខៀវស្រស់';
      case SkinBackdropStyle.luxuryStardust:
        return 'កម្ទេចផ្កាយមាសរាជវង្ស';
      case SkinBackdropStyle.khmerLattice:
        return 'ក្បាច់ផ្កាឈូកអង្គរ';
      case SkinBackdropStyle.festivePetals:
        return 'ផ្កាម្លិះ និងកាំរស្មីសង្ក្រាន្ត';
      case SkinBackdropStyle.lanternRiver:
        return 'គោមបណ្ដែតទឹកទន្លេសាប';
      case SkinBackdropStyle.sacredLotus:
        return 'ពន្លឺទៀន និងផ្កាឈូកពិសិដ្ឋ';
      case SkinBackdropStyle.winterConstellation:
        return 'តារានិកររដូវរងារ និងព្រិល';
      case SkinBackdropStyle.fireworksGlitter:
        return 'កាំជ្រួចអបអរឆ្នាំថ្មី';
      case SkinBackdropStyle.mysticFog:
        return 'អ័ព្ទព្រលប់ និងពពកអាថ៌កំបាំង';
      case SkinBackdropStyle.romanticPetals:
        return 'ផ្កាកុលាបស្នេហាពណ៌ផ្កាឈូក';
      case SkinBackdropStyle.springMeadow:
        return 'វាលផ្ការីកស្រស់បំព្រង';
      case SkinBackdropStyle.tropicalBreeze:
        return 'ខ្យល់សមុទ្រ និងម្លប់ដូង';
      case SkinBackdropStyle.orientalClouds:
        return 'ពពកមង្គល និងគោមក្រហម';
      case SkinBackdropStyle.cyberGrid:
        return 'ក្រឡាចត្រង្គឡាស៊ែរ Cyber';
      case SkinBackdropStyle.celestialCrescent:
        return 'ព្រះចន្ទចរ និងផ្កាយអារ៉ាប់';
      case SkinBackdropStyle.forestCanopy:
        return 'ម្លប់ព្រឹក្សា និងពន្លឺព្រះអាទិត្យ';
      case SkinBackdropStyle.liquidGlassPrism:
        return 'ចំណាំងពន្លឺកញ្ចក់ Prism';
      case SkinBackdropStyle.retroMemphis:
        return 'រចនាបថធរណីមាត្រ Retro 80s';
      case SkinBackdropStyle.architecturalMinimal:
        return 'ក្រឡាចំនុច Architectural Studio';
    }
  }

  /// Check whether this theme is seasonally active on a given date (defaults to today).
  bool isSeasonallyActiveAt([DateTime? date]) {
    final now = date ?? DateTime.now();
    final m = now.month;
    final d = now.day;
    switch (id) {
      case AppColorPalette.christmas:
      case AppColorPalette.christmasWonderland:
        return m == 12;
      case AppColorPalette.newYearCelebration:
        return (m == 12 && d >= 26) || (m == 1 && d <= 7);
      case AppColorPalette.halloweenNight:
        return m == 10;
      case AppColorPalette.valentinesDay:
        return m == 2 && d <= 20;
      case AppColorPalette.easterSpring:
        return m == 3 || m == 4;
      case AppColorPalette.summerTropical:
        return m >= 6 && m <= 8;
      case AppColorPalette.lunarNewYear:
        return (m == 1 && d >= 15) || (m == 2 && d <= 25);
      case AppColorPalette.blackFridayCyber:
        return m == 11 && d >= 15;
      case AppColorPalette.ramadanEid:
        return m == 3 || m == 4;
      case AppColorPalette.khmerNewYear:
      case AppColorPalette.songkranNewYear:
        return m == 4;
      case AppColorPalette.pchumBen:
        return m == 9 || m == 10;
      case AppColorPalette.waterFestival:
        return m == 11;
      default:
        return false;
    }
  }

  /// Whether this theme is currently in-season today.
  bool get isSeasonallyActive => isSeasonallyActiveAt();

  /// Accessible foreground colour for content placed on [primary].
  /// Chooses between white and a near-black ink based on WCAG contrast.
  Color get onPrimary {
    const ink = Color(0xFF0B1220);
    final whiteContrast = _contrastRatio(primary, Colors.white);
    final inkContrast = _contrastRatio(primary, ink);
    return whiteContrast >= inkContrast ? Colors.white : ink;
  }

  /// Alias for design system secondary accent highlight
  Color get accent => primaryAccent;

  /// WCAG 2.1 relative contrast ratio between two opaque colours.
  static double contrastRatio(Color a, Color b) => _contrastRatio(a, b);

  static double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  // ---------------------------------------------------------------------------
  // Signature Brand Themes
  // ---------------------------------------------------------------------------

  static const PaletteData orangeCoral = PaletteData(
    id: AppColorPalette.orangeCoral,
    nameEn: 'Warm Coral',
    nameKh: 'ពណ៌ទឹកក្រូច / Coral',
    descriptionEn: 'Appetizing signature food delivery warmth',
    descriptionKh: 'រចនាបថពណ៌ទឹកក្រូចដ៏ទាក់ទាញ និងស្រស់ស្រាយ',
    primary: Color(0xFFFF5722),
    primaryDark: Color(0xFFD84315),
    primaryAccent: Color(0xFFFF8A65),
    secondary: Color(0xFFFFB300),
    ratingAccent: Color(0xFFFFB300),
    backgroundLight: Color(0xFFFFF8F5),
    backgroundDark: Color(0xFF16100E),
    surfaceDark: Color(0xFF221814),
    surfaceCardDark: Color(0xFF2C1E19),
    cardDark: Color(0xFF251A15),
    dialogDark: Color(0xFF251A15),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FF8A65),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FF8A65),
        Color(0x20FFCCBC),
        Color(0x10FF5722),
        Color(0x4DD84315),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF87240B), Color(0xFFC4380D), Color(0xFFFF5722)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFFAB40),
    pillCardShadowColor: Color(0x33FF5722),
    icon: Icons.restaurant_rounded,
    categoryEn: 'Signature Brand',
    categoryKh: 'រចនាបថដើម',
    badgeText: 'CLASSIC',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.warmGlow,
  );

  static const PaletteData emeraldGreen = PaletteData(
    id: AppColorPalette.emeraldGreen,
    nameEn: 'Light Classic',
    nameKh: 'បុរាណបែបពន្លឺ / Light Classic',
    descriptionEn: 'Bright • Comfortable • Familiar',
    descriptionKh: 'រចនាបថបុរាណពណ៌កក់ក្តៅ ប្រកបដោយភាពប្រណិត និងផាសុកភាព',
    primary: Color(0xFFEA580C),
    primaryDark: Color(0xFFC2410C),
    primaryAccent: Color(0xFFFB923C),
    secondary: Color(0xFFF59E0B),
    ratingAccent: Color(0xFFFFB300),
    backgroundLight: Color(0xFFFAF7F2),
    backgroundDark: Color(0xFF161311),
    surfaceDark: Color(0xFF221D1A),
    surfaceCardDark: Color(0xFF2B2522),
    cardDark: Color(0xFF26201D),
    dialogDark: Color(0xFF26201D),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FB923C),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FB923C),
        Color(0x20FFEDD5),
        Color(0x10EA580C),
        Color(0x4DC2410C),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF9A3412), Color(0xFFC2410C), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFDBA74),
    pillCardShadowColor: Color(0x33EA580C),
    icon: Icons.lunch_dining_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'CLASSIC',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.warmGlow,
  );

  static const PaletteData smaltBlue = PaletteData(
    id: AppColorPalette.smaltBlue,
    nameEn: 'Royal Smalt',
    nameKh: 'ពណ៌ខៀវ Smalt',
    descriptionEn: 'Cyber neon glass and futuristic luxury',
    descriptionKh: 'រចនាបថពណ៌ខៀវ Smalt ទំនើប និងឆើតឆាយ',
    primary: Color(0xFF2A52BE),
    primaryDark: Color(0xFF0047AB),
    primaryAccent: Color(0xFFA9B7E1),
    secondary: Color(0xFFFFB800),
    ratingAccent: Color(0xFFFFB800),
    backgroundLight: Color(0xFFF4F6FC),
    backgroundDark: Color(0xFF0C1220),
    surfaceDark: Color(0xFF1A2653),
    surfaceCardDark: Color(0xFF202E5F),
    cardDark: Color(0xFF1F2847),
    dialogDark: Color(0xFF1F2847),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40A9B7E1),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66A9B7E1),
        Color(0x20BBC6EC),
        Color(0x102A52BE),
        Color(0x4D3B4AB5),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF1F336B), Color(0xFF223C7A), Color(0xFF2A52BE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFCCFF00),
    pillCardShadowColor: Color(0x332A52BE),
    icon: Icons.water_drop_rounded,
    categoryEn: 'Signature Brand',
    categoryKh: 'រចនាបថដើម',
    badgeText: 'CYBER SMALT',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.oceanicWaves,
  );

  static const PaletteData darkGold = PaletteData(
    id: AppColorPalette.darkGold,
    nameEn: 'Dark Gold & Amber',
    nameKh: 'ពណ៌មាសប្រណិត',
    descriptionEn: 'Prestige dining, gourmet luxury, and nightlife',
    descriptionKh: 'រចនាបថពណ៌មាសប្រណិត សម្រាប់ភោជនីយដ្ឋានលំដាប់ខ្ពស់',
    primary: Color(0xFFD4AF37),
    primaryDark: Color(0xFFAA820A),
    primaryAccent: Color(0xFFF3E5AB),
    secondary: Color(0xFFFFD700),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFFAF8F2),
    backgroundDark: Color(0xFF14120B),
    surfaceDark: Color(0xFF201C11),
    surfaceCardDark: Color(0xFF2C2617),
    cardDark: Color(0xFF241F13),
    dialogDark: Color(0xFF241F13),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40F3E5AB),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66F3E5AB),
        Color(0x20FCF5DE),
        Color(0x10D4AF37),
        Color(0x4DAA820A),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF4A3B0F), Color(0xFF826815), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFFE277),
    pillCardShadowColor: Color(0x33D4AF37),
    icon: Icons.workspace_premium_rounded,
    categoryEn: 'Signature Brand',
    categoryKh: 'រចនាបថដើម',
    badgeText: 'PRESTIGE',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.luxuryStardust,
  );

  // ---------------------------------------------------------------------------
  // Khmer & Seasonal Festival Themes
  // ---------------------------------------------------------------------------

  static const PaletteData khmerNewYear = PaletteData(
    id: AppColorPalette.khmerNewYear,
    nameEn: 'Khmer New Year (Sangkran)',
    nameKh: 'បុណ្យចូលឆ្នាំថ្មីប្រពៃណីខ្មែរ',
    descriptionEn: 'Festive • Traditional • Joyful',
    descriptionKh: 'អបអរសាទរបុណ្យចូលឆ្នាំថ្មី រស្មីពណ៌មាស និងសិរីសួស្តី',
    primary: Color(0xFFE5A910),
    primaryDark: Color(0xFFB87A04),
    primaryAccent: Color(0xFFFDE68A),
    secondary: Color(0xFFDC2626),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFFFFDF5),
    backgroundDark: Color(0xFF140F04),
    surfaceDark: Color(0xFF221A08),
    surfaceCardDark: Color(0xFF2C220B),
    cardDark: Color(0xFF251C09),
    dialogDark: Color(0xFF251C09),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FDE68A),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDE68A),
        Color(0x20FFFBEB),
        Color(0x10E5A910),
        Color(0x4DB87A04),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF78350F), Color(0xFFD97706), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFBBF24),
    pillCardShadowColor: Color(0x33E5A910),
    icon: Icons.celebration_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'ចូលឆ្នាំខ្មែរ',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.festivePetals,
  );

  static const PaletteData christmas = PaletteData(
    id: AppColorPalette.christmas,
    nameEn: 'Christmas Wonderland',
    nameKh: 'បុណ្យគ្រីស្ទម៉ាស / ណូអែល',
    descriptionEn:
        'Magical snowfall, crimson ribbons, pine forests and warm holiday cheer',
    descriptionKh: 'ព្រិលធ្លាក់ត្រជាក់ស្រស់ថ្លា និងបរិយាកាសកក់ក្តៅនៃបុណ្យណូអែល',
    primary: Color(0xFFDC2626),
    primaryDark: Color(0xFF991B1B),
    primaryAccent: Color(0xFF86EFAC),
    secondary: Color(0xFF16A34A),
    ratingAccent: Color(0xFFFBBF24),
    backgroundLight: Color(0xFFF9FBFA),
    backgroundDark: Color(0xFF0C1410),
    surfaceDark: Color(0xFF131E18),
    surfaceCardDark: Color(0xFF1A2A22),
    cardDark: Color(0xFF17241D),
    dialogDark: Color(0xFF17241D),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FCA5A5),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FCA5A5),
        Color(0x20FEE2E2),
        Color(0x10DC2626),
        Color(0x4D991B1B),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF14532D), Color(0xFF991B1B), Color(0xFFDC2626)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFF87171),
    pillCardShadowColor: Color(0x33DC2626),
    icon: Icons.ac_unit_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'CHRISTMAS',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.winterConstellation,
  );

  static const PaletteData christmasWonderland = PaletteData(
    id: AppColorPalette.christmasWonderland,
    nameEn: 'Christmas Wonderland',
    nameKh: 'បុណ្យណូអែល និងរដូវរងា',
    descriptionEn: 'Festive • Warm • Magical',
    descriptionKh: 'ព្រិលធ្លាក់ត្រជាក់ស្រស់ថ្លា និងបរិយាកាសកក់ក្តៅនៃបុណ្យណូអែល',
    primary: Color(0xFFDC2626),
    primaryDark: Color(0xFF991B1B),
    primaryAccent: Color(0xFF86EFAC),
    secondary: Color(0xFF16A34A),
    ratingAccent: Color(0xFFFBBF24),
    backgroundLight: Color(0xFFF9FBFA),
    backgroundDark: Color(0xFF0C1410),
    surfaceDark: Color(0xFF131E18),
    surfaceCardDark: Color(0xFF1A2A22),
    cardDark: Color(0xFF17241D),
    dialogDark: Color(0xFF17241D),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FCA5A5),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FCA5A5),
        Color(0x20FEE2E2),
        Color(0x10DC2626),
        Color(0x4D991B1B),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF14532D), Color(0xFF991B1B), Color(0xFFDC2626)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFF87171),
    pillCardShadowColor: Color(0x33DC2626),
    icon: Icons.ac_unit_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'WONDERLAND',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.winterConstellation,
  );

  static const PaletteData waterFestival = PaletteData(
    id: AppColorPalette.waterFestival,
    nameEn: 'Water Festival (Bon Om Touk)',
    nameKh: 'ព្រះរាជពិធីបុណ្យអុំទូក',
    descriptionEn: 'Fresh • Cultural • Joyful',
    descriptionKh: 'ពិធីបុណ្យអុំទូក បណ្តែតប្រទីប និងសំពះព្រះខែ នៃដងទន្លេសាប',
    primary: Color(0xFF0284C7),
    primaryDark: Color(0xFF0369A1),
    primaryAccent: Color(0xFF7DD3FC),
    secondary: Color(0xFFF59E0B),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFF4F9FD),
    backgroundDark: Color(0xFF081524),
    surfaceDark: Color(0xFF0E2238),
    surfaceCardDark: Color(0xFF142D4A),
    cardDark: Color(0xFF10263E),
    dialogDark: Color(0xFF10263E),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x407DD3FC),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x667DD3FC),
        Color(0x20E0F2FE),
        Color(0x100284C7),
        Color(0x4D0369A1),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0C4A6E), Color(0xFF0284C7), Color(0xFF38BDF8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF38BDF8),
    pillCardShadowColor: Color(0x330284C7),
    icon: Icons.sailing_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'បុណ្យអុំទូក',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.lanternRiver,
  );

  static const PaletteData pchumBen = PaletteData(
    id: AppColorPalette.pchumBen,
    nameEn: 'Pchum Ben (Lotus Blessing)',
    nameKh: 'ពិធីបុណ្យភ្ជុំបិណ្ឌ',
    descriptionEn: 'Peaceful • Respectful • Spiritual',
    descriptionKh: 'បុណ្យភ្ជុំបិណ្ឌ ឧទ្ទិសកុសល ផ្កាឈូកបរិសុទ្ធ និងសន្តិភាព',
    primary: Color(0xFFD946EF),
    primaryDark: Color(0xFFA21CAF),
    primaryAccent: Color(0xFFF5D0FE),
    secondary: Color(0xFFF59E0B),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFFDF8FD),
    backgroundDark: Color(0xFF180E1C),
    surfaceDark: Color(0xFF26152D),
    surfaceCardDark: Color(0xFF331C3C),
    cardDark: Color(0xFF2B1732),
    dialogDark: Color(0xFF2B1732),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40F5D0FE),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66F5D0FE),
        Color(0x20FAE8FF),
        Color(0x10D946EF),
        Color(0x4DA21CAF),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF701A75), Color(0xFFA21CAF), Color(0xFFD946EF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFE879F9),
    pillCardShadowColor: Color(0x33D946EF),
    icon: Icons.spa_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'ភ្ជុំបិណ្ឌ',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.sacredLotus,
  );

  static const PaletteData angkorHeritage = PaletteData(
    id: AppColorPalette.angkorHeritage,
    nameEn: 'Angkor Heritage',
    nameKh: 'សម្បត្តិវប្បធម៌អង្គរ',
    descriptionEn:
        'Majestic sunrise over Angkor Wat & ancient sandstone bronze',
    descriptionKh:
        'ភាពអស្ចារ្យនៃប្រាសាទអង្គរវត្ត ថ្មភក់បុរាណ និងរស្មីព្រះអាទិត្យរះ',
    primary: Color(0xFFEA580C),
    primaryDark: Color(0xFF9A3412),
    primaryAccent: Color(0xFFFDBA74),
    secondary: Color(0xFFD97706),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFFAF7F2),
    backgroundDark: Color(0xFF17110E),
    surfaceDark: Color(0xFF241A14),
    surfaceCardDark: Color(0xFF30231B),
    cardDark: Color(0xFF271C16),
    dialogDark: Color(0xFF271C16),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FDBA74),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDBA74),
        Color(0x20FFEDD5),
        Color(0x10EA580C),
        Color(0x4D9A3412),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF431407), Color(0xFF9A3412), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFB923C),
    pillCardShadowColor: Color(0x33EA580C),
    icon: Icons.account_balance_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'អង្គរវត្ត',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.khmerLattice,
  );

  static const PaletteData khmerHeritage = PaletteData(
    id: AppColorPalette.khmerHeritage,
    nameEn: 'Khmer Heritage',
    nameKh: 'មរតកវប្បធម៌ខ្មែរ',
    descriptionEn: 'Traditional • Cultural • Proud',
    descriptionKh:
        'សោភ័ណភាពស្ថាបត្យកម្មប្រាសាទបុរាណ និងក្បូរក្បាច់រចនាខ្មែរដ៏រុងរឿង',
    primary: Color(0xFFB45309),
    primaryDark: Color(0xFF78350F),
    primaryAccent: Color(0xFFFDE68A),
    secondary: Color(0xFFD97706),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFFFFBF2),
    backgroundDark: Color(0xFF14100B),
    surfaceDark: Color(0xFF1F1710),
    surfaceCardDark: Color(0xFF2B2016),
    cardDark: Color(0xFF221A12),
    dialogDark: Color(0xFF221A12),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FDE68A),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDE68A),
        Color(0x20FEF3C7),
        Color(0x10B45309),
        Color(0x4D78350F),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF451A03), Color(0xFF78350F), Color(0xFFB45309)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFF59E0B),
    pillCardShadowColor: Color(0x33B45309),
    icon: Icons.temple_buddhist_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'មរតកខ្មែរ',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.khmerLattice,
  );

  static const PaletteData modernFoodGo = PaletteData(
    id: AppColorPalette.modernFoodGo,
    nameEn: 'Modern FoodGo',
    nameKh: 'FoodGo ទាន់សម័យ',
    descriptionEn: 'Clean • Friendly • Professional',
    descriptionKh: 'រចនាបថដើម FoodGo ពណ៌ទឹកក្រូចស្រស់ថ្លា និងទំនើបទាន់សម័យ',
    primary: Color(0xFFFF5722),
    primaryDark: Color(0xFFD84315),
    primaryAccent: Color(0xFFFF8A65),
    secondary: Color(0xFFFFB300),
    ratingAccent: Color(0xFFFFB300),
    backgroundLight: Color(0xFFFFF8F5),
    backgroundDark: Color(0xFF14171F),
    surfaceDark: Color(0xFF1C2230),
    surfaceCardDark: Color(0xFF242C3D),
    cardDark: Color(0xFF202838),
    dialogDark: Color(0xFF202838),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40FF8A65),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FF8A65),
        Color(0x20FFCCBC),
        Color(0x10FF5722),
        Color(0x4DD84315),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF87240B), Color(0xFFC4380D), Color(0xFFFF5722)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFFAB40),
    pillCardShadowColor: Color(0x33FF5722),
    icon: Icons.restaurant_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'ORIGINAL',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.liquidMesh,
  );

  static const PaletteData darkPremium = PaletteData(
    id: AppColorPalette.darkPremium,
    nameEn: 'Dark Premium',
    nameKh: 'រាត្រីប្រណិត (Dark Premium)',
    descriptionEn: 'Deep • Elegant • Luxurious',
    descriptionKh: 'ផ្ទៃពណ៌ងងឹតស៊ីវិល័យ កាត់បន្ថយពន្លឺចាំង និងបង្កើនភាពទាក់ទាញ',
    primary: Color(0xFFD4AF37),
    primaryDark: Color(0xFFA07B18),
    primaryAccent: Color(0xFFF3E5AB),
    secondary: Color(0xFFE2E8F0),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFF1F5F9),
    backgroundDark: Color(0xFF0D0F12),
    surfaceDark: Color(0xFF15181E),
    surfaceCardDark: Color(0xFF1E222A),
    cardDark: Color(0xFF191D24),
    dialogDark: Color(0xFF191D24),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40D4AF37),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66F3E5AB),
        Color(0x20D4AF37),
        Color(0x1015181E),
        Color(0x4DA07B18),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0D0F12), Color(0xFF262015), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFD4AF37),
    pillCardShadowColor: Color(0x33D4AF37),
    icon: Icons.dark_mode_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'PREMIUM',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.luxuryStardust,
  );

  static const PaletteData softMinimal = PaletteData(
    id: AppColorPalette.softMinimal,
    nameEn: 'Soft Minimal',
    nameKh: 'សាមញ្ញទន់ភ្លន់ (Minimal)',
    descriptionEn: 'Gentle • Calm • Relaxing',
    descriptionKh: 'សោភ័ណភាពស្រទន់ ស្ងប់ស្ងាត់ មានលំហ និងភាពទន់ភ្លន់',
    primary: Color(0xFF5B7065),
    primaryDark: Color(0xFF3F4F46),
    primaryAccent: Color(0xFFA3B899),
    secondary: Color(0xFFD8B4A6),
    ratingAccent: Color(0xFFE5A93B),
    backgroundLight: Color(0xFFF9F9F7),
    backgroundDark: Color(0xFF141615),
    surfaceDark: Color(0xFF1C1E1D),
    surfaceCardDark: Color(0xFF252927),
    cardDark: Color(0xFF202321),
    dialogDark: Color(0xFF202321),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40A3B899),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66A3B899),
        Color(0x20E5EAE3),
        Color(0x105B7065),
        Color(0x4D3F4F46),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF2B3630), Color(0xFF3F4F46), Color(0xFF5B7065)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFA3B899),
    pillCardShadowColor: Color(0x335B7065),
    icon: Icons.spa_outlined,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'SOFT',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.architecturalMinimal,
  );

  static const PaletteData songkranNewYear = PaletteData(
    id: AppColorPalette.songkranNewYear,
    nameEn: 'Songkran Splash',
    nameKh: 'សង្ក្រាន្តសប្បាយ (Songkran)',
    descriptionEn:
        'Cooling aquatic cyan, joyful splashes, and refreshing celebration',
    descriptionKh: 'រដូវកាលសង្ក្រាន្តត្រជាក់ស្រស់ស្រាយ និងទឹកថ្លាឈ្វេង',
    primary: Color(0xFF06B6D4),
    primaryDark: Color(0xFF0891B2),
    primaryAccent: Color(0xFF67E8F9),
    secondary: Color(0xFFF59E0B),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFF0FDF4),
    backgroundDark: Color(0xFF081822),
    surfaceDark: Color(0xFF0F2535),
    surfaceCardDark: Color(0xFF16344A),
    cardDark: Color(0xFF122C3E),
    dialogDark: Color(0xFF122C3E),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x4067E8F9),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6667E8F9),
        Color(0x20CFFAFE),
        Color(0x1006B6D4),
        Color(0x4D0891B2),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF164E63), Color(0xFF0891B2), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF22D3EE),
    pillCardShadowColor: Color(0x3306B6D4),
    icon: Icons.water_drop_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'សង្ក្រាន្ត',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.festivePetals,
  );

  static const PaletteData monochrome = PaletteData(
    id: AppColorPalette.monochrome,
    nameEn: 'Monochrome Studio',
    nameKh: 'ស-ខ្មៅទាន់សម័យ',
    descriptionEn: 'Simple • Bold • Timeless',
    descriptionKh: 'រចនាបថទាន់សម័យ បែបស្ទូឌីយោ ស និងខ្មៅ',
    primary: Color(0xFF475569),
    primaryDark: Color(0xFF1E293B),
    primaryAccent: Color(0xFF94A3B8),
    secondary: Color(0xFFCBD5E1),
    ratingAccent: Color(0xFFFFD700),
    backgroundLight: Color(0xFFF8FAFC),
    backgroundDark: Color(0xFF0F172A),
    surfaceDark: Color(0xFF1E293B),
    surfaceCardDark: Color(0xFF273549),
    cardDark: Color(0xFF222F42),
    dialogDark: Color(0xFF222F42),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x4094A3B8),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6694A3B8),
        Color(0x20E2E8F0),
        Color(0x10475569),
        Color(0x4D1E293B),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF475569)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF94A3B8),
    pillCardShadowColor: Color(0x33475569),
    icon: Icons.contrast_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'STUDIO',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.architecturalMinimal,
  );

  static const PaletteData highContrast = PaletteData(
    id: AppColorPalette.highContrast,
    nameEn: 'High Contrast (WCAG AAA)',
    nameKh: 'កម្រិតពណ៌ច្បាស់ពិសេស',
    descriptionEn: 'Clear • Accessible • Focused',
    descriptionKh: 'កម្រិតកម្រិតពណ៌ខ្ពស់បំផុត ងាយស្រួលមើល សម្រាប់គ្រប់គ្នា',
    primary: Color(0xFFFFEA00),
    primaryDark: Color(0xFFC7B700),
    primaryAccent: Color(0xFFFFFF56),
    secondary: Color(0xFF00E5FF),
    ratingAccent: Color(0xFFFFEA00),
    backgroundLight: Color(0xFFFFFFFF),
    backgroundDark: Color(0xFF000000),
    surfaceDark: Color(0xFF121212),
    surfaceCardDark: Color(0xFF1E1E1E),
    cardDark: Color(0xFF181818),
    dialogDark: Color(0xFF181818),
    borderLight: Color(0xFF000000),
    borderDark: Color(0xFFFFEA00),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFF00),
        Color(0x80FFFF56),
        Color(0x30FFEA00),
        Color(0x80C7B700),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF1A1A00), Color(0xFFFFEA00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFFEA00),
    pillCardShadowColor: Color(0x66FFEA00),
    icon: Icons.visibility_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'AAA CONTRAST',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.architecturalMinimal,
  );

  // ---------------------------------------------------------------------------
  // Advanced Seasonal Themes Expansion
  // ---------------------------------------------------------------------------

  static const PaletteData newYearCelebration = PaletteData(
    id: AppColorPalette.newYearCelebration,
    nameEn: 'New Year Celebration',
    nameKh: 'អបអរសាទរឆ្លងឆ្នាំសកល',
    descriptionEn: 'Bright • Happy • Energetic',
    descriptionKh: 'រាត្រីឆ្លងឆ្នាំសកល ពោរពេញដោយកាំជ្រួច និងពន្លឺមាសចែងចាំង',
    primary: Color(0xFFF59E0B),
    primaryDark: Color(0xFFD97706),
    primaryAccent: Color(0xFFFDE68A),
    secondary: Color(0xFF3B82F6),
    ratingAccent: Color(0xFFF59E0B),
    backgroundLight: Color(0xFFFFFBEB),
    backgroundDark: Color(0xFF0B0F19),
    surfaceDark: Color(0xFF111827),
    surfaceCardDark: Color(0xFF1F2937),
    cardDark: Color(0xFF192231),
    dialogDark: Color(0xFF192231),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40F59E0B),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDE68A),
        Color(0x20FEF3C7),
        Color(0x10F59E0B),
        Color(0x4DD97706),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0B172E), Color(0xFF1E3A8A), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFBBF24),
    pillCardShadowColor: Color(0x33F59E0B),
    icon: Icons.celebration_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'NEW YEAR',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.fireworksGlitter,
  );

  static const PaletteData halloweenNight = PaletteData(
    id: AppColorPalette.halloweenNight,
    nameEn: 'Halloween Night',
    nameKh: 'រាត្រីបុណ្យហាឡូវីន',
    descriptionEn: 'Spooky • Fun • Mysterious',
    descriptionKh:
        'រាត្រីអាថ៌កំបាំង ផ្លែឃ្លោកភ្លើង និងបរិយាកាសភ័យរន្ធត់បែបកម្សាន្ត',
    primary: Color(0xFFEA580C),
    primaryDark: Color(0xFFC2410C),
    primaryAccent: Color(0xFFA855F7),
    secondary: Color(0xFF7E22CE),
    ratingAccent: Color(0xFFF59E0B),
    backgroundLight: Color(0xFFFAF5FF),
    backgroundDark: Color(0xFF0F0B18),
    surfaceDark: Color(0xFF181126),
    surfaceCardDark: Color(0xFF241938),
    cardDark: Color(0xFF1E1530),
    dialogDark: Color(0xFF1E1530),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40EA580C),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66A855F7),
        Color(0x20F3E8FF),
        Color(0x10EA580C),
        Color(0x4DC2410C),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF3B0764), Color(0xFF7E22CE), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFF97316),
    pillCardShadowColor: Color(0x33EA580C),
    icon: Icons.nightlight_round,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'HALLOWEEN',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.mysticFog,
  );

  static const PaletteData valentinesDay = PaletteData(
    id: AppColorPalette.valentinesDay,
    nameEn: 'Valentine\'s Day',
    nameKh: 'ទិវានៃក្តីស្រឡាញ់',
    descriptionEn: 'Romantic • Soft • Lovely',
    descriptionKh: 'ផ្កាកុលាបក្រហមឆ្អៅ ក្តីស្រឡាញ់ដ៏ផ្អែមល្ហែម និងភាពកក់ក្តៅ',
    primary: Color(0xFFE11D48),
    primaryDark: Color(0xFFBE123C),
    primaryAccent: Color(0xFFFDA4AF),
    secondary: Color(0xFFEC4899),
    ratingAccent: Color(0xFFF59E0B),
    backgroundLight: Color(0xFFFFF1F2),
    backgroundDark: Color(0xFF190B10),
    surfaceDark: Color(0xFF261019),
    surfaceCardDark: Color(0xFF381725),
    cardDark: Color(0xFF2E131E),
    dialogDark: Color(0xFF2E131E),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40E11D48),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDA4AF),
        Color(0x20FFE4E6),
        Color(0x10E11D48),
        Color(0x4DBE123C),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFFB7185)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFB7185),
    pillCardShadowColor: Color(0x33E11D48),
    icon: Icons.favorite_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'VALENTINE',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.romanticPetals,
  );

  static const PaletteData easterSpring = PaletteData(
    id: AppColorPalette.easterSpring,
    nameEn: 'Easter & Spring',
    nameKh: 'រដូវផ្ការីក និងបុណ្យអ៊ីស្ទ័រ',
    descriptionEn:
        'Blossoming lilac meadows, sweet pastels, and fresh vernal renewal',
    descriptionKh: 'រដូវផ្ការីកស្រស់បំព្រង ពណ៌ប៉ាស្តែលផ្អែម និងភាពស្រស់ថ្លា',
    primary: Color(0xFF7C3AED),
    primaryDark: Color(0xFF6D28D9),
    primaryAccent: Color(0xFF86EFAC),
    secondary: Color(0xFFFDE047),
    ratingAccent: Color(0xFFF59E0B),
    backgroundLight: Color(0xFFF5F3FF),
    backgroundDark: Color(0xFF0F0E1A),
    surfaceDark: Color(0xFF19172B),
    surfaceCardDark: Color(0xFF252240),
    cardDark: Color(0xFF1F1C36),
    dialogDark: Color(0xFF1F1C36),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x408B5CF6),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66C4B5FD),
        Color(0x20EDE9FE),
        Color(0x108B5CF6),
        Color(0x4D6D28D9),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFA78BFA),
    pillCardShadowColor: Color(0x338B5CF6),
    icon: Icons.eco_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'EASTER',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.springMeadow,
  );

  static const PaletteData summerTropical = PaletteData(
    id: AppColorPalette.summerTropical,
    nameEn: 'Summer Tropical',
    nameKh: 'រដូវក្តៅត្រូពិច និងសមុទ្រ',
    descriptionEn:
        'Sun-drenched golden mango, cooling coconut water, and azure waves',
    descriptionKh: 'រដូវក្តៅត្រូពិច ទឹកសមុទ្រខៀវស្រងាត់ និងផ្លែស្វាយទុំផ្អែម',
    primary: Color(0xFFF97316),
    primaryDark: Color(0xFFC2410C),
    primaryAccent: Color(0xFF06B6D4),
    secondary: Color(0xFFF43F5E),
    ratingAccent: Color(0xFFFBBF24),
    backgroundLight: Color(0xFFFFF7ED),
    backgroundDark: Color(0xFF08131A),
    surfaceDark: Color(0xFF0E202B),
    surfaceCardDark: Color(0xFF163142),
    cardDark: Color(0xFF122836),
    dialogDark: Color(0xFF122836),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x4006B6D4),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6667E8F9),
        Color(0x20CFFAFE),
        Color(0x10F97316),
        Color(0x4DC2410C),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0E7490), Color(0xFF0284C7), Color(0xFFF97316)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF22D3EE),
    pillCardShadowColor: Color(0x33F97316),
    icon: Icons.wb_sunny_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'TROPICAL',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.tropicalBreeze,
  );

  static const PaletteData lunarNewYear = PaletteData(
    id: AppColorPalette.lunarNewYear,
    nameEn: 'Lunar New Year',
    nameKh: 'បុណ្យចូលឆ្នាំប្រពៃណីចិន',
    descriptionEn:
        'Imperial vermilion, lantern glow, good fortune envelopes, and festive feasts',
    descriptionKh: 'អាំងប៉ាវក្រហម គោមមាស និងសិរីសួស្តីវិបុលសុខនៃឆ្នាំថ្មី',
    primary: Color(0xFFDC2626),
    primaryDark: Color(0xFF991B1B),
    primaryAccent: Color(0xFFF59E0B),
    secondary: Color(0xFFFBBF24),
    ratingAccent: Color(0xFFFBBF24),
    backgroundLight: Color(0xFFFEF2F2),
    backgroundDark: Color(0xFF170909),
    surfaceDark: Color(0xFF241010),
    surfaceCardDark: Color(0xFF331717),
    cardDark: Color(0xFF2B1414),
    dialogDark: Color(0xFF2B1414),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40F59E0B),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDE68A),
        Color(0x20FEF2F2),
        Color(0x10DC2626),
        Color(0x4D991B1B),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFEF4444),
    pillCardShadowColor: Color(0x33DC2626),
    icon: Icons.local_fire_department_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'ចូលឆ្នាំចិន',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.orientalClouds,
  );

  static const PaletteData blackFridayCyber = PaletteData(
    id: AppColorPalette.blackFridayCyber,
    nameEn: 'Black Friday & Cyber Sale',
    nameKh: 'មហាមហោស្រពទិញទំនិញ Black Friday',
    descriptionEn:
        'Sleek dark obsidian with electric neon discounts and flash deals',
    descriptionKh: 'រចនាបថខ្មៅរលោង ភ្លើងណេអុងខៀវ និងការបញ្ចុះតម្លៃពិសេស',
    primary: Color(0xFF00E5FF),
    primaryDark: Color(0xFF00B0FF),
    primaryAccent: Color(0xFFFFB300),
    secondary: Color(0xFFFF0055),
    ratingAccent: Color(0xFFFFB300),
    backgroundLight: Color(0xFFF8FAFC),
    backgroundDark: Color(0xFF050507),
    surfaceDark: Color(0xFF101014),
    surfaceCardDark: Color(0xFF181820),
    cardDark: Color(0xFF14141B),
    dialogDark: Color(0xFF14141B),
    borderLight: Color(0xFFE2E8F0),
    borderDark: Color(0x6000E5FF),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x8000E5FF),
        Color(0x2000B0FF),
        Color(0x20FF0055),
        Color(0x80000000),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF111827), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF00E5FF),
    pillCardShadowColor: Color(0x4000E5FF),
    icon: Icons.shopping_bag_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'CYBER SALE',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.cyberGrid,
  );

  static const PaletteData ramadanEid = PaletteData(
    id: AppColorPalette.ramadanEid,
    nameEn: 'Ramadan & Eid',
    nameKh: 'ពិធីបុណ្យរ៉ាម៉ាដាន និងអេត',
    descriptionEn:
        'Sacred crescent moon, glowing lanterns, dates, and joyous community iftar',
    descriptionKh: 'ព្រះចន្ទអឌ្ឍចន្ទ គោមបំភ្លឺរាត្រី និងពរជ័យដ៏បរិសុទ្ធ',
    primary: Color(0xFF059669),
    primaryDark: Color(0xFF047857),
    primaryAccent: Color(0xFFF59E0B),
    secondary: Color(0xFFFDE68A),
    ratingAccent: Color(0xFFF59E0B),
    backgroundLight: Color(0xFFF0FDF4),
    backgroundDark: Color(0xFF06140F),
    surfaceDark: Color(0xFF0C1F18),
    surfaceCardDark: Color(0xFF132F25),
    cardDark: Color(0xFF0F261E),
    dialogDark: Color(0xFF0F261E),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x40F59E0B),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x66FDE68A),
        Color(0x20F0FDF4),
        Color(0x10059669),
        Color(0x4D047857),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF10B981),
    pillCardShadowColor: Color(0x33059669),
    icon: Icons.nights_stay_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'RAMADAN',
    isFestive: true,
    backdropStyle: SkinBackdropStyle.celestialCrescent,
  );

  static const PaletteData natureOrganic = PaletteData(
    id: AppColorPalette.natureOrganic,
    nameEn: 'Nature & Organic',
    nameKh: 'ធម្មជាតិ និងសរីរាង្គ',
    descriptionEn:
        'Wholesome botanicals, fresh organic produce, and earthy sustainability',
    descriptionKh: 'បន្លែផ្លែឈើធម្មជាតិស្រស់ៗ និងការរស់នៅបែបសុខភាព',
    primary: Color(0xFF10B981),
    primaryDark: Color(0xFF047857),
    primaryAccent: Color(0xFF34D399),
    secondary: Color(0xFFF59E0B),
    ratingAccent: Color(0xFFEAB308),
    backgroundLight: Color(0xFFF6FBF8),
    backgroundDark: Color(0xFF0A140F),
    surfaceDark: Color(0xFF102018),
    surfaceCardDark: Color(0xFF182E23),
    cardDark: Color(0xFF13241C),
    dialogDark: Color(0xFF13241C),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x4034D399),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6634D399),
        Color(0x20A7F3D0),
        Color(0x1010B981),
        Color(0x4D047857),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF34D399),
    pillCardShadowColor: Color(0x3310B981),
    icon: Icons.grass_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'ORGANIC',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.forestCanopy,
  );

  static const PaletteData glassmorphism = PaletteData(
    id: AppColorPalette.glassmorphism,
    nameEn: 'Glassmorphism',
    nameKh: 'កញ្ចក់ថ្លាទំនើប / Glassmorphism',
    descriptionEn:
        'Translucent frosted glass, specular highlights, and multi-depth blur',
    descriptionKh: 'រចនាបថកញ្ចក់ថ្លាទាន់សម័យ ពន្លឺចែងចាំង និងស្រទាប់ស៊ីជម្រៅ',
    primary: Color(0xFF2563EB),
    primaryDark: Color(0xFF1D4ED8),
    primaryAccent: Color(0xFF67E8F9),
    secondary: Color(0xFF818CF8),
    ratingAccent: Color(0xFFF59E0B),
    backgroundLight: Color(0xFFF1F5F9),
    backgroundDark: Color(0xFF0A0F1D),
    surfaceDark: Color(0xFF111A30),
    surfaceCardDark: Color(0xFF192545),
    cardDark: Color(0xFF141F3A),
    dialogDark: Color(0xFF141F3A),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x5067E8F9),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x8067E8F9),
        Color(0x30E0F2FE),
        Color(0x202563EB),
        Color(0x601D4ED8),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E40AF), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF38BDF8),
    pillCardShadowColor: Color(0x332563EB),
    icon: Icons.blur_on_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'AERO GLASS',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.liquidGlassPrism,
  );

  static const PaletteData minimalPremium = PaletteData(
    id: AppColorPalette.minimalPremium,
    nameEn: 'Minimal Premium',
    nameKh: 'សាមញ្ញប្រណិត / Minimal',
    descriptionEn:
        'Quiet luxury, refined Scandinavian restraint, and editorial clarity',
    descriptionKh: 'ភាពសាមញ្ញតែប្រណិត ស្ងប់ស្ងាត់ ផាសុកភាព និងទាន់សម័យ',
    primary: Color(0xFF334155),
    primaryDark: Color(0xFF1E293B),
    primaryAccent: Color(0xFF94A3B8),
    secondary: Color(0xFFCBD5E1),
    ratingAccent: Color(0xFFEAB308),
    backgroundLight: Color(0xFFFAFBFD),
    backgroundDark: Color(0xFF0F141C),
    surfaceDark: Color(0xFF171F2C),
    surfaceCardDark: Color(0xFF222C3D),
    cardDark: Color(0xFF1D2635),
    dialogDark: Color(0xFF1D2635),
    borderLight: Color(0xFFE2E8F0),
    borderDark: Color(0x4094A3B8),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6694A3B8),
        Color(0x20E2E8F0),
        Color(0x10334155),
        Color(0x4D1E293B),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF475569)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF94A3B8),
    pillCardShadowColor: Color(0x20334155),
    icon: Icons.spa_rounded,
    categoryEn: 'Theme Styles',
    categoryKh: 'រចនាបថទូទៅ',
    badgeText: 'MINIMAL',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.architecturalMinimal,
  );

  static const PaletteData retroPop = PaletteData(
    id: AppColorPalette.retroPop,
    nameEn: 'Retro Pop',
    nameKh: 'បែបអតីតកាលទសវត្សរ៍ ៨០',
    descriptionEn:
        'Vibrant 80s synthwave, punchy arcade contrast, and nostalgic rhythm',
    descriptionKh: 'រចនាបថទសវត្សរ៍ ៨០ ពណ៌ដិតស្រស់ស្អាត បែបយុវវ័យ និងតន្ត្រី',
    primary: Color(0xFFE11D74),
    primaryDark: Color(0xFFBE125E),
    primaryAccent: Color(0xFFFFDE59),
    secondary: Color(0xFF00F0FF),
    ratingAccent: Color(0xFFFFDE59),
    backgroundLight: Color(0xFFFFF5F8),
    backgroundDark: Color(0xFF140817),
    surfaceDark: Color(0xFF200F25),
    surfaceCardDark: Color(0xFF301738),
    cardDark: Color(0xFF28132F),
    dialogDark: Color(0xFF28132F),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x50FFDE59),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x80FFDE59),
        Color(0x3000F0FF),
        Color(0x20E11D74),
        Color(0x60BE125E),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF4A0E4E), Color(0xFFE11D74), Color(0xFFFFDE59)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFFFF2A85),
    pillCardShadowColor: Color(0x40E11D74),
    icon: Icons.music_note_rounded,
    categoryEn: 'Creative & Pop',
    categoryKh: 'ការច្នៃប្រឌិត និងសិល្បៈ',
    badgeText: '80s RETRO',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.retroMemphis,
  );

  static const PaletteData neonNight = PaletteData(
    id: AppColorPalette.neonNight,
    nameEn: 'Neon Night',
    nameKh: 'រាត្រីពន្លឺណេអុង / Cyberpunk',
    descriptionEn:
        'Ultra-vivid cyberpunk glow, matrix cyan streaks, and night city pulse',
    descriptionKh: 'ពន្លឺណេអុងនាពេលរាត្រី បច្ចេកវិទ្យាអនាគត និងភាពរស់រវើក',
    primary: Color(0xFF00FFCC),
    primaryDark: Color(0xFF00C896),
    primaryAccent: Color(0xFFFF007F),
    secondary: Color(0xFFFFE600),
    ratingAccent: Color(0xFFFFE600),
    backgroundLight: Color(0xFFF5F7FB),
    backgroundDark: Color(0xFF05080E),
    surfaceDark: Color(0xFF0B101D),
    surfaceCardDark: Color(0xFF131A2F),
    cardDark: Color(0xFF0F1526),
    dialogDark: Color(0xFF0F1526),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x6000FFCC),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x8000FFCC),
        Color(0x40FF007F),
        Color(0x2005080E),
        Color(0x8000C896),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF05080E), Color(0xFF4C0519), Color(0xFF00FFCC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF00FFCC),
    pillCardShadowColor: Color(0x4000FFCC),
    icon: Icons.bolt_rounded,
    categoryEn: 'Creative & Pop',
    categoryKh: 'ការច្នៃប្រឌិត និងសិល្បៈ',
    badgeText: 'CYBERPUNK',
    isFestive: false,
    backdropStyle: SkinBackdropStyle.cyberGrid,
  );

  // ---------------------------------------------------------------------------
  // Palette Registry & Lookups
  // ---------------------------------------------------------------------------

  /// The 9 Core Theme Styles from the master FoodGo UI/UX Journey:
  /// Modern FoodGo, Light Classic, Dark Premium, Minimal Premium, Soft Minimal,
  /// Monochrome, High Contrast, Glassmorphism, Nature & Organic.
  static const List<PaletteData> themeStyles = [
    modernFoodGo,
    emeraldGreen,
    darkPremium,
    minimalPremium,
    softMinimal,
    monochrome,
    highContrast,
    glassmorphism,
    natureOrganic,
  ];

  /// The Core Seasonal & Cultural Themes from the FoodGo UI/UX Journey:
  /// Christmas, Khmer New Year, Valentine's Day, Halloween, Water Festival,
  /// Lunar New Year, Pchum Ben, Ramadan & Eid, Summer, Black Friday, Khmer Heritage.
  static const List<PaletteData> seasonalThemes = [
    christmasWonderland,
    khmerNewYear,
    valentinesDay,
    halloweenNight,
    waterFestival,
    lunarNewYear,
    pchumBen,
    ramadanEid,
    summerTropical,
    blackFridayCyber,
    khmerHeritage,
  ];

  static const List<PaletteData> allPalettes = [
    // ── Khmer & Festive Themes ──────────────────────────────────────────────
    khmerNewYear,
    khmerHeritage,
    songkranNewYear,
    pchumBen,
    waterFestival,
    angkorHeritage,
    christmasWonderland,
    newYearCelebration,
    halloweenNight,
    valentinesDay,
    easterSpring,
    summerTropical,
    lunarNewYear,
    blackFridayCyber,
    ramadanEid,

    // ── Signature Brand & Modern Themes ─────────────────────────────────────
    modernFoodGo,
    natureOrganic,
    glassmorphism,
    minimalPremium,
    emeraldGreen,
    orangeCoral,
    darkPremium,
    softMinimal,
    smaltBlue,
    darkGold,

    // ── Creative & Pop Themes ───────────────────────────────────────────────
    retroPop,
    neonNight,

    // ── Accessibility & Special ─────────────────────────────────────────────
    monochrome,
    highContrast,
  ];

  static PaletteData fromId(AppColorPalette id) {
    switch (id) {
      case AppColorPalette.orangeCoral:
        return orangeCoral;
      case AppColorPalette.emeraldGreen:
        return emeraldGreen;
      case AppColorPalette.smaltBlue:
        return smaltBlue;
      case AppColorPalette.darkGold:
        return darkGold;
      case AppColorPalette.khmerNewYear:
        return khmerNewYear;
      case AppColorPalette.christmas:
        return christmas;
      case AppColorPalette.waterFestival:
        return waterFestival;
      case AppColorPalette.pchumBen:
        return pchumBen;
      case AppColorPalette.angkorHeritage:
        return angkorHeritage;
      case AppColorPalette.khmerHeritage:
        return khmerHeritage;
      case AppColorPalette.modernFoodGo:
        return modernFoodGo;
      case AppColorPalette.darkPremium:
        return darkPremium;
      case AppColorPalette.softMinimal:
        return softMinimal;
      case AppColorPalette.songkranNewYear:
        return songkranNewYear;
      case AppColorPalette.monochrome:
        return monochrome;
      case AppColorPalette.highContrast:
        return highContrast;
      case AppColorPalette.christmasWonderland:
        return christmasWonderland;
      case AppColorPalette.newYearCelebration:
        return newYearCelebration;
      case AppColorPalette.halloweenNight:
        return halloweenNight;
      case AppColorPalette.valentinesDay:
        return valentinesDay;
      case AppColorPalette.easterSpring:
        return easterSpring;
      case AppColorPalette.summerTropical:
        return summerTropical;
      case AppColorPalette.lunarNewYear:
        return lunarNewYear;
      case AppColorPalette.blackFridayCyber:
        return blackFridayCyber;
      case AppColorPalette.ramadanEid:
        return ramadanEid;
      case AppColorPalette.natureOrganic:
        return natureOrganic;
      case AppColorPalette.glassmorphism:
        return glassmorphism;
      case AppColorPalette.minimalPremium:
        return minimalPremium;
      case AppColorPalette.retroPop:
        return retroPop;
      case AppColorPalette.neonNight:
        return neonNight;
    }
  }

  static PaletteData fromString(String? key) {
    if (key == null) return modernFoodGo;
    if (key == 'christmas') return christmas;
    if (key == 'christmasWonderland') return christmasWonderland;
    if (key == 'lightClassic') return emeraldGreen;
    for (final palette in allPalettes) {
      if (palette.id.name == key) return palette;
    }
    return modernFoodGo;
  }
}
