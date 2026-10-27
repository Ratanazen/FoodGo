import 'package:flutter/material.dart';

enum AppColorPalette { orangeCoral, emeraldGreen, smaltBlue, darkGold }

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
  });

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
  );

  static const PaletteData emeraldGreen = PaletteData(
    id: AppColorPalette.emeraldGreen,
    nameEn: 'Emerald Green',
    nameKh: 'ពណ៌បៃតងត្បូងមរកត',
    descriptionEn: 'Fresh, organic, and eco-friendly dining',
    descriptionKh: 'រចនាបថពណ៌បៃតងធម្មជាតិ ស្រស់ថ្លា និងសុខភាព',
    primary: Color(0xFF00A86B),
    primaryDark: Color(0xFF007A4D),
    primaryAccent: Color(0xFF66E2B1),
    secondary: Color(0xFFFFB800),
    ratingAccent: Color(0xFFFFB800),
    backgroundLight: Color(0xFFF4FAF6),
    backgroundDark: Color(0xFF0A1610),
    surfaceDark: Color(0xFF102219),
    surfaceCardDark: Color(0xFF162E22),
    cardDark: Color(0xFF12261C),
    dialogDark: Color(0xFF12261C),
    borderLight: Color(0x80FFFFFF),
    borderDark: Color(0x4066E2B1),
    liquidGlassBorderDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x6666E2B1),
        Color(0x20A7F3D0),
        Color(0x1000A86B),
        Color(0x4D007A4D),
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF004D31), Color(0xFF007A4D), Color(0xFF00A86B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    auraColor: Color(0xFF00E676),
    pillCardShadowColor: Color(0x3300A86B),
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
  );

  static const List<PaletteData> allPalettes = [
    orangeCoral,
    emeraldGreen,
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
    }
  }

  static PaletteData fromString(String? key) {
    if (key == null) return orangeCoral;
    for (final palette in allPalettes) {
      if (palette.id.name == key) return palette;
    }
    return orangeCoral;
  }
}
