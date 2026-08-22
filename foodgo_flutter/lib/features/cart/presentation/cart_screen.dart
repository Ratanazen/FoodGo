import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Your Cart',
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: GlassTheme.primaryGreen),
                  const SizedBox(height: 24),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Discover delicious food', style: TextStyle(color: GlassTheme.textMuted)),
                  const SizedBox(height: 32),
                  GlassButton(
                    text: 'Explore Food',
                    onPressed: () => context.go('/explore'),
                  ),
                ],
              ),
            );
          }
          final cartItems = cart.items.values.toList();
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: GlassTheme.borderRadiusSmall,
                                image: item.image != null
                                    ? DecorationImage(
                                        image: NetworkImage(item.image!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.image == null ? const Icon(Icons.fastfood, size: 40, color: GlassTheme.primaryGreen) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            GlassContainer(
                              borderRadius: GlassTheme.borderRadiusSmall,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      cart.removeItem(item.id);
                                    }, 
                                    icon: const Icon(Icons.remove, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      cart.addItem(item.id, item.name, item.price, item.image);
                                    }, 
                                    icon: const Icon(Icons.add, size: 20, color: GlassTheme.primaryGreen),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ).animate().fade(delay: (100 * index).ms).slideX(),
                    );
                  },
                ),
              ),
              GlassContainer(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                padding: const EdgeInsets.all(24.0),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 16)),
                          Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery Fee', style: TextStyle(fontSize: 16)),
                          Text('\$2.99', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount', style: TextStyle(fontSize: 16)),
                          Text('-\$0.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: GlassTheme.borderLight),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('\$${(cart.totalAmount + 2.99).toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          text: 'Proceed to Checkout',
                          onPressed: () => context.push('/checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 1.0),
            ],
          );
        }
      ),
    );
  }
}
