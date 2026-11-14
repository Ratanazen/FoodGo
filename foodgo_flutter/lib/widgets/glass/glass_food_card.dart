import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';

import 'animated_pressable.dart';

class GlassFoodCard extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final String subtitle;
  final String price;
  final String rating;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  const GlassFoodCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final greenAccent = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final starColor = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFB45309);

    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: GlassContainer(
        borderRadius: GlassTheme.borderRadiusSmall,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        customBorder: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'food_image_$id',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 82,
                          height: 82,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: greenAccent,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 82,
                          height: 82,
                          color: Colors.grey.withValues(alpha: 0.2),
                          child: Icon(Icons.fastfood, color: secondaryText),
                        ),
                      )
                    : Container(
                        width: 82,
                        height: 82,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: Icon(Icons.image, color: secondaryText),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: starColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: textTheme.bodySmall?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: greenAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedIconButton(
              icon: Icons.add_rounded,
              onPressed: onAddTap,
              size: 38,
              iconSize: 22,
              color: greenAccent.withValues(alpha: 0.15),
              iconColor: greenAccent,
              borderColor: greenAccent.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
