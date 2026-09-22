import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../services/api_service.dart';
import '../../payment/services/payment_service.dart';
import '../../payment/screens/qr_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedProvider = 'ABA'; // 'ABA', 'ACLEDA', 'COD'
  bool _isProcessing = false;
  final ApiService _api = ApiService();
  final FlutterPaymentService _paymentService = FlutterPaymentService();

  Future<void> _handlePlaceOrder(CartProvider cart, double total) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Get first active restaurant or fallback to 1
      final restaurantProvider = context.read<RestaurantProvider>();
      final int restaurantId = restaurantProvider.restaurants.isNotEmpty
          ? restaurantProvider.restaurants.first['id']
          : 1;

      // 2. Sync cart items to backend cart before creating order
      for (final entry in cart.items.values) {
        try {
          await _api.post('cart-items/', {
            'food_item': entry.id,
            'quantity': entry.quantity,
          });
        } catch (_) {}
      }

      // 3. Create Order on Django backend
      final orderResponse = await _api.post('orders/', {
        'restaurant': restaurantId,
        'special_instructions': 'FoodGo Order via $_selectedProvider',
      });

      final int orderId = orderResponse['id'];

      // 4. Create Payment on backend
      final payment = await _paymentService.createPayment(
        orderId: orderId,
        provider: _selectedProvider,
        currency: 'USD',
      );

      cart.clear();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (_selectedProvider == 'COD') {
        // COD order is confirmed directly
        context.go('/order-success');
      } else {
        // Navigate to KHQR Screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QRPaymentScreen(payment: payment),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placement failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Checkout',
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: GlassTheme.primaryGreen, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('123 Street, Phnom Penh', style: TextStyle(color: GlassTheme.textMuted)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/addresses'),
                    child: const Icon(Icons.edit, color: GlassTheme.primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ABA KHQR Option
            _PaymentOptionTile(
              title: 'ABA KHQR (Dynamic QR)',
              subtitle: 'Scan with ABA Mobile or any Bakong app',
              icon: Icons.qr_code_2,
              iconColor: const Color(0xFF005A87),
              isSelected: _selectedProvider == 'ABA',
              onTap: () => setState(() => _selectedProvider = 'ABA'),
            ),
            const SizedBox(height: 10),

            // ACLEDA KHQR Option
            _PaymentOptionTile(
              title: 'ACLEDA KHQR',
              subtitle: 'Pay via ACLEDA mobile & Bakong network',
              icon: Icons.qr_code_scanner,
              iconColor: const Color(0xFF16325C),
              isSelected: _selectedProvider == 'ACLEDA',
              onTap: () => setState(() => _selectedProvider = 'ACLEDA'),
            ),
            const SizedBox(height: 10),

            // Cash on Delivery Option
            _PaymentOptionTile(
              title: 'Cash on Delivery (COD)',
              subtitle: 'Pay cash directly to driver upon delivery',
              icon: Icons.delivery_dining,
              iconColor: GlassTheme.primaryGreen,
              isSelected: _selectedProvider == 'COD',
              onTap: () => setState(() => _selectedProvider = 'COD'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final total = cart.totalAmount > 0 ? cart.totalAmount + 2.99 : 0.0;
          return GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            padding: const EdgeInsets.all(24.0),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: GlassButton(
                      text: _isProcessing
                          ? 'Processing Order...'
                          : (_selectedProvider == 'COD' ? 'Place COD Order' : 'Proceed to KHQR Pay'),
                      icon: _isProcessing ? Icons.hourglass_empty : Icons.lock_outline,
                      onPressed: _isProcessing ? () {} : () => _handlePlaceOrder(cart, total),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? GlassTheme.primaryGreen : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}
