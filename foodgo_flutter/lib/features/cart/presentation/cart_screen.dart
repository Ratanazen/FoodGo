import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Widget _buildCartItemCard(CartProvider cart, CartItem item, int index) {
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
                        image: CachedNetworkImageProvider(item.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.image == null
                  ? const Icon(Icons.fastfood, size: 40, color: GlassTheme.primaryGreen)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      cart.decrementItem(item.id);
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
                      cart.addItem(
                        item.id,
                        item.name,
                        item.price,
                        item.image,
                        restaurantId: item.restaurantId,
                        restaurantName: item.restaurantName,
                      );
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
  }

  Widget _buildSummaryCard(BuildContext context, CartProvider cart, {bool isDesktop = false}) {
    return GlassContainer(
      borderRadius: isDesktop ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(32)),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        bottom: !isDesktop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop) ...[
              const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 16)),
                Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee', style: TextStyle(fontSize: 16)),
                Text('\$${cart.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                Text('\$${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen)),
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
    );
  }

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
          final isWide = ResponsiveBreakpoints.isWide(context);

          if (isWide) {
            return ResponsiveWebContainer(
              maxWidth: 1050,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) =>
                            _buildCartItemCard(cart, cartItems[index], index),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildSummaryCard(context, cart, isDesktop: true)
                          .animate()
                          .fade(delay: 200.ms)
                          .slideX(begin: 0.1),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) =>
                      _buildCartItemCard(cart, cartItems[index], index),
                ),
              ),
              _buildSummaryCard(context, cart, isDesktop: false)
                  .animate()
                  .fade(delay: 200.ms)
                  .slideY(begin: 1.0),
            ],
          );
        },
      ),
    );
  }
}
