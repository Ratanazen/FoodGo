import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/svg_icon.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/restaurant_provider.dart';
import '../../../../providers/address_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../payment/services/payment_service.dart';
import '../../payment/models/payment_model.dart';
import '../../../../core/utils/khmer_currency.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedProvider =
      'BAKONG'; // 'BAKONG', 'ABA', 'ACLEDA', 'COD', 'WALLET'
  bool _isProcessing = false;
  int? _selectedDriverId; // null = Auto-assign fastest driver
  List<Map<String, dynamic>> _availableDrivers = [];
  bool _isLoadingDrivers = true;
  double _walletBalance = 50.00;
  bool _isLoadingWallet = true;
  List<PaymentMethodConfig> _availablePaymentMethods = [];
  bool _isLoadingPaymentMethods = true;

  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _deliveryInstructionsController =
      TextEditingController();
  final ApiService _api = ApiService();
  final FlutterPaymentService _paymentService = FlutterPaymentService();

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    _fetchWalletBalance();
    _fetchPaymentMethods();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cart = context.read<CartProvider>();
      if (cart.specialInstructions.isNotEmpty &&
          _deliveryInstructionsController.text.isEmpty) {
        _deliveryInstructionsController.text = cart.specialInstructions;
      }
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final hasToken = await SecureStorage().hasAccessToken();
      if (!hasToken) {
        if (!mounted) return;
        setState(() => _isLoadingWallet = false);
        return;
      }
      final res = await _api.get('wallets/my_wallet/');
      if (!mounted) return;
      if (res != null && res['balance'] != null) {
        setState(() {
          _walletBalance = double.tryParse(res['balance'].toString()) ?? 50.00;
          _isLoadingWallet = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final methods = await _paymentService.getAvailablePaymentMethods();
      if (!mounted) return;
      setState(() {
        _availablePaymentMethods = methods;
        _isLoadingPaymentMethods = false;
        final isSelectedActive = methods.any((m) => m.code == _selectedProvider && m.isEnabled);
        if (!isSelectedActive && methods.isNotEmpty) {
          final firstEnabled = methods.firstWhere((m) => m.isEnabled, orElse: () => methods.first);
          _selectedProvider = firstEnabled.code;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPaymentMethods = false);
    }
  }

  PaymentMethodConfig? _getMethodConfig(String code) {
    for (final method in _availablePaymentMethods) {
      if (method.code.toUpperCase() == code.toUpperCase()) {
        return method;
      }
    }
    return null;
  }

  Future<void> _fetchDrivers() async {
    try {
      final res = await _api.get('drivers/?online=true');
      final List<dynamic> list = res is List
          ? res
          : (res['results'] as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _availableDrivers = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoadingDrivers = false;
      });
    } catch (_) {
      if (!mounted) return;
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

  void _showAddressPickerModal() {
    final addressProvider = context.read<AddressProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ResponsiveBottomSheet(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GlassTheme.dialogDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...addressProvider.addresses.map((addr) {
                  final isSelected =
                      addressProvider.selectedAddress?.id == addr.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        addressProvider.selectAddress(addr);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GlassTheme.primaryGreen.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? GlassTheme.primaryGreen
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              addr.isDefault
                                  ? AppIcons.home
                                  : AppIcons.locationOutline,
                              color: isSelected
                                  ? GlassTheme.primaryGreen
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        addr.street,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      if (addr.isDefault) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: GlassTheme.primaryGreen
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'Default',
                                            style: TextStyle(
                                              color: GlassTheme.primaryGreen,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addr.city,
                                    style: TextStyle(
                                      color: GlassTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? AppIcons.radioSelected
                                  : AppIcons.radioUnselected,
                              color: isSelected
                                  ? GlassTheme.primaryGreen
                                  : Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/addresses');
                  },
                  icon: Icon(AppIcons.add, color: GlassTheme.primaryGreen),
                  label: const Text(
                    'Manage & Add Addresses',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInsufficientBalanceDialog(double total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(AppIcons.warning, color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Text(
              'Insufficient Balance',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account balance is \$${_walletBalance.toStringAsFixed(2)}, but order total is \$${total.toStringAsFixed(2)}.',
              style: TextStyle(color: GlassTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please select another payment method such as Bakong KHQR, ABA, ACLEDA, or Cash on Delivery.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryGreen,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedProvider = 'BAKONG');
            },
            child: const Text(
              'Pay via Bakong KHQR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.lock,
                color: GlassTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign In Required',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please sign in or create an account to place your order and track live delivery.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text(
              'Sign In / Register',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlaceOrder(CartProvider cart, double total) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    final restaurantProvider = context.read<RestaurantProvider>();
    final addressProvider = context.read<AddressProvider>();

    final hasToken = await SecureStorage().hasAccessToken();
    if (!hasToken) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    if (_selectedProvider == 'WALLET' && _walletBalance < total) {
      _showInsufficientBalanceDialog(total);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Validate the cart against the live catalogue. Never substitute a
      // different restaurant or food item: the customer must see exactly the
      // items they chose, or an actionable error.
      if (restaurantProvider.isDemo) {
        throw const _CheckoutValidationException(
          'This menu is demo data, not live availability. Reconnect to '
          'FoodGo and reload the restaurant before ordering.',
        );
      }

      if (restaurantProvider.restaurants.isEmpty) {
        await restaurantProvider.fetchRestaurants();
        if (!mounted) return;
        if (restaurantProvider.isDemo) {
          throw const _CheckoutValidationException(
            'This menu is demo data, not live availability. Reconnect to '
            'FoodGo and reload the restaurant before ordering.',
          );
        }
        if (restaurantProvider.restaurants.isEmpty) {
          throw const _CheckoutValidationException(
            'We could not verify the restaurant menu with FoodGo. Check '
            'your connection and try again — your cart is unchanged.',
          );
        }
      }

      final liveRestaurants = restaurantProvider.restaurants
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();

      int? readId(Object? value) =>
          value is int ? value : int.tryParse(value?.toString() ?? '');

      final candidateRestId =
          cart.restaurantId ??
          (cart.items.isNotEmpty ? cart.items.values.first.restaurantId : null);

      Map<String, dynamic>? liveRestaurant;
      for (final restaurant in liveRestaurants) {
        if (readId(restaurant['id']) == candidateRestId) {
          liveRestaurant = restaurant;
          break;
        }
      }

      if (candidateRestId == null || liveRestaurant == null) {
        throw const _CheckoutValidationException(
          'This restaurant is no longer available in FoodGo. Remove the '
          'items and choose a restaurant from the live catalogue.',
        );
      }

      final validRestaurantId = candidateRestId;
      final menuFoodIds = <int>{};
      final categories = liveRestaurant['food_categories'];
      if (categories is List) {
        for (final category in categories) {
          if (category is! Map) continue;
          final items = category['items'];
          if (items is! List) continue;
          for (final item in items) {
            if (item is! Map) continue;
            final id = readId(item['id']);
            if (id != null) menuFoodIds.add(id);
          }
        }
      }

      if (menuFoodIds.isEmpty) {
        throw const _CheckoutValidationException(
          'The menu for this restaurant could not be loaded. Refresh the '
          'restaurant and try again — your cart is unchanged.',
        );
      }

      final unavailableItems = cart.items.values.where((entry) {
        final sameRestaurant =
            entry.restaurantId == null ||
            entry.restaurantId == validRestaurantId;
        return !sameRestaurant || !menuFoodIds.contains(entry.id);
      }).toList();

      if (unavailableItems.isNotEmpty) {
        final names = unavailableItems
            .map((item) => item.name)
            .take(3)
            .join(', ');
        throw _CheckoutValidationException(
          'These items are no longer on the live menu: $names. Remove them '
          'from your cart before placing the order.',
        );
      }

      final List<Map<String, dynamic>> itemsPayload = cart.items.values
          .map(
            (entry) => <String, dynamic>{
              'food_item': entry.id,
              'quantity': entry.quantity,
            },
          )
          .toList();

      final selectedAddr = addressProvider.selectedAddress;

      final Map<String, dynamic> orderPayload = {
        'restaurant': validRestaurantId,
        'special_instructions':
            _deliveryInstructionsController.text.trim().isNotEmpty
            ? _deliveryInstructionsController.text.trim()
            : 'FoodGo Order via $_selectedProvider',
        'items': itemsPayload,
      };

      if (selectedAddr != null) {
        orderPayload['address'] = selectedAddr.id;
        orderPayload['delivery_address_snapshot'] = selectedAddr.fullAddress;
      }
      if (_selectedDriverId != null) {
        orderPayload['driver_id'] = _selectedDriverId;
      }
      if (cart.appliedPromoCode != null && cart.appliedPromoCode!.isNotEmpty) {
        orderPayload['coupon_code'] = cart.appliedPromoCode;
      }

      final orderResponse = await _api.post('orders/', orderPayload);

      final int orderId = orderResponse['id'];
      cart.setLastOrderId(orderId);

      // Create Payment on backend
      final payment = await _paymentService.createPayment(
        orderId: orderId,
        provider: _selectedProvider,
        currency: 'USD',
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (_selectedProvider == 'COD' || _selectedProvider == 'WALLET') {
        // Order confirmed directly (COD or Wallet instant pay)
        cart.clear();
        _fetchWalletBalance(); // update balance
        context.go('/order-success', extra: orderId);
      } else {
        // Navigate to KHQR Screen (Bakong, ABA, ACLEDA)
        context.push('/qr-payment', extra: payment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        String errorMsg = e.toString();
        bool isAuthError = false;
        if (e is DioException) {
          if (e.response?.statusCode == 401 ||
              e.message?.contains('refresh token') == true ||
              e.message?.contains('Unauthorized') == true) {
            isAuthError = true;
            errorMsg = 'Session expired. Please sign in to place your order.';
          } else {
            final resData = e.response?.data;
            if (resData is Map) {
              final parts = <String>[];
              resData.forEach((key, val) {
                if (val is List) {
                  parts.add('$key: ${val.join(", ")}');
                } else {
                  parts.add('$key: $val');
                }
              });
              if (parts.isNotEmpty) {
                errorMsg = parts.join(' | ');
              }
            } else if (resData is String && resData.isNotEmpty) {
              errorMsg = resData;
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAuthError ? errorMsg : 'Order placement failed: $errorMsg',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            action: isAuthError
                ? SnackBarAction(
                    label: 'Sign In',
                    textColor: Colors.white,
                    onPressed: () => context.push('/login'),
                  )
                : null,
          ),
        );
        if (isAuthError) {
          _showLoginRequiredDialog();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final addressProvider = context.watch<AddressProvider>();
    final activeAddress = addressProvider.selectedAddress;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Checkout',
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveWebContainer(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Delivery Address Section ─────────────────────────────
              const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SvgAssetIcon(
                      assetName: 'restaurant_pin',
                      size: 30,
                      color: GlassTheme.primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  activeAddress != null
                                      ? activeAddress.street
                                      : 'Home',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (activeAddress?.isDefault == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GlassTheme.primaryGreen.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      color: GlassTheme.primaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeAddress != null
                                ? activeAddress.fullAddress
                                : 'Daun Penh, Phnom Penh, Cambodia',
                            style: TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedPressable(
                      pressedScale: 0.92,
                      onTap: _showAddressPickerModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.primaryGreen.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.35,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 10),

              // Estimated Delivery Time Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: GlassTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      AppIcons.eta,
                      color: GlassTheme.primaryGreen,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Estimated Delivery Time: 25 - 35 mins',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: GlassTheme.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 12),

              // Delivery Instructions
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _deliveryInstructionsController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    icon: const Icon(
                      AppIcons.edit,
                      color: GlassTheme.primaryGreen,
                      size: 20,
                    ),
                    hintText:
                        'Delivery instructions (e.g., Gate code, ring bell, leave at door)...',
                    hintStyle: TextStyle(
                      color: GlassTheme.textMuted,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Choose Delivery Driver Section ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Choose Delivery Driver',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedDriverId != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedDriverId = null),
                      child: const Text(
                        'Reset to Auto',
                        style: TextStyle(
                          color: GlassTheme.primaryGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Option 1: Auto-assign fastest driver
              AnimatedPressable(
                pressedScale: 0.98,
                onTap: () => setState(() => _selectedDriverId = null),
                child: GlassCard(
                  border: Border.all(
                    color: _selectedDriverId == null
                        ? primary
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : const Color(0xFFE5E7EB)),
                    width: _selectedDriverId == null ? 1.6 : 1.2,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedDriverId == null
                              ? primary
                              : (isDark
                                    ? Colors.white12
                                    : const Color(0xFFF0FDF4)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.fastDelivery,
                          color: _selectedDriverId == null
                              ? Colors.white
                              : (isDark ? Colors.white70 : primary),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Fastest Available Driver',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppIcons.fastDelivery,
                                        size: 13,
                                        color: primary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Auto-Assign',
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'System automatically pairs with nearest top-rated rider',
                              style: TextStyle(
                                color: GlassTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selectedDriverId == null
                            ? AppIcons.radioSelected
                            : AppIcons.radioUnselected,
                        color: _selectedDriverId == null
                            ? primary
                            : (isDark
                                  ? Colors.white38
                                  : const Color(0xFFD1D5DB)),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Specific available drivers
              if (_isLoadingDrivers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: GlassTheme.primaryGreen,
                    ),
                  ),
                )
              else
                ..._availableDrivers.map((driver) {
                  final driverId = driver['id'] as int;
                  final name =
                      driver['full_name'] ??
                      driver['username'] ??
                      'Delivery Driver';
                  final vehicle = driver['vehicle_type'] ?? 'Motorcycle';
                  final plate = driver['license_plate'] ?? 'PP-2026';
                  final rating = driver['rating']?.toString() ?? '4.9';
                  final isSelected = _selectedDriverId == driverId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: AnimatedPressable(
                      pressedScale: 0.98,
                      onTap: () => setState(() => _selectedDriverId = driverId),
                      child: GlassCard(
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.14)
                                    : const Color(0xFFE5E7EB)),
                          width: isSelected ? 1.6 : 1.2,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary
                                    : (isDark
                                          ? Colors.white12
                                          : const Color(0xFFF0FDF4)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppIcons.delivery,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : primary),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              AppIcons.star,
                                              color: Colors.amber,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              rating,
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$vehicle • $plate',
                                    style: TextStyle(
                                      color: GlassTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? AppIcons.radioSelected
                                  : AppIcons.radioUnselected,
                              color: isSelected
                                  ? primary
                                  : (isDark
                                        ? Colors.white38
                                        : const Color(0xFFD1D5DB)),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // ── Voucher & Discounts Summary ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voucher & Discount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (cart.appliedPromoCode != null)
                    TextButton(
                      onPressed: () => cart.removePromoCode(),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.coupon,
                      color: GlassTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: cart.appliedPromoCode != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Promo Code "${cart.appliedPromoCode}" Applied',
                                  style: const TextStyle(
                                    color: GlassTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Saving \$${cart.discountAmount.toStringAsFixed(2)} on this order',
                                  style: TextStyle(
                                    color: GlassTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: _voucherController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Promo Code (e.g. FOODGO30)',
                                hintStyle: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (code) {
                                if (cart.applyPromoCode(code)) {
                                  _voucherController.clear();
                                }
                              },
                            ),
                    ),
                    if (cart.appliedPromoCode == null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (cart.applyPromoCode(_voucherController.text)) {
                            _voucherController.clear();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid code. Try FOODGO30, FOODGOFREE',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Select Payment Method Section ────────────────────────
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_isLoadingPaymentMethods && _availablePaymentMethods.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              const SizedBox(height: 12),

              // 1. FoodGo Digital Wallet (Integrated Fintech)
              // 1. FoodGo Account Balance (Direct Instant Pay)
              _PaymentOptionTile(
                title: 'FoodGo Balance (សមតុល្យគណនី)',
                subtitle: _isLoadingWallet
                    ? 'Checking account balance...'
                    : 'Balance: \$${_walletBalance.toStringAsFixed(2)} (${KhmerCurrency.formatKhr(_walletBalance)}) • 1-Tap Pay',
                icon: AppIcons.wallet,
                iconColor: Theme.of(context).colorScheme.primary,
                isSelected: _selectedProvider == 'WALLET',
                badge: _walletBalance >= cart.grandTotal
                    ? 'INSTANT PAY'
                    : 'LOW BALANCE',
                badgeColor: _walletBalance >= cart.grandTotal
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white24,
                onTap: () => setState(() => _selectedProvider = 'WALLET'),
              ),
              const SizedBox(height: 10),

              // 2. Bakong KHQR Option (NBC Open API)
              _PaymentOptionTile(
                title: 'Bakong KHQR (ធនាគារជាតិនៃកម្ពុជា)',
                subtitle: 'Scan with Bakong or any Cambodian bank in USD / KHR',
                svgAsset: 'bakong_logo',
                iconColor: GlassTheme.bakongRed,
                badge: _getMethodConfig('BAKONG')?.isConfigured == true
                    ? 'NBC OPEN API'
                    : null,
                badgeColor: GlassTheme.bakongRed,
                isSelected: _selectedProvider == 'BAKONG',
                onTap: () => setState(() => _selectedProvider = 'BAKONG'),
              ),
              const SizedBox(height: 10),

              // 3. ABA KHQR Option
              _PaymentOptionTile(
                title: 'ABA KHQR (ABA Mobile / PayWay)',
                subtitle: 'Scan with ABA Mobile or any KHQR app',
                svgAsset: 'khqr_logo',
                iconColor: GlassTheme.abaBlue,
                badge: _getMethodConfig('ABA')?.isConfigured == false
                    ? 'VIA BAKONG'
                    : null,
                badgeColor: Colors.white24,
                isSelected: _selectedProvider == 'ABA',
                onTap: () => setState(() => _selectedProvider = 'ABA'),
              ),
              const SizedBox(height: 10),

              // 4. ACLEDA KHQR Option
              _PaymentOptionTile(
                title: 'ACLEDA KHQR (ACLEDA Mobile)',
                subtitle: 'Pay via ACLEDA mobile & Bakong network',
                icon: AppIcons.qrScan,
                iconColor: GlassTheme.acledaNavy,
                badge: _getMethodConfig('ACLEDA')?.isConfigured == false
                    ? 'VIA BAKONG'
                    : null,
                badgeColor: Colors.white24,
                isSelected: _selectedProvider == 'ACLEDA',
                onTap: () => setState(() => _selectedProvider = 'ACLEDA'),
              ),
              const SizedBox(height: 10),

              // 5. Cash on Delivery Option
              _PaymentOptionTile(
                title: 'Cash on Delivery / COD (ទូទាត់ពេលដឹកដល់)',
                subtitle: 'Pay cash in USD or Khmer Riel (៛) directly to rider',
                svgAsset: 'delivery_bike',
                iconColor: Theme.of(context).colorScheme.primary,
                isSelected: _selectedProvider == 'COD',
                onTap: () => setState(() => _selectedProvider = 'COD'),
              ),
              if (_selectedProvider == 'BAKONG' ||
                  _selectedProvider == 'ABA' ||
                  _selectedProvider == 'ACLEDA') ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: GlassTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Live Real-Time KHQR Active',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.eta,
                                  size: 12,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '15m Session',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Generates a dynamic KHQR code with live WebSocket status. Supported by all Cambodian banking apps:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCheckoutBankChip(
                              'Bakong',
                              const Color(0xFFE12326),
                            ),
                            _buildCheckoutBankChip(
                              'ABA Bank',
                              const Color(0xFF004B87),
                            ),
                            _buildCheckoutBankChip(
                              'ACLEDA',
                              const Color(0xFF1E3A8A),
                            ),
                            _buildCheckoutBankChip(
                              'Wing',
                              const Color(0xFF00A859),
                            ),
                            _buildCheckoutBankChip(
                              'Canadia',
                              const Color(0xFFC8102E),
                            ),
                            _buildCheckoutBankChip(
                              'Sathapana',
                              const Color(0xFF003366),
                            ),
                            _buildCheckoutBankChip(
                              'TrueMoney',
                              const Color(0xFFFF6600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Consumer<CartProvider>(
            builder: (context, cart, child) {
              final total = cart.grandTotal;

              String buttonText;
              IconData buttonIcon;
              if (_isProcessing) {
                buttonText = 'Processing Order...';
                buttonIcon = AppIcons.loading;
              } else if (_selectedProvider == 'WALLET') {
                buttonText =
                    'Pay \$${total.toStringAsFixed(2)} with FoodGo Balance';
                buttonIcon = AppIcons.fastDelivery;
              } else if (_selectedProvider == 'COD') {
                buttonText = 'Place Cash on Delivery Order';
                buttonIcon = AppIcons.delivery;
              } else if (_selectedProvider == 'BAKONG') {
                buttonText = 'Proceed to Pay with Bakong KHQR';
                buttonIcon = AppIcons.qrCode;
              } else if (_selectedProvider == 'ABA') {
                buttonText = 'Proceed to Pay with ABA KHQR';
                buttonIcon = AppIcons.qrCode;
              } else {
                buttonText = 'Proceed to Pay with ACLEDA KHQR';
                buttonIcon = AppIcons.qrScan;
              }

              return GlassContainer(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    customColor: isDark ? null : Colors.white,
                    customShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    customBorder: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE5E7EB),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  if (cart.discountAmount > 0)
                                    Text(
                                      'Saved \$${cart.discountAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: primary,
                                    ),
                                  ),
                                  Text(
                                    '≈ ${KhmerCurrency.formatKhr(total)} KHR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: GlassButton(
                              text: buttonText,
                              icon: buttonIcon,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              onPressed: _isProcessing
                                  ? () {}
                                  : () => _handlePlaceOrder(cart, total),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.15, end: 0);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBankChip(String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    this.icon,
    this.svgAsset,
    required this.iconColor,
    required this.isSelected,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $subtitle',
      child: AnimatedPressable(
        pressedScale: 0.97,
        onTap: onTap,
        child: GlassCard(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withValues(alpha: 0.14),
            width: isSelected ? 1.6 : 1.2,
          ),
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
                    : Icon(
                        icon ?? AppIcons.payment,
                        color: iconColor,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (badgeColor ??
                                          Theme.of(context).colorScheme.primary)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color:
                                    badgeColor ??
                                    Theme.of(context).colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? AppIcons.radioSelected : AppIcons.radioUnselected,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.05, end: 0);
  }
}

/// A checkout validation failure with a message that is safe to show to the
/// customer. These errors never imply that an order or payment succeeded.
class _CheckoutValidationException implements Exception {
  final String message;

  const _CheckoutValidationException(this.message);

  @override
  String toString() => message;
}
