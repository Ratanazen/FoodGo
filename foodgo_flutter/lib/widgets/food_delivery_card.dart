import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/app_icons.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/glass_theme.dart';
import '../core/utils/khmer_currency.dart';
import '../providers/favorites_provider.dart';
import 'glass/animated_pressable.dart';
import 'shimmer_widgets.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: widget.onTap,
      pressedScale: 0.985,
      hoverScale: 1.01,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: isDark ? GlassTheme.dynamicSurfaceCardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? GlassTheme.dynamicBorderDark
                : GlassTheme.borderLight,
            width: 1.1,
          ),
          boxShadow: [GlassTheme.dynamicSoftShadow(isDark: isDark)],
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
                        placeholder: (context, url) => ShimmerBox(
                          width: double.infinity,
                          height: imageHeight,
                          borderRadius: 0,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.withValues(alpha: 0.15),
                          child: const Icon(
                            AppIcons.restaurants,
                            color: GlassTheme.textMuted,
                            size: 40,
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
                          isFreeDelivery ? AppIcons.delivery : AppIcons.offers,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFreeDelivery ? 'Free Delivery' : '20% OFF Deals',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
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
                            backgroundColor: GlassTheme.dynamicSurfaceDark,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          isFavorite
                              ? AppIcons.favorite
                              : AppIcons.favoriteBorder,
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
                          AppIcons.eta,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$minTime-$maxTime min',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTypography.primaryTextColor(
                                      Theme.of(context).brightness,
                                    ),
                                  ),
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? GlassTheme.ratingAmber.withValues(alpha: 0.16)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.star,
                              size: 12,
                              color: isDark
                                  ? GlassTheme.ratingAmber
                                  : const Color(0xFFB45309),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? GlassTheme.ratingAmber
                                        : const Color(0xFFB45309),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTypography.secondaryTextColor(
                        Theme.of(context).brightness,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),

                  // Delivery Fee Tag
                  Row(
                    children: [
                      Icon(
                        AppIcons.delivery,
                        size: 14,
                        color: isFreeDelivery
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? GlassTheme.primaryGreen
                                  : GlassTheme.primaryGreenDark)
                            : AppTypography.secondaryTextColor(
                                Theme.of(context).brightness,
                              ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isFreeDelivery
                              ? 'Free Delivery'
                              : '${KhmerCurrency.formatDual(deliveryFee)} delivery',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isFreeDelivery
                                    ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? GlassTheme.primaryGreen
                                          : GlassTheme.primaryGreenDark)
                                    : AppTypography.secondaryTextColor(
                                        Theme.of(context).brightness,
                                      ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '15% OFF \$10+',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? GlassTheme.foodpandaPink
                              : const Color(0xFFBE185D),
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
