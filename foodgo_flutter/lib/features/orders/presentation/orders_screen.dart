import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/shimmer_widgets.dart';
import '../../../widgets/lottie_assets.dart';
import '../../../widgets/vector_illustrations.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/delivery_qr_modal.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../payment/models/payment_model.dart';
import '../../payment/services/payment_service.dart';

class OrdersScreen extends StatefulWidget {
  final List<dynamic>? initialOrders;

  const OrdersScreen({super.key, this.initialOrders});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrders != null) {
      _orders = List<dynamic>.from(widget.initialOrders!);
      _isLoading = false;
      return;
    }
    _fetchOrders();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchOrdersSilently();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrdersSilently() async {
    try {
      final hasToken = await SecureStorage().hasAccessToken();
      if (!hasToken) return;
      final data = await ApiService().get('orders/');
      final List<dynamic> orders = data is List
          ? data
          : (data['results'] as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _orders = orders;
      });
    } catch (_) {}
  }

  Future<void> _resumeKhqrPayment(Map<String, dynamic> order) async {
    try {
      final paymentService = FlutterPaymentService();
      final orderId = order['id'] is int
          ? order['id'] as int
          : int.parse(order['id'].toString());
      final payInfo =
          (order['payment_info'] is Map
              ? Map<String, dynamic>.from(order['payment_info'] as Map)
              : null) ??
          (order['payment'] is Map
              ? Map<String, dynamic>.from(order['payment'] as Map)
              : null);

      if (payInfo != null &&
          payInfo['qr_payload'] != null &&
          payInfo['qr_payload'].toString().isNotEmpty &&
          payInfo['status'] == 'PENDING') {
        payInfo['order_id'] ??= orderId;
        final payment = PaymentModel.fromJson(payInfo);
        if (mounted) {
          context.push('/qr-payment', extra: payment);
          return;
        }
      }

      final String provider =
          (payInfo != null &&
              payInfo['provider'] != null &&
              payInfo['provider'].toString().isNotEmpty)
          ? payInfo['provider'].toString().toUpperCase()
          : 'BAKONG';
      final payment = await paymentService.createPayment(
        orderId: orderId,
        provider: provider == 'COD' || provider == 'WALLET'
            ? 'BAKONG'
            : provider,
        currency: 'USD',
      );
      if (mounted) {
        context.push('/qr-payment', extra: payment);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initiate KHQR payment: ${ApiService.formatError(e)}',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    if (_selectedFilter == 'Active') {
      return _orders
          .where((o) => _isInProgress((o['status'] as String?) ?? ''))
          .toList();
    }
    if (_selectedFilter == 'Delivered') {
      return _orders
          .where((o) => (o['status'] as String?) == 'delivered')
          .toList();
    }
    if (_selectedFilter == 'Cancelled') {
      return _orders
          .where((o) => (o['status'] as String?) == 'cancelled')
          .toList();
    }
    return _orders;
  }

  void _reorderItems(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No items found in this order to re-order.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GlassTheme.surfaceDark,
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    int addedCount = 0;
    for (final it in items) {
      final id =
          int.tryParse(
            it['food_item']?.toString() ?? it['id']?.toString() ?? '0',
          ) ??
          0;
      final name =
          it['food_item_name']?.toString() ?? it['name']?.toString() ?? 'Item';
      final price = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
      final qty = int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
      final img = it['image']?.toString();

      final restId =
          int.tryParse(
            order['restaurant']?.toString() ??
                order['restaurant_id']?.toString() ??
                '',
          ) ??
          1;
      final restName = order['restaurant_name']?.toString() ?? 'FoodGo Kitchen';

      for (int i = 0; i < qty; i++) {
        cart.addItem(
          id,
          name,
          price,
          img,
          restaurantId: restId,
          restaurantName: restName,
        );
        addedCount++;
      }
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $addedCount item(s) from Order #${order['id']} to your cart!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: GlassTheme.primaryGreenDark,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
    context.push('/cart');
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hasToken = await SecureStorage().hasAccessToken();
      if (!hasToken) {
        if (!mounted) return;
        setState(() {
          _orders = [];
          _isLoading = false;
          _error = 'Please sign in to view your orders.';
        });
        return;
      }
      final data = await ApiService().get('orders/');
      final List<dynamic> orders = data is List
          ? data
          : (data['results'] as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String errorMsg = ApiService.formatError(e);
      if (errorMsg.contains('401') ||
          errorMsg.contains('refresh token') ||
          errorMsg.contains('Unauthorized') ||
          errorMsg.contains('Session expired')) {
        errorMsg = 'Please sign in to view your orders.';
      }
      setState(() {
        _error = errorMsg;
        _isLoading = false;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'driver_assigned':
      case 'driver_accepted':
      case 'preparing':
      case 'ready_for_pickup':
        return Colors.blue;
      case 'picked_up':
      case 'on_the_way':
      case 'out_for_delivery':
      case 'driver_arrived':
      case 'arrived':
      case 'on_delivery':
        return Colors.purple;
      case 'delivered':
        return Theme.of(context).colorScheme.primary;
      case 'failed_delivery':
      case 'cancelled':
        return Colors.red;
      default:
        return GlassTheme.textMuted;
    }
  }

  bool _isInProgress(String status) {
    return [
      'pending',
      'confirmed',
      'driver_assigned',
      'driver_accepted',
      'preparing',
      'ready_for_pickup',
      'picked_up',
      'on_the_way',
      'out_for_delivery',
      'driver_arrived',
      'arrived',
      'on_delivery',
    ].contains(status);
  }

  // ── UI builders ─────────────────────────────────────────────────────

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 4,
      itemBuilder: (context, index) => const ShimmerOrderCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: GlassTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GlassTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            GlassButton(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: _fetchOrders,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VectorIllustration(
              type: VectorIllustrationType.emptyOrders,
              size: 160,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here',
              style: TextStyle(color: GlassTheme.textMuted),
            ),
            const SizedBox(height: 24),
            GlassButton(
              text: 'Browse Food',
              icon: Icons.explore,
              onPressed: () => context.go('/explore'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final steps = ['pending', 'confirmed', 'preparing', 'on_delivery'];
    int currentIdx = 0;
    if (['confirmed', 'driver_assigned', 'driver_accepted'].contains(status)) {
      currentIdx = 1;
    } else if (['preparing', 'ready_for_pickup'].contains(status)) {
      currentIdx = 2;
    } else if ([
      'picked_up',
      'on_the_way',
      'out_for_delivery',
      'driver_arrived',
      'arrived',
      'on_delivery',
    ].contains(status)) {
      currentIdx = 3;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final reached = i <= currentIdx;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached
                        ? _statusColor(status)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: (i < currentIdx)
                          ? _statusColor(status)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final status = (order['status'] as String?) ?? 'pending';
    final color = _statusColor(status);
    final itemCount = (order['items'] as List?)?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : GlassTheme.borderLight,
          width: 1.2,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Order ID + Help + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order #${order['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, size: 18),
                      tooltip: 'Get Help',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: GlassTheme.textMuted,
                      onPressed: () => _showSupportBottomSheet(
                        context,
                        orderId: order['id'],
                      ),
                    ),
                  ],
                ),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  borderRadius: GlassTheme.borderRadiusSmall,
                  customColor: color.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status.toLowerCase() == 'preparing') ...[
                        LottieAsset.cooking(size: 18),
                        const SizedBox(width: 4),
                      ] else if (status.toLowerCase() == 'on_delivery') ...[
                        LottieAsset.deliveryBike(size: 18),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _formatStatus(status),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info row: icon + details
            Row(
              children: [
                ClipRRect(
                  borderRadius: GlassTheme.borderRadiusSmall,
                  child:
                      order['restaurant_image'] != null &&
                          order['restaurant_image'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: order['restaurant_image'].toString(),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: GlassTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.restaurant,
                              color: GlassTheme.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: GlassTheme.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: GlassTheme.textMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['restaurant_name'] ??
                            'Restaurant #${order['restaurant']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemCount items • \$${order['total_amount']} (${KhmerCurrency.formatKhr(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0)})',
                        style: TextStyle(color: GlassTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order['created_at'] as String?),
                        style: TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Status timeline for in-progress orders
            if (_isInProgress(status)) _buildStatusTimeline(status),

            // Assigned Driver & ETA Info
            if (order['assigned_driver'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : GlassTheme.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining,
                      size: 20,
                      color: GlassTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver: ${order['assigned_driver']['name'] ?? 'Courier'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            '${order['assigned_driver']['vehicle_type'] ?? 'Motorbike'} • ${order['assigned_driver']['license_plate'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order['eta_minutes'] != null &&
                        (order['eta_minutes'] as num) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ETA: ~${order['eta_minutes']} min',
                          style: const TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AnimatedPressable(
                  pressedScale: 0.94,
                  onTap: () => _showOrderBillDialog(order),
                  child: IgnorePointer(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryText,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : secondaryText.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: GlassTheme.primaryGreen,
                      ),
                      label: Text(
                        'View Bill',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
                if ((order['payment_status'] as String? ?? 'UNPAID') !=
                        'PAID' &&
                    status != 'cancelled') ...[
                  AnimatedPressable(
                    pressedScale: 0.94,
                    onTap: () => _resumeKhqrPayment(order),
                    child: IgnorePointer(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_2, size: 16),
                        label: const Text(
                          'Pay KHQR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                if (_isInProgress(status) ||
                    status == 'on_delivery' ||
                    status == 'picked_up' ||
                    status == 'arrived') ...[
                  if (status == 'pending' || status == 'confirmed') ...[
                    AnimatedPressable(
                      pressedScale: 0.94,
                      onTap: () => _confirmCancelOrder(order),
                      child: IgnorePointer(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  AnimatedPressable(
                    pressedScale: 0.94,
                    onTap: () => DeliveryQrModal.show(
                      context,
                      orderId: order['id'].toString(),
                      isDriver: false,
                      onDelivered: () => _fetchOrders(),
                    ),
                    child: IgnorePointer(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_2, size: 16),
                        label: const Text(
                          'Delivery QR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  AnimatedPressable(
                    pressedScale: 0.94,
                    onTap: () => context.push('/map/${order['id']}'),
                    child: IgnorePointer(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.05),
                          foregroundColor: primaryText,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : secondaryText.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        icon: Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: isDark
                              ? GlassTheme.limeAccent
                              : GlassTheme.primaryGreenDark,
                        ),
                        label: Text(
                          'Track Order',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ] else ...[
                  if (status == 'delivered') ...[
                    AnimatedPressable(
                      pressedScale: 0.94,
                      onTap: () => _showRatingDialog(order),
                      child: IgnorePointer(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.amber
                                : const Color(0xFFB45309),
                            side: BorderSide(
                              color:
                                  (isDark
                                          ? Colors.amber
                                          : const Color(0xFFB45309))
                                      .withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          icon: Icon(
                            Icons.star,
                            size: 16,
                            color: isDark
                                ? Colors.amber
                                : const Color(0xFFB45309),
                          ),
                          label: Text(
                            'Rate',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.amber
                                  : const Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                  AnimatedPressable(
                    pressedScale: 0.94,
                    onTap: () => _reorderItems(order),
                    child: IgnorePointer(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.limeAccent,
                          foregroundColor: Colors.black,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Order Again',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ).animate().fade(delay: (100 * index).ms).slideY(),
    );
  }

  void _confirmCancelOrder(Map<String, dynamic> order) {
    final orderId = order['id'];
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        title: Text(
          'Cancel Order #$orderId?',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Order', style: TextStyle(color: secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().post('orders/$orderId/cancel/', {
                  'cancellation_reason': 'Cancelled by customer',
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order #$orderId cancelled successfully.'),
                    backgroundColor: GlassTheme.dialogDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _fetchOrders();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to cancel order: ${ApiService.formatError(e)}',
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportBottomSheet(BuildContext context, {dynamic orderId}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ResponsiveBottomSheet(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: GlassTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FoodGo Support Concierge',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          orderId != null
                              ? 'Assistance for Order #$orderId'
                              : '24/7 Customer Support',
                          style: TextStyle(
                            fontSize: 12,
                            color: GlassTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSupportTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Live Chat Support',
                subtitle: 'Average response time: 2 minutes',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Connecting to live support agent...'),
                      backgroundColor: GlassTheme.primaryGreenDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildSupportTile(
                icon: Icons.phone_in_talk_outlined,
                title: 'Call Support Hotline',
                subtitle: '+855 23 999 888 (Toll-Free in Cambodia)',
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(const ClipboardData(text: '+85523999888'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Support hotline copied to clipboard: +855 23 999 888',
                      ),
                      backgroundColor: GlassTheme.primaryGreenDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildSupportTile(
                icon: Icons.report_problem_outlined,
                title: 'Report Order Issue',
                subtitle: 'Missing item, food damage, or late delivery',
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportIssueDialog(orderId);
                },
              ),
              const SizedBox(height: 10),
              _buildSupportTile(
                icon: Icons.help_outline_rounded,
                title: 'Delivery FAQs & Terms',
                subtitle: 'Refund guarantee, delivery tracking, and policies',
                onTap: () {
                  Navigator.pop(ctx);
                  _showFaqDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: GlassTheme.primaryGreen, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: GlassTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showReportIssueDialog(dynamic orderId) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderReportIssueDialog(
        orderId: orderId,
        onSubmitted: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Report submitted for Order #${orderId ?? ''}. Our support team will investigate within 15 minutes.',
              ),
              backgroundColor: GlassTheme.primaryGreenDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showFaqDialog() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        title: Text(
          'FoodGo Support FAQ',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How do refunds work?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cancelled orders or reported missing items are refunded back to your original payment method within 2-4 business hours.',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Text(
                'What if my food is late?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'If your order is delayed more than 20 minutes past the estimated arrival time, you receive an automated 20% discount coupon for your next order.',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Text(
                'Need immediate help?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Contact our Phnom Penh support center 24/7 at +855 23 999 888.',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryGreen,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderRatingDialog(
        order: order,
        onSubmitted: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text('Thank you for your rating!'),
                ],
              ),
              backgroundColor: GlassTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showOrderBillDialog(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final status = (order['status'] as String?) ?? 'pending';
    final paymentStatus = (order['payment_status'] as String?) ?? 'UNPAID';
    final restaurantName =
        order['restaurant_name'] ?? 'Restaurant #${order['restaurant']}';
    final totalAmount =
        double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResponsiveBottomSheet(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
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
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Bill Receipt',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#FG-${order['id']} · ${_formatDate(order['created_at'] as String?)}',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatStatus(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.store,
                        color: GlassTheme.primaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          restaurantName,
                          style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ITEMS',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, sepIdx) => Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      height: 12,
                    ),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      final name =
                          it['food_name'] ?? 'Item #${it['food_item']}';
                      final qty = it['quantity'] ?? 1;
                      final price = it['price'] ?? '0.00';
                      final lineTotal =
                          ((double.tryParse(price.toString()) ?? 0.0) *
                                  (int.tryParse(qty.toString()) ?? 1))
                              .toStringAsFixed(2);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$qty x $name',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '\$$lineTotal',
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.12),
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Status',
                      style: TextStyle(color: secondaryText, fontSize: 13),
                    ),
                    Text(
                      paymentStatus,
                      style: TextStyle(
                        color: paymentStatus == 'PAID'
                            ? GlassTheme.primaryGreen
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '≈ ${KhmerCurrency.formatKhr(totalAmount)} KHR (អត្រា ៤,១០០)',
                          style: TextStyle(color: secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (paymentStatus != 'PAID' &&
                    (order['status'] as String? ?? '') != 'cancelled') ...[
                  GlassButton(
                    text: 'Pay Now with KHQR',
                    icon: Icons.qr_code_2,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resumeKhqrPayment(order);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryText,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: GlassTheme.primaryGreen,
                        ),
                        label: const Text(
                          'Copy Receipt TXT',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          final buffer = StringBuffer()
                            ..writeln(
                              '========================================',
                            )
                            ..writeln(
                              'FOODGO CUSTOMER ORDER RECEIPT #FG-${order['id']}',
                            )
                            ..writeln(
                              '========================================',
                            )
                            ..writeln('Restaurant     : $restaurantName')
                            ..writeln(
                              'Order Status   : ${_formatStatus(status)}',
                            )
                            ..writeln('Payment Status : $paymentStatus')
                            ..writeln(
                              '----------------------------------------',
                            )
                            ..writeln('ITEMS:');
                          for (final it in items) {
                            final name =
                                it['food_name'] ?? 'Item #${it['food_item']}';
                            final qty = it['quantity'] ?? 1;
                            final price = it['price'] ?? '0.00';
                            final lineTotal =
                                ((double.tryParse(price.toString()) ?? 0.0) *
                                        (int.tryParse(qty.toString()) ?? 1))
                                    .toStringAsFixed(2);
                            buffer.writeln(' - ${qty}x $name : \$$lineTotal');
                          }
                          buffer
                            ..writeln(
                              '----------------------------------------',
                            )
                            ..writeln(
                              'TOTAL AMOUNT   : \$${totalAmount.toStringAsFixed(2)} (~${KhmerCurrency.formatKhr(totalAmount)} KHR)',
                            )
                            ..writeln(
                              '========================================',
                            );
                          Clipboard.setData(
                            ClipboardData(text: buffer.toString()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Order receipt TXT copied to clipboard!',
                              ),
                              backgroundColor: GlassTheme.primaryGreenDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        text: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    const filters = ['All', 'Active', 'Delivered', 'Cancelled'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedPressable(
              pressedScale: 0.94,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GlassTheme.limeAccent
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black12)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : GlassTheme.borderLight),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: GlassTheme.limeAccent.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.black : primaryText,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderList() {
    final brightness = Theme.of(context).brightness;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final list = _filteredOrders;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 56,
                color: secondaryText.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No $_selectedFilter orders found',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Orders will appear here once updated to this status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryText, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: GlassTheme.primaryGreen,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final order = list[index] as Map<String, dynamic>;
          return _buildOrderCard(order, index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ResponsiveWebContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Orders',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Customer Support',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: GlassTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _showSupportBottomSheet(context),
                  ),
                ],
              ),
            ),
            if (!_isLoading && _error == null && _orders.isNotEmpty)
              _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                  ? _buildError()
                  : _orders.isEmpty
                  ? _buildEmpty()
                  : _buildOrderList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderReportIssueDialog extends StatefulWidget {
  final dynamic orderId;
  final VoidCallback onSubmitted;

  const _OrderReportIssueDialog({
    required this.orderId,
    required this.onSubmitted,
  });

  @override
  State<_OrderReportIssueDialog> createState() =>
      _OrderReportIssueDialogState();
}

class _OrderReportIssueDialogState extends State<_OrderReportIssueDialog> {
  static const List<String> _reasons = [
    'Missing items',
    'Food arrived cold / damaged',
    'Incorrect order items',
    'Extreme delivery delay',
    'Other issue',
  ];

  String _selectedReason = 'Missing items';
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      title: Text(
        widget.orderId != null
            ? 'Report Issue: Order #${widget.orderId}'
            : 'Report Delivery Issue',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select the problem with this order:',
              style: TextStyle(color: secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((r) {
              final isSelected = _selectedReason == r;
              return InkWell(
                onTap: () => setState(() => _selectedReason = r),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? GlassTheme.primaryGreen
                            : secondaryText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(fontSize: 13, color: primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: TextStyle(color: primaryText, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Additional details (optional)...',
                hintStyle: TextStyle(color: secondaryText, fontSize: 12),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFD1D5DB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFD1D5DB),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: secondaryText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GlassTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            widget.onSubmitted();
          },
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}

class _OrderRatingDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onSubmitted;

  const _OrderRatingDialog({required this.order, required this.onSubmitted});

  @override
  State<_OrderRatingDialog> createState() => _OrderRatingDialogState();
}

class _OrderRatingDialogState extends State<_OrderRatingDialog> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      title: Text(
        'Rate Order #${widget.order['id']}',
        style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was your meal from ${widget.order['restaurant_name'] ?? 'the restaurant'}?',
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return IconButton(
                icon: Icon(
                  starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _selectedRating = starIndex),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 2,
            style: TextStyle(color: primaryText, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Share your feedback (optional)...',
              hintStyle: TextStyle(color: secondaryText, fontSize: 12),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Later', style: TextStyle(color: secondaryText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GlassTheme.primaryGreen,
          ),
          onPressed: () {
            Navigator.pop(context);
            widget.onSubmitted();
          },
          child: const Text(
            'Submit Rating',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
