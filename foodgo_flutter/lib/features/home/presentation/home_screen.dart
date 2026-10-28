import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../providers/restaurant_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../widgets/shimmer_widgets.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/glass/glass_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  String _selectedSort = 'All';
  final bool _showActiveOrderFloater = true;
  int _activeOrderEta = 11;
  Timer? _etaUpdateTimer;

  // Healthy & Organic Quick Categories
  final List<Map<String, dynamic>> _quickCategories = [
    {'name': 'All', 'icon': Icons.restaurant_rounded},
    {'name': 'Salad', 'icon': Icons.eco_rounded},
    {'name': 'Fruit Salad', 'icon': Icons.apple_rounded},
    {'name': 'Healthy Bowls', 'icon': Icons.rice_bowl_rounded},
    {'name': 'Sushi', 'icon': Icons.set_meal_rounded},
    {'name': 'Chicken', 'icon': Icons.kebab_dining_rounded},
  ];
  int _selectedQuickCategoryIndex = 0;

  final List<Map<String, dynamic>> _popularMenuItems = [
    {
      'id': 201,
      'name': 'Garden Fresh Salad',
      'subtitle': 'Crisp greens, avocado & vinaigrette',
      'price': 4.50,
      'image':
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&q=80',
      'category': 'Salad',
      'calories': '180',
      'proteins': '6.0',
      'fats': '9.0',
      'carbo': '14.0',
      'location': 'BKK1, Phnom Penh',
      'description':
          'Crisp romaine lettuce, baby spinach, organic avocado, cherry tomatoes, and cucumber drizzled with extra virgin olive oil vinaigrette.',
      'restaurantId': 201,
      'restaurantName': 'Green Vitality Organics BKK1',
    },
    {
      'id': 202,
      'name': 'Fresh Fruit Salad',
      'subtitle': 'Melon, kiwi, dragon fruit & berries',
      'price': 5.00,
      'image':
          'https://images.unsplash.com/photo-1519996529931-28324d5a630e?w=500&q=80',
      'category': 'Fruit Salad',
      'calories': '150',
      'proteins': '3.0',
      'fats': '1.0',
      'carbo': '32.0',
      'location': 'Daun Penh, Phnom Penh',
      'description':
          'Freshly chopped organic cantaloupe, kiwi, Cambodian sweet mango, dragon fruit, and blueberries with a honey lime drizzle.',
      'restaurantId': 202,
      'restaurantName': 'Fresh Harvest Fruit Bar',
    },
    {
      'id': 203,
      'name': 'Tomato Basil Bowl',
      'subtitle': 'Vine-ripened tomatoes & roasted quinoa',
      'price': 4.00,
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
      'category': 'Healthy Bowls',
      'calories': '210',
      'proteins': '8.0',
      'fats': '5.0',
      'carbo': '28.0',
      'location': 'Toul Kork, Phnom Penh',
      'description':
          'Warm roasted vine tomatoes blended with fresh basil, topped with toasted pine nuts, organic quinoa, and goat cheese crumbles.',
      'restaurantId': 203,
      'restaurantName': 'Botanica Healthy Eats Toul Kork',
    },
    {
      'id': 204,
      'name': 'Salmon Avocado Bowl',
      'subtitle': 'Pan-seared Atlantic salmon & edamame',
      'price': 6.50,
      'image':
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500&q=80',
      'category': 'Salad',
      'calories': '290',
      'proteins': '26.0',
      'fats': '14.0',
      'carbo': '16.0',
      'location': 'Koh Pich, Phnom Penh',
      'description':
          'Pan-seared Atlantic salmon fillet on a bed of seasoned brown rice, organic avocado slices, edamame, and sesame ginger glaze.',
      'restaurantId': 204,
      'restaurantName': 'Ocean Greens Kitchen Koh Pich',
    },
    {
      'id': 205,
      'name': 'Organic Oatmeal Bowl',
      'subtitle': 'Rolled oats, almond butter & berries',
      'price': 3.50,
      'image':
          'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=500&q=80',
      'category': 'Healthy Bowls',
      'calories': '190',
      'proteins': '7.0',
      'fats': '4.5',
      'carbo': '34.0',
      'location': 'BKK2, Phnom Penh',
      'description':
          'Slow-cooked steel cut rolled oats served with organic almond butter, chia seeds, fresh blueberries, and raw honey.',
      'restaurantId': 205,
      'restaurantName': 'Nourish Organic Bowls BKK2',
    },
  ];

  final List<Map<String, dynamic>> _recommendedDishes = [
    {
      'id': 101,
      'name': 'Garden Fresh Salad',
      'subtitle': 'Crisp romaine, avocado & herbs',
      'price': 4.50,
      'image':
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&q=80',
      'category': 'Salad',
      'calories': '180',
      'proteins': '6.0',
      'fats': '9.0',
      'carbo': '14.0',
      'location': 'BKK1, Phnom Penh',
      'description':
          'Crisp romaine lettuce, baby spinach, organic avocado, cherry tomatoes, and cucumber drizzled with extra virgin olive oil vinaigrette.',
      'restaurantId': 201,
      'restaurantName': 'Green Vitality Organics BKK1',
    },
    {
      'id': 102,
      'name': 'Fresh Fruit Salad',
      'subtitle': 'Kiwi, dragon fruit, melon & berries',
      'price': 5.00,
      'image':
          'https://images.unsplash.com/photo-1519996529931-28324d5a630e?w=500&q=80',
      'category': 'Fruit Salad',
      'calories': '150',
      'proteins': '3.0',
      'fats': '1.0',
      'carbo': '32.0',
      'location': 'Daun Penh, Phnom Penh',
      'description':
          'Freshly chopped organic cantaloupe, kiwi, Cambodian sweet mango, dragon fruit, and blueberries with a honey lime drizzle.',
      'restaurantId': 202,
      'restaurantName': 'Fresh Harvest Fruit Bar',
    },
    {
      'id': 103,
      'name': 'Tomato Basil Bowl',
      'subtitle': 'Roasted tomatoes & warm quinoa',
      'price': 4.00,
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
      'category': 'Healthy Bowls',
      'calories': '210',
      'proteins': '8.0',
      'fats': '5.0',
      'carbo': '28.0',
      'location': 'Toul Kork, Phnom Penh',
      'description':
          'Warm roasted vine tomatoes blended with fresh basil, topped with toasted pine nuts, organic quinoa, and goat cheese crumbles.',
      'restaurantId': 203,
      'restaurantName': 'Botanica Healthy Eats Toul Kork',
    },
    {
      'id': 104,
      'name': 'Salmon Avocado Bowl',
      'subtitle': 'Pan-seared Atlantic salmon & rice',
      'price': 6.50,
      'image':
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500&q=80',
      'category': 'Sushi',
      'calories': '290',
      'proteins': '26.0',
      'fats': '14.0',
      'carbo': '16.0',
      'location': 'Koh Pich, Phnom Penh',
      'description':
          'Pan-seared Atlantic salmon fillet on a bed of seasoned brown rice, organic avocado slices, edamame, and sesame ginger glaze.',
      'restaurantId': 204,
      'restaurantName': 'Ocean Greens Kitchen Koh Pich',
    },
    {
      'id': 105,
      'name': 'Golden Herb Chicken',
      'subtitle': 'Herb roasted breast & greens',
      'price': 5.50,
      'image':
          'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&q=80',
      'category': 'Chicken',
      'calories': '240',
      'proteins': '32.0',
      'fats': '8.0',
      'carbo': '10.0',
      'location': 'Daun Penh, Phnom Penh',
      'description':
          'Tender pasture-raised chicken breast marinated with rosemary and thyme, oven roasted and served with steamed broccoli and lemon tahini dressing.',
      'restaurantId': 101,
      'restaurantName': 'Daun Penh Organic Kitchen',
    },
    {
      'id': 106,
      'name': 'Organic Oatmeal Bowl',
      'subtitle': 'Rolled oats, almond butter & berries',
      'price': 3.50,
      'image':
          'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=500&q=80',
      'category': 'Healthy Bowls',
      'calories': '190',
      'proteins': '7.0',
      'fats': '4.5',
      'carbo': '34.0',
      'location': 'BKK2, Phnom Penh',
      'description':
          'Slow-cooked steel cut rolled oats served with organic almond butter, chia seeds, fresh blueberries, and raw honey.',
      'restaurantId': 205,
      'restaurantName': 'Nourish Organic Bowls BKK2',
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.restaurant_rounded},
    {'name': 'Burger', 'icon': Icons.lunch_dining_rounded},
    {'name': 'Pizza', 'icon': Icons.local_pizza_rounded},
    {'name': 'Sushi', 'icon': Icons.set_meal_rounded},
    {'name': 'Chicken', 'icon': Icons.kebab_dining_rounded},
    {'name': 'Drinks', 'icon': Icons.local_drink_rounded},
    {'name': 'Dessert', 'icon': Icons.cake_rounded},
  ];

  final List<Map<String, dynamic>> _deals = [
    {
      'label': 'YOUR WHOLE ORDER',
      'discount': '30% OFF',
      'code': 'FOODIE30',
      'imageUrl':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
    },
    {
      'label': 'DELIVERY FEE',
      'discount': 'FREE',
      'code': 'FREESHIP',
      'imageUrl':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
    },
    {
      'label': 'BURGER SPECIAL',
      'discount': '20% OFF',
      'code': 'BURGER20',
      'imageUrl':
          'https://images.unsplash.com/photo-1550547660-d9450f859349?w=400&q=80',
    },
  ];

  final List<Map<String, dynamic>> _fastDeliveryRestaurants = [
    {
      'id': 101,
      'name': 'Tealive - BKK1 Phnom Penh',
      'discount': '5% OFF',
      'rating': 4.6,
      'timeMin': 10,
      'distanceKm': 0.6,
      'imageUrl':
          'https://images.unsplash.com/photo-1558857563-b371033873b8?w=400&q=80',
    },
    {
      'id': 102,
      'name': 'KFC - Norodom Boulevard',
      'discount': '20% OFF',
      'rating': 4.5,
      'timeMin': 15,
      'distanceKm': 0.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1513639776629-7b61b0ac49cb?w=400&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulate live dynamic ETA countdown (from 11 min down to 9 min like in video)
    _etaUpdateTimer = Timer.periodic(const Duration(seconds: 12), (t) {
      if (!mounted) return;
      setState(() {
        if (_activeOrderEta > 8) {
          _activeOrderEta--;
        }
      });
    });
  }

  @override
  void dispose() {
    _etaUpdateTimer?.cancel();
    super.dispose();
  }

  void _claimCoupon(String code) {
    final cart = context.read<CartProvider>();
    final applied = cart.applyPromoCode(code);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              applied
                  ? 'Coupon $code claimed! Applied to your cart.'
                  : 'Coupon $code ready for checkout!',
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Stack(
            children: [
              RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () =>
                    context.read<RestaurantProvider>().fetchRestaurants(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── 1. Top Modern Location Header (Search | Location | Notification) ──
                    SliverToBoxAdapter(
                      child: _buildModernLocationHeader(context, isDark)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(
                            begin: -0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                    ),

                    // ── 2. Content Body with Hero & Categories ─────────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),

                          // ── Hero Promo: 50% OFF Your First Healthy Meal! ───
                          _buildFastAndFreeHeroPromo(context, isDark)
                              .animate()
                              .fadeIn(duration: 450.ms, delay: 100.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 22),

                          // ── Popular Menu Section ──────────────────────────
                          _buildSectionHeader(
                            'Popular Menu',
                            () => context.push('/explore'),
                          ),
                          const SizedBox(height: 12),
                          _buildPopularMenuHorizontal(isDark)
                              .animate()
                              .fadeIn(duration: 450.ms, delay: 150.ms)
                              .slideX(
                                begin: 0.05,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 22),

                          // ── Categories Section Header ("Categories" | "See All") ──
                          _buildSectionHeader(
                            'Categories',
                            () => context.push('/explore'),
                          ),
                          const SizedBox(height: 12),

                          // ── Quick Categories: All, Salad, Fruit Salad, etc. ──
                          _buildModernFourCategories(isDark)
                              .animate()
                              .fadeIn(duration: 450.ms, delay: 180.ms)
                              .slideX(
                                begin: 0.05,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 24),

                          // ── "Recomended" Section Header ───────────────────
                          _buildRecommendedHeader(
                            context,
                            isDark,
                          ).animate().fadeIn(duration: 400.ms, delay: 240.ms),
                          const SizedBox(height: 14),
                        ]),
                      ),
                    ),

                    // ── 3. 2-Column Recommended Dishes Grid ────────────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: _buildRecommendedGrid(context, isDark),
                    ),

                    // ── 4. Deals For You & Fast Delivery ───────────────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            'Deals for you',
                            () => context.push('/explore'),
                          ),
                          const SizedBox(height: 12),
                          _buildDealsList(isDark),
                          const SizedBox(height: 24),

                          _buildFastDeliverySection(isDark),
                          const SizedBox(height: 24),

                          _buildSectionHeader(
                            'Restaurants near you',
                            () => context.push('/explore'),
                          ),
                          const SizedBox(height: 8),

                          // Sorting filter chips
                          _buildSortingChips(isDark),
                          const SizedBox(height: 14),
                        ]),
                      ),
                    ),

                    // ── 5. Full Restaurant Catalog Grid ────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: _buildRestaurantGrid(context, isDark),
                    ),

                    // Bottom footer on web or spacer on mobile
                    if (ResponsiveBreakpoints.isWide(context))
                      const SliverToBoxAdapter(child: WebFooter())
                    else
                      const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
              ),

              // ── Sticky Floating Active Order Floater ──
              if (_showActiveOrderFloater)
                _buildFloatingActiveOrder(context, isDark)
                    .animate()
                    .fadeIn(duration: 450.ms, delay: 350.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────
  // 1. Lush Green Delivery Curved Header & Search Bar (TikTok Reference Style)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildModernLocationHeader(BuildContext context, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    final activeAddress = context.watch<AddressProvider>().selectedAddress;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final avatarUrl = user?['avatar_url'] ?? user?['avatar'];
    final username = (user?['first_name'] as String?)?.isNotEmpty == true
        ? user!['first_name'] as String
        : (user?['username'] as String? ?? 'Foodie');
    final String locationName =
        (activeAddress?.city.isNotEmpty == true &&
            activeAddress?.street.isNotEmpty == true)
        ? '${activeAddress!.street}, ${activeAddress.city}'
        : (activeAddress?.city.isNotEmpty == true
              ? activeAddress!.city
              : 'Phnom Penh, Cambodia');

    return Container(
      color: isDark ? GlassTheme.surfaceDark : Colors.white,
      padding: EdgeInsets.only(
        top: topPadding + 10,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        children: [
          // Top Row: Location on Left, Notification & Profile Avatar on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Location Icon + "Your Location" + City dropdown
              AnimatedPressable(
                pressedScale: 0.96,
                onTap: () => context.push('/addresses'),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: GlassTheme.lightGreenSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: GlassTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Location',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              locationName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF374151),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Notification Bell & Profile Avatar
              Row(
                children: [
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, child) {
                      final unread = notifProvider.unreadCount;
                      return AnimatedPressable(
                        onTap: () => context.push('/notifications'),
                        pressedScale: 0.92,
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                size: 20,
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedPressable(
                    onTap: () => context.push('/profile'),
                    pressedScale: 0.92,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GlassTheme.primaryGreen,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            avatarUrl != null && avatarUrl.toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl.toString(),
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Container(
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: GlassTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                errorWidget: (ctx, url, err) => Container(
                                  color: GlassTheme.lightGreenSurface,
                                  alignment: Alignment.center,
                                  child: Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : 'F',
                                    style: const TextStyle(
                                      color: GlassTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: GlassTheme.lightGreenSurface,
                                alignment: Alignment.center,
                                child: Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : 'F',
                                  style: const TextStyle(
                                    color: GlassTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Second Row: Rounded Clean Pill Search Bar
          AnimatedPressable(
            pressedScale: 0.98,
            onTap: () => context.push('/search'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2922)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search food...',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.tune_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. 50% OFF Healthy Promo Hero Card
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFastAndFreeHeroPromo(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Left: Promo Texts & Buy Now button
          Positioned(
            left: 20,
            top: 18,
            bottom: 18,
            right: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '50% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your First Healthy Meal!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                AnimatedPressable(
                  onTap: () => _claimCoupon('HEALTHY50'),
                  pressedScale: 0.94,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buy Now',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF16A34A),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Large Appetizing Circular Salad Bowl
          Positioned(
            right: 12,
            top: 12,
            bottom: 12,
            child: Center(
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&q=80',
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      color: Colors.white24,
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Popular Menu Horizontal Carousel (Mockup Style)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPopularMenuHorizontal(bool isDark) {
    return SizedBox(
      height: 215,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _popularMenuItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = _popularMenuItems[index];
          final favoritesProvider = context.watch<FavoritesProvider>();
          final isFav = favoritesProvider.isFoodFavorite(item['id'] as int);

          return AnimatedPressable(
            pressedScale: 0.96,
            onTap: () => context.push('/food-details', extra: item),
            child: Container(
              width: 165,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular image with top-right green heart button
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: item['image'] as String,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.eco,
                                  color: GlassTheme.primaryGreen,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: AnimatedPressable(
                          pressedScale: 0.82,
                          onTap: () => favoritesProvider.toggleFoodItem(item),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isFav
                                  ? const Color(0xFFDCFCE7)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : const Color(0xFFF3F4F6)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isFav
                                  ? GlassTheme.primaryGreen
                                  : (isDark
                                        ? Colors.white60
                                        : const Color(0xFF9CA3AF)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Item Name
                  Text(
                    item['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Rating row
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• 15 min',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Green Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$${(item['price'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: GlassTheme.primaryGreen,
                        ),
                      ),
                      AnimatedPressable(
                        pressedScale: 0.88,
                        onTap: () {
                          context.read<CartProvider>().addItem(
                            item['id'] as int,
                            item['name'] as String,
                            item['price'] as double,
                            item['image'] as String,
                          );
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item['name']} added to cart!'),
                              backgroundColor: GlassTheme.primaryGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: GlassTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Categories Horizontal Carousel (All, Burger, Pizza, Sushi, Chicken)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildModernFourCategories(bool isDark) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _quickCategories[index];
          final isSelected = _selectedQuickCategoryIndex == index;

          return AnimatedPressable(
            pressedScale: 0.93,
            onTap: () {
              setState(() {
                if (_selectedQuickCategoryIndex == index) {
                  _selectedQuickCategoryIndex = 0;
                } else {
                  _selectedQuickCategoryIndex = index;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? GlassTheme.surfaceCardDark : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE5E7EB)),
                  width: isSelected ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: isSelected ? 10 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 28,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF444444)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF616161)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. "Recomended" Section Header (Mockup Style)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendedHeader(BuildContext context, bool isDark) {
    return _buildSectionHeader('Recomended', () => context.push('/explore'));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. Recommended Dishes 2-Column Grid (Direct /food-details Navigation)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendedGrid(BuildContext context, bool isDark) {
    var list = _recommendedDishes;
    final selectedCat =
        _quickCategories[_selectedQuickCategoryIndex]['name'] as String;
    if (selectedCat != 'All') {
      final filtered = list.where((d) => d['category'] == selectedCat).toList();
      if (filtered.isNotEmpty) {
        list = filtered;
      }
    }

    if (_selectedSort == r'$') {
      final priceFiltered = list
          .where((d) => (d['price'] as double) <= 4.00)
          .toList();
      if (priceFiltered.isNotEmpty) list = priceFiltered;
    } else if (_selectedSort == r'$$') {
      final priceFiltered = list
          .where(
            (d) =>
                (d['price'] as double) > 4.00 && (d['price'] as double) <= 5.50,
          )
          .toList();
      if (priceFiltered.isNotEmpty) list = priceFiltered;
    } else if (_selectedSort == r'$$$') {
      final priceFiltered = list
          .where((d) => (d['price'] as double) > 5.50)
          .toList();
      if (priceFiltered.isNotEmpty) list = priceFiltered;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1100
        ? 4
        : (screenWidth >= 700 ? 3 : 2);
    final double childAspectRatio = screenWidth >= 1100
        ? 0.80
        : (screenWidth >= 700 ? 0.78 : (screenWidth < 370 ? 0.70 : 0.72));

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = list[index];
        final favoritesProvider = context.watch<FavoritesProvider>();
        final isFav = favoritesProvider.isFoodFavorite(item['id']);

        return AnimatedPressable(
              pressedScale: 0.97,
              onTap: () => context.push('/food-details', extra: item),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Favorite Heart Button in top right
                    Align(
                      alignment: Alignment.topRight,
                      child: AnimatedPressable(
                        pressedScale: 0.8,
                        onTap: () => favoritesProvider.toggleFoodItem(item),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isFav
                                ? const Color(0xFFDCFCE7)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFF3F4F6)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFav
                                ? GlassTheme.primaryGreen
                                : (isDark
                                      ? Colors.white60
                                      : const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                    ),

                    // Centered Circular Dish Image
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: item['image'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.eco,
                                  size: 32,
                                  color: GlassTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Item Name
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Subtitle
                    Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF8E8E93),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Green Price & '+' Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${(item['price'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                            Text(
                              KhmerCurrency.formatKhr(item['price'] as double),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        AnimatedPressable(
                          pressedScale: 0.88,
                          onTap: () {
                            context.read<CartProvider>().addItem(
                              item['id'] as int,
                              item['name'] as String,
                              item['price'] as double,
                              item['image'] as String,
                            );
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${item['name']} added to cart!',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: GlassTheme.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: Colors.white,
                                  onPressed: () => context.push('/cart'),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: GlassTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 350.ms, delay: (index * 50).ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
      }, childCount: list.length),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Deals For You Horizontal Carousel with Coupon Claim Button
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDealsList(bool isDark) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _deals.length,
        itemBuilder: (context, index) {
          final deal = _deals[index];

          return Container(
            width: 290,
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? GlassTheme.surfaceCardDark
                  : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.16),
                  blurRadius: 12,
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
                      Text(
                        deal['label'] ?? 'YOUR WHOLE ORDER',
                        style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        deal['discount'] ?? '30% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF3A3A3C),
                              ),
                            ),
                            child: Text(
                              deal['code'] ?? 'FOODIE30',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedPressable(
                            pressedScale: 0.93,
                            onTap: () => _claimCoupon(deal['code']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Claim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: deal['imageUrl'],
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Fast Delivery: 20 min or less (TikTok Signature Section)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFastDeliverySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fast delivery · 20 min or less',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _fastDeliveryRestaurants.length,
            itemBuilder: (context, index) {
              final item = _fastDeliveryRestaurants[index];
              return Container(
                width: 175,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: item['imageUrl'],
                            height: 85,
                            width: 175,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['discount'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFB300),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${item['rating']} · ${item['timeMin']} min · ${item['distanceKm']} km',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: GlassTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sorting Filter Chips
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSortingChips(bool isDark) {
    const sorts = [
      {'name': 'All', 'icon': null},
      {'name': 'Top Rated', 'icon': Icons.star_rounded},
      {'name': 'Fastest', 'icon': Icons.bolt_rounded},
      {'name': 'Free Delivery', 'icon': Icons.delivery_dining_rounded},
      {'name': r'$', 'icon': Icons.attach_money_rounded},
      {'name': r'$$', 'icon': Icons.payments_outlined},
      {'name': r'$$$', 'icon': Icons.workspace_premium_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sorts.map((item) {
          final sort = item['name'] as String;
          final icon = item['icon'] as IconData?;
          final isSelected = _selectedSort == sort;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: icon != null
                  ? Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF444444)),
                    )
                  : null,
              label: Text(sort),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedSort = sort),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF444444)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2-Column Restaurant Grid (Matching TikTok Video 2-Col Layout)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRestaurantGrid(BuildContext context, bool isDark) {
    return Consumer<RestaurantProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final int crossAxisCount = screenWidth >= 1100
            ? 4
            : (screenWidth >= 700 ? 3 : 2);
        final double childAspectRatio = screenWidth >= 1100
            ? 0.84
            : (screenWidth >= 700 ? 0.80 : (screenWidth < 370 ? 0.70 : 0.74));

        if (provider.isLoading) {
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ShimmerFoodCard(isHorizontal: false),
              childCount: crossAxisCount * 2,
            ),
          );
        }

        var restaurants = List<Map<String, dynamic>>.from(provider.restaurants);

        // Filter by category if not 'All'
        if (_selectedCategoryIndex > 0) {
          final catName = _categories[_selectedCategoryIndex]['name']
              .toString()
              .toLowerCase();
          restaurants = restaurants.where((r) {
            final name = (r['name']?.toString() ?? '').toLowerCase();
            final desc = (r['description']?.toString() ?? '').toLowerCase();
            return name.contains(catName) || desc.contains(catName);
          }).toList();
        }

        // Apply sorting & price tier filtering
        if (_selectedSort == 'Top Rated') {
          restaurants.sort(
            (a, b) => (double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0)
                .compareTo(
                  double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0,
                ),
          );
        } else if (_selectedSort == 'Fastest') {
          restaurants.sort(
            (a, b) =>
                (int.tryParse(a['delivery_time_min']?.toString() ?? '99') ?? 99)
                    .compareTo(
                      int.tryParse(
                            b['delivery_time_min']?.toString() ?? '99',
                          ) ??
                          99,
                    ),
          );
        } else if (_selectedSort == 'Free Delivery') {
          restaurants = restaurants
              .where(
                (r) =>
                    (double.tryParse(r['delivery_fee']?.toString() ?? '1') ??
                        1.0) ==
                    0.0,
              )
              .toList();
        } else if (_selectedSort == r'$') {
          restaurants = restaurants
              .where(
                (r) =>
                    (double.tryParse(r['delivery_fee']?.toString() ?? '1') ??
                        1.0) <=
                    1.50,
              )
              .toList();
        } else if (_selectedSort == r'$$') {
          restaurants = restaurants.where((r) {
            final fee =
                double.tryParse(r['delivery_fee']?.toString() ?? '1') ?? 1.0;
            final rating =
                double.tryParse(r['rating']?.toString() ?? '0') ?? 0.0;
            return fee <= 2.50 && rating >= 4.0;
          }).toList();
        } else if (_selectedSort == r'$$$') {
          restaurants = restaurants.where((r) {
            final rating =
                double.tryParse(r['rating']?.toString() ?? '0') ?? 0.0;
            return rating >= 4.5;
          }).toList();
        }

        if (restaurants.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No restaurants match this category.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryIndex = 0;
                          _selectedSort = 'All';
                        });
                        provider.fetchRestaurants();
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Reset Filter',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final res = restaurants[index];
            return _buildModernRestaurantCard(context, res, isDark, index);
          }, childCount: restaurants.length),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Modern Restaurant Card (2-Column Card with Discount Pill & Brand Logo)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildModernRestaurantCard(
    BuildContext context,
    Map<String, dynamic> res,
    bool isDark,
    int index,
  ) {
    final id = res['id'];
    final name = res['name']?.toString() ?? 'Restaurant';
    final banner = res['banner']?.toString();
    final rating = double.tryParse(res['rating']?.toString() ?? '4.6') ?? 4.6;
    final timeMin = res['delivery_time_min'] ?? 15;
    final fee =
        double.tryParse(res['delivery_fee']?.toString() ?? '1.0') ?? 1.0;
    final distanceKm = 0.6 + (index * 0.4);

    final String discountText = (index % 3 == 0)
        ? '20% OFF'
        : (index % 3 == 1)
        ? '15% OFF'
        : '25% OFF';

    final String fallbackBanner = (index % 2 == 0)
        ? 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80'
        : 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80';
    final effectiveBanner = (banner != null && banner.isNotEmpty)
        ? banner
        : fallbackBanner;

    final isFavorite = context.watch<FavoritesProvider>().isRestaurantFavorite(
      id,
    );

    return AnimatedPressable(
      pressedScale: 0.97,
      onTap: () => context.push('/restaurant/$id'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Discount Tag & Brand Logo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: effectiveBanner,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 110,
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    errorWidget: (context, url, error) => CachedNetworkImage(
                      imageUrl: fallbackBanner,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Top-Left Discount Pill
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      discountText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // Top-Right Brand Logo Chip
                Positioned(top: 8, right: 8, child: _buildBrandLogo(name)),

                // Favorite Button bottom-right of image
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: AnimatedPressable(
                    pressedScale: 0.8,
                    onTap: () =>
                        context.read<FavoritesProvider>().toggleRestaurant(res),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFFFF5252)
                            : Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Restaurant Title & Metadata
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF222222),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Rating • Delivery Time • Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFB300),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF444444),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          ' • ${timeMin}m • ${distanceKm.toStringAsFixed(1)}km',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF757575),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Dual Currency Delivery Fee
                  Text(
                    fee == 0.0
                        ? 'Free Delivery'
                        : 'Delivery ${KhmerCurrency.formatDualApprox(fee)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: fee == 0.0
                          ? Theme.of(context).colorScheme.primary
                          : GlassTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Brand Logo Helper (McDonald's, KFC, Domino's, Pizza Hut, etc.)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBrandLogo(String name) {
    final lower = name.toLowerCase();
    String? letter;
    Color bg = Colors.white;
    Color fg = Colors.red;

    if (lower.contains('mcdonald')) {
      letter = 'M';
      bg = const Color(0xFFFFC72C);
      fg = const Color(0xFFDA291C);
    } else if (lower.contains('kfc')) {
      letter = 'KFC';
      bg = const Color(0xFFA3080C);
      fg = Colors.white;
    } else if (lower.contains('domino')) {
      letter = 'D';
      bg = const Color(0xFF006491);
      fg = Colors.white;
    } else if (lower.contains('pizza')) {
      letter = 'PH';
      bg = const Color(0xFFEE3124);
      fg = Colors.white;
    } else if (lower.contains('tealive')) {
      letter = 'T';
      bg = const Color(0xFF5B2C6F);
      fg = Colors.white;
    } else {
      letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'F';
      bg = Colors.white;
      fg = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: fg,
          fontSize: letter.length > 2 ? 8 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Floating Persistent Active Order Floater (Docked above bottom nav)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFloatingActiveOrder(BuildContext context, bool isDark) {
    final notifs = context.watch<NotificationProvider>().orderNotifications;
    // Only show floater if an order is actively in transit (exclude delivered orders)
    final activeNotif = notifs.where((n) {
      final t = n.title.toLowerCase();
      final m = n.message.toLowerCase();
      return !t.contains('delivered') && !m.contains('delivered');
    }).firstOrNull;

    if (activeNotif == null) {
      return const SizedBox.shrink();
    }

    final activeOrderId = activeNotif.orderId?.toString() ?? '1024';
    final courierTitle = activeNotif.title;
    final courierSub =
        '${activeNotif.data['restaurant_name'] ?? 'FoodGo'} • Arriving in ${_activeOrderEta}m';

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;

    return Positioned(
      bottom: isWide ? 32 : 96,
      left: isWide ? null : 16,
      right: isWide ? 24 : 16,
      width: isWide ? 420 : null,
      child: AnimatedPressable(
        pressedScale: 0.98,
        onTap: () => context.push('/map/$activeOrderId'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : const Color(0xFFE0E0E0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Driver Avatar
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=160&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      courierTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      courierSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Stacked ETA Green Badge (TikTok Reference Style)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? GlassTheme.deepSmalt.withValues(alpha: 0.45)
                      : GlassTheme.paleSmalt.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_activeOrderEta',
                      style: TextStyle(
                        color: isDark
                            ? GlassTheme.paleSmalt
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'min',
                      style: TextStyle(
                        color: isDark
                            ? GlassTheme.paleSmalt
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Common Section Header with Green "See All"
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        AnimatedPressable(
          pressedScale: 0.92,
          onTap: onSeeAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
