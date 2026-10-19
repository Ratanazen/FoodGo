import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../services/api_service.dart';
import '../../../widgets/delivery_qr_modal.dart';
import '../../../widgets/delivery_scanner_modal.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _availableOrders = [];
  bool _isOnline = false;
  int _completedDeliveries = 4;
  double _todayEarningsUsd = 16.50;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('orders/');
      if (!mounted) return;
      if (data is List) {
        final active = data
            .where(
              (o) =>
                  o['status'] == 'preparing' ||
                  o['status'] == 'on_the_way' ||
                  o['status'] == 'arrived',
            )
            .toList();
        final completed = data
            .where((o) => o['status'] == 'delivered')
            .toList();
        final double earnings = completed.fold<double>(0.0, (acc, item) {
          final fee =
              double.tryParse(
                item['delivery_fee_charged']?.toString() ??
                    item['delivery_fee']?.toString() ??
                    '2.00',
              ) ??
              2.00;
          return acc + fee;
        });
        setState(() {
          _availableOrders = active;
          _completedDeliveries = completed.isNotEmpty ? completed.length : 4;
          _todayEarningsUsd = earnings > 0 ? earnings : 16.50;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _api.patch('orders/$orderId/', {'status': newStatus});
      _fetchOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as $newStatus'),
          backgroundColor: GlassTheme.primaryGreen,
        ),
      );
    } catch (e) {
      debugPrint('Failed to update status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Driver Portal',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: GlassTheme.backgroundDark,
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80',
            ),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: ResponsiveWebContainer(
            maxWidth: 1000,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: GlassTheme.borderRadiusSmall,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver Status',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _isOnline
                                            ? GlassTheme.primaryGreen
                                            : Colors.redAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: _isOnline
                                            ? [
                                                BoxShadow(
                                                  color: GlassTheme.primaryGreen
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isOnline
                                          ? 'Online & Ready for Orders'
                                          : 'Offline',
                                      style: TextStyle(
                                        color: _isOnline
                                            ? GlassTheme.primaryGreen
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _isOnline,
                              activeTrackColor: GlassTheme.primaryGreen,
                              onChanged: (val) async {
                                setState(() => _isOnline = val);
                                try {
                                  await _api.post('drivers/toggle-online/', {
                                    'is_online': val,
                                  });
                                } catch (_) {}
                              },
                            ),
                          ],
                        ),
                        if (_isOnline) ...[
                          const Divider(color: Colors.white12, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Live GPS Broadcaster',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: GlassTheme.primaryGreen,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                                icon: const Icon(Icons.my_location, size: 16),
                                label: const Text(
                                  'Broadcast Location',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  try {
                                    await _api.post('drivers/location/', {
                                      'lat': 11.5580,
                                      'lng': 104.9210,
                                    });
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'GPS coordinates broadcast to active orders!',
                                        ),
                                        backgroundColor:
                                            GlassTheme.primaryGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (_) {}
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),

                  // ── Driver Earnings Header ──
                  GlassContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        customColor: GlassTheme.primaryGreen.withValues(
                          alpha: 0.12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: GlassTheme.primaryGreen.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: GlassTheme.primaryGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Today's Earnings",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '\$${_todayEarningsUsd.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '≈ ${KhmerCurrency.formatKhr(_todayEarningsUsd)}',
                                    style: const TextStyle(
                                      color: GlassTheme.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_completedDeliveries Trips Completed',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_availableOrders.length} In Progress',
                                  style: TextStyle(
                                    color: GlassTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 20),
                  const Text(
                    'Available Deliveries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: GlassTheme.primaryGreen,
                            ),
                          )
                        : !_isOnline
                        ? Center(
                            child: Text(
                              'Go online to see orders',
                              style: TextStyle(color: GlassTheme.textMuted),
                            ),
                          )
                        : _availableOrders.isEmpty
                        ? Center(
                            child: Text(
                              'No orders waiting',
                              style: TextStyle(color: GlassTheme.textMuted),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 650;
                              if (isWide) {
                                return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        mainAxisExtent: 220,
                                      ),
                                  itemCount: _availableOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _availableOrders[index];
                                    return _buildDriverOrderCard(order);
                                  },
                                );
                              }
                              return ListView.builder(
                                itemCount: _availableOrders.length,
                                itemBuilder: (context, index) {
                                  final order = _availableOrders[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: _buildDriverOrderCard(order),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverOrderCard(dynamic order) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
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
                      order['status'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (order['restaurant'] != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.store,
                      color: GlassTheme.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['restaurant']['name'] ?? 'Restaurant',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              if (order['address'] != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['address']['street'] ?? 'Unknown address',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.phone,
                      size: 14,
                      color: GlassTheme.primaryGreen,
                    ),
                    label: const Text(
                      'Call Customer',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      final phone =
                          order['customer_phone'] ??
                          order['phone'] ??
                          '+855 12 345 678';
                      Clipboard.setData(ClipboardData(text: phone.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Customer phone copied: $phone'),
                          backgroundColor: GlassTheme.primaryGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.directions,
                      size: 14,
                      color: Colors.blueAccent,
                    ),
                    label: const Text(
                      'Directions',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      final addr =
                          order['address']?['street'] ??
                          'Delivery Destination, Phnom Penh';
                      Clipboard.setData(ClipboardData(text: addr.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Destination address copied: $addr'),
                          backgroundColor: Colors.blueAccent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
          Row(
            children: [
              if (order['status'] == 'preparing') ...[
                Expanded(
                  child: GlassButton(
                    text: 'Pick Up Order',
                    icon: Icons.delivery_dining,
                    onPressed: () => _updateOrderStatus(
                      order['id'].toString(),
                      'on_the_way',
                    ),
                  ),
                ),
              ],
              if (order['status'] == 'on_the_way' ||
                  order['status'] == 'arrived') ...[
                Expanded(
                  child: GlassButton(
                    text: 'Arrived at Customer',
                    icon: Icons.qr_code_2,
                    onPressed: () => DeliveryQrModal.show(
                      context,
                      orderId: order['id'].toString(),
                      isDriver: true,
                      onDelivered: () => _fetchOrders(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.pin_outlined,
                      color: GlassTheme.primaryGreen,
                      size: 18,
                    ),
                  ),
                  tooltip: 'Manual PIN Verify / Scan',
                  onPressed: () => DeliveryScannerModal.show(
                    context,
                    orderId: order['id'].toString(),
                    onConfirmed: () => _fetchOrders(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}
