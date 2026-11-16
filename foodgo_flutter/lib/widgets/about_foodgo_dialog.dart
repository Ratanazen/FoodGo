import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/glass_theme.dart';
import 'glass_container.dart';
import 'svg_icon.dart';

/// Displays the official About FoodGo modal dialog with app logo, version,
/// capabilities, and platform links.
Future<void> showAboutFoodGoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) {
      final brightness = Theme.of(ctx).brightness;
      final isDark = brightness == Brightness.dark;
      final textTheme = Theme.of(ctx).textTheme;
      final colorScheme = Theme.of(ctx).colorScheme;
      final primaryText = AppTypography.primaryTextColor(brightness);
      final secondaryText = AppTypography.secondaryTextColor(brightness);
      final brandTextColor = isDark
          ? GlassTheme.dynamicPrimaryColor
          : HSLColor.fromColor(
              GlassTheme.dynamicPrimaryColor,
            ).withLightness(0.32).toColor();

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo Icon Showcase
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GlassTheme.dynamicPrimaryColor.withValues(
                        alpha: 0.12,
                      ),
                      border: Border.all(
                        color: GlassTheme.dynamicPrimaryColor.withValues(
                          alpha: 0.4,
                        ),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GlassTheme.dynamicPrimaryColor.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const FoodGoAppIcon(size: 64, borderRadius: 16),
                  ),
                  const SizedBox(height: 14),

                  // Brand Title & Slogan
                  Text(
                    'FoodGo Delivery',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Healthy & Organic Food Delivery · Phnom Penh',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Version Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: GlassTheme.dynamicPrimaryColor.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: GlassTheme.dynamicPrimaryColor.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Text(
                      'Version 2.0.0 (Build 20) • Production Ready',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: brandTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Highlights & Badges
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureChip(
                        textTheme: textTheme,
                        icon: Icons.qr_code_2_rounded,
                        label: 'Bakong KHQR',
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFB91C1C),
                      ),
                      _buildFeatureChip(
                        textTheme: textTheme,
                        icon: Icons.bolt_rounded,
                        label: 'Live Daphne WS',
                        color: isDark ? Colors.amber : const Color(0xFFB45309),
                      ),
                      _buildFeatureChip(
                        textTheme: textTheme,
                        icon: Icons.eco_rounded,
                        label: '100% Organic',
                        color: brandTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'FoodGo brings fresh, organic meals and drinks from Phnom Penh\'s top culinary kitchens directly to your home with real-time driver tracking and cashless KHQR payments.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: 18),

                  // Links Row
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final entry in const [
                        ('Terms', '/terms'),
                        ('Privacy', '/privacy'),
                        ('Settings', '/settings'),
                      ].indexed) ...[
                        if (entry.$1 > 0)
                          Text(
                            '•',
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(entry.$2.$2);
                          },
                          child: Text(
                            entry.$2.$1,
                            style: textTheme.bodySmall?.copyWith(
                              color: brandTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Close',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildFeatureChip({
  required TextTheme textTheme,
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
