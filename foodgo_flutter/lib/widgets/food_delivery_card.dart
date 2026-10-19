import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/glass_theme.dart';
import '../providers/favorites_provider.dart';

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
  @override
  Widget build(BuildContext context) {
    final res = widget.restaurant;
    final isFavorite = context.watch<FavoritesProvider>().isRestaurantFavorite(
      res['id'],
    );
    final name = res['name']?.toString() ?? 'Restaurant';
    final banner = res['banner']?.toString();
    final rating = res['rating']?.toString() ?? '4.8';
    final minTime = res['delivery_time_min'] ?? 15;
    final maxTime = res['delivery_time_max'] ?? 30;
    final deliveryFee =
        double.tryParse(res['delivery_fee']?.toString() ?? '0') ?? 0.0;
    final isFreeDelivery = deliveryFee <= 0.0;

    final width = widget.isHorizontal ? 260.0 : double.infinity;
    final imageHeight = widget.isHorizontal ? 130.0 : 155.0;

    final String fallbackBanner = res['id'] == 1
        ? 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80'
        : res['id'] == 2
        ? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80'
        : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80';
    final effectiveBanner = (banner != null && banner.isNotEmpty)
        ? banner
        : fallbackBanner;

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
                Hero(
                  tag: 'restaurant_banner_${res['id']}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Container(
                      height: imageHeight,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: CachedNetworkImage(
                        imageUrl: effectiveBanner,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            CachedNetworkImage(
                              imageUrl: fallbackBanner,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(
                                color: Colors.grey.withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.store,
                                  color: GlassTheme.textMuted,
                                  size: 40,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),

                // Top-Left Discount/Promo Tag (Foodpanda signature style)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFreeDelivery
                          ? GlassTheme.primaryGreen
                          : GlassTheme.foodpandaPink,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFreeDelivery
                              ? Icons.moped
                              : Icons.local_fire_department,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFreeDelivery ? 'Free Delivery' : '20% OFF Deals',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
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
                      onTap: () async {
                        final added = await context
                            .read<FavoritesProvider>()
                            .toggleRestaurant(res);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Saved $name to Favorites'
                                  : 'Removed $name from Favorites',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: GlassTheme.surfaceDark,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite
                              ? GlassTheme.foodpandaPink
                              : Colors.white,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$minTime-$maxTime min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
                        child: Hero(
                          tag: 'restaurant_title_${res['id']}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.ratingAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: GlassTheme.ratingAmber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: GlassTheme.ratingAmber,
                              ),
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
                      Icon(
                        Icons.moped,
                        size: 14,
                        color: isFreeDelivery
                            ? GlassTheme.primaryGreen
                            : GlassTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFreeDelivery
                            ? 'Free Delivery'
                            : '\$${deliveryFee.toStringAsFixed(2)} delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isFreeDelivery
                              ? GlassTheme.primaryGreen
                              : GlassTheme.textMuted,
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
