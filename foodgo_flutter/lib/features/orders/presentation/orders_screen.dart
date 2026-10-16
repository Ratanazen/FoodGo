import 'dart:async';
import 'package:flutter/material.dart';
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
import '../../../widgets/delivery_scanner_modal.dart';
import '../../../core/utils/khmer_currency.dart';

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
      final List<dynamic> orders =
          data is List ? data : (data['results'] as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _orders = orders;
      });
    } catch (_) {}
  }

  List<dynamic> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    if (_selectedFilter == 'Active') {
      return _orders.where((o) => _isInProgress((o['status'] as String?) ?? '')).toList();
    }
    if (_selectedFilter == 'Delivered') {
      return _orders.where((o) => (o['status'] as String?) == 'delivered').toList();
    }
    if (_selectedFilter == 'Cancelled') {
      return _orders.where((o) => (o['status'] as String?) == 'cancelled').toList();
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
      final id = int.tryParse(it['food_item']?.toString() ?? it['id']?.toString() ?? '0') ?? 0;
      final name = it['food_item_name']?.toString() ?? it['name']?.toString() ?? 'Item';
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
        content: Text('Added $addedCount item(s) from Order #${order['id']} to your cart!'),
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
      final List<dynamic> orders =
          data is List ? data : (data['results'] as List<dynamic>? ?? []);
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      case 'preparing':
        return Colors.blue;
      case 'on_delivery':
        return Colors.purple;
      case 'delivered':
        return GlassTheme.primaryGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return GlassTheme.textMuted;
    }
  }

  bool _isInProgress(String status) {
    return ['pending', 'confirmed', 'preparing', 'on_delivery']
        .contains(status);
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
    final currentIdx = steps.indexOf(status);

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
            // Header row: Order ID + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  child: order['restaurant_image'] != null && order['restaurant_image'].toString().isNotEmpty
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: GlassTheme.primaryGreen),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Icon(Icons.restaurant, color: GlassTheme.textMuted),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: GlassTheme.borderRadiusSmall,
                          ),
                          child: const Icon(Icons.restaurant, color: GlassTheme.textMuted),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['restaurant_name'] ?? 'Restaurant #${order['restaurant']}',
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
                            color: GlassTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Status timeline for in-progress orders
            if (_isInProgress(status)) _buildStatusTimeline(status),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 16, color: GlassTheme.primaryGreen),
                    label: const Text('View Bill', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () => _showOrderBillDialog(order),
                  ),
                ),
                if (_isInProgress(status) || status == 'on_delivery' || status == 'picked_up' || status == 'arrived') ...[
                  if (status == 'pending') ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onPressed: () => _confirmCancelOrder(order),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GlassTheme.primaryGreen,
                      side: const BorderSide(color: GlassTheme.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => DeliveryScannerModal.show(
                      context,
                      orderId: order['id'].toString(),
                      onConfirmed: () => _fetchOrders(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassButton(
                      text: 'Track',
                      icon: Icons.map_outlined,
                      onPressed: () => context.push('/map/${order['id']}'),
                      color: Colors.transparent,
                    ),
                  ),
                ] else ...[
                  if (status == 'delivered') ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      icon: const Icon(Icons.star, size: 16, color: Colors.amber),
                      label: const Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _showRatingDialog(order),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Order Again', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () => _reorderItems(order),
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
            child: const Text('Keep Order', style: TextStyle(color: Colors.white60)),
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
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      starIndex <= selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = starIndex),
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
                  hintStyle: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: GlassTheme.primaryGreen),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your rating! ⭐'),
                    backgroundColor: GlassTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit Rating', style: TextStyle(color: Colors.white)),
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
    final restaurantName = order['restaurant_name'] ?? 'Restaurant #${order['restaurant']}';
    final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                        style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const Icon(Icons.store, color: GlassTheme.primaryGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        restaurantName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('ITEMS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (context, sepIdx) => Divider(color: Colors.white.withValues(alpha: 0.08), height: 12),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final name = it['food_name'] ?? 'Item #${it['food_item']}';
                    final qty = it['quantity'] ?? 1;
                    final price = it['price'] ?? '0.00';
                    final lineTotal = ((double.tryParse(price.toString()) ?? 0.0) * (int.tryParse(qty.toString()) ?? 1)).toStringAsFixed(2);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$qty x $name',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        Text(
                          '\$$lineTotal',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Status', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    paymentStatus,
                    style: TextStyle(
                      color: paymentStatus == 'PAID' ? GlassTheme.primaryGreen : Colors.orangeAccent,
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
                  const Text('Total Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: GlassTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(
                        '≈ ${KhmerCurrency.formatKhr(totalAmount)} KHR (អត្រា ៤,១០០)',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassButton(
                text: 'Close',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Active', 'Delivered', 'Cancelled'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: GlassTheme.primaryGreen,
              backgroundColor: GlassTheme.surfaceDark,
              side: BorderSide(
                color: isSelected ? GlassTheme.primaryGreen : GlassTheme.borderDark,
                width: 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
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
              Icon(Icons.filter_list_off, size: 56, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'No $_selectedFilter orders found',
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Orders will appear here once updated to this status.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
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
              child: Text(
                'My Orders',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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