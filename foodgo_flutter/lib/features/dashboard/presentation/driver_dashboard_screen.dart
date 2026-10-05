import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
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

  void _openQrScanner(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final expectedPin = 'FG-${(int.tryParse(orderId) ?? 1) * 73 % 9000 + 1000}';
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.qr_code_scanner, color: GlassTheme.primaryGreen, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Scan Customer QR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Order #$orderId Handover', style: const TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Camera viewfinder with scanning effect
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassTheme.primaryGreen, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(top: 10, left: 10, child: _scannerCorner(isTop: true, isLeft: true)),
                        Positioned(top: 10, right: 10, child: _scannerCorner(isTop: true, isLeft: false)),
                        Positioned(bottom: 10, left: 10, child: _scannerCorner(isTop: false, isLeft: true)),
                        Positioned(bottom: 10, right: 10, child: _scannerCorner(isTop: false, isLeft: false)),

                        Icon(Icons.qr_code_2, size: 90, color: Colors.white.withValues(alpha: 0.3)),

                        Positioned(
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: GlassTheme.primaryGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: GlassTheme.primaryGreen.withValues(alpha: 0.9),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('READY TO SCAN', style: TextStyle(color: GlassTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Align customer\'s Delivery QR code within the frame, or enter PIN below:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: pinController,
                    style: const TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'PIN: $expectedPin',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12, letterSpacing: 1),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Verify QR & Mark Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _updateOrderStatus(orderId, 'delivered');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 Order #$orderId Handover Verified! Marked as Delivered (Done).'),
                            backgroundColor: GlassTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scannerCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: GlassTheme.primaryGreen, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: GlassTheme.primaryGreen, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: GlassTheme.primaryGreen, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: GlassTheme.primaryGreen, width: 3) : BorderSide.none,
        ),
      ),
    );
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
            image: CachedNetworkImageProvider('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),
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
                              Text('Driver Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(_isOnline ? '🟢 Online & Ready for Orders' : '⚪ Offline', style: TextStyle(color: _isOnline ? GlassTheme.primaryGreen : Colors.redAccent)),
                            ],
                          ),
                          Switch(
                            value: _isOnline,
                            activeTrackColor: GlassTheme.primaryGreen,
                            onChanged: (val) async {
                              setState(() => _isOnline = val);
                              try {
                                await _api.post('drivers/toggle-online/', {'is_online': val});
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
                            const Text('Live GPS Broadcaster', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: GlassTheme.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text('Broadcast Location', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                try {
                                  await _api.post('drivers/location/', {
                                    'lat': 11.5580,
                                    'lng': 104.9210,
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('GPS coordinates broadcast to active orders!'),
                                      backgroundColor: GlassTheme.primaryGreen,
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
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 650;
                                    if (isWide) {
                                      return GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: _buildDriverOrderCard(order),
                                        );
                                      },
                                    );
                                  },
                                ),
                )
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
              const SizedBox(height: 10),
              if (order['restaurant'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.store, color: GlassTheme.textMuted, size: 16),
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
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
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
            ],
          ),
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
              if (order['status'] == 'on_the_way') ...[
                Expanded(
                  child: GlassButton(
                    text: 'Scan QR Done',
                    icon: Icons.qr_code_scanner,
                    onPressed: () => _openQrScanner(order),
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
                    child: const Icon(Icons.check, color: GlassTheme.primaryGreen, size: 18),
                  ),
                  tooltip: 'Quick Mark Delivered',
                  onPressed: () => _updateOrderStatus(order['id'].toString(), 'delivered'),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}
