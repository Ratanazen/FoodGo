import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/svg_icon.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../services/api_service.dart';
import '../../payment/services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedProvider = 'BAKONG'; // 'BAKONG', 'ABA', 'ACLEDA', 'COD'
  bool _isProcessing = false;
  int? _selectedDriverId; // null = Auto-assign fastest driver
  List<Map<String, dynamic>> _availableDrivers = [];
  bool _isLoadingDrivers = true;
  final ApiService _api = ApiService();
  final FlutterPaymentService _paymentService = FlutterPaymentService();

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      final res = await _api.get('drivers/?online=true');
      final List<dynamic> list = res is List ? res : (res['results'] as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _availableDrivers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoadingDrivers = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fallback demo drivers for uninterrupted testing
      setState(() {
        _availableDrivers = [
          {
            'id': 1,
            'full_name': 'Bob Rider',
            'vehicle_type': 'Motorcycle (Honda Wave 125i)',
            'rating': 4.9,
            'phone': '+855 12 888 999',
            'is_online': true,
          },
          {
            'id': 3,
            'full_name': 'Sophea Swift',
            'vehicle_type': 'Scooter (Yamaha Fazzio 125)',
            'rating': 5.0,
            'phone': '+855 12 777 666',
            'is_online': true,
          },
        ];
        _isLoadingDrivers = false;
      });
    }
  }

  Future<void> _handlePlaceOrder(CartProvider cart, double total) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
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
      final List<Map<String, dynamic>> itemsPayload = cart.items.values.map((entry) {
        return <String, dynamic>{
          'food_item': entry.id,
          'quantity': entry.quantity,
        };
      }).toList();

      // 3. Create Order on Django backend with direct items, restaurant & selected driver
      final Map<String, dynamic> orderPayload = {
        'restaurant': restaurantId,
        'special_instructions': 'FoodGo Order via $_selectedProvider',
        'items': itemsPayload,
      };
      if (_selectedDriverId != null) {
        orderPayload['driver_id'] = _selectedDriverId;
      }

      final orderResponse = await _api.post('orders/', orderPayload);

      final int orderId = orderResponse['id'];
      cart.setLastOrderId(orderId);

      // 4. Create Payment on backend
      final payment = await _paymentService.createPayment(
        orderId: orderId,
        provider: _selectedProvider,
        currency: 'USD',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (_selectedProvider == 'COD') {
        // Order confirmed directly (COD)
        cart.clear();
        context.go('/order-success', extra: orderId);
      } else {
        // Navigate to KHQR Screen (Bakong, ABA, ACLEDA)
        // Cart will be cleared upon confirmed PAID status in QRPaymentScreen
        context.push('/qr-payment', extra: payment);
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
                  const SvgAssetIcon(assetName: 'restaurant_pin', size: 30, color: GlassTheme.primaryGreen),
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

            // Choose Delivery Driver Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Choose Delivery Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_selectedDriverId != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDriverId = null),
                    child: const Text('Reset to Auto', style: TextStyle(color: GlassTheme.primaryGreen, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Option 1: Auto-assign fastest driver
            GestureDetector(
              onTap: () => setState(() => _selectedDriverId = null),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedDriverId == null ? GlassTheme.primaryGreen : Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('Fastest Available Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 6),
                              Text('⚡ Auto-Assign', style: TextStyle(color: GlassTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('System automatically pairs with nearest top-rated rider', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(
                      _selectedDriverId == null ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: _selectedDriverId == null ? GlassTheme.primaryGreen : Colors.white38,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Option 2: Specific available drivers
            if (_isLoadingDrivers)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: GlassTheme.primaryGreen)))
            else
              ..._availableDrivers.map((driver) {
                final driverId = driver['id'] as int;
                final name = driver['full_name'] ?? driver['username'] ?? 'Delivery Driver';
                final vehicle = driver['vehicle_type'] ?? 'Motorcycle';
                final plate = driver['license_plate'] ?? 'PP-2026';
                final rating = driver['rating']?.toString() ?? '4.9';
                final isSelected = _selectedDriverId == driverId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDriverId = driverId),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? GlassTheme.primaryGreen : Colors.white12,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 12),
                                          const SizedBox(width: 2),
                                          Text(rating, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('$vehicle • $plate', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? GlassTheme.primaryGreen : Colors.white38,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Bakong KHQR Option (NBC Open API)
            _PaymentOptionTile(
              title: 'Bakong KHQR (NBC Open API)',
              subtitle: 'Scan with Bakong or any Cambodian banking app',
              svgAsset: 'bakong_logo',
              iconColor: GlassTheme.bakongRed,
              isSelected: _selectedProvider == 'BAKONG',
              onTap: () => setState(() => _selectedProvider = 'BAKONG'),
            ),
            const SizedBox(height: 10),

            // ABA KHQR Option
            _PaymentOptionTile(
              title: 'ABA KHQR (Dynamic QR)',
              subtitle: 'Scan with ABA Mobile or any KHQR app',
              svgAsset: 'khqr_logo',
              iconColor: GlassTheme.abaBlue,
              isSelected: _selectedProvider == 'ABA',
              onTap: () => setState(() => _selectedProvider = 'ABA'),
            ),
            const SizedBox(height: 10),

            // ACLEDA KHQR Option
            _PaymentOptionTile(
              title: 'ACLEDA KHQR',
              subtitle: 'Pay via ACLEDA mobile & Bakong network',
              icon: Icons.qr_code_scanner,
              iconColor: GlassTheme.acledaNavy,
              isSelected: _selectedProvider == 'ACLEDA',
              onTap: () => setState(() => _selectedProvider = 'ACLEDA'),
            ),
            const SizedBox(height: 10),

            // Cash on Delivery Option
            _PaymentOptionTile(
              title: 'Cash on Delivery (COD)',
              subtitle: 'Pay cash directly to driver upon delivery',
              svgAsset: 'delivery_bike',
              iconColor: GlassTheme.primaryGreen,
              isSelected: _selectedProvider == 'COD',
              onTap: () => setState(() => _selectedProvider = 'COD'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final total = cart.grandTotal;

          String buttonText;
          IconData buttonIcon;
          if (_isProcessing) {
            buttonText = 'Processing Order...';
            buttonIcon = Icons.hourglass_empty;
          } else if (_selectedProvider == 'COD') {
            buttonText = 'Place Cash on Delivery Order';
            buttonIcon = Icons.delivery_dining;
          } else if (_selectedProvider == 'BAKONG') {
            buttonText = 'Proceed to Pay with Bakong KHQR';
            buttonIcon = Icons.qr_code_2;
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
  final IconData? icon;
  final String? svgAsset;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    this.icon,
    this.svgAsset,
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
              child: svgAsset != null
                  ? SvgAssetIcon(assetName: svgAsset!, size: 26)
                  : Icon(icon ?? Icons.payment, color: iconColor, size: 26),
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
