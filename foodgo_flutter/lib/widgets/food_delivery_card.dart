import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/glass_theme.dart';

class FoodDeliveryCard extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;
  final bool isHorizontal;

  const FoodDeliveryCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  State<FoodDeliveryCard> createState() => _FoodDeliveryCardState();
}

class _FoodDeliveryCardState extends State<FoodDeliveryCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final res = widget.restaurant;
    final name = res['name']?.toString() ?? 'Restaurant';
    final banner = res['banner']?.toString();
    final rating = res['rating']?.toString() ?? '4.8';
    final minTime = res['delivery_time_min'] ?? 15;
    final maxTime = res['delivery_time_max'] ?? 30;
    final deliveryFee = double.tryParse(res['delivery_fee']?.toString() ?? '0') ?? 0.0;
    final isFreeDelivery = deliveryFee <= 0.0;

    final width = widget.isHorizontal ? 260.0 : double.infinity;
    final imageHeight = widget.isHorizontal ? 130.0 : 155.0;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? GlassTheme.surfaceCardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Hero Banner with Badges ─────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: banner != null && banner.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: banner,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: GlassTheme.primaryGreen),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.withValues(alpha: 0.15),
                              child: const Icon(Icons.store, color: GlassTheme.textMuted, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey.withValues(alpha: 0.15),
                            child: const Icon(Icons.store, color: GlassTheme.textMuted, size: 40),
                          ),
                  ),
                ),

                // Top-Left Discount/Promo Tag (Foodpanda signature style)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFreeDelivery ? GlassTheme.primaryGreen : GlassTheme.foodpandaPink,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isFreeDelivery ? Icons.moped : Icons.local_fire_department, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          isFreeDelivery ? 'Free Delivery' : '20% OFF Deals',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-Right Favorite Heart Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isFavorite ? 'Saved to Favorites' : 'Removed from Favorites'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: _isFavorite ? GlassTheme.foodpandaPink : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom-Right Delivery Time Badge
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '$minTime-$maxTime min',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Restaurant Details ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GlassTheme.ratingAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: GlassTheme.ratingAmber),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GlassTheme.ratingAmber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Cuisine & Distance Subtitle
                  Text(
                    '\$\$ • Burgers • Fast Food • 1.2 km',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Delivery Fee Tag
                  Row(
                    children: [
                      Icon(Icons.moped, size: 14, color: isFreeDelivery ? GlassTheme.primaryGreen : GlassTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        isFreeDelivery ? 'Free Delivery' : '\$${deliveryFee.toStringAsFixed(2)} delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isFreeDelivery ? GlassTheme.primaryGreen : GlassTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '15% OFF \$10+',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: GlassTheme.foodpandaPink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
