import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../providers/restaurant_provider.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Explore',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassSearchBar(),
            const SizedBox(height: 24),
            Text('Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryCard('Burger', Icons.fastfood),
                  _buildCategoryCard('Pizza', Icons.local_pizza),
                  _buildCategoryCard('Healthy', Icons.eco),
                  _buildCategoryCard('Drinks', Icons.local_drink),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('All Restaurants', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Consumer<RestaurantProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen));
                }
                
                final restaurants = provider.restaurants;
                if (restaurants.isEmpty) {
                  return const Center(child: Text('No restaurants found.'));
                }
                
                return Column(
                  children: restaurants.map((restaurant) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => context.push('/restaurant/${restaurant["id"]}'),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        child: _buildRestaurantCard(
                          restaurant['name'] ?? 'Unknown',
                          '${restaurant['rating'] ?? 'New'} • ${restaurant['address'] ?? 'No address'}',
                          restaurant['banner'],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 80,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: GlassTheme.primaryGreen, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(String name, String details, String? imageUrl) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
              borderRadius: GlassTheme.borderRadiusSmall,
              image: imageUrl != null 
                ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                : null,
            ),
            child: imageUrl == null ? const Icon(Icons.restaurant, color: GlassTheme.primaryGreen, size: 40) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: GlassTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
