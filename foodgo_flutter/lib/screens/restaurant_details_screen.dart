import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  const RestaurantDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Delicious Restaurant 0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                color: Colors.grey.shade800,
                child: const Center(child: Icon(Icons.restaurant, size: 80, color: Colors.white54)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const Text(' 4.5  •  Fast Food  •  \$\$', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 18),
                      const Text(' 15-25 min', style: TextStyle(fontSize: 16)),
                    ],
                  ).animate().fade(delay: 200.ms).slideY(),
                  const SizedBox(height: 24),
                  const Text('Menu Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)).animate().fade(delay: 300.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fastfood),
                  ),
                  title: Text('Menu Item $index', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Delicious description of the food item goes here.'),
                  trailing: Text('\$${(index + 5).toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  onTap: () {}, // Navigate to food details
                ).animate().fade(delay: (400 + 100 * index).ms).slideX();
              },
              childCount: 10,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/cart'),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('View Cart'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ).animate().fade(delay: 1000.ms).scale(),
    );
  }
}
