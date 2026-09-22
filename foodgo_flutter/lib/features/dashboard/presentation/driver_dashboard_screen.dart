import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';

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
      setState(() {
        _availableOrders = (data as List).where((o) => o['status'] == 'preparing' || o['status'] == 'on_the_way').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _api.patch('orders/$orderId/', {'status': newStatus});
      _fetchOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order marked as $newStatus'),
        backgroundColor: GlassTheme.primaryGreen,
      ));
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: GlassTheme.backgroundDark,
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: GlassTheme.borderRadiusSmall,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Driver Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_isOnline ? 'Online & Ready' : 'Offline', style: TextStyle(color: _isOnline ? GlassTheme.primaryGreen : Colors.redAccent)),
                        ],
                      ),
                      Switch(
                        value: _isOnline,
                        activeTrackColor: GlassTheme.primaryGreen,
                        onChanged: (val) {
                          setState(() => _isOnline = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Available Deliveries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen))
                      : !_isOnline
                          ? Center(child: Text('Go online to see orders', style: TextStyle(color: GlassTheme.textMuted)))
                          : _availableOrders.isEmpty
                              ? Center(child: Text('No orders waiting', style: TextStyle(color: GlassTheme.textMuted)))
                              : ListView.builder(
                                  itemCount: _availableOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _availableOrders[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: GlassCard(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    order['status'].toString().toUpperCase(),
                                                    style: const TextStyle(color: GlassTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            if (order['restaurant'] != null) ...[
                                              Row(
                                                children: [
                                                  const Icon(Icons.store, color: GlassTheme.textMuted, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(order['restaurant']['name'] ?? 'Restaurant', style: const TextStyle(color: Colors.white70)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            if (order['address'] != null) ...[
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(order['address']['street'] ?? 'Unknown address', style: const TextStyle(color: Colors.white70)),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            Row(
                                              children: [
                                                if (order['status'] == 'preparing')
                                                  Expanded(
                                                    child: GlassButton(
                                                      text: 'Wait at Restaurant',
                                                      icon: Icons.hourglass_empty,
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                                if (order['status'] == 'on_the_way')
                                                  Expanded(
                                                    child: GlassButton(
                                                      text: 'Mark Delivered',
                                                      icon: Icons.check_circle,
                                                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'delivered'),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
