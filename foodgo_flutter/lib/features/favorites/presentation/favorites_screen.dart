import 'package:flutter/material.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass/glass_food_card.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming empty state for demonstration, usually backed by provider
    

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Favorites',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassFoodCard(
                  id: 'fav_$index',
                  title: 'Favorite Meal $index',
                  subtitle: 'Delicious Restaurant',
                  price: '\$14.99',
                  rating: '4.8',
                  imageUrl: '',
                  onTap: () {},
                  onAddTap: () {},
                ),
              );
            },
          ),
    );
  }
}
