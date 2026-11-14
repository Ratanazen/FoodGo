import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/food_delivery_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final textTheme = Theme.of(context).textTheme;
    final accentColor = isDark
        ? GlassTheme.limeAccent
        : GlassTheme.primaryGreenDark;
    final favorites = context.watch<FavoritesProvider>();
    final restaurants = favorites.favoriteRestaurants;
    final foods = favorites.favoriteFoodItems;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Favorites (${favorites.totalFavoritesCount})',
          leading: Navigator.of(context).canPop()
              ? AnimatedPressable(
                  pressedScale: 0.9,
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: primaryText,
                      ),
                    ),
                  ),
                )
              : null,
          bottom: TabBar(
            indicatorColor: accentColor,
            indicatorWeight: 3,
            labelColor: accentColor,
            unselectedLabelColor: secondaryText,
            labelStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'Restaurants (${restaurants.length})'),
              Tab(text: 'Food Items (${foods.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Restaurants
            restaurants.isEmpty
                ? _buildEmptyState(
                    context,
                    title: 'No Favorite Restaurants Yet',
                    subtitle:
                        'Tap the heart icon on any restaurant card to save your favorite spots here for fast ordering.',
                    buttonText: 'Explore Restaurants',
                    onAction: () => context.go('/explore'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final res = restaurants[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: FoodDeliveryCard(
                          restaurant: res,
                          onTap: () {
                            final id = res['id'];
                            if (id != null) context.push('/restaurant/$id');
                          },
                        ),
                      ).animate().fade(delay: (50 * index).ms).slideY();
                    },
                  ),

            // Tab 2: Food Items
            foods.isEmpty
                ? _buildEmptyState(
                    context,
                    title: 'No Favorite Foods Yet',
                    subtitle:
                        'Save specific dishes and treats you love so you can re-order them in seconds.',
                    buttonText: 'Discover Food',
                    onAction: () => context.go('/home'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final item = foods[index];
                      final name = item['name']?.toString() ?? 'Delicious Food';
                      final price =
                          double.tryParse(item['price']?.toString() ?? '0') ??
                          0.0;
                      final imgUrl = item['image_url']?.toString() ?? '';
                      final desc = item['description']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? GlassTheme.surfaceCardDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imgUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imgUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) => Container(
                                          width: 70,
                                          height: 70,
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black12,
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: GlassTheme.textMuted,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                        child: const Icon(
                                          Icons.fastfood,
                                          color: GlassTheme.textMuted,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: primaryText,
                                      ),
                                      maxLines: 2,
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        desc,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: secondaryText,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      '\$${price.toStringAsFixed(2)}',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: isDark
                                            ? GlassTheme.limeAccentBright
                                            : const Color(0xFF15803D),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: GlassTheme.foodpandaPink,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await favorites.toggleFoodItem(item);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Removed $name from Favorites',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: GlassTheme.surfaceDark,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              AnimatedPressable(
                                pressedScale: 0.88,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final cart = context.read<CartProvider>();
                                  final id =
                                      int.tryParse(
                                        item['id']?.toString() ?? '0',
                                      ) ??
                                      0;
                                  final restId =
                                      int.tryParse(
                                        item['restaurant_id']?.toString() ??
                                            item['restaurantId']?.toString() ??
                                            item['restaurant']?.toString() ??
                                            '',
                                      ) ??
                                      1;
                                  final restName =
                                      item['restaurant_name']?.toString() ??
                                      item['restaurantName']?.toString() ??
                                      'FoodGo Kitchen';
                                  cart.addItem(
                                    id,
                                    name,
                                    price,
                                    imgUrl,
                                    restaurantId: restId,
                                    restaurantName: restName,
                                  );
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added $name to cart!'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        textColor: isDark
                                            ? GlassTheme.limeAccent
                                            : Colors.white,
                                        onPressed: () => context.push('/cart'),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: GlassTheme.limeAccent,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(delay: (40 * index).ms).slideX();
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onAction,
  }) {
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: GlassTheme.foodpandaPink.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: GlassTheme.foodpandaPink.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 48,
                color: GlassTheme.foodpandaPink,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: AppTypography.primaryTextColor(brightness),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: AppTypography.secondaryTextColor(brightness),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: GlassButton(
                text: buttonText,
                icon: Icons.restaurant_menu,
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
