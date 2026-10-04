import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../providers/cart_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      final items = await ApiService().get('food-items/');
      if (!mounted) return;
      if (_searchController.text.trim() != query) return;

      final queryLower = query.toLowerCase();
      final filtered = (items as List).where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final desc = (item['description'] ?? '').toString().toLowerCase();
        final category = (item['category_name'] ?? '').toString().toLowerCase();
        return name.contains(queryLower) || desc.contains(queryLower) || category.contains(queryLower);
      }).toList();

      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Search Food',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for pizza, burger, Khmer dishes...',
                  hintStyle: TextStyle(color: GlassTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, color: GlassTheme.primaryGreen),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: GlassTheme.borderRadiusSmall,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen))
                    : _searchResults.isEmpty && _searchController.text.trim().isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 54, color: GlassTheme.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No food found matching "${_searchController.text.trim()}"',
                                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 15),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _searchResults.isEmpty
                            ? GlassCard(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.restaurant_menu, size: 64, color: GlassTheme.primaryGreen),
                                    SizedBox(height: 16),
                                    Text('Find your craving', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Text('Start typing to find delicious food!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final item = _searchResults[index];
                                  final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                                  final int? restId = item['restaurant'] is int 
                                      ? item['restaurant'] as int 
                                      : (item['restaurant'] is Map ? item['restaurant']['id'] as int? : null);
                                  final String? restName = item['restaurant_name']?.toString();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.2),
                                              borderRadius: GlassTheme.borderRadiusSmall,
                                              image: item['image'] != null && item['image'].toString().isNotEmpty
                                                  ? DecorationImage(
                                                      image: CachedNetworkImageProvider(item['image']),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: item['image'] == null || item['image'].toString().isEmpty
                                                ? const Icon(Icons.fastfood, size: 40, color: GlassTheme.primaryGreen)
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name']?.toString() ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${price.toStringAsFixed(2)}',
                                                  style: const TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                if (restName != null && restName.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    restName,
                                                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              context.read<CartProvider>().addItem(
                                                item['id'] is int ? item['id'] as int : int.parse(item['id'].toString()),
                                                item['name']?.toString() ?? 'Food Item',
                                                price,
                                                item['image']?.toString(),
                                                restaurantId: restId,
                                                restaurantName: restName,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${item['name']} added to cart!'),
                                                  duration: const Duration(seconds: 1),
                                                  backgroundColor: GlassTheme.primaryGreen,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            child: GlassContainer(
                                              borderRadius: BorderRadius.circular(20),
                                              padding: const EdgeInsets.all(8),
                                              child: const Icon(Icons.add, color: GlassTheme.primaryGreen),
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
