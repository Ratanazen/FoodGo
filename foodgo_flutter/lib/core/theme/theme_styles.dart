import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass/animated_pressable.dart';
import 'app_palette.dart';
import 'glass_theme.dart';

/// Central styling helper for dynamic theme styling, festival greetings, and seasonal decorations.
class ThemeStyles {
  /// Returns authentic festival or theme greeting message.
  static String getFestivalGreeting([PaletteData? palette]) {
    final p = palette ?? GlassTheme.activePalette;
    switch (p.id) {
      case AppColorPalette.khmerNewYear:
        return 'សួស្តីឆ្នាំថ្មី! Happy Khmer New Year!';
      case AppColorPalette.khmerHeritage:
        return 'មរតកវប្បធម៌ខ្មែរ! Majestic Khmer Heritage 🏛️';
      case AppColorPalette.songkranNewYear:
        return 'រីករាយពិធីបុណ្យចូលឆ្នាំថ្មី សង្ក្រាន្តត្រជាក់ចិត្ត! 💦';
      case AppColorPalette.christmas:
        return 'Merry Christmas & Happy Holidays! 🎄';
      case AppColorPalette.waterFestival:
        return 'រីករាយព្រះរាជពិធីបុណ្យអុំទូក! ⛵';
      case AppColorPalette.pchumBen:
        return 'ពិធីបុណ្យភ្ជុំបិណ្ឌ! Pchum Ben Blessings! 🪷';
      case AppColorPalette.angkorHeritage:
        return 'មោទនភាពជាតិខ្មែរ! Majestic Angkor Heritage 🏛️';
      case AppColorPalette.modernFoodGo:
      case AppColorPalette.emeraldGreen:
        return 'Fresh & Healthy Organic Food Dining 🌿';
      case AppColorPalette.orangeCoral:
        return 'Delicious Food Delivered Hot & Fresh 🍔';
      case AppColorPalette.darkPremium:
        return 'Prestige Onyx & Champagne Gourmet ✨';
      case AppColorPalette.softMinimal:
        return 'Calm, Mindful & Organic Living 🍃';
      case AppColorPalette.smaltBlue:
        return 'Modern Cyber Dining Experience ⚡';
      case AppColorPalette.darkGold:
        return 'Prestige Gourmet Dining & Luxury ✨';
      case AppColorPalette.monochrome:
        return 'Editorial Studio Precision & Clarity 🏁';
      case AppColorPalette.highContrast:
        return 'Maximum Contrast Accessible Experience 👁️';
    }
  }

  /// Returns festival subtitle / blessing in Khmer script.
  static String getFestivalSubtitleKh([PaletteData? palette]) {
    final p = palette ?? GlassTheme.activePalette;
    switch (p.id) {
      case AppColorPalette.khmerNewYear:
        return 'អបអរសាទរទេវតាឆ្នាំថ្មី សិរីសួស្តី វិបុលសុខគ្រប់ប្រការ';
      case AppColorPalette.khmerHeritage:
        return 'មោទនភាពសម្បត្តិបេតិកភណ្ឌ និងអរិយធម៌ខ្មែរដ៏រុងរឿង';
      case AppColorPalette.songkranNewYear:
        return 'ត្រជាក់ត្រជុំ សិរីសួស្តី និងភាពរីករាយពេញមួយឆ្នាំ';
      case AppColorPalette.christmas:
        return 'ជូនពរសេចក្តីសុខ សុភមង្គល និងភាពកក់ក្តៅក្នុងរដូវកាលបុណ្យ';
      case AppColorPalette.waterFestival:
        return 'បណ្តែតប្រទីប អកអំបុក សំពះព្រះខែ នៃដងទន្លេសាប';
      case AppColorPalette.pchumBen:
        return 'ឧទ្ទិសកុសលផលបុណ្យ ផ្កាឈូកបរិសុទ្ធ និងភាពសុខដុម';
      case AppColorPalette.angkorHeritage:
        return 'អរិយធម៌ដ៏រុងរឿង និងភាពអស្ចារ្យនៃប្រាសាទអង្គរវត្តខ្មែរ';
      default:
        return p.descriptionKh;
    }
  }

  /// Themed container / card decoration that adapts to the active palette.
  static BoxDecoration cardDecoration(
    BuildContext context, {
    bool isGlass = true,
    double borderRadius = 20,
    double borderWidth = 1.2,
    bool glow = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = GlassTheme.activePalette;

    if (isDark) {
      return BoxDecoration(
        color: palette.surfaceCardDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: palette.primaryAccent.withValues(alpha: isGlass ? 0.22 : 0.12),
          width: borderWidth,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );
    } else {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.14),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }
  }

  /// Themed pill badge decoration.
  static BoxDecoration pillBadgeDecoration(
    BuildContext context, {
    Color? customColor,
    double radius = 12,
  }) {
    final palette = GlassTheme.activePalette;
    final baseColor = customColor ?? palette.primary;
    return BoxDecoration(
      color: baseColor.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: baseColor.withValues(alpha: 0.45),
        width: 1.0,
      ),
    );
  }

  /// Themed elevated button style.
  static ButtonStyle primaryButtonStyle(
    BuildContext context, {
    double radius = 16,
    EdgeInsetsGeometry? padding,
  }) {
    final palette = GlassTheme.activePalette;
    return ElevatedButton.styleFrom(
      backgroundColor: palette.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shadowColor: palette.pillCardShadowColor,
    );
  }
}

/// An interactive, animated banner showcasing the active theme/festival greeting.
class FestivalThemeBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showBadge;

  const FestivalThemeBanner({
    super.key,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider?>();
    final palette = themeProvider?.paletteData ?? GlassTheme.activePalette;
    if (palette.isFestive && themeProvider != null && !themeProvider.seasonalDecorationsEnabled) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    palette.surfaceCardDark,
                    palette.surfaceDark,
                  ]
                : [
                    palette.primary.withValues(alpha: 0.12),
                    palette.primaryAccent.withValues(alpha: 0.06),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.primary.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: palette.headerGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                palette.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ThemeStyles.getFestivalGreeting(palette),
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showBadge && palette.badgeText.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            palette.badgeText,
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ThemeStyles.getFestivalSubtitleKh(palette),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.palette_outlined,
              color: palette.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
