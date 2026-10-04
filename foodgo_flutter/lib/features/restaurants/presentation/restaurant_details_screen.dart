import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/floating_mini_cart_bar.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/restaurant_provider.dart';
import '../../../providers/cart_provider.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String? id;
  const RestaurantDetailsScreen({super.key, this.id});

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  int _selectedCategoryIndex = 0;
  bool _isFavorite = false;

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
              body: Center(
                child: CircularProgressIndicator(color: GlassTheme.primaryGreen),
              ),
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
                      Icon(Icons.store_mall_directory_outlined, size: 64, color: GlassTheme.textMuted),
                      const SizedBox(height: 16),
                      const Text('Restaurant not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('The requested restaurant may be closed or unavailable.', textAlign: TextAlign.center, style: TextStyle(color: GlassTheme.textMuted, fontSize: 13)),
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

          final categories = List<dynamic>.from(restaurant['food_categories'] ?? []);
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
          final categoryNames = ['All', ...categories.map((c) => c['name']?.toString() ?? 'Menu')];

          // Filter items based on tab
          final displayedItems = _selectedCategoryIndex == 0
              ? allItems
              : allItems.where((it) => it['category_name'] == categoryNames[_selectedCategoryIndex]).toList();

          final minTime = restaurant['delivery_time_min'] ?? 15;
          final maxTime = restaurant['delivery_time_max'] ?? 30;
          final deliveryFee = double.tryParse(restaurant['delivery_fee']?.toString() ?? '0') ?? 0.0;
          final rating = restaurant['rating']?.toString() ?? '4.8';

          return Stack(
            children: [
              CustomScrollView(
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                        child: IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? GlassTheme.foodpandaPink : Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _isFavorite = !_isFavorite);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isFavorite ? 'Saved to Favorites' : 'Removed from Favorites'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (restaurant['banner'] != null && restaurant['banner'].toString().isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: restaurant['banner'].toString(),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(color: Colors.grey.withValues(alpha: 0.2)),
                            )
                          else
                            Container(color: Colors.grey.withValues(alpha: 0.2)),
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
                        ],
                      ),
                    ),
                  ),

                  // ── Restaurant Info Card & Deals Banner ────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                    const Icon(Icons.star, color: GlassTheme.ratingAmber, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      rating,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(350+ reviews)',
                                      style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 14, color: GlassTheme.primaryGreen),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$minTime-$maxTime min',
                                            style: const TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: Colors.white12),
                                Row(
                                  children: [
                                    const Icon(Icons.moped, color: GlassTheme.primaryGreen, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      deliveryFee <= 0 ? 'Free Delivery' : 'Delivery: \$${deliveryFee.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 4),
                                    const Text('1.2 km away', style: TextStyle(fontSize: 13, color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Foodpanda Deals Pill Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: GlassTheme.foodpandaPink.withValues(alpha: 0.15),
                              border: Border.all(color: GlassTheme.foodpandaPink.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.local_offer, color: GlassTheme.foodpandaPink, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '20% OFF orders over \$10 • Code: FOODGO20',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Sticky Category Tab Bar (Foodpanda Style) ────
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categoryNames.length,
                              itemBuilder: (context, index) {
                                final isSelected = _selectedCategoryIndex == index;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedCategoryIndex = index),
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? GlassTheme.primaryGreen
                                            : Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          categoryNames[index],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            categoryNames[_selectedCategoryIndex],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = displayedItems[index];
                          final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                          final itemId = item['id'] as int? ?? index;
                          final cartItem = context.watch<CartProvider>().items[itemId];
                          final int inCartQty = cartItem?.quantity ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left side: Item title, description, price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Dish',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['description'] ?? 'Delicious freshly prepared recipe.',
                                          style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '\$${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: GlassTheme.primaryGreen,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
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
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          color: Colors.white.withValues(alpha: 0.05),
                                          child: item['image'] != null && item['image'].toString().isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: item['image'].toString(),
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.white.withValues(alpha: 0.05),
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(strokeWidth: 2, color: GlassTheme.primaryGreen),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    color: Colors.grey.withValues(alpha: 0.2),
                                                    child: const Icon(Icons.fastfood, color: Colors.white38),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey.withValues(alpha: 0.2),
                                                  child: const Icon(Icons.fastfood, color: Colors.white38),
                                                ),
                                        ),
                                      ),

                                      // Foodpanda style Add / Plus Button overlay
                                      Positioned(
                                        bottom: -6,
                                        right: -6,
                                        child: Material(
                                          color: inCartQty > 0 ? GlassTheme.primaryGreen : Colors.white,
                                          shape: const CircleBorder(),
                                          elevation: 4,
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: () {
                                              context.read<CartProvider>().addItem(
                                                itemId,
                                                item['name'] ?? 'Dish',
                                                price,
                                                item['image']?.toString(),
                                                restaurantId: int.tryParse(widget.id ?? '1'),
                                                restaurantName: restaurant['name'],
                                              );
                                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Added "${item['name']}" to cart!'),
                                                  duration: const Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                  action: SnackBarAction(
                                                    label: 'View Cart',
                                                    textColor: GlassTheme.primaryGreen,
                                                    onPressed: () => context.push('/cart'),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: inCartQty > 0
                                                  ? Text(
                                                      '$inCartQty',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    )
                                                  : const Icon(Icons.add, color: Colors.black87, size: 18),
                                            ),
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
                        childCount: displayedItems.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
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
