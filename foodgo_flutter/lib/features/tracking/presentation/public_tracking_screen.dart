import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass/glass_widgets.dart';
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
  Timer? _autoRefreshTimer;

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
    _autoRefreshTimer?.cancel();
    _orderIdController.dispose();
    super.dispose();
  }

  void _syncAutoRefresh(String cleanId, String? status) {
    final lower = (status ?? '').toLowerCase();
    final isTerminal =
        lower == 'delivered' ||
        lower == 'cancelled' ||
        lower == 'failed_delivery';
    if (isTerminal) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
      return;
    }
    _autoRefreshTimer ??= Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _performTrack(cleanId, silent: true);
    });
  }

  Future<void> _performTrack(String idStr, {bool silent = false}) async {
    final cleanId = idStr.trim();
    if (cleanId.isEmpty) {
      _autoRefreshTimer?.cancel();
      setState(() {
        _errorMessage = 'Please enter a valid numeric Order ID.';
        _trackingData = null;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      dynamic response;
      try {
        response = await ApiService().get('orders/$cleanId/track/');
      } catch (_) {
        response = await ApiService().get('orders/$cleanId/tracking/');
      }

      if (!mounted) return;
      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          _trackingData = response;
          _isLoading = false;
        });
        _syncAutoRefresh(cleanId, response['status']?.toString());
      } else if (!silent) {
        setState(() {
          _errorMessage = 'Order not found or tracking data unavailable.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || silent) return;
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final dangerRed = isDark ? Colors.redAccent : const Color(0xFFB91C1C);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Live Delivery Tracking',
        leading: IconButton(
          icon: Icon(AppIcons.back, color: primaryText),
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
                      Text(
                        'Public Order Tracker',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your FoodGo order reference number to view real-time delivery status.',
                        style: textTheme.bodySmall?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _orderIdController,
                              keyboardType: TextInputType.number,
                              style: textTheme.bodyMedium?.copyWith(
                                color: primaryText,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  AppIcons.search,
                                  color: accentGreen,
                                ),
                                hintText: 'Enter Order ID (e.g. 101)',
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: secondaryText,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.1),
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
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Track',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
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
                      color: dangerRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: dangerRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.error, color: dangerRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tracking Results
                if (_trackingData != null) ...[
                  _buildOrderOverviewCard(_trackingData!, isDark),
                  const SizedBox(height: 16),
                  _buildDeliveryProgressCard(_trackingData!, isDark),
                  const SizedBox(height: 16),
                  if (_trackingData!['driver'] != null)
                    _buildDriverCard(
                      _trackingData!['driver'] as Map<String, dynamic>,
                      isDark,
                    )
                  else
                    GlassContainer(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.delivery,
                            color: isDark
                                ? GlassTheme.primaryGreenAccent
                                : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigning Nearby Driver',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Auto-dispatch is locating an online rider for restaurant pickup.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(AppIcons.map, color: Colors.white),
                    label: Text(
                      'Open Full Interactive Map',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.authBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final id = _trackingData!['order_id'];
                      final st = _trackingData!['status']?.toString() ?? '';
                      context.push('/map/$id?status=$st');
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

  Widget _buildOrderOverviewCard(Map<String, dynamic> data, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final accentAmber = isDark ? Colors.orangeAccent : const Color(0xFFB45309);
    final status = (data['status'] ?? '').toString();
    final isPickedUp = data['is_picked_up'] == true;
    final driverAssigned =
        data['driver_assigned'] == true || data['driver'] != null;
    final trackingStage = (data['tracking_stage'] ?? '').toString();
    final etaMinutes = data['eta_minutes'];
    final autoTracking = data['auto_tracking'] == true;
    final restaurant = data['restaurant_name'] ?? 'Restaurant';
    final address = data['delivery_address'] ?? 'Destination address';

    String pickupSummary = 'Picked Up • In Transit';
    if (status == 'delivered') {
      pickupSummary = 'Delivered to Destination';
    } else if (!isPickedUp) {
      if (!driverAssigned) {
        pickupSummary = 'Not Picked Up • Auto-Assigning Driver';
      } else if (trackingStage == 'at_restaurant') {
        pickupSummary = 'Not Picked Up • Rider at Restaurant';
      } else {
        pickupSummary = 'Not Picked Up • Rider Heading to Restaurant';
      }
    } else if (trackingStage == 'arrived') {
      pickupSummary = 'Picked Up • Rider at Destination';
    }

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Order #${data['order_id']}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status, isDark),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isPickedUp ? accentGreen : accentAmber).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pickupSummary,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPickedUp ? accentGreen : accentAmber,
                  ),
                ),
              ),
              if (autoTracking)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    etaMinutes != null && (etaMinutes as num) > 0
                        ? 'Auto-Tracking Live • ETA $etaMinutes min'
                        : 'Auto-Tracking Live',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accentGreen,
                    ),
                  ),
                ),
            ],
          ),
          Divider(height: 24, color: isDark ? Colors.white12 : Colors.black12),
          Row(
            children: [
              Icon(AppIcons.restaurants, color: accentGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Merchant: $restaurant',
                  style: textTheme.bodyMedium?.copyWith(
                    color: primaryText,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.locationOutline, color: accentAmber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery: $address',
                  style: textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProgressCard(Map<String, dynamic> data, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
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
          Text(
            'Delivery Milestones',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryText,
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
                            ? Theme.of(context).colorScheme.primary
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.12)),
                      ),
                      child: isDone
                          ? Icon(
                              AppIcons.check,
                              size: 14,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: index < currentStep
                            ? Theme.of(context).colorScheme.primary
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.1)),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step['title']!,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDone ? primaryText : secondaryText,
                      ),
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

  Widget _buildDriverCard(Map<String, dynamic> driver, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final accentAmber = isDark ? Colors.amber : const Color(0xFFB45309);

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Courier Details',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                child: Icon(AppIcons.motorcycle, color: accentGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'] ?? 'Driver Partner',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver['vehicle_type'] ?? 'Motorcycle'} • ${driver['license_plate'] ?? 'Phnom Penh'}',
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryText,
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
                    Icon(AppIcons.star, color: accentAmber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${driver['rating'] ?? 4.9}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentAmber,
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

  Widget _buildStatusBadge(String status, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    Color bg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    Color fg = primaryText;
    final String label = status.replaceAll('_', ' ').toUpperCase();

    if (status == 'delivered') {
      bg = GlassTheme.primaryGreen.withValues(alpha: 0.16);
      fg = isDark ? GlassTheme.primaryGreenAccent : const Color(0xFF15803D);
    } else if (status == 'on_the_way' || status == 'picked_up') {
      bg = Colors.blue.withValues(alpha: 0.16);
      fg = isDark ? Colors.lightBlueAccent : const Color(0xFF1D4ED8);
    } else if (status == 'preparing') {
      bg = Colors.orange.withValues(alpha: 0.16);
      fg = isDark ? Colors.orangeAccent : const Color(0xFFB45309);
    } else if (status == 'cancelled') {
      bg = Colors.red.withValues(alpha: 0.16);
      fg = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
