import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _restaurant;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final resData = await _api.get('restaurants/my_restaurant/');
      final ordData = await _api.get('orders/');
      if (!mounted) return;
      setState(() {
        _restaurant = resData;
        _orders = (ordData as List).reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _api.patch('orders/$orderId/', {'status': newStatus});
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order updated to $newStatus'),
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
        title: 'Restaurant Portal',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen))
              : _restaurant == null
                  ? Center(child: Text('You do not own a restaurant.', style: TextStyle(color: GlassTheme.textMuted)))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: GlassTheme.borderRadiusSmall,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                                  child: const Icon(Icons.store, size: 30, color: GlassTheme.primaryGreen),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_restaurant!['name'], style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text('Incoming Orders: ${_orders.length}', style: TextStyle(color: GlassTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Live Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _orders.isEmpty
                                ? Center(child: Text('No orders yet', style: TextStyle(color: GlassTheme.textMuted)))
                                : ListView.builder(
                                    itemCount: _orders.length,
                                    itemBuilder: (context, index) {
                                      final order = _orders[index];
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
                                              Text('Total: \$${order['total_amount']}', style: const TextStyle(color: Colors.white70)),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  if (order['status'] == 'pending')
                                                    Expanded(
                                                      child: GlassButton(
                                                        text: 'Accept & Cook',
                                                        icon: Icons.soup_kitchen,
                                                        onPressed: () => _updateOrderStatus(order['id'].toString(), 'preparing'),
                                                      ),
                                                    ),
                                                  if (order['status'] == 'preparing')
                                                    Expanded(
                                                      child: GlassButton(
                                                        text: 'Hand to Driver',
                                                        icon: Icons.delivery_dining,
                                                        onPressed: () => _updateOrderStatus(order['id'].toString(), 'on_the_way'),
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
