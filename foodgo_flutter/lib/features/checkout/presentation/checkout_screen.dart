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
  String _selectedProvider = 'ABA'; // 'ABA', 'ACLEDA', 'WALLET', 'COD'
  bool _isProcessing = false;
  Map<String, dynamic>? _wallet;
  final ApiService _api = ApiService();
  final FlutterPaymentService _paymentService = FlutterPaymentService();

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final data = await _api.get('wallets/my_wallet/');
      if (mounted) setState(() => _wallet = data);
    } catch (_) {}
  }

  Future<void> _handlePlaceOrder(CartProvider cart, double total) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    final double walletBalance = double.tryParse(_wallet?['balance']?.toString() ?? '0') ?? 0.0;
    if (_selectedProvider == 'WALLET' && walletBalance < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance (\$${walletBalance.toStringAsFixed(2)}). Please top up your account.'),
          backgroundColor: Colors.orangeAccent,
          action: SnackBarAction(
            label: 'Top Up',
            textColor: Colors.white,
            onPressed: () => context.push('/wallet'),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Determine accurate restaurantId from cart items or restaurantProvider
      final restaurantProvider = context.read<RestaurantProvider>();
      final int restaurantId = cart.restaurantId ??
          (restaurantProvider.restaurants.isNotEmpty
              ? restaurantProvider.restaurants.first['id']
              : 1);

      // 2. Prepare items payload for direct order creation
      final List<Map<String, dynamic>> itemsPayload = cart.items.values.map((entry) => {
        'food_item': entry.id,
        'quantity': entry.quantity,
      }).toList();

      // 3. Create Order on Django backend with direct items & restaurant
      final orderResponse = await _api.post('orders/', {
        'restaurant': restaurantId,
        'special_instructions': 'FoodGo Order via $_selectedProvider',
        'items': itemsPayload,
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

      if (_selectedProvider == 'COD' || _selectedProvider == 'WALLET') {
        // Order confirmed directly (COD or paid via account wallet)
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
    final double walletBalance = double.tryParse(_wallet?['balance']?.toString() ?? '0') ?? 0.0;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () => context.push('/wallet').then((_) => _fetchWallet()),
                  child: Text('+ Top Up', style: TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // FoodGo Account Balance Option
            _PaymentOptionTile(
              title: 'FoodGo Wallet / Account Balance',
              subtitle: 'Available: \$${walletBalance.toStringAsFixed(2)} · Instant 1-click pay',
              icon: Icons.account_balance_wallet,
              iconColor: GlassTheme.primaryGreen,
              isSelected: _selectedProvider == 'WALLET',
              onTap: () => setState(() => _selectedProvider = 'WALLET'),
            ),
            const SizedBox(height: 10),

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
              iconColor: Colors.amber,
              isSelected: _selectedProvider == 'COD',
              onTap: () => setState(() => _selectedProvider = 'COD'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final total = cart.totalAmount > 0 ? cart.totalAmount + 2.99 : 0.0;
          final bool isWalletInsufficient = _selectedProvider == 'WALLET' && walletBalance < total;

          String buttonText;
          IconData buttonIcon;
          if (_isProcessing) {
            buttonText = 'Processing Order...';
            buttonIcon = Icons.hourglass_empty;
          } else if (_selectedProvider == 'WALLET') {
            if (isWalletInsufficient) {
              buttonText = 'Top Up Wallet (Short \$${(total - walletBalance).toStringAsFixed(2)})';
              buttonIcon = Icons.add_card;
            } else {
              buttonText = 'Pay \$${total.toStringAsFixed(2)} with Wallet';
              buttonIcon = Icons.check_circle_outline;
            }
          } else if (_selectedProvider == 'COD') {
            buttonText = 'Place Cash on Delivery Order';
            buttonIcon = Icons.delivery_dining;
          } else if (_selectedProvider == 'ABA') {
            buttonText = 'Proceed to Pay with ABA KHQR';
            buttonIcon = Icons.qr_code_2;
          } else {
            buttonText = 'Proceed to Pay with ACLEDA KHQR';
            buttonIcon = Icons.qr_code_scanner;
          }

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
                      text: buttonText,
                      icon: buttonIcon,
                      onPressed: _isProcessing
                          ? () {}
                          : isWalletInsufficient
                              ? () => context.push('/wallet').then((_) => _fetchWallet())
                              : () => _handlePlaceOrder(cart, total),
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
              child: Icon(icon, color: iconColor, size: 26),
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
