import "package:provider/provider.dart";
import "../../../providers/restaurant_provider.dart";
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => context.push('/addresses'),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: GlassTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deliver to', style: TextStyle(color: GlassTheme.textMuted, fontSize: 10)),
                          Row(
                            children: [
                              Text('Phnom Penh', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GlassContainer(
                  padding: const EdgeInsets.all(8),
                  borderRadius: GlassTheme.borderRadiusSmall,
                  child: InkWell(
                    onTap: () => context.push('/notifications'),
                    child: const Icon(Icons.notifications_none, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'What are you craving?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => context.push('/search'),
              child: const GlassSearchBar(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => context.push('/explore'), child: const Text('See all', style: TextStyle(color: GlassTheme.primaryGreen))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  final categories = ['Pizza', 'Burger', 'Ramen', 'Chicken', 'Healthy'];
                  final icons = [Icons.local_pizza, Icons.lunch_dining, Icons.soup_kitchen, Icons.set_meal, Icons.eco];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: InkWell(
                      onTap: () => context.push('/explore'),
                      borderRadius: GlassTheme.borderRadiusSmall,
                      child: Column(
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: GlassTheme.borderRadiusSmall,
                            child: Icon(icons[index], size: 28, color: GlassTheme.primaryGreen),
                          ),
                          const SizedBox(height: 8),
                          Text(categories[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: (100 * index).ms).slideX();
                },
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              customColor: GlassTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: GlassTheme.borderRadiusSmall,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROMOTION', style: TextStyle(color: GlassTheme.primaryGreenDark, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text('30% OFF', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {},
                          child: const Row(
                            children: [
                              Text('Order now', style: TextStyle(fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16, color: GlassTheme.primaryGreen),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.fastfood, size: 80, color: GlassTheme.primaryGreen.withValues(alpha: 0.3)),
                ],
              ),
            ).animate().fade().scale(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Popular Restaurants', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => context.push('/explore'), child: const Text('See all', style: TextStyle(color: GlassTheme.primaryGreen))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Consumer<RestaurantProvider>(
                builder: (context, restaurantProvider, child) {
                  if (restaurantProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen));
                  }
                  
                  final restaurants = restaurantProvider.restaurants;
                  if (restaurants.isEmpty) {
                    return const Center(child: Text("No restaurants found."));
                  }
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: InkWell(
                          onTap: () => context.push('/restaurant/${restaurant["id"]}'),
                          child: GlassContainer(
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            borderRadius: GlassTheme.borderRadiusSmall,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    image: restaurant['banner'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(restaurant['banner']),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: restaurant['banner'] == null ? const Center(child: Icon(Icons.store, size: 40, color: Colors.grey)) : null,
                                ),
                                const SizedBox(height: 12),
                                Text(restaurant['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text('${restaurant['rating'] ?? 'New'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: (200 + 100 * index).ms).slideY(begin: 0.2),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
