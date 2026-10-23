import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: GlassContainer(
        borderRadius: GlassTheme.borderRadiusSmall,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        customBorder: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
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
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 82,
                          height: 82,
                          color: Colors.grey.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : Container(
                        width: 82,
                        height: 82,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Icon(Icons.image),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: GlassTheme.primaryGreen,
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
              color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
              iconColor: GlassTheme.primaryGreen,
              borderColor: GlassTheme.primaryGreen.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
