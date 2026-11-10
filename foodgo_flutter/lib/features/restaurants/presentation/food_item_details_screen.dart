import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../widgets/glass/animated_pressable.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/favorites_provider.dart';

class FoodItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;

  const FoodItemDetailsScreen({super.key, this.itemData});

  @override
  State<FoodItemDetailsScreen> createState() => _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends State<FoodItemDetailsScreen> {
  int _quantity = 1;
  bool _isDescriptionExpanded = false;
  final TextEditingController _instructionsCtrl = TextEditingController();
  bool _addedToBagAnimation = false;

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _onAddToCart(
    BuildContext context,
    int itemId,
    String name,
    double price,
    String imageUrl,
    Map<String, dynamic> data, {
    bool buyNow = false,
  }) {
    final cart = context.read<CartProvider>();
    final notes = _instructionsCtrl.text.trim();
    if (notes.isNotEmpty) {
      cart.setSpecialInstructions(notes);
    }
    cart.addItem(
      itemId,
      name,
      price,
      imageUrl,
      restaurantId:
          int.tryParse(
            data['restaurantId']?.toString() ??
                data['restaurant_id']?.toString() ??
                data['restaurant']?.toString() ??
                '',
          ) ??
          1,
      restaurantName:
          data['restaurantName']?.toString() ??
          data['restaurant_name']?.toString() ??
          'FoodGo Kitchen',
      quantity: _quantity,
    );
    if (buyNow) {
      context.push('/checkout');
    } else {
      setState(() => _addedToBagAnimation = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _addedToBagAnimation = false);
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(AppIcons.successFilled, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _quantity > 1
                      ? '$_quantity x $name added to cart!'
                      : '$name added to cart!',
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Use passed data or defaults matching the reference mockup (Double Beef Cheese Burger)
    final data =
        widget.itemData ??
        {
          'id': 1,
          'name': 'Double Beef Cheese Burger',
          'location': 'Naperville, Illinois',
          'price': 6.50,
          'calories': '198',
          'proteins': '25.2',
          'fats': '13.8',
          'carbo': '23.7',
          'image':
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
          'description':
              'Burger with patty filled with macaroni & cheese and real beef, Stroganoff sauce, topped with onions, served on a soft black sesame burger bun with patty filled with melted cheddar cheese and crispy garden greens.',
          'restaurantId': 1,
          'restaurantName': 'Naperville Gourmet Burgers',
        };

    final int itemId = (data['id'] is int)
        ? data['id'] as int
        : int.tryParse(data['id']?.toString() ?? '1') ?? 1;
    final String name = data['name']?.toString() ?? 'Double Beef Cheese Burger';
    final String location =
        data['location']?.toString() ?? 'Naperville, Illinois';
    final double price = (data['price'] is num)
        ? (data['price'] as num).toDouble()
        : double.tryParse(data['price']?.toString() ?? '6.50') ?? 6.50;
    final String imageUrl =
        data['image']?.toString() ??
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80';
    final String description =
        data['description']?.toString() ??
        'Burger with patty filled with macaroni & cheese and real beef, Stroganoff sauce, topped with onions, served on a soft black sesame burger bun with patty filled with melted cheddar cheese and crispy garden greens.';

    final String calories = data['calories']?.toString() ?? '198';
    final String proteins = data['proteins']?.toString() ?? '25.2';
    final String fats = data['fats']?.toString() ?? '13.8';
    final String carbo = data['carbo']?.toString() ?? '23.7';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Scrollable Body ──────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Image Background with Subtle Diagonal Effect
                Stack(
                  children: [
                    Container(
                      height: 380,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E2820),
                                  const Color(0xFF141C16),
                                ]
                              : [const Color(0xFFEBECEE), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Centered Large Hero Food Image
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: topPadding + 40,
                          bottom: 20,
                        ),
                        child: Center(
                          child:
                              Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.4 : 0.18,
                                          ),
                                          blurRadius: 36,
                                          offset: const Offset(0, 18),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 230,
                                        height: 230,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              width: 230,
                                              height: 230,
                                              color: Colors.grey.shade200,
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              width: 230,
                                              height: 230,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                AppIcons.emptyState,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                            ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .scale(
                                    duration: 500.ms,
                                    begin: const Offset(0.85, 0.85),
                                    end: const Offset(1, 1),
                                    curve: Curves.easeOutBack,
                                  )
                                  .fadeIn(duration: 400.ms),
                        ),
                      ),
                    ),
                  ],
                ),

                // Dish Info & Macro-Nutrients Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dish Title & Price Header
                      Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1B1B1B),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? GlassTheme
                                                .activePalette
                                                .primaryAccent
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    KhmerCurrency.formatKhr(price),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: GlassTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 150.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 6),

                      // Location Row (e.g., Naperville, Illinois)
                      Row(
                        children: [
                          Icon(
                            AppIcons.location,
                            size: 16,
                            color: GlassTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: GlassTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms, delay: 180.ms),
                      const SizedBox(height: 20),

                      // 4 Macro-Nutrient Metrics (kcal, proteins, fats, carbo)
                      Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? GlassTheme.surfaceCardDark
                                  : const Color(0xFFF7F8F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : const Color(0xFFEDEDED),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildMacroMetric(calories, 'kcal', isDark),
                                _buildVerticalDivider(isDark),
                                _buildMacroMetric(proteins, 'proteins', isDark),
                                _buildVerticalDivider(isDark),
                                _buildMacroMetric(fats, 'fats', isDark),
                                _buildVerticalDivider(isDark),
                                _buildMacroMetric(carbo, 'carbo', isDark),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 450.ms, delay: 220.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 24),

                      // Description Section
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        description,
                        maxLines: _isDescriptionExpanded ? null : 3,
                        overflow: _isDescriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 6),

                      AnimatedPressable(
                        pressedScale: 0.94,
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Text(
                          _isDescriptionExpanded ? 'Show less' : 'Show more',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? GlassTheme.activePalette.primaryAccent
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quantity Stepper Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1B1B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${(price * _quantity).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(AppIcons.remove, size: 18),
                                  splashRadius: 20,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  onPressed: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$_quantity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(AppIcons.add, size: 18),
                                  splashRadius: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Special Instructions Note Input
                      Text(
                        'Special Instructions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF6F7F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: TextField(
                          controller: _instructionsCtrl,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Extra sauce, no onions, allergy notes...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            prefixIcon: Icon(
                              AppIcons.edit,
                              size: 22,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      // Bottom clearance for sticky action bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Top Navigation Bar (Floating Circular Buttons) ───────────
          Positioned(
            top: topPadding + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                AnimatedIconButton(
                  icon: AppIcons.back,
                  iconSize: 26,
                  size: 44,
                  color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
                  borderColor: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.1),
                  iconColor: isDark ? Colors.white : Colors.black87,
                  onPressed: () => context.pop(),
                ),

                // Center Title
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                  ),
                ),

                // Target / Favorite Button
                Consumer<FavoritesProvider>(
                  builder: (context, favs, child) {
                    final isFav = favs.isFoodFavorite(itemId);
                    return AnimatedIconButton(
                      icon: isFav ? AppIcons.favorite : AppIcons.favoriteBorder,
                      iconSize: 20,
                      size: 44,
                      color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
                      borderColor: isDark
                          ? (isFav
                                ? const Color(0xFFE53935).withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.22))
                          : (isFav
                                ? const Color(0xFFE53935).withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.1)),
                      iconColor: isFav
                          ? const Color(0xFFE53935)
                          : (isDark ? Colors.white70 : Colors.black87),
                      onPressed: () => favs.toggleFoodItem(data),
                    );
                  },
                ),
              ],
            ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15, end: 0),
          ),

          // ── Bottom Sticky Action Bar (Shopping Bag + "Buy Now") ─────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child:
                Container(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 14,
                        bottom: bottomPadding + 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? GlassTheme.surfaceDark : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFE2E4E6),
                            width: 1.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Shopping Bag Icon Button with Animated Feedback
                          AnimatedPressable(
                            pressedScale: 0.90,
                            onTap: () => _onAddToCart(
                              context,
                              itemId,
                              name,
                              price,
                              imageUrl,
                              data,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _addedToBagAnimation
                                    ? Theme.of(context).colorScheme.primary
                                    : (isDark
                                          ? Colors.white10
                                          : const Color(0xFFF5F6F7)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _addedToBagAnimation
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.18,
                                              )
                                            : const Color(0xFFE2E4E6)),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                _addedToBagAnimation
                                    ? AppIcons.check
                                    : AppIcons.cart,
                                color: _addedToBagAnimation
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black87),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Large Brand Pill Button
                          Expanded(
                            child: AnimatedPressable(
                              pressedScale: 0.96,
                              onTap: () => _onAddToCart(
                                context,
                                itemId,
                                name,
                                price,
                                imageUrl,
                                data,
                                buyNow: true,
                              ),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 350.ms)
                    .slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMetric(String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: GlassTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
    );
  }
}
