import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/glass_theme.dart';
import 'glass_container.dart';
import 'svg_icon.dart';

/// Displays the official About FoodGo modal dialog with app logo, version,
/// capabilities, and platform links.
Future<void> showAboutFoodGoDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'FoodGo Delivery',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Healthy & Organic Food Delivery · Phnom Penh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: GlassTheme.textMuted,
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
                    style: TextStyle(
                      color: GlassTheme.dynamicPrimaryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Highlights & Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureChip(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Bakong KHQR',
                      color: const Color(0xFFE1251B),
                    ),
                    const SizedBox(width: 8),
                    _buildFeatureChip(
                      icon: Icons.bolt_rounded,
                      label: 'Live Daphne WS',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    _buildFeatureChip(
                      icon: Icons.eco_rounded,
                      label: '100% Organic',
                      color: GlassTheme.dynamicPrimaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'FoodGo brings fresh, organic meals and drinks from Phnom Penh\'s top culinary kitchens directly to your home with real-time driver tracking and cashless KHQR payments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Links Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/terms');
                      },
                      child: Text(
                        'Terms',
                        style: TextStyle(
                          color: GlassTheme.dynamicPrimaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/privacy');
                      },
                      child: Text(
                        'Privacy',
                        style: TextStyle(
                          color: GlassTheme.dynamicPrimaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/settings');
                      },
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: GlassTheme.dynamicPrimaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                      backgroundColor: GlassTheme.dynamicPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildFeatureChip({
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
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
