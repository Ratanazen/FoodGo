import 'package:flutter/material.dart';
import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: GlassTheme.borderRadiusSmall,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Hero(
              tag: 'food_image_$id',
              child: ClipRRect(
                borderRadius: GlassTheme.borderRadiusSmall,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GlassTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onAddTap,
              child: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(12),
                customColor: GlassTheme.primaryGreen.withValues(alpha: 0.1),
                child: const Icon(Icons.add, color: GlassTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
