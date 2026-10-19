import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/shimmer_widgets.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/favorites_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  final List<String> _recentSearches = ['Burgers', 'Fish Amok', 'Iced Latte'];

  final List<String> _popularSuggestions = [
    'Burgers',
    'Pizza',
    'Khmer Food',
    'Coffee',
    'Fried Chicken',
    'Noodles',
    'Healthy Bowls',
    'Desserts',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final res = await ApiService().get('food-items/?search=$encoded');
      if (!mounted) return;
      if (_searchController.text.trim() != query) return;

      final List<dynamic> items = res is List
          ? res
          : (res['results'] as List<dynamic>? ?? []);

      if (query.isNotEmpty && !_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 6) _recentSearches.removeLast();
      }

      setState(() {
        _searchResults = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDishDetailSheet(Map<String, dynamic> item) {
    int qty = 1;
    final name = item['name']?.toString() ?? 'Food Item';
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final desc =
        item['description']?.toString() ??
        'Freshly prepared with quality ingredients.';
    final image = item['image']?.toString();
    final itemId = item['id'] is int
        ? item['id'] as int
        : int.parse(item['id'].toString());
    final int? restId = item['restaurant'] is int
        ? item['restaurant'] as int
        : (item['restaurant'] is Map ? item['restaurant']['id'] as int? : null);
    final String? restName = item['restaurant_name']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: GlassTheme.dialogDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(24),
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
              if (image != null && image.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: image,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      height: 160,
                      color: Colors.white10,
                      child: const Icon(
                        Icons.fastfood,
                        size: 48,
                        color: GlassTheme.primaryGreen,
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
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Consumer<FavoritesProvider>(
                    builder: (context, favs, child) {
                      final isFav = favs.isFoodFavorite(itemId);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? GlassTheme.foodpandaPink
                              : Colors.white70,
                        ),
                        onPressed: () => favs.toggleFoodItem(item),
                      );
                    },
                  ),
                ],
              ),
              if (restName != null && restName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  restName,
                  style: TextStyle(
                    color: GlassTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                desc,
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${(price * qty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: GlassTheme.primaryGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: qty > 1
                              ? () => setSheetState(() => qty--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setSheetState(() => qty++),
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: GlassTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.limeAccent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.black,
                    size: 20,
                  ),
                  label: Text(
                    'Add $qty to Cart • \$${(price * qty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    final cart = context.read<CartProvider>();
                    for (int i = 0; i < qty; i++) {
                      cart.addItem(
                        itemId,
                        name,
                        price,
                        image,
                        restaurantId: restId,
                        restaurantName: restName,
                      );
                    }
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $qty "$name" to your cart!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: GlassTheme.surfaceDark,
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'View Cart',
                          textColor: GlassTheme.limeAccent,
                          onPressed: () => context.push('/cart'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              )
            : null,
        centerTitle: true,
        title: const Text(
          'Search Food',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search for pizza, burger, Khmer dishes...',
                    hintStyle: TextStyle(
                      color: GlassTheme.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: GlassTheme.limeAccent,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Recent & Popular quick tags
              if (_searchController.text.isEmpty) ...[
                if (_recentSearches.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Searches',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _recentSearches.clear()),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _recentSearches.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            avatar: const Icon(
                              Icons.history,
                              size: 14,
                              color: GlassTheme.primaryGreen,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            label: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () {
                              _searchController.text = tag;
                              _performSearch(tag);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text(
                  'Popular Searches',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _popularSuggestions.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          label: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            _searchController.text = tag;
                            _performSearch(tag);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12.0),
                          child: ShimmerFoodCard(),
                        ),
                      )
                    : _searchResults.isEmpty &&
                          _searchController.text.trim().isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 54,
                              color: GlassTheme.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No food found matching "${_searchController.text.trim()}"',
                              style: TextStyle(
                                color: GlassTheme.textMuted,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                    ? Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: GlassTheme.primaryGreen,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Find your craving',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select a popular category or type any dish above!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: GlassTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final price =
                              double.tryParse(
                                item['price']?.toString() ?? '0',
                              ) ??
                              0.0;
                          final int? restId = item['restaurant'] is int
                              ? item['restaurant'] as int
                              : (item['restaurant'] is Map
                                    ? item['restaurant']['id'] as int?
                                    : null);
                          final String? restName = item['restaurant_name']
                              ?.toString();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassCard(
                              onTap: () => _showDishDetailSheet(item),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: GlassTheme.borderRadiusSmall,
                                    child: Container(
                                      width: 80,
                                      height: 80,
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
                                              errorWidget: (_, _, _) =>
                                                  const Icon(
                                                    Icons.fastfood,
                                                    size: 40,
                                                    color:
                                                        GlassTheme.primaryGreen,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.fastfood,
                                              size: 40,
                                              color: GlassTheme.primaryGreen,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name']?.toString() ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: GlassTheme.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (restName != null &&
                                            restName.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            restName,
                                            style: TextStyle(
                                              color: GlassTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      context.read<CartProvider>().addItem(
                                        item['id'] is int
                                            ? item['id'] as int
                                            : int.parse(item['id'].toString()),
                                        item['name']?.toString() ?? 'Food Item',
                                        price,
                                        item['image']?.toString(),
                                        restaurantId: restId,
                                        restaurantName: restName,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${item['name']} added to cart!',
                                          ),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor:
                                              GlassTheme.primaryGreen,
                                          behavior: SnackBarBehavior.floating,
                                          action: SnackBarAction(
                                            label: 'View Cart',
                                            textColor: Colors.white,
                                            onPressed: () =>
                                                context.push('/cart'),
                                          ),
                                        ),
                                      );
                                    },
                                    child: GlassContainer(
                                      borderRadius: BorderRadius.circular(20),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.add,
                                        color: GlassTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade().slideX(),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
