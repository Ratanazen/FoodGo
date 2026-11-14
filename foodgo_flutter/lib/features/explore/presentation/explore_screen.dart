import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/food_delivery_card.dart';
import '../../../widgets/floating_mini_cart_bar.dart';
import '../../../widgets/svg_icon.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/shimmer_widgets.dart';
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final amberText = isDark ? Colors.amber : const Color(0xFFB45309);
    final surfaceFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.85);
    final surfaceBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : GlassTheme.borderLight;
    final accentIconColor = isDark
        ? GlassTheme.limeAccent
        : const Color(0xFF15803D);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Explore Food & Spots',
        actions: [
          Container(
            decoration: BoxDecoration(
              color: surfaceFill,
              shape: BoxShape.circle,
              border: Border.all(color: surfaceBorder),
            ),
            child: IconButton(
              icon: Icon(Icons.map_outlined, color: accentIconColor, size: 20),
              tooltip: 'View on Google Maps',
              onPressed: () => context.push('/map'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ResponsiveWebContainer(
            maxWidth: 1200,
            child: RefreshIndicator(
              color: accentIconColor,
              onRefresh: () =>
                  context.read<RestaurantProvider>().fetchRestaurants(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Rounded Pill Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceFill,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: surfaceBorder),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: accentIconColor, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              style: textTheme.bodyMedium?.copyWith(
                                color: primaryText,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Search restaurants, cuisines, dishes...',
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: secondaryText,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(
                                  () => _searchQuery = val.trim().toLowerCase(),
                                );
                              },
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: secondaryText,
                              ),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Modern Filter Chips ──────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(_filters.length, (index) {
                          final isSelected = _activeFilterIndex == index;
                          final filter = _filters[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _activeFilterIndex = index);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? GlassTheme.limeAccent
                                      : surfaceFill,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark
                                              ? GlassTheme.limeAccent
                                              : Colors.black12)
                                        : surfaceBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (filter['svg'] != null) ...[
                                      SvgAssetIcon(
                                        assetName: filter['svg'] as String,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.black
                                            : secondaryText,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      filter['label'] as String,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.black
                                            : primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Restaurants Result Count ──────────────────────────────
                    Consumer<RestaurantProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ResponsiveCardGrid(
                              minCardWidth: 320,
                              spacing: 16,
                              runSpacing: 16,
                              children: List.generate(
                                4,
                                (_) =>
                                    const ShimmerFoodCard(isHorizontal: false),
                              ),
                            ),
                          );
                        }

                        var restaurants = provider.restaurants;

                        // Apply search filter
                        if (_searchQuery.isNotEmpty) {
                          restaurants = restaurants.where((r) {
                            final name =
                                r['name']?.toString().toLowerCase() ?? '';
                            final desc =
                                r['description']?.toString().toLowerCase() ??
                                '';
                            return name.contains(_searchQuery) ||
                                desc.contains(_searchQuery);
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
                            final fee =
                                double.tryParse(
                                  r['delivery_fee']?.toString() ?? '0',
                                ) ??
                                0;
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
                            final rate =
                                double.tryParse(
                                  r['rating']?.toString() ?? '0',
                                ) ??
                                0;
                            return rate >= 4.5;
                          }).toList();
                        }

                        if (restaurants.isEmpty) {
                          final hasFilter =
                              _searchQuery.isNotEmpty ||
                              _activeFilterIndex != 0;
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 40.0,
                                bottom: 120.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasFilter
                                        ? Icons.filter_list_off
                                        : Icons.storefront_outlined,
                                    size: 68,
                                    color: secondaryText.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    hasFilter
                                        ? 'No restaurants match this filter'
                                        : 'No restaurants available right now',
                                    textAlign: TextAlign.center,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                    ),
                                    child: Text(
                                      hasFilter
                                          ? 'Try clearing your search term or picking another category filter above.'
                                          : 'Could not connect to the live restaurant server. Check your connection or load the demo menu.',
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: secondaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (hasFilter)
                                    GlassButton(
                                      text: 'Reset Filters',
                                      icon: Icons.refresh,
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _activeFilterIndex = 0;
                                        });
                                      },
                                    )
                                  else
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        GlassButton(
                                          text: 'Retry',
                                          icon: Icons.refresh,
                                          onPressed: () =>
                                              provider.fetchRestaurants(),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              provider.loadDemoFallback(),
                                          icon: Icon(
                                            Icons.restaurant_menu,
                                            color: accentGreen,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Load demo menu',
                                            style: textTheme.labelLarge
                                                ?.copyWith(color: primaryText),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: accentGreen,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (provider.isDemo) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: amberText,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Demo menu — not live availability. '
                                        'Reconnect to FoodGo before ordering.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: amberText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              'Showing ${restaurants.length} restaurants',
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ResponsiveCardGrid(
                              minCardWidth: 320,
                              spacing: 16,
                              runSpacing: 16,
                              children: restaurants.map((restaurant) {
                                return FoodDeliveryCard(
                                  restaurant: restaurant,
                                  isHorizontal: false,
                                  onTap: () => context.push(
                                    '/restaurant/${restaurant["id"]}',
                                  ),
                                ).animate().fade().slideY(begin: 0.1);
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // ── Sticky Floating Mini-Cart Bar ──────────────────────────
          const FloatingMiniCartBar(bottomOffset: 95.0),
        ],
      ),
    );
  }
}
