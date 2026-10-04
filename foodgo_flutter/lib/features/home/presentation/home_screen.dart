import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/restaurant_provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/food_delivery_card.dart';
import '../../../widgets/floating_mini_cart_bar.dart';
import '../../../widgets/svg_icon.dart';
import '../../../core/theme/glass_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDeliveryMode = true;
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.restaurant},
    {'name': 'Burgers', 'icon': Icons.lunch_dining},
    {'name': 'Pizza', 'icon': Icons.local_pizza},
    {'name': 'Khmer', 'icon': Icons.soup_kitchen},
    {'name': 'Chicken', 'icon': Icons.set_meal},
    {'name': 'Drinks', 'icon': Icons.local_drink},
    {'name': 'Healthy', 'icon': Icons.eco},
    {'name': 'Desserts', 'icon': Icons.cake},
  ];

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'FREE DELIVERY',
      'subtitle': 'On your orders above \$5',
      'tag': 'Limited Time',
      'code': 'FOODGOFREE',
      'color': GlassTheme.primaryGreenDark,
      'icon': Icons.moped,
    },
    {
      'title': '30% OFF DEALS',
      'subtitle': 'Save big on selected burgers',
      'tag': 'HOT DEAL',
      'code': 'FOODGO30',
      'color': GlassTheme.foodpandaPink,
      'icon': Icons.local_fire_department,
    },
    {
      'title': 'EXPRESS DROPS',
      'subtitle': 'Hot meals delivered in <25 mins',
      'tag': 'FAST TRACK',
      'code': 'EXPRESS',
      'color': GlassTheme.promoBlue,
      'icon': Icons.bolt,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // ── Top Bar: Delivery / Pick-up Switcher + Location ────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Foodpanda-style Delivery / Pickup Pill
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          _buildModePill('Delivery', Icons.moped, _isDeliveryMode, () {
                            setState(() => _isDeliveryMode = true);
                          }),
                          _buildModePill('Pick-up', Icons.shopping_bag_outlined, !_isDeliveryMode, () {
                            setState(() => _isDeliveryMode = false);
                          }),
                        ],
                      ),
                    ),

                    // Map + Notifications Quick Actions
                    Row(
                      children: [
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => context.push('/map'),
                            child: const Icon(Icons.map_outlined, size: 22, color: GlassTheme.primaryGreen),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => context.push('/notifications'),
                            child: const Icon(Icons.notifications_none, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Deliver to Address selector bar
                InkWell(
                  onTap: () => context.push('/addresses'),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: GlassTheme.primaryGreen, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _isDeliveryMode ? 'Deliver to: ' : 'Pick-up near: ',
                        style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                      ),
                      const Text(
                        'Phnom Penh, Cambodia',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 18, color: GlassTheme.primaryGreen),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Search Bar
                InkWell(
                  onTap: () => context.push('/search'),
                  child: const GlassSearchBar(),
                ),
                const SizedBox(height: 20),

                // ── Promotional Carousel (Foodpanda Banner Style) ──────────
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _promoBanners.length,
                    itemBuilder: (context, index) {
                      final promo = _promoBanners[index];
                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (promo['color'] as Color).withValues(alpha: 0.9),
                              (promo['color'] as Color).withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (promo['color'] as Color).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      promo['tag'],
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    promo['title'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    promo['subtitle'],
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(promo['icon'], size: 64, color: Colors.white.withValues(alpha: 0.25)),
                          ],
                        ),
                      ).animate().fade(delay: (100 * index).ms).slideX(begin: 0.2);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Circular Category Badges ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/explore'),
                      child: const Text('See all', style: TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategoryIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedCategoryIndex = index);
                            if (index > 0) context.push('/explore');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? GlassTheme.primaryGreen
                                      : Colors.white.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: GlassTheme.primaryGreen.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  cat['icon'],
                                  color: isSelected ? Colors.white : Colors.white70,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? GlassTheme.primaryGreen : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(delay: (60 * index).ms).slideX();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Featured Deals & Popular Horizontal Section ───────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('Featured Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        SvgAssetIcon(assetName: 'hot_deal', size: 20),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/explore'),
                      child: const Text('See all', style: TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: Consumer<RestaurantProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen));
                      }
                      final restaurants = provider.restaurants;
                      if (restaurants.isEmpty) {
                        return const Center(child: Text("No restaurants found."));
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: FoodDeliveryCard(
                              restaurant: restaurant,
                              isHorizontal: true,
                              onTap: () => context.push('/restaurant/${restaurant["id"]}'),
                            ),
                          ).animate().fade(delay: (100 * index).ms).slideX(begin: 0.2);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── All Restaurants Near You Feed (Vertical List) ─────────
                const Row(
                  children: [
                    Text('All Restaurants Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    SvgAssetIcon(assetName: 'restaurant_pin', size: 20, color: GlassTheme.primaryGreen),
                  ],
                ),
                const SizedBox(height: 14),
                Consumer<RestaurantProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen));
                    }
                    final restaurants = provider.restaurants;
                    if (restaurants.isEmpty) {
                      return const Center(child: Text("No restaurants found."));
                    }

                    return Column(
                      children: restaurants.map((res) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: FoodDeliveryCard(
                            restaurant: res,
                            isHorizontal: false,
                            onTap: () => context.push('/restaurant/${res["id"]}'),
                          ),
                        ).animate().fade().slideY(begin: 0.1);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Sticky Floating Mini-Cart Bar (Foodpanda Style) ────────
          const FloatingMiniCartBar(bottomOffset: 95.0),
        ],
      ),
    );
  }

  Widget _buildModePill(String title, IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? GlassTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
              ? [BoxShadow(color: GlassTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.white60),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
