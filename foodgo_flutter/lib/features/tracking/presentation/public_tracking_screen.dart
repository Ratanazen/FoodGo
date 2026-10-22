import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';

class PublicTrackingScreen extends StatefulWidget {
  final String? initialOrderId;

  const PublicTrackingScreen({super.key, this.initialOrderId});

  @override
  State<PublicTrackingScreen> createState() => _PublicTrackingScreenState();
}

class _PublicTrackingScreenState extends State<PublicTrackingScreen> {
  final _orderIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _trackingData;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty) {
      _orderIdController.text = widget.initialOrderId!;
      _performTrack(widget.initialOrderId!);
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _performTrack(String idStr) async {
    final cleanId = idStr.trim();
    if (cleanId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid numeric Order ID.';
        _trackingData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dynamic response;
      try {
        response = await ApiService().get('orders/$cleanId/track/');
      } catch (_) {
        response = await ApiService().get('orders/$cleanId/tracking/');
      }

      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          _trackingData = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Order not found or tracking data unavailable.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to locate Order #$cleanId. Verify the ID and try again.';
        _isLoading = false;
        _trackingData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Live Delivery Tracking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveWebContainer(
          maxWidth: 800,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Card
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Public Order Tracker',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your FoodGo order reference number to view real-time delivery status.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _orderIdController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: GlassTheme.primaryGreen,
                                ),
                                hintText: 'Enter Order ID (e.g. 101)',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              onSubmitted: (val) => _performTrack(val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _performTrack(_orderIdController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Track',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tracking Results
                if (_trackingData != null) ...[
                  _buildOrderOverviewCard(_trackingData!),
                  const SizedBox(height: 16),
                  _buildDeliveryProgressCard(_trackingData!),
                  const SizedBox(height: 16),
                  if (_trackingData!['driver'] != null)
                    _buildDriverCard(
                      _trackingData!['driver'] as Map<String, dynamic>,
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map_outlined, color: Colors.white),
                    label: const Text(
                      'Open Full Interactive Map',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.authBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final id = _trackingData!['order_id'];
                      context.push('/map?orderId=$id');
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderOverviewCard(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final restaurant = data['restaurant_name'] ?? 'Restaurant';
    final address = data['delivery_address'] ?? 'Destination address';

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${data['order_id']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const Divider(height: 24, color: Colors.white12),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: GlassTheme.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Merchant: $restaurant',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery: $address',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProgressCard(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();

    final steps = [
      {'title': 'Order Placed', 'code': 'pending'},
      {'title': 'Merchant Preparing', 'code': 'preparing'},
      {'title': 'Driver On The Way', 'code': 'on_the_way'},
      {'title': 'Delivered & Confirmed', 'code': 'delivered'},
    ];

    int currentStep = 0;
    if (status == 'pending' || status == 'confirmed') {
      currentStep = 0;
    } else if (status == 'preparing' ||
        status == 'ready' ||
        status == 'ready_for_pickup') {
      currentStep = 1;
    } else if (status == 'picked_up' ||
        status == 'on_the_way' ||
        status == 'driver_arrived') {
      currentStep = 2;
    } else if (status == 'delivered') {
      currentStep = 3;
    }

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Milestones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final isDone = index <= currentStep;
            final isCurrent = index == currentStep;
            final step = steps[index];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? GlassTheme.primaryGreen
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                      child: isDone
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: index < currentStep
                            ? GlassTheme.primaryGreen
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    step['title']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isDone ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Courier Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.two_wheeler,
                  color: GlassTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'] ?? 'Driver Partner',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver['vehicle_type'] ?? 'Motorcycle'} • ${driver['license_plate'] ?? 'Phnom Penh'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${driver['rating'] ?? 4.9}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.white10;
    Color fg = Colors.white;
    String label = status.replaceAll('_', ' ').toUpperCase();

    if (status == 'delivered') {
      bg = GlassTheme.primaryGreen.withValues(alpha: 0.2);
      fg = GlassTheme.primaryGreen;
    } else if (status == 'on_the_way' || status == 'picked_up') {
      bg = Colors.blue.withValues(alpha: 0.2);
      fg = Colors.lightBlueAccent;
    } else if (status == 'preparing') {
      bg = Colors.orange.withValues(alpha: 0.2);
      fg = Colors.orangeAccent;
    } else if (status == 'cancelled') {
      bg = Colors.red.withValues(alpha: 0.2);
      fg = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
