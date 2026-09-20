import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final items = await ApiService().get('food-items/');
      final queryLower = query.toLowerCase();
      final filtered = (items as List).where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        return name.contains(queryLower);
      }).toList();
      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
                onChanged: _performSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for pizza, burger...',
                  hintStyle: TextStyle(color: GlassTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, color: GlassTheme.primaryGreen),
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
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty
                        ? const Center(child: Text('No food found matching your search.'))
                        : _searchResults.isEmpty
                            ? GlassCard(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey),
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
                                              image: item['image'] != null
                                                  ? DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover)
                                                  : null,
                                            ),
                                            child: item['image'] == null ? const Icon(Icons.fastfood, size: 40, color: GlassTheme.primaryGreen) : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Text('\$${item['price']}', style: const TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              context.read<CartProvider>().addItem(
                                                item['id'],
                                                item['name'],
                                                double.parse(item['price'].toString()),
                                                item['image']
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${item['name']} added to cart!'),
                                                  duration: const Duration(seconds: 1),
                                                  backgroundColor: GlassTheme.primaryGreen,
                                                )
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
