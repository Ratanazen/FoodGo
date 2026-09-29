import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/food_delivery_card.dart';
import '../../../widgets/floating_mini_cart_bar.dart';
import '../../../widgets/svg_icon.dart';
import '../../../providers/restaurant_provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _activeFilterIndex = 0;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'svg': null},
    {'label': 'Hot Deals', 'svg': 'hot_deal'},
    {'label': 'Free Delivery', 'svg': 'delivery_bike'},
    {'label': 'Under 25 min', 'svg': 'lightning'},
    {'label': 'Top Rated 4.5+', 'svg': 'star'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Explore Food & Spots',
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: GlassTheme.primaryGreen),
            tooltip: 'View on Google Maps',
            onPressed: () => context.push('/map'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input with clear button
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: GlassTheme.primaryGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search restaurants, cuisines, dishes...',
                            hintStyle: TextStyle(color: GlassTheme.textMuted, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val.trim().toLowerCase());
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filter Chips (Foodpanda & Grab style) ──────────────────
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final isSelected = _activeFilterIndex == index;
                      final filter = _filters[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => setState(() => _activeFilterIndex = index),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? GlassTheme.primaryGreen
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (filter['svg'] != null) ...[
                                  SvgAssetIcon(
                                    assetName: filter['svg'] as String,
                                    size: 14,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  filter['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Restaurants Result Count ──────────────────────────────
                Consumer<RestaurantProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen)),
                      );
                    }

                    var restaurants = provider.restaurants;

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      restaurants = restaurants.where((r) {
                        final name = r['name']?.toString().toLowerCase() ?? '';
                        final desc = r['description']?.toString().toLowerCase() ?? '';
                        return name.contains(_searchQuery) || desc.contains(_searchQuery);
                      }).toList();
                    }

                    // Apply chip filters
                    if (_activeFilterIndex == 1) {
                      // Hot Deals
                      restaurants = restaurants.where((r) {
                        return (r['id'] as int? ?? 0) % 2 == 1;
                      }).toList();
                    } else if (_activeFilterIndex == 2) {
                      // Free Delivery
                      restaurants = restaurants.where((r) {
                        final fee = double.tryParse(r['delivery_fee']?.toString() ?? '0') ?? 0;
                        return fee <= 0.0 || (r['id'] as int? ?? 0) == 1;
                      }).toList();
                    } else if (_activeFilterIndex == 3) {
                      // Under 25 min
                      restaurants = restaurants.where((r) {
                        final max = r['delivery_time_max'] ?? 30;
                        return max <= 25;
                      }).toList();
                    } else if (_activeFilterIndex == 4) {
                      // Top Rated 4.5+
                      restaurants = restaurants.where((r) {
                        final rate = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
                        return rate >= 4.5;
                      }).toList();
                    }

                    if (restaurants.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text('No restaurants match this filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text('Try clearing search or selecting another category.', style: TextStyle(color: GlassTheme.textMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Showing ${restaurants.length} restaurants',
                          style: TextStyle(color: GlassTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...restaurants.map((restaurant) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: FoodDeliveryCard(
                              restaurant: restaurant,
                              isHorizontal: false,
                              onTap: () => context.push('/restaurant/${restaurant["id"]}'),
                            ),
                          ).animate().fade().slideY(begin: 0.1);
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ── Sticky Floating Mini-Cart Bar ──────────────────────────
          const FloatingMiniCartBar(bottomOffset: 95.0),
        ],
      ),
    );
  }
}
