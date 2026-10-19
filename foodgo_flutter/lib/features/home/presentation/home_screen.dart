import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../providers/restaurant_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../widgets/shimmer_widgets.dart';

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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'emoji': '🍽️', 'icon': Icons.restaurant},
    {'name': 'Burger', 'emoji': '🍔', 'icon': Icons.lunch_dining},
    {'name': 'Pizza', 'emoji': '🍕', 'icon': Icons.local_pizza},
    {'name': 'Sushi', 'emoji': '🍣', 'icon': Icons.set_meal},
    {'name': 'Chicken', 'emoji': '🍗', 'icon': Icons.egg_alt},
    {'name': 'Drinks', 'emoji': '🧋', 'icon': Icons.local_drink},
    {'name': 'Dessert', 'emoji': '🍰', 'icon': Icons.cake},
  ];

  final List<Map<String, dynamic>> _deals = [
    {
      'badge': '30% OFF',
      'title': 'Mega Feast Drop',
      'subtitle': 'Save 30% on popular meals',
      'code': 'FOODIE30',
      'bgGradient': [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80',
    },
    {
      'badge': 'FREE DELIVERY',
      'title': 'Zero Fee Week',
      'subtitle': 'Free courier delivery on all items',
      'code': 'FREESHIP',
      'bgGradient': [Color(0xFF00796B), Color(0xFF004D40)],
      'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
    },
    {
      'badge': '20% OFF',
      'title': 'Burger Bash',
      'subtitle': 'Extra savings on burgers & fries',
      'code': 'BURGER20',
      'bgGradient': [Color(0xFFD84315), Color(0xFFBF360C)],
      'imageUrl': 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=400&q=80',
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
            Text(applied
                ? 'Coupon $code claimed! Applied to your cart.'
                : 'Coupon $code ready for checkout!'),
          ],
        ),
        backgroundColor: GlassTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GlassTheme.backgroundDark : const Color(0xFFF7F9F7),
      body: Stack(
        children: [
          RefreshIndicator(
            color: GlassTheme.primaryGreen,
            onRefresh: () => context.read<RestaurantProvider>().fetchRestaurants(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Curved Lush Green Gradient Header ──────────────
                SliverToBoxAdapter(
                  child: _buildCurvedHeader(context, isDark),
                ),

                // ── 2. Content Body with Sections ──────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 18),

                      // ── Hero Promo Banner: FAST & FREE DELIVERY! ────
                      _buildHeroPromoBanner(context),
                      const SizedBox(height: 22),

                      // ── Categories Horizontal Carousel ──────────────
                      _buildSectionHeader('Categories', () => context.push('/explore')),
                      const SizedBox(height: 12),
                      _buildCategoriesList(isDark),
                      const SizedBox(height: 22),

                      // ── Deals For You Section ────────────────────────
                      _buildSectionHeader('Deals for you', () => context.push('/explore')),
                      const SizedBox(height: 12),
                      _buildDealsList(isDark),
                      const SizedBox(height: 24),

                      // ── Restaurants Near You Section ────────────────
                      _buildSectionHeader('Restaurants near you', () => context.push('/explore')),
                      const SizedBox(height: 8),

                      // Sorting filter chips
                      _buildSortingChips(isDark),
                      const SizedBox(height: 14),
                    ]),
                  ),
                ),

                // ── 3. 2-Column Responsive Restaurant Grid ────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: _buildRestaurantGrid(context, isDark),
                ),

                // Bottom padding to clear floating elements
                const SliverToBoxAdapter(
                  child: SizedBox(height: 180),
                ),
              ],
            ),
          ),

          // ── Sticky Floating Active Order Floater (TikTok Signature) ──
          if (_showActiveOrderFloater)
            _buildFloatingActiveOrder(context, isDark),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Header: Curved Lush Green Top Bar with Deliver-to Selector & Pill Search
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCurvedHeader(BuildContext context, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    final user = context.watch<UserProvider>().user;
    final activeAddress = context.watch<AddressProvider>().selectedAddress;

    final String addressLabel = activeAddress?.label.isNotEmpty == true
        ? activeAddress!.label
        : 'Home';
    final String addressStreet = activeAddress != null
        ? '${activeAddress.street}, ${activeAddress.city}'
        : '12 Jalan Ampang, Kuala Lumpur';

    final String avatarUrl = (user?['avatar_url']?.toString().isNotEmpty == true)
        ? user!['avatar_url']
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=160&q=80';

    return Container(
      decoration: const BoxDecoration(
        gradient: GlassTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33236E31),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 10,
        left: 16,
        right: 16,
        bottom: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar | Deliver to Switcher | Notification Bell
          Row(
            children: [
              // User Avatar
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Deliver to location selector
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/addresses'),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC8E6C9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Deliver to',
                            style: TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$addressLabel  $addressStreet',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Notification Bell with Red Badge
              InkWell(
                onTap: () => context.push('/notifications'),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                      Positioned(
                        top: 9,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Bar: Pure White Rounded Pill Container (Reference Video Style)
          InkWell(
            onTap: () => context.push('/search'),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF757575), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Search restaurants or dishes',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: GlassTheme.primaryGreen,
                      size: 18,
                    ),
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
  // Hero Promo Banner: "FAST & FREE DELIVERY!" with "ORDER NOW" Red CTA
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroPromoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1B5E20),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FAST & FREE DELIVERY!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'On all orders this week!',
                  style: TextStyle(
                    color: Color(0xFFC8E6C9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _claimCoupon('FREESHIP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'ORDER NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.two_wheeler,
              size: 54,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Categories Horizontal Carousel with 3D Styled Badges
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildCategoriesList(bool isDark) {
    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategoryIndex = index);
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 76,
                decoration: BoxDecoration(
                  color: isSelected
                      ? GlassTheme.primaryGreen
                      : (isDark ? GlassTheme.surfaceCardDark : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? GlassTheme.primaryGreen.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat['emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF333333)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Deals For You Horizontal Carousel with Coupon Claim Button
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDealsList(bool isDark) {
    return SizedBox(
      height: 142,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _deals.length,
        itemBuilder: (context, index) {
          final deal = _deals[index];
          final gradientColors = deal['bgGradient'] as List<Color>;

          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.3),
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
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deal['badge'],
                          style: TextStyle(
                            color: gradientColors.first,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        deal['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Claim Button
                      ElevatedButton(
                        onPressed: () => _claimCoupon(deal['code']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: gradientColors.first,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          'Claim',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: deal['imageUrl'],
                    width: 80,
                    height: 80,
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
  // Sorting Filter Chips
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSortingChips(bool isDark) {
    const sorts = ['All', '⭐ Top Rated', '⚡ Fastest', '🛵 Free Delivery'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sorts.map((sort) {
          final isSelected = _selectedSort == sort;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(sort),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedSort = sort),
              selectedColor: GlassTheme.primaryGreen,
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
        if (provider.isLoading) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.74,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ShimmerFoodCard(isHorizontal: false),
              childCount: 4,
            ),
          );
        }

        var restaurants = List<Map<String, dynamic>>.from(provider.restaurants);

        // Filter by category if not 'All'
        if (_selectedCategoryIndex > 0) {
          final catName = _categories[_selectedCategoryIndex]['name'].toString().toLowerCase();
          restaurants = restaurants.where((r) {
            final name = (r['name']?.toString() ?? '').toLowerCase();
            final desc = (r['description']?.toString() ?? '').toLowerCase();
            return name.contains(catName) || desc.contains(catName);
          }).toList();
        }

        // Apply sorting
        if (_selectedSort == '⭐ Top Rated') {
          restaurants.sort((a, b) => (double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0)
              .compareTo(double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0));
        } else if (_selectedSort == '⚡ Fastest') {
          restaurants.sort((a, b) => (int.tryParse(a['delivery_time_min']?.toString() ?? '99') ?? 99)
              .compareTo(int.tryParse(b['delivery_time_min']?.toString() ?? '99') ?? 99));
        } else if (_selectedSort == '🛵 Free Delivery') {
          restaurants = restaurants.where((r) =>
              (double.tryParse(r['delivery_fee']?.toString() ?? '1') ?? 1.0) == 0.0).toList();
        }

        if (restaurants.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text('No restaurants match this category.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedCategoryIndex = 0;
                          _selectedSort = 'All';
                        });
                        provider.fetchRestaurants();
                      },
                      icon: const Icon(Icons.refresh, color: GlassTheme.primaryGreen),
                      label: const Text('Reset Filter', style: TextStyle(color: GlassTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.74,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final res = restaurants[index];
              return _buildModernRestaurantCard(context, res, isDark, index);
            },
            childCount: restaurants.length,
          ),
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
    final fee = double.tryParse(res['delivery_fee']?.toString() ?? '1.0') ?? 1.0;
    final distanceKm = 0.6 + (index * 0.4);

    final String discountText = (index % 3 == 0)
        ? '20% OFF'
        : (index % 3 == 1)
            ? '15% OFF'
            : '25% OFF';

    final String fallbackBanner = (index % 2 == 0)
        ? 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80'
        : 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80';
    final effectiveBanner = (banner != null && banner.isNotEmpty) ? banner : fallbackBanner;

    final isFavorite = context.watch<FavoritesProvider>().isRestaurantFavorite(id);

    return InkWell(
      onTap: () => context.push('/restaurant/$id'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: GlassTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildBrandLogo(name),
                ),

                // Favorite Button bottom-right of image
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => context.read<FavoritesProvider>().toggleRestaurant(res),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? const Color(0xFFFF5252) : Colors.white,
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
                      const Icon(Icons.star, color: Color(0xFFFFB300), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF444444),
                        ),
                      ),
                      Text(
                        ' • ${timeMin}m • ${distanceKm.toStringAsFixed(1)}km',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF757575),
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
                      color: fee == 0.0 ? GlassTheme.primaryGreen : GlassTheme.textMuted,
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
      fg = GlassTheme.primaryGreen;
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
    return Positioned(
      bottom: 96,
      left: 16,
      right: 16,
      child: InkWell(
        onTap: () => context.push('/map/1904'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? GlassTheme.primaryGreen.withValues(alpha: 0.5) : const Color(0xFFE0E0E0),
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
                        color: GlassTheme.primaryGreen,
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
                    const Text(
                      'Ahmad is on the way',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To Home • Arriving 11:15 PM',
                      style: TextStyle(
                        fontSize: 12,
                        color: GlassTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic ETA Green Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? GlassTheme.primaryGreen.withValues(alpha: 0.25)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_activeOrderEta min',
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: GlassTheme.primaryGreen,
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
        InkWell(
          onTap: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(
              color: GlassTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
