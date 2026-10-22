import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/floating_mini_cart_bar.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/restaurant_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/shimmer_widgets.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String? id;
  const RestaurantDetailsScreen({super.key, this.id});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDietaryBadge(String label, Color color, [IconData? icon]) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDishDetailSheet(
    Map<String, dynamic> item,
    Map<String, dynamic> restaurant,
  ) {
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice = double.tryParse(
      item['original_price']?.toString() ?? '0',
    );
    final isVeg = item['is_vegetarian'] == true;
    final isSpicy = item['is_spicy'] == true;
    final isHalal = item['is_halal'] == true;
    final isAvailable = item['is_available'] != false;
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ResponsiveBottomSheet(
          child: Container(
            padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: GlassTheme.dialogDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (item['image'] != null &&
                    item['image'].toString().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: item['image'].toString(),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: Colors.white12,
                        child: const Icon(
                          Icons.fastfood,
                          size: 48,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Dish',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: GlassTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                if (originalPrice != null && originalPrice > price) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '\$${originalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isVeg)
                      _buildDietaryBadge('Vegetarian', Colors.green, Icons.eco),
                    if (isHalal)
                      _buildDietaryBadge('Halal', Colors.teal, Icons.verified),
                    if (isSpicy)
                      _buildDietaryBadge(
                        'Spicy',
                        Colors.deepOrange,
                        Icons.local_fire_department,
                      ),
                    if (item['preparation_time_mins'] != null)
                      _buildDietaryBadge(
                        '${item['preparation_time_mins']} mins',
                        Colors.blueAccent,
                        Icons.schedule,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['description'] ??
                      'Freshly prepared recipe from our kitchen.',
                  style: TextStyle(
                    color: GlassTheme.textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (!isAvailable)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Currently Sold Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: qty > 1
                            ? () => setSheetState(() => qty--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 28),
                        color: GlassTheme.primaryGreen,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setSheetState(() => qty++),
                        icon: const Icon(Icons.add_circle_outline, size: 28),
                        color: GlassTheme.primaryGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final cart = context.read<CartProvider>();
                      final restId = int.tryParse(
                        restaurant['id']?.toString() ?? '',
                      );
                      for (int i = 0; i < qty; i++) {
                        cart.addItem(
                          item['id'] as int? ?? 0,
                          item['name'] ?? 'Dish',
                          price,
                          item['image']?.toString(),
                          restaurantId: restId,
                          restaurantName: restaurant['name']?.toString(),
                        );
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $qty "${item['name']}" to cart'),
                          backgroundColor: GlassTheme.dialogDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      'Add to Cart • \$${(price * qty).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RestaurantProvider>();
      if (provider.restaurants.isEmpty && !provider.isLoading) {
        provider.fetchRestaurants();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.restaurants.isEmpty) {
            return const Scaffold(
              appBar: GlassAppBar(title: 'Loading Restaurant...'),
              body: SafeArea(child: ShimmerDetailHeader()),
            );
          }

          final restaurant = provider.restaurants.firstWhere(
            (r) => r['id'].toString() == widget.id,
            orElse: () => null,
          );

          if (restaurant == null) {
            return Scaffold(
              appBar: const GlassAppBar(title: 'Restaurant'),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.store_mall_directory_outlined,
                        size: 64,
                        color: GlassTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Restaurant not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The requested restaurant may be closed or unavailable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        text: 'Explore Restaurants',
                        icon: Icons.explore,
                        onPressed: () => context.go('/explore'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final categories = List<dynamic>.from(
            restaurant['food_categories'] ?? [],
          );
          final allItems = <Map<String, dynamic>>[];
          for (var cat in categories) {
            final catItems = List<dynamic>.from(cat['items'] ?? []);
            for (var item in catItems) {
              final map = Map<String, dynamic>.from(item);
              map['category_name'] = cat['name'];
              allItems.add(map);
            }
          }

          // Build category list for tabs
          final categoryNames = [
            'All',
            ...categories.map((c) => c['name']?.toString() ?? 'Menu'),
          ];

          // Filter items based on tab and menu search query
          final displayedItems = allItems.where((it) {
            final matchesCat =
                _selectedCategoryIndex == 0 ||
                it['category_name'] == categoryNames[_selectedCategoryIndex];
            final q = _searchQuery.trim().toLowerCase();
            final matchesSearch =
                q.isEmpty ||
                (it['name']?.toString().toLowerCase().contains(q) ?? false) ||
                (it['description']?.toString().toLowerCase().contains(q) ??
                    false);
            return matchesCat && matchesSearch;
          }).toList();

          final minTime = restaurant['delivery_time_min'] ?? 15;
          final maxTime = restaurant['delivery_time_max'] ?? 30;
          final deliveryFee =
              double.tryParse(restaurant['delivery_fee']?.toString() ?? '0') ??
              0.0;
          final rating = restaurant['rating']?.toString() ?? '4.8';

          return Stack(
            children: [
              ResponsiveWebContainer(
                maxWidth: 1150,
                child: CustomScrollView(
                  slivers: [
                    // ── Hero Banner AppBar (Foodpanda / Grab style) ────────
                    SliverAppBar(
                      expandedHeight: 250.0,
                      pinned: true,
                      backgroundColor: GlassTheme.backgroundDark,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Consumer<FavoritesProvider>(
                            builder: (context, favProvider, child) {
                              final isResFav = favProvider.isRestaurantFavorite(
                                restaurant['id'],
                              );
                              return IconButton(
                                icon: Icon(
                                  isResFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isResFav
                                      ? GlassTheme.foodpandaPink
                                      : Colors.white,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final added = await favProvider
                                      .toggleRestaurant(restaurant);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        added
                                            ? 'Saved "${restaurant['name']}" to Favorites'
                                            : 'Removed "${restaurant['name']}" from Favorites',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'restaurant_banner_${widget.id}',
                              child: CachedNetworkImage(
                                imageUrl:
                                    (restaurant['banner'] != null &&
                                        restaurant['banner']
                                            .toString()
                                            .isNotEmpty)
                                    ? restaurant['banner'].toString()
                                    : (widget.id == '1'
                                          ? 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80'
                                          : widget.id == '2'
                                          ? 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80'
                                          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80'),
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Hero(
                                tag: 'restaurant_title_${widget.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    restaurant['name'] ?? 'Restaurant',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Restaurant Info Card & Deals Banner ────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Restaurant Metadata Card
                            GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: GlassTheme.ratingAmber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            rating,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(350+ reviews)',
                                            style: TextStyle(
                                              color: GlassTheme.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  (restaurant['is_active'] !=
                                                              false
                                                          ? GlassTheme
                                                                .primaryGreen
                                                          : Colors.redAccent)
                                                      .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              restaurant['is_active'] != false
                                                  ? 'Open Now'
                                                  : 'Closed',
                                              style: TextStyle(
                                                color:
                                                    restaurant['is_active'] !=
                                                        false
                                                    ? GlassTheme.primaryGreen
                                                    : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: GlassTheme.primaryGreen
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color:
                                                      GlassTheme.primaryGreen,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$minTime-$maxTime min',
                                                  style: const TextStyle(
                                                    color:
                                                        GlassTheme.primaryGreen,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        height: 20,
                                        color: Colors.white12,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.moped,
                                            color: GlassTheme.primaryGreen,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            deliveryFee <= 0
                                                ? 'Free Delivery'
                                                : 'Delivery: \$${deliveryFee.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.blueAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            '1.2 km away',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                ),
                            const SizedBox(height: 12),

                            // Foodpanda Deals Pill Banner
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GlassTheme.foodpandaPink.withValues(
                                      alpha: 0.15,
                                    ),
                                    border: Border.all(
                                      color: GlassTheme.foodpandaPink
                                          .withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer,
                                        color: GlassTheme.foodpandaPink,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '20% OFF orders over \$10 • Code: FOODGO20',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 12),

                            // In-Restaurant Menu Search Bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  icon: const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: GlassTheme.primaryGreen,
                                  ),
                                  hintText:
                                      'Search dishes in this restaurant...',
                                  hintStyle: TextStyle(
                                    color: GlassTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 16,
                                            color: Colors.white60,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                              ),
                            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                            const SizedBox(height: 14),

                            // ── Sticky Category Tab Bar (Foodpanda Style) ────
                            SizedBox(
                                  height: 38,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categoryNames.length,
                                    itemBuilder: (context, index) {
                                      final isSelected =
                                          _selectedCategoryIndex == index;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: InkWell(
                                          onTap: () => setState(
                                            () =>
                                                _selectedCategoryIndex = index,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? GlassTheme.primaryGreen
                                                  : Colors.white.withValues(
                                                      alpha: 0.06,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.transparent
                                                    : Colors.white.withValues(
                                                        alpha: 0.12,
                                                      ),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                categoryNames[index],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 400.ms)
                                .slideX(begin: 0.05, end: 0),
                            const SizedBox(height: 16),

                            Text(
                              categoryNames[_selectedCategoryIndex],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // ── Menu Items List (Foodpanda Food Item Layout) ────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = displayedItems[index];
                          final price =
                              double.tryParse(
                                item['price']?.toString() ?? '0',
                              ) ??
                              0.0;
                          final originalPrice = double.tryParse(
                            item['original_price']?.toString() ?? '',
                          );
                          final isAvailable = item['is_available'] != false;
                          final isVeg = item['is_vegetarian'] == true;
                          final isSpicy = item['is_spicy'] == true;
                          final isHalal = item['is_halal'] == true;
                          final itemId = item['id'] as int? ?? index;
                          final cartItem = context
                              .watch<CartProvider>()
                              .items[itemId];
                          final int inCartQty = cartItem?.quantity ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () =>
                                  _showDishDetailSheet(item, restaurant),
                              borderRadius: BorderRadius.circular(16),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left side: Item title, description, badges, price
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['name'] ?? 'Dish',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!isAvailable)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Sold Out',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['description'] ??
                                                'Delicious freshly prepared recipe.',
                                            style: TextStyle(
                                              color: GlassTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (isVeg || isSpicy || isHalal) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                if (isVeg)
                                                  _buildDietaryBadge(
                                                    'Veg',
                                                    Colors.green,
                                                    Icons.eco,
                                                  ),
                                                if (isHalal)
                                                  _buildDietaryBadge(
                                                    'Halal',
                                                    Colors.teal,
                                                    Icons.verified,
                                                  ),
                                                if (isSpicy)
                                                  _buildDietaryBadge(
                                                    'Spicy',
                                                    Colors.deepOrange,
                                                    Icons.local_fire_department,
                                                  ),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                '\$${price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color:
                                                      GlassTheme.primaryGreen,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (originalPrice != null &&
                                                  originalPrice > price) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '\$${originalPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.white38,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Right side: Dish Image + Plus Add Button
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            child:
                                                item['image'] != null &&
                                                    item['image']
                                                        .toString()
                                                        .isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: item['image']
                                                        .toString(),
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Container(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.05,
                                                              ),
                                                          child: const Center(
                                                            child: SizedBox(
                                                              width: 18,
                                                              height: 18,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: GlassTheme
                                                                    .primaryGreen,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Container(
                                                              color: Colors.grey
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                              child: const Icon(
                                                                Icons.fastfood,
                                                                color: Colors
                                                                    .white38,
                                                              ),
                                                            ),
                                                  )
                                                : Container(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.2),
                                                    child: const Icon(
                                                      Icons.fastfood,
                                                      color: Colors.white38,
                                                    ),
                                                  ),
                                          ),
                                        ),

                                        // Favorite Dish Heart Icon overlay
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Consumer<FavoritesProvider>(
                                            builder: (context, favs, child) {
                                              final isFav = favs.isFoodFavorite(
                                                itemId,
                                              );
                                              return Material(
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: () async {
                                                    final added = await favs
                                                        .toggleFoodItem(item);
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).hideCurrentSnackBar();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          added
                                                              ? 'Saved "${item['name']}" to Favorites'
                                                              : 'Removed "${item['name']}" from Favorites',
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 1,
                                                            ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          5.0,
                                                        ),
                                                    child: Icon(
                                                      isFav
                                                          ? Icons.favorite
                                                          : Icons
                                                                .favorite_border,
                                                      size: 14,
                                                      color: isFav
                                                          ? GlassTheme
                                                                .foodpandaPink
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                        // Foodpanda style Add / Plus Button overlay
                                        if (isAvailable)
                                          Positioned(
                                            bottom: -6,
                                            right: -6,
                                            child: Material(
                                              color: inCartQty > 0
                                                  ? GlassTheme.primaryGreen
                                                  : Colors.white,
                                              shape: const CircleBorder(),
                                              elevation: 4,
                                              child: InkWell(
                                                customBorder:
                                                    const CircleBorder(),
                                                onTap: () {
                                                  context
                                                      .read<CartProvider>()
                                                      .addItem(
                                                        itemId,
                                                        item['name'] ?? 'Dish',
                                                        price,
                                                        item['image']
                                                            ?.toString(),
                                                        restaurantId:
                                                            int.tryParse(
                                                              widget.id ?? '1',
                                                            ),
                                                        restaurantName:
                                                            restaurant['name'],
                                                      );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).hideCurrentSnackBar();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Added "${item['name']}" to cart!',
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 1,
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      action: SnackBarAction(
                                                        label: 'View Cart',
                                                        textColor: GlassTheme
                                                            .primaryGreen,
                                                        onPressed: () =>
                                                            context.go('/cart'),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    6.0,
                                                  ),
                                                  child: inCartQty > 0
                                                      ? Text(
                                                          '$inCartQty',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons.add,
                                                          color: Colors.black87,
                                                          size: 18,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 350.ms, delay: ((index % 8) * 40).ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad);
                        }, childCount: displayedItems.length),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),

              // ── Sticky Bottom Checkout Bar (Foodpanda Style) ─────────
              const FloatingMiniCartBar(bottomOffset: 24.0),
            ],
          );
        },
      ),
    );
  }
}
