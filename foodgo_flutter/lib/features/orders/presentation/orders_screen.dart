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
                        'Restaurant #${order['restaurant']}',
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

            // Track Order button for delivered orders
            if (status == 'delivered') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: 'Track Order',
                  icon: Icons.map_outlined,
                  onPressed: () => context.push('/map/${order['id']}'),
                  color: Colors.transparent,
                ),
              ),
            ],
          ],
        ),
      ).animate().fade(delay: (100 * index).ms).slideY(),
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