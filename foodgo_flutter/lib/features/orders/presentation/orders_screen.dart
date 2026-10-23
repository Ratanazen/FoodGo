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
import '../../../core/theme/glass_theme.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/delivery_qr_modal.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../payment/services/payment_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

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
      final String provider = (order['payment'] is Map &&
              order['payment']['provider'] != null &&
              order['payment']['provider'].toString().isNotEmpty)
          ? order['payment']['provider'].toString().toUpperCase()
          : 'ABA';
      final payment = await paymentService.createPayment(
        orderId: orderId,
        provider: provider == 'COD' || provider == 'WALLET' ? 'ABA' : provider,
        currency: 'USD',
      );
      if (mounted) {
        context.push('/qr-payment', extra: payment);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate KHQR payment: $e'),
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

      for (int i = 0; i < qty; i++) {
        cart.addItem(id, name, price, img);
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
      setState(() {
        _error = e.toString();
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
        return GlassTheme.primaryGreen;
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
            LottieAsset.emptyBox(size: 150),
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
    final status = (order['status'] as String?) ?? 'pending';
    final color = _statusColor(status);
    final itemCount = (order['items'] as List?)?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${order['assigned_driver']['vehicle_type'] ?? 'Motorbike'} • ${order['assigned_driver']['license_plate'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: GlassTheme.textMuted,
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
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
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
                  label: const Text(
                    'View Bill',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _showOrderBillDialog(order),
                ),
                if ((order['payment_status'] as String? ?? 'UNPAID') !=
                        'PAID' &&
                    status != 'cancelled') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.primaryGreen,
                      foregroundColor: Colors.black,
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
                    onPressed: () => _resumeKhqrPayment(order),
                  ),
                ],
                if (_isInProgress(status) ||
                    status == 'on_delivery' ||
                    status == 'picked_up' ||
                    status == 'arrived') ...[
                  if (status == 'pending' || status == 'confirmed') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => _confirmCancelOrder(order),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GlassTheme.primaryGreen,
                      side: const BorderSide(color: GlassTheme.primaryGreen),
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
                    onPressed: () => DeliveryQrModal.show(
                      context,
                      orderId: order['id'].toString(),
                      isDriver: false,
                      onDelivered: () => _fetchOrders(),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(
                      Icons.map_outlined,
                      size: 16,
                      color: GlassTheme.limeAccent,
                    ),
                    label: const Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => context.push('/map/${order['id']}'),
                  ),
                ] else ...[
                  if (status == 'delivered') ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.6),
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
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      label: const Text(
                        'Rate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _showRatingDialog(order),
                    ),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.limeAccent,
                      foregroundColor: Colors.black,
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
                    onPressed: () => _reorderItems(order),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Cancel Order #$orderId?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Order',
              style: TextStyle(color: Colors.white60),
            ),
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
                    content: Text('Failed to cancel order: $e'),
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
    String selectedReason = 'Missing items';
    final reasons = [
      'Missing items',
      'Food arrived cold / damaged',
      'Incorrect order items',
      'Extreme delivery delay',
      'Other issue',
    ];
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: GlassTheme.dialogDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            orderId != null
                ? 'Report Issue: Order #$orderId'
                : 'Report Delivery Issue',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select the problem with this order:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) {
                  final isSelected = selectedReason == r;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedReason = r),
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
                                : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)...',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                  ),
                ),
              ],
            ),
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
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
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
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaqDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('FoodGo Support FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How do refunds work?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cancelled orders or reported missing items are refunded back to your original payment method within 2-4 business hours.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 14),
              Text(
                'What if my food is late?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'If your order is delayed more than 20 minutes past the estimated arrival time, you receive an automated 20% discount coupon for your next order.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 14),
              Text(
                'Need immediate help?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Contact our Phnom Penh support center 24/7 at +855 23 999 888.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: GlassTheme.dialogDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Rate Order #${order['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your meal from ${order['restaurant_name'] ?? 'the restaurant'}?',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => selectedRating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Share your feedback (optional)...',
                  hintStyle: TextStyle(
                    color: GlassTheme.textMuted,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.primaryGreen,
              ),
              onPressed: () {
                Navigator.pop(ctx);
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
              child: const Text(
                'Submit Rating',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResponsiveBottomSheet(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: GlassTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Bill Receipt',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#FG-${order['id']} · ${_formatDate(order['created_at'] as String?)}',
                          style: TextStyle(
                            color: GlassTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
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
                    color: Colors.white.withValues(alpha: 0.05),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ITEMS',
                  style: TextStyle(
                    color: Colors.white54,
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
                      color: Colors.white.withValues(alpha: 0.08),
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
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '\$$lineTotal',
                            style: const TextStyle(
                              color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.15),
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Status',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
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
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white,
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
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
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
                GlassButton(text: 'Close', onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Active', 'Delivered', 'Cancelled'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = filter);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GlassTheme.limeAccent
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? GlassTheme.limeAccent
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No $_selectedFilter orders found',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Orders will appear here once updated to this status.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
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
