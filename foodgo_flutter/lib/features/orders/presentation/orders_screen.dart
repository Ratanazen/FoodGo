import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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
    return const Center(
      child: CircularProgressIndicator(color: GlassTheme.primaryGreen),
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
            Icon(Icons.receipt_long_outlined,
                size: 80, color: GlassTheme.textMuted),
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  borderRadius: GlassTheme.borderRadiusSmall,
                  customColor: color.withValues(alpha: 0.2),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info row: icon + details
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: GlassTheme.borderRadiusSmall,
                  ),
                  child: const Icon(Icons.restaurant,
                      color: GlassTheme.textMuted),
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
                        '$itemCount items • \$${order['total_amount']}',
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
                if (status == 'delivered' || status == 'on_delivery' || status == 'picked_up') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassButton(
                      text: 'Track',
                      icon: Icons.map_outlined,
                      onPressed: () => context.push('/map/${order['id']}'),
                      color: Colors.transparent,
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

  void _showOrderBillDialog(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final status = (order['status'] as String?) ?? 'pending';
    final paymentStatus = (order['payment_status'] as String?) ?? 'UNPAID';
    final restaurantName = order['restaurant_name'] ?? 'Restaurant #${order['restaurant']}';
    final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final totalKhr = (totalAmount * 4100).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF141F18),
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
                        '≈ ៛$totalKhr KHR',
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

  Widget _buildOrderList() {
    return RefreshIndicator(
      color: GlassTheme.primaryGreen,
      onRefresh: _fetchOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index] as Map<String, dynamic>;
          return _buildOrderCard(order, index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'My Orders',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
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
    );
  }
}