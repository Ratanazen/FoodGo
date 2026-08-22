import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final String? id;
  const RestaurantDetailsScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: '',
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(24),
                  child: Hero(
                    tag: 'restaurant_title_$id',
                    child: Text(
                      'Delicious Restaurant ${id ?? '0'}', 
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: GlassTheme.borderRadiusSmall,
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Text('4.5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(width: 1, height: 20, color: GlassTheme.textMuted),
                        const Spacer(),
                        const Icon(Icons.fastfood, color: GlassTheme.primaryGreen),
                        const SizedBox(width: 8),
                        const Text('Fast Food', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        Container(width: 1, height: 20, color: GlassTheme.textMuted),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 18, color: GlassTheme.textMuted),
                        const SizedBox(width: 8),
                        const Text('15-25 min', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).slideY(),
                  const SizedBox(height: 32),
                  const Text('Menu Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)).animate().fade(delay: 300.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      onTap: () {},
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: GlassTheme.borderRadiusSmall,
                            ),
                            child: const Icon(Icons.fastfood, size: 40, color: GlassTheme.primaryGreen),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Menu Item $index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Delicious description of the food item goes here.',
                                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text('\$${(index + 5).toStringAsFixed(2)}', style: const TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          GlassContainer(
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.add, color: GlassTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: (400 + 100 * index).ms).slideX(),
                  );
                },
                childCount: 10,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for checkout bar
        ],
      ),
      bottomSheet: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Price', style: TextStyle(color: GlassTheme.textMuted, fontSize: 14)),
                    const Text('\$0.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
              ),
              GlassButton(
                text: 'View Cart',
                icon: Icons.shopping_cart,
                onPressed: () => context.push('/cart'),
              ),
            ],
          ),
        ),
      ).animate().fade(delay: 800.ms).slideY(begin: 1.0),
    );
  }
}