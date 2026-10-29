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
  });

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
  );

  static const PaletteData emeraldGreen = PaletteData(
    id: AppColorPalette.emeraldGreen,
    nameEn: 'Healthy Organic Green',
    nameKh: 'ពណ៌បៃតងធម្មជាតិ / Organic',
    descriptionEn: 'Fresh, organic, and clean healthy food dining',
    descriptionKh: 'រចនាបថពណ៌បៃតងធម្មជាតិ ស្រស់ថ្លា និងសុខភាព',
    primary: Color(0xFF22C55E),
    primaryDark: Color(0xFF16A34A),
    primaryAccent: Color(0xFF86EFAC),
    secondary: Color(0xFFFFB800),
    ratingAccent: Color(0xFFFFB800),
    backgroundLight: Color(0xFFF8FAF8),
    backgroundDark: Color(0xFF0B1710),
    surfaceDark: Color(0xFF12231A),
    surfaceCardDark: Color(0xFF182D22),
    cardDark: Color(0xFF14271D),
    dialogDark: Color(0xFF14271D),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x4086EFAC),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6686EFAC),
        Color(0x20DCFCE7),
        Color(0x1022C55E),
        Color(0x4D16A34A),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF4ADE80),
    pillCardShadowColor: Color(0x3322C55E),
    icon: Icons.eco_rounded,
    categoryEn: 'Signature Brand',
    categoryKh: 'រចនាបថដើម',
    badgeText: 'ORGANIC',
    isFestive: false,
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
  );

  // ---------------------------------------------------------------------------
  // Khmer & Seasonal Festival Themes
  // ---------------------------------------------------------------------------

  static const PaletteData khmerNewYear = PaletteData(
    id: AppColorPalette.khmerNewYear,
    nameEn: 'Khmer New Year (Sangkran)',
    nameKh: 'បុណ្យចូលឆ្នាំថ្មីប្រពៃណីខ្មែរ',
    descriptionEn: 'Sangkran golden joy, festive prosperity & celebration',
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
  );

  static const PaletteData christmas = PaletteData(
    id: AppColorPalette.christmas,
    nameEn: 'Christmas Festive',
    nameKh: 'បុណ្យគ្រីស្ទម៉ាស / ណូអែល',
    descriptionEn: 'Warm holiday cheer, evergreen pine & holly berry red',
    descriptionKh: 'បរិយាកាសបុណ្យណូអែល ស្រស់បំព្រងដោយពណ៌ក្រហម និងបៃតងស្រល់',
    primary: Color(0xFFDC2626),
    primaryDark: Color(0xFF991B1B),
    primaryAccent: Color(0xFF86EFAC),
    secondary: Color(0xFF16A34A),
    ratingAccent: Color(0xFFFBBF24),
    backgroundLight: Color(0xFFF9FBFA),
    backgroundDark: Color(0xFF0F1712),
    surfaceDark: Color(0xFF16231B),
    surfaceCardDark: Color(0xFF1E2E24),
    cardDark: Color(0xFF18261E),
    dialogDark: Color(0xFF18261E),
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
    icon: Icons.park_rounded,
    categoryEn: 'Khmer & Festive',
    categoryKh: 'ពិធីបុណ្យ និងប្រពៃណីជាតិ',
    badgeText: 'CHRISTMAS',
    isFestive: true,
  );

  static const PaletteData waterFestival = PaletteData(
    id: AppColorPalette.waterFestival,
    nameEn: 'Water Festival (Bon Om Touk)',
    nameKh: 'ព្រះរាជពិធីបុណ្យអុំទូក',
    descriptionEn: 'Tonle Sap river regatta, illuminated boats & full moon glow',
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
  );

  static const PaletteData pchumBen = PaletteData(
    id: AppColorPalette.pchumBen,
    nameEn: 'Pchum Ben (Lotus Blessing)',
    nameKh: 'ពិធីបុណ្យភ្ជុំបិណ្ឌ',
    descriptionEn: 'Sacred merit blessings, pure white lotus & harmony',
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
  );

  static const PaletteData angkorHeritage = PaletteData(
    id: AppColorPalette.angkorHeritage,
    nameEn: 'Angkor Heritage',
    nameKh: 'សម្បត្តិវប្បធម៌អង្គរ',
    descriptionEn: 'Majestic sunrise over Angkor Wat & ancient sandstone bronze',
    descriptionKh: 'ភាពអស្ចារ្យនៃប្រាសាទអង្គរវត្ត ថ្មភក់បុរាណ និងរស្មីព្រះអាទិត្យរះ',
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
  );

  // ---------------------------------------------------------------------------
  // Palette Registry & Lookups
  // ---------------------------------------------------------------------------

  static const List<PaletteData> allPalettes = [
    // Khmer & Festive Themes
    khmerNewYear,
    christmas,
    waterFestival,
    pchumBen,
    angkorHeritage,
    // Signature Brand Themes
    emeraldGreen,
    orangeCoral,
    smaltBlue,
    darkGold,
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
    }
  }

  static PaletteData fromString(String? key) {
    if (key == null) return emeraldGreen;
    for (final palette in allPalettes) {
      if (palette.id.name == key) return palette;
    }
    return emeraldGreen;
  }
}
