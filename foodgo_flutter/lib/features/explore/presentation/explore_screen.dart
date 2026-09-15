import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: GlassAppBar(
        title: 'Explore',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
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
            Text('Popular Restaurants', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildRestaurantCard('Glass Burger', '4.8 (120 reviews) • Burger'),
            const SizedBox(height: 12),
            _buildRestaurantCard('Crystal Pizza', '4.5 (90 reviews) • Pizza'),
            const SizedBox(height: 12),
            _buildRestaurantCard('Vegan Window', '4.9 (200 reviews) • Healthy'),
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

  Widget _buildRestaurantCard(String name, String details) {
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
            ),
            child: const Icon(Icons.restaurant, color: GlassTheme.primaryGreen, size: 40),
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
