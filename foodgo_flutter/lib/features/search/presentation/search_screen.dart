import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/shimmer_widgets.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/vector_illustrations.dart';

enum SearchScope { all, dishes, restaurants }

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _recentSearchesKey = 'foodgo_recent_searches';

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  SearchScope _selectedScope = SearchScope.all;
  List<String> _recentSearches = ['Burgers', 'Fish Amok', 'Iced Latte'];
  List<dynamic> _foodResults = [];
  List<dynamic> _restaurantResults = [];

  // Filter & Sorting state
  String? _selectedPriceTier; // null (All), '$', '419884', '419884$'
  bool _isVegetarianOnly = false;
  double? _minRating; // null, 4.0, 4.5
  String _sortBy =
      'recommended'; // 'recommended', 'price_asc', 'price_desc', 'rating'

  static const List<Map<String, dynamic>> _quickCategories = [
    {'name': 'Burgers', 'icon': Icons.lunch_dining},
    {'name': 'Khmer Food', 'icon': Icons.ramen_dining},
    {'name': 'Coffee & Drinks', 'icon': Icons.local_cafe},
    {'name': 'Pizza', 'icon': Icons.local_pizza},
    {'name': 'Healthy Bowls', 'icon': Icons.eco},
    {'name': 'Desserts', 'icon': Icons.icecream},
    {'name': 'Fried Chicken', 'icon': Icons.fastfood},
    {'name': 'Noodles', 'icon': Icons.set_meal},
  ];

  int get _activeFilterCount {
    int count = 0;
    if (_selectedPriceTier != null) count++;
    if (_isVegetarianOnly) count++;
    if (_minRating != null) count++;
    if (_sortBy != 'recommended') count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentSearchesKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _recentSearches = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (_) {}
  }

  void _addToRecentSearches(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 8) {
        _recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
    _saveRecentSearches();
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty && _activeFilterCount == 0) {
      setState(() {
        _foodResults = [];
        _restaurantResults = [];
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
    final trimmed = query.trim();
    if (trimmed.isEmpty && _activeFilterCount == 0) {
      if (mounted) {
        setState(() {
          _foodResults = [];
          _restaurantResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final encoded = Uri.encodeComponent(trimmed);

      // Build food items query
      final foodParams = <String>[];
      if (encoded.isNotEmpty) foodParams.add('search=$encoded');
      if (_isVegetarianOnly) foodParams.add('vegetarian=true');
      if (_selectedPriceTier == r'$') {
        foodParams.add('max_price=5.00');
      } else if (_selectedPriceTier == r'$$') {
        foodParams.add('min_price=5.00&max_price=15.00');
      } else if (_selectedPriceTier == r'$$$') {
        foodParams.add('min_price=15.00');
      }
      if (_sortBy == 'price_asc') {
        foodParams.add('ordering=price_asc');
      } else if (_sortBy == 'price_desc') {
        foodParams.add('ordering=price_desc');
      } else if (_sortBy == 'rating') {
        foodParams.add('ordering=rating');
      }

      final foodUrl = 'food-items/?${foodParams.join('&')}';

      // Build restaurants query
      final restParams = <String>[];
      if (encoded.isNotEmpty) restParams.add('search=$encoded');
      if (_minRating != null) restParams.add('min_rating=$_minRating');
      if (_selectedPriceTier != null) {
        restParams.add(
          'price_tier=${Uri.encodeComponent(_selectedPriceTier!)}',
        );
      }

      final restUrl = 'restaurants/?${restParams.join('&')}';

      final responses = await Future.wait([
        ApiService().get(foodUrl),
        ApiService().get(restUrl),
      ]);

      if (!mounted) return;
      if (_searchController.text.trim() != trimmed && trimmed.isNotEmpty) {
        return;
      }

      final foodData = responses[0];
      final restData = responses[1];

      final List<dynamic> foods = foodData is List
          ? foodData
          : (foodData['results'] as List<dynamic>? ?? []);

      final List<dynamic> rests = restData is List
          ? restData
          : (restData['results'] as List<dynamic>? ?? []);

      if (trimmed.isNotEmpty) {
        _addToRecentSearches(trimmed);
      }

      setState(() {
        _foodResults = foods;
        _restaurantResults = rests;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterModal() {
    String? tempPriceTier = _selectedPriceTier;
    bool tempVegetarian = _isVegetarianOnly;
    double? tempMinRating = _minRating;
    String tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          final primaryText = AppTypography.primaryTextColor(
            isDark ? Brightness.dark : Brightness.light,
          );
          final secondaryText = AppTypography.secondaryTextColor(
            isDark ? Brightness.dark : Brightness.light,
          );
          final accentGreen = isDark
              ? GlassTheme.primaryGreen
              : GlassTheme.primaryGreenDark;
          final sectionBorder = isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08);
          final surfaceFill = isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04);

          return ResponsiveBottomSheet(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? GlassTheme.dialogDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: sectionBorder),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.tune,
                                size: 18,
                                color: accentGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Filters & Sorting',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempPriceTier = null;
                              tempVegetarian = false;
                              tempMinRating = null;
                              tempSortBy = 'recommended';
                            });
                          },
                          child: Text(
                            'Reset All',
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sort By Section
                    Text(
                      'SORT BY',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: 'Recommended',
                          selected: tempSortBy == 'recommended',
                          onTap: () =>
                              setModalState(() => tempSortBy = 'recommended'),
                        ),
                        _buildFilterChip(
                          label: 'Price: Low to High',
                          selected: tempSortBy == 'price_asc',
                          onTap: () =>
                              setModalState(() => tempSortBy = 'price_asc'),
                        ),
                        _buildFilterChip(
                          label: 'Price: High to Low',
                          selected: tempSortBy == 'price_desc',
                          onTap: () =>
                              setModalState(() => tempSortBy = 'price_desc'),
                        ),
                        _buildFilterChip(
                          label: 'Highest Rated',
                          selected: tempSortBy == 'rating',
                          onTap: () =>
                              setModalState(() => tempSortBy = 'rating'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price Tier Section
                    Text(
                      'PRICE TIER',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: 'All Prices',
                          selected: tempPriceTier == null,
                          onTap: () =>
                              setModalState(() => tempPriceTier = null),
                        ),
                        _buildFilterChip(
                          label: r'$ (Under $5)',
                          selected: tempPriceTier == r'$',
                          onTap: () =>
                              setModalState(() => tempPriceTier = r'$'),
                        ),
                        _buildFilterChip(
                          label: r'$$ ($5 - $15)',
                          selected: tempPriceTier == r'$$',
                          onTap: () =>
                              setModalState(() => tempPriceTier = r'$$'),
                        ),
                        _buildFilterChip(
                          label: r'$$$ ($15+)',
                          selected: tempPriceTier == r'$$$',
                          onTap: () =>
                              setModalState(() => tempPriceTier = r'$$$'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dietary Preference Section
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.eco, size: 20, color: accentGreen),
                              const SizedBox(width: 10),
                              Text(
                                'Vegetarian Friendly',
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: tempVegetarian,
                            activeTrackColor: GlassTheme.primaryGreen,
                            onChanged: (val) =>
                                setModalState(() => tempVegetarian = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rating Filter Section
                    Text(
                      'MINIMUM RATING',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: 'Any Rating',
                          selected: tempMinRating == null,
                          onTap: () =>
                              setModalState(() => tempMinRating = null),
                        ),
                        _buildFilterChip(
                          label: '4.0+ Stars',
                          icon: Icons.star,
                          selected: tempMinRating == 4.0,
                          onTap: () => setModalState(() => tempMinRating = 4.0),
                        ),
                        _buildFilterChip(
                          label: '4.5+ Stars',
                          icon: Icons.star,
                          selected: tempMinRating == 4.5,
                          onTap: () => setModalState(() => tempMinRating = 4.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Apply Button
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.limeAccent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedPriceTier = tempPriceTier;
                            _isVegetarianOnly = tempVegetarian;
                            _minRating = tempMinRating;
                            _sortBy = tempSortBy;
                          });
                          Navigator.pop(ctx);
                          _performSearch(_searchController.text.trim());
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
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

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? GlassTheme.primaryGreen
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? GlassTheme.primaryGreen
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.amber : const Color(0xFFB45309)),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppTypography.primaryTextColor(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDishDetailSheet(Map<String, dynamic> item) {
    int qty = 1;
    final name = item['name']?.toString() ?? 'Food Item';
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final khrPrice = (price * 4100).toInt();
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
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primaryText = AppTypography.primaryTextColor(
            isDark ? Brightness.dark : Brightness.light,
          );
          final secondaryText = AppTypography.secondaryTextColor(
            isDark ? Brightness.dark : Brightness.light,
          );
          final accentGreen = isDark
              ? GlassTheme.primaryGreen
              : GlassTheme.primaryGreenDark;

          return ResponsiveBottomSheet(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? GlassTheme.dialogDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
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
                        color: isDark ? Colors.white24 : Colors.black26,
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
                          color: isDark ? Colors.white10 : Colors.black12,
                          child: Icon(
                            Icons.fastfood,
                            size: 48,
                            color: accentGreen,
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
                          style: TextStyle(
                            color: primaryText,
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
                                  : secondaryText,
                            ),
                            onPressed: () => favs.toggleFoodItem(item),
                          );
                        },
                      ),
                    ],
                  ),
                  if (restName != null && restName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: restId != null
                          ? () {
                              Navigator.pop(sheetCtx);
                              context.push('/restaurant/$restId');
                            }
                          : null,
                      child: Row(
                        children: [
                          Icon(Icons.storefront, size: 14, color: accentGreen),
                          const SizedBox(width: 6),
                          Text(
                            restName,
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    style: TextStyle(color: secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${(price * qty).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: accentGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '~${(khrPrice * qty)} KHR',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: qty > 1
                                  ? () => setSheetState(() => qty--)
                                  : null,
                              icon: Icon(
                                Icons.remove,
                                size: 18,
                                color: qty > 1 ? primaryText : secondaryText,
                              ),
                            ),
                            Text(
                              '$qty',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setSheetState(() => qty++),
                              icon: Icon(
                                Icons.add,
                                size: 18,
                                color: accentGreen,
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
                          fontSize: 15,
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
                            content: Text(
                              'Added $qty "$name" to your cart!',
                              style: const TextStyle(color: Colors.white),
                            ),
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
          );
        },
      ),
    );
  }

  Widget _buildScopePill(String title, SearchScope scope, int count) {
    final isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () => setState(() => _selectedScope = scope),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? GlassTheme.primaryGreen
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? GlassTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> r) {
    final rating = double.tryParse(r['rating']?.toString() ?? '0') ?? 0.0;
    final deliveryFee =
        double.tryParse(r['delivery_fee']?.toString() ?? '0') ?? 0.0;
    final minTime = r['delivery_time_min'] ?? 15;
    final maxTime = r['delivery_time_max'] ?? 35;
    final logo = r['logo']?.toString();
    final banner = r['banner']?.toString();
    final imgUrl = (logo != null && logo.isNotEmpty) ? logo : banner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        onTap: () => context.push('/restaurant/${r['id']}'),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: GlassTheme.borderRadiusSmall,
              child: Container(
                width: 72,
                height: 72,
                color: Colors.white.withValues(alpha: 0.05),
                child: (imgUrl != null && imgUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.storefront,
                          size: 36,
                          color: GlassTheme.primaryGreen,
                        ),
                      )
                    : const Icon(
                        Icons.storefront,
                        size: 36,
                        color: GlassTheme.primaryGreen,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name']?.toString() ?? 'Restaurant',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$minTime-$maxTime min',
                        style: const TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deliveryFee == 0
                            ? 'Free Delivery'
                            : '\$${deliveryFee.toStringAsFixed(2)} del.',
                        style: TextStyle(
                          color: deliveryFee == 0
                              ? GlassTheme.primaryGreen
                              : GlassTheme.textMuted,
                          fontSize: 12,
                          fontWeight: deliveryFee == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (r['address'] != null &&
                      r['address'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r['address'].toString(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white38,
            ),
          ],
        ),
      ).animate().fade().slideX(),
    );
  }

  Widget _buildDishCard(Map<String, dynamic> item) {
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final int? restId = item['restaurant'] is int
        ? item['restaurant'] as int
        : (item['restaurant'] is Map ? item['restaurant']['id'] as int? : null);
    final String? restName = item['restaurant_name']?.toString();
    final bool isVeg = item['is_vegetarian'] == true;

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
                color: Colors.white.withValues(alpha: 0.05),
                child:
                    item['image'] != null && item['image'].toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item['image'].toString(),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: GlassTheme.primaryGreen,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVeg) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.eco,
                          size: 14,
                          color: GlassTheme.primaryGreen,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: GlassTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '~${(price * 4100).toInt()} KHR',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (restName != null && restName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      restName,
                      style: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: () {
                final cart = context.read<CartProvider>();
                cart.addItem(
                  item['id'] is int
                      ? item['id'] as int
                      : int.parse(item['id'].toString()),
                  item['name']?.toString() ?? 'Food Item',
                  price,
                  item['image']?.toString(),
                  restaurantId: restId,
                  restaurantName: restName,
                );
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['name']} added to cart!'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: GlassTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: Colors.white,
                      onPressed: () => context.push('/cart'),
                    ),
                  ),
                );
              },
              child: GlassContainer(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.add, color: GlassTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ).animate().fade().slideX(),
    );
  }

  Widget _buildEmptyState() {
    final query = _searchController.text.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VectorIllustration(
              type: VectorIllustrationType.noSearchResults,
              size: 140,
            ),
            const SizedBox(height: 14),
            Text(
              query.isNotEmpty
                  ? 'No results found for "$query"'
                  : 'No matches found with current filters',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try checking for spelling errors, adjusting price tiers, or clearing active filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_activeFilterCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlassTheme.primaryGreen,
                        side: BorderSide(color: GlassTheme.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset Filters'),
                      onPressed: () {
                        setState(() {
                          _selectedPriceTier = null;
                          _isVegetarianOnly = false;
                          _minRating = null;
                          _sortBy = 'recommended';
                        });
                        _performSearch(_searchController.text.trim());
                      },
                    ),
                  ),
                if (query.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.limeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Text(
                      'Clear Query',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final hasSearched = query.isNotEmpty || _activeFilterCount > 0;
    final totalDishes = _foodResults.length;
    final totalRestaurants = _restaurantResults.length;
    final totalCount = totalDishes + totalRestaurants;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          'Search FoodGo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveWebContainer(
          maxWidth: 1000,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // Search Bar & Filter Action Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search dishes, restaurants, cravings...',
                            hintStyle: const TextStyle(
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
                    ),
                    const SizedBox(width: 10),
                    // Tune / Filter Button with Badge
                    InkWell(
                      onTap: _showFilterModal,
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _activeFilterCount > 0
                                  ? GlassTheme.primaryGreen.withValues(
                                      alpha: 0.25,
                                    )
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _activeFilterCount > 0
                                    ? GlassTheme.primaryGreen
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              Icons.tune,
                              size: 20,
                              color: _activeFilterCount > 0
                                  ? GlassTheme.limeAccent
                                  : Colors.white70,
                            ),
                          ),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: GlassTheme.limeAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Scope Segmented Tabs (All / Dishes / Restaurants) when search is executed
                if (hasSearched && !_isLoading) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildScopePill('All', SearchScope.all, totalCount),
                        const SizedBox(width: 8),
                        _buildScopePill(
                          'Dishes',
                          SearchScope.dishes,
                          totalDishes,
                        ),
                        const SizedBox(width: 8),
                        _buildScopePill(
                          'Restaurants',
                          SearchScope.restaurants,
                          totalRestaurants,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // When query is empty and no active filters: show Recent & Quick Craving chips
                if (!hasSearched) ...[
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
                          onTap: _clearAllRecentSearches,
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: GlassTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
                            child: Chip(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              avatar: const Icon(
                                Icons.history,
                                size: 14,
                                color: GlassTheme.primaryGreen,
                              ),
                              label: InkWell(
                                onTap: () {
                                  _searchController.text = tag;
                                  _performSearch(tag);
                                },
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white60,
                              ),
                              onDeleted: () => _removeRecentSearch(tag),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Text(
                    'Quick Cravings',
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
                      children: _quickCategories.map((cat) {
                        final name = cat['name'] as String;
                        final icon = cat['icon'] as IconData;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.06,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            avatar: Icon(
                              icon,
                              size: 15,
                              color: GlassTheme.limeAccent,
                            ),
                            label: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () {
                              _searchController.text = name;
                              _performSearch(name);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Results View
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 4,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: ShimmerFoodCard(),
                          ),
                        )
                      : !hasSearched
                      ? Center(
                          child: GlassCard(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.restaurant_menu,
                                  size: 56,
                                  color: GlassTheme.primaryGreen,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Explore Food & Restaurants',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Search for favorite dishes, restaurants, or select a craving chip above!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: GlassTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : totalCount == 0
                      ? _buildEmptyState()
                      : ListView(
                          children: [
                            // 1. Restaurants Section (when Scope is 'all' or 'restaurants')
                            if ((_selectedScope == SearchScope.all ||
                                    _selectedScope ==
                                        SearchScope.restaurants) &&
                                _restaurantResults.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.storefront,
                                        size: 16,
                                        color: GlassTheme.limeAccent,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Restaurants (${_restaurantResults.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedScope == SearchScope.all &&
                                      _restaurantResults.length > 2)
                                    InkWell(
                                      onTap: () => setState(
                                        () => _selectedScope =
                                            SearchScope.restaurants,
                                      ),
                                      child: const Text(
                                        'View All',
                                        style: TextStyle(
                                          color: GlassTheme.primaryGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ..._restaurantResults
                                  .take(
                                    _selectedScope == SearchScope.all ? 3 : 100,
                                  )
                                  .map((r) => _buildRestaurantCard(r)),
                              const SizedBox(height: 12),
                            ],

                            // 2. Dishes Section (when Scope is 'all' or 'dishes')
                            if ((_selectedScope == SearchScope.all ||
                                    _selectedScope == SearchScope.dishes) &&
                                _foodResults.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.fastfood,
                                    size: 16,
                                    color: GlassTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dishes (${_foodResults.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ..._foodResults.map(
                                (item) => _buildDishCard(item),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
