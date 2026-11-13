import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/khmer_currency.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../services/api_service.dart';
import '../../../widgets/delivery_qr_modal.dart';
import '../../../widgets/delivery_scanner_modal.dart';
import '../../../widgets/phone_verification_modal.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  final bool initialLoading;
  final Map<String, dynamic>? initialProfile;
  final List<dynamic>? initialAvailable;
  final List<dynamic>? initialActive;
  final List<dynamic>? initialHistory;

  const DriverDashboardScreen({
    super.key,
    this.initialLoading = true,
    this.initialProfile,
    this.initialAvailable,
    this.initialActive,
    this.initialHistory,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final ApiService _api = ApiService();

  int _selectedTab =
      0; // 0: Active, 1: Available, 2: History & Earnings, 3: Profile
  late bool _isLoading;
  bool _isOnline = true;
  bool _isApproved = true;

  Map<String, dynamic>? _driverProfile;
  List<dynamic> _availableOrders = [];
  List<dynamic> _activeOrders = [];
  List<dynamic> _historyOrders = [];

  int _completedDeliveries = 0;
  double _todayEarningsUsd = 0.0;
  double _totalEarningsUsd = 0.0;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.initialLoading;
    if (widget.initialProfile != null) {
      _driverProfile = widget.initialProfile;
      _isOnline = widget.initialProfile!['is_online'] == true;
      _isApproved = widget.initialProfile!['is_approved'] ?? true;
    }
    if (widget.initialAvailable != null) {
      _availableOrders = List.from(widget.initialAvailable!);
    }
    if (widget.initialActive != null) {
      _activeOrders = List.from(widget.initialActive!);
    }
    if (widget.initialHistory != null) {
      _historyOrders = List.from(widget.initialHistory!);
      _completedDeliveries = _historyOrders.length;
    }
    if (widget.initialLoading) {
      _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch driver profile
      try {
        final profileRes = await _api.get('drivers/me/');
        if (profileRes is Map<String, dynamic>) {
          _driverProfile = profileRes;
          _isOnline = profileRes['is_online'] == true;
          _isApproved = profileRes['is_approved'] ?? true;
        }
      } catch (_) {}

      // 2. Fetch available orders
      try {
        final availRes = await _api.get('drivers/available-orders/');
        if (availRes is List) {
          _availableOrders = availRes;
        }
      } catch (_) {}

      // 3. Fetch active deliveries
      try {
        final activeRes = await _api.get('drivers/active-deliveries/');
        if (activeRes is List) {
          _activeOrders = activeRes;
        }
      } catch (_) {}

      // 4. Fetch history
      try {
        final historyRes = await _api.get('drivers/history/');
        if (historyRes is List) {
          _historyOrders = historyRes;
        }
      } catch (_) {}

      // 5. Fetch verified earnings
      try {
        final earningsRes = await _api.get('drivers/earnings/');
        if (earningsRes is Map<String, dynamic>) {
          _todayEarningsUsd =
              (earningsRes['today_earnings_usd'] as num?)?.toDouble() ?? 0.0;
          _totalEarningsUsd =
              (earningsRes['total_earnings_usd'] as num?)?.toDouble() ?? 0.0;
          _completedDeliveries =
              (earningsRes['completed_trips'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}

      // Fallback if specific endpoints were empty/unavailable
      if (_activeOrders.isEmpty && _availableOrders.isEmpty) {
        try {
          final fallbackData = await _api.get('orders/');
          if (fallbackData is List) {
            final active = fallbackData
                .where(
                  (o) =>
                      o['status'] == 'preparing' ||
                      o['status'] == 'ready' ||
                      o['status'] == 'on_the_way' ||
                      o['status'] == 'driver_arrived' ||
                      o['status'] == 'arrived',
                )
                .toList();
            final completed = fallbackData
                .where((o) => o['status'] == 'delivered')
                .toList();

            _availableOrders = active;
            if (_historyOrders.isEmpty) {
              _historyOrders = completed;
            }
            if (_completedDeliveries == 0) {
              _completedDeliveries = completed.length;
            }
            if (_todayEarningsUsd == 0.0) {
              _todayEarningsUsd = completed.fold<double>(0.0, (acc, item) {
                final fee =
                    double.tryParse(
                      item['delivery_fee_charged']?.toString() ??
                          item['delivery_fee']?.toString() ??
                          '2.00',
                    ) ??
                    2.00;
                return acc + fee;
              });
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    try {
      await _api.post('drivers/toggle-online/', {'is_online': value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Status: Online and accepting orders' : 'Status: Offline',
          ),
          backgroundColor: value ? GlassTheme.primaryGreen : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      _fetchDashboardData();
    } catch (_) {
      if (mounted) setState(() => _isOnline = !value);
    }
  }

  Future<void> _broadcastLocation() async {
    try {
      await _api.post('drivers/location/', {'lat': 11.5580, 'lng': 104.9210});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live GPS location broadcast to active customers.'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  Future<void> _acceptOrder(String orderId) async {
    setState(() => _isLoading = true);
    try {
      await _api.post('drivers/orders/$orderId/accept/', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery accepted. Route assigned.'),
          backgroundColor: GlassTheme.primaryGreen,
        ),
      );
      _selectedTab = 0; // Switch to Active Delivery tab
      await _fetchDashboardData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMsg =
          'Unable to accept order. It may have been claimed by another driver.';
      bool needsVerification = false;
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['error'] != null) {
          errorMsg = data['error'].toString();
          if (errorMsg.toLowerCase().contains('phone') ||
              errorMsg.toLowerCase().contains('verif')) {
            needsVerification = true;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: needsVerification
              ? SnackBarAction(
                  label: 'Verify Phone',
                  textColor: Colors.white,
                  onPressed: () {
                    PhoneVerificationModal.show(
                      context,
                      initialPhone: _driverProfile?['phone'],
                      purpose: 'driver_verification',
                      onVerified: _fetchDashboardData,
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _declineOrder(String orderId) async {
    try {
      await _api.post('drivers/orders/$orderId/decline/', {});
      setState(() {
        _availableOrders.removeWhere((o) => o['id'].toString() == orderId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order request dismissed.'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {}
  }

  Future<void> _advanceDeliveryStep(
    Map<String, dynamic> order,
    String currentStatus,
  ) async {
    final orderId = order['id'].toString();
    try {
      if (currentStatus == 'assigned' || currentStatus == 'accepted') {
        await _api.post('drivers/orders/$orderId/arrive-restaurant/', {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrived at restaurant recorded.'),
            backgroundColor: GlassTheme.primaryGreen,
          ),
        );
      } else if (currentStatus == 'arrived_at_restaurant' ||
          currentStatus == 'ready' ||
          currentStatus == 'preparing') {
        await _api.post('drivers/orders/$orderId/pickup/', {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food picked up. Proceed to customer.'),
            backgroundColor: GlassTheme.primaryGreen,
          ),
        );
      } else if (currentStatus == 'picked_up' ||
          currentStatus == 'on_the_way') {
        await _api.post('drivers/orders/$orderId/arrive-customer/', {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrived at customer address.'),
            backgroundColor: GlassTheme.primaryGreen,
          ),
        );
      } else if (currentStatus == 'arrived' ||
          currentStatus == 'driver_arrived') {
        _showDeliveryCompletionSheet(order);
        return;
      }
      _fetchDashboardData();
    } catch (e) {
      if (!mounted) return;
      String err = 'Status update failed. Please retry.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        err = (data['error'] ?? data['detail'] ?? err).toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _reportFailedDelivery(Map<String, dynamic> order) async {
    final orderId = order['id'].toString();
    final reasonController = TextEditingController();
    final shouldReport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Report Delivery Issue',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify reason (e.g., Customer unreachable, wrong address, gate locked):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Customer phone unreachable',
                filled: true,
                fillColor: Colors.black26,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Submit Report',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldReport == true) {
      try {
        final reason = reasonController.text.trim().isEmpty
            ? 'Customer unreachable after multiple attempts'
            : reasonController.text.trim();
        await _api.post('drivers/orders/$orderId/failed-delivery/', {
          'reason': reason,
        });
        _fetchDashboardData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery issue logged. Order marked failed delivery.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log issue.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeliveryCompletionSheet(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final isUnpaid = order['payment_status'] != 'PAID';
    final rawProvider =
        (order['payment_info'] is Map
            ? order['payment_info']['provider']
            : null) ??
        order['payment_provider'] ??
        '';
    final provider = rawProvider.toString().toUpperCase();
    final isBankPayment = {
      'BAKONG',
      'ABA',
      'ACLEDA',
      'BAKONG_KHQR',
      'ABA_KHQR',
      'ACLEDA_KHQR',
      'KHQR',
    }.contains(provider);
    final isCod =
        provider == 'COD' ||
        provider == 'CASH_ON_DELIVERY' ||
        (!isBankPayment && provider.isEmpty);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ResponsiveBottomSheet(
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 16),
              Text(
                'Complete Delivery #$orderId',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (isUnpaid && isBankPayment) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_2, color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank QR Pending Verification',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Customer must complete payment in their banking app or scan the KHQR code before delivery.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (isUnpaid && isCod) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Due Upon Delivery',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Collect \$${order['total_amount']} (≈ ${KhmerCurrency.formatKhr(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0)}) cash from customer',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Select delivery verification method:',
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ListTile(
                tileColor: GlassTheme.primaryGreen.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.4),
                  ),
                ),
                leading: const Icon(
                  AppIcons.qrScan,
                  color: GlassTheme.primaryGreen,
                  size: 26,
                ),
                title: const Text(
                  'Scan Customer Delivery QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Scan QR from customer\'s FoodGo app or enter PIN',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  color: GlassTheme.primaryGreen,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  DeliveryScannerModal.show(
                    context,
                    orderId: orderId,
                    isDriver: true,
                    onConfirmed: () => _fetchDashboardData(),
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(AppIcons.qrCode, color: Colors.white70),
                title: const Text(
                  'Show Driver Handover QR',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Customer scans code displayed on your screen',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  color: Colors.white30,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  DeliveryQrModal.show(
                    context,
                    orderId: orderId,
                    isDriver: true,
                    onDelivered: () => _fetchDashboardData(),
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  AppIcons.checkCircle,
                  color: GlassTheme.primaryGreen,
                ),
                title: const Text(
                  'Direct Handover Confirmation',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Confirm package handed to customer directly',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  color: Colors.white30,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (isBankPayment && isUnpaid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bank QR payment is still pending. Customer must complete payment before handover.',
                        ),
                        backgroundColor: Colors.amber,
                      ),
                    );
                    return;
                  }
                  final isCashDue = isUnpaid && isCod;
                  final confirmed = await _confirmDirectHandover(
                    orderId: orderId,
                    paymentDue: isCashDue,
                    amount: order['total_amount']?.toString(),
                  );
                  if (!confirmed || !mounted) return;

                  try {
                    final response = await _api.post(
                      'drivers/orders/$orderId/deliver/',
                      {'payment_collected': isCashDue},
                    );
                    if (!mounted) return;
                    final fee = response['fee_earned'];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          fee != null
                              ? 'Delivery confirmed by FoodGo. '
                                    'Fee earned: \$$fee'
                              : 'Delivery confirmed by FoodGo.',
                        ),
                        backgroundColor: GlassTheme.primaryGreen,
                      ),
                    );
                    _fetchDashboardData();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'FoodGo did not confirm this delivery. '
                          'Nothing was marked complete — please retry.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Asks the driver to explicitly confirm a direct handover before the
  /// irreversible `deliver/` call. When cash is still due, the driver must
  /// also confirm that the payment was collected.
  Future<bool> _confirmDirectHandover({
    required String orderId,
    required bool paymentDue,
    String? amount,
  }) async {
    var cashCollected = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canConfirm = !paymentDue || cashCollected;
          return AlertDialog(
            title: Text('Confirm delivery #$orderId'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This marks the order as delivered on FoodGo and cannot be '
                  'undone from the app. Only continue once the customer has '
                  'the package in hand.',
                ),
                if (paymentDue) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Cash payment due: \$${amount ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: cashCollected,
                    onChanged: (value) {
                      setDialogState(() => cashCollected = value ?? false);
                    },
                    title: const Text(
                      'I collected the cash payment from the customer',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: canConfirm ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Confirm delivered'),
              ),
            ],
          );
        },
      ),
    );

    return confirmed ?? false;
  }

  void _showCancelOrderDialog(String orderId) {
    final reasonController = TextEditingController(
      text: 'Vehicle breakdown or emergency',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E242B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Report Issue / Cancel',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to release this delivery? If not picked up yet, it will be reassigned to another driver.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Keep Delivery',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.post('drivers/orders/$orderId/cancel/', {
                    'reason': reasonController.text.trim(),
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery cancelled and reported.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  _fetchDashboardData();
                } catch (_) {}
              },
              child: const Text(
                'Confirm Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coordinates copied: $lat, $lng')),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Coordinates copied: $lat, $lng')));
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $text'),
        backgroundColor: GlassTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Driver Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of the Driver Portal?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              context.read<UserProvider>().clearUser();
              context.go('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: context.tr('driver.dashboard'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(AppIcons.logout, color: Colors.redAccent),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80',
            ),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
        child: SafeArea(
          child: ResponsiveWebContainer(
            maxWidth: 900,
            child: Column(
              children: [
                // ── Status & Navigation Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _buildHeaderCard(),
                ),

                // ── Segmented Tab Selector ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: _buildTabSelector(),
                ),

                const SizedBox(height: 8),

                // ── Tab Content ──
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : RefreshIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          backgroundColor: GlassTheme.backgroundDark,
                          onRefresh: _fetchDashboardData,
                          child: _buildSelectedTabContent(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final rating = (_driverProfile?['rating'] as num?)?.toDouble() ?? 4.9;
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusSmall,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlassTheme.primaryGreen.withValues(alpha: 0.35),
                      GlassTheme.primaryGreen.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: GlassTheme.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _driverProfile?['full_name'] ??
                                _driverProfile?['username'] ??
                                'FoodGo Driver',
                            style: TextStyle(
                              color: AppTypography.primaryTextColor(
                                Theme.of(context).brightness,
                              ),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isApproved) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pending Approval',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_driverProfile?['vehicle_type'] ?? 'Motorcycle'} · ${_driverProfile?['license_plate'] ?? 'PP-2026'}',
                      style: TextStyle(
                        color: AppTypography.secondaryTextColor(
                          Theme.of(context).brightness,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isOnline,
                activeTrackColor: GlassTheme.primaryGreen,
                onChanged: _toggleOnline,
              ),
            ],
          ),
          if (_isOnline) ...[
            const Divider(color: Colors.white12, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('driver.onlineAvailable'),
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: GlassTheme.primaryGreen,
                    backgroundColor: GlassTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  icon: const Icon(Icons.my_location, size: 14),
                  label: const Text(
                    'Broadcast Location',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _broadcastLocation,
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTabSelector() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final tabs = [
      {
        'title':
            '${context.tr('driver.activeDeliveries')} (${_activeOrders.length})',
        'icon': AppIcons.delivery,
      },
      {
        'title':
            '${context.tr('driver.availableOrders')} (${_availableOrders.length})',
        'icon': AppIcons.orders,
      },
      {'title': context.tr('driver.earnings'), 'icon': AppIcons.payment},
      {'title': context.tr('nav.profile'), 'icon': AppIcons.profile},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : GlassTheme.borderLight,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : secondaryText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[index]['title'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? primaryText : secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildActiveDeliveriesTab();
      case 1:
        return _buildAvailableOrdersTab();
      case 2:
        return _buildEarningsTab();
      case 3:
        return _buildDriverProfileTab();
      default:
        return _buildActiveDeliveriesTab();
    }
  }

  // ─────────────────────────────────────────────
  // TAB 0: ACTIVE DELIVERIES
  // ─────────────────────────────────────────────
  Widget _buildActiveDeliveriesTab() {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bike,
                size: 56,
                color: GlassTheme.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Deliveries',
                style: TextStyle(
                  color: AppTypography.primaryTextColor(
                    Theme.of(context).brightness,
                  ),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check available orders tab to accept an order assignment.',
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('View Available Orders'),
                onPressed: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return _buildActiveOrderCard(order).motionEntrance(staggerIndex: index);
      },
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'assigned';
    final rest = order['restaurant'] is Map
        ? order['restaurant']
        : {'name': order['restaurant_name'] ?? 'Restaurant'};
    final restName = rest['name'] ?? 'Restaurant';
    final restPhone = rest['phone'] ?? '+855 23 888 777';
    final restAddress = rest['address'] ?? 'Phnom Penh';
    final restLat = (rest['lat'] as num?)?.toDouble() ?? 11.5564;
    final restLng = (rest['lng'] as num?)?.toDouble() ?? 104.9282;

    final addr = order['address'] is Map
        ? order['address']
        : {'street': order['delivery_address_snapshot'] ?? 'Phnom Penh'};
    final custStreet = addr['street'] ?? 'Delivery Address, Phnom Penh';
    final custLat = (addr['lat'] as num?)?.toDouble() ?? 11.5621;
    final custLng = (addr['lng'] as num?)?.toDouble() ?? 104.9160;

    final cust = order['customer_info'] is Map ? order['customer_info'] : {};
    final custName = cust['name'] ?? 'Customer';
    final custPhone = cust['phone'] ?? '+855 12 345 678';

    final totalAmount = order['total_amount']?.toString() ?? '0.00';
    final deliveryFee = order['delivery_fee_charged']?.toString() ?? '2.00';
    final isPaid = order['payment_status'] == 'PAID';
    final rawProvider =
        (order['payment_info'] is Map
            ? order['payment_info']['provider']
            : null) ??
        order['payment_provider'] ??
        '';
    final provider = rawProvider.toString().toUpperCase();
    final isBankPayment = {
      'BAKONG',
      'ABA',
      'ACLEDA',
      'BAKONG_KHQR',
      'ABA_KHQR',
      'ACLEDA_KHQR',
      'KHQR',
    }.contains(provider);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order['id']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (order['order_reference'] != null) ...[
            const SizedBox(height: 2),
            Text(
              order['order_reference'],
              style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),

          // Lifecycle Stepper
          _buildLifecycleStepper(status),
          const SizedBox(height: 16),

          // Restaurant Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.store,
                      color: GlassTheme.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pickup: $restName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  restAddress,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlassTheme.primaryGreen,
                        side: BorderSide(color: GlassTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 14),
                      label: const Text(
                        'Map Route',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () =>
                          context.push('/map/${order['id']}?isDriver=true'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.navigation, size: 14),
                      label: const Text(
                        'Directions',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => _launchMaps(restLat, restLng, restName),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.phone, size: 14),
                      label: const Text('Call', style: TextStyle(fontSize: 11)),
                      onPressed: () =>
                          _copyToClipboard(restPhone, 'Restaurant Phone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Customer Dropoff Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deliver to: $custName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  custStreet,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (order['special_instructions'] != null &&
                    order['special_instructions']
                        .toString()
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${order['special_instructions']}',
                    style: const TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: GlassTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.map_rounded, size: 15),
                      label: const Text(
                        'Open Delivery Map',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () =>
                          context.push('/map/${order['id']}?isDriver=true'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.navigation, size: 14),
                      label: const Text(
                        'Directions',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () =>
                          _launchMaps(custLat, custLng, custStreet),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.phone, size: 14),
                      label: const Text('Call', style: TextStyle(fontSize: 11)),
                      onPressed: () =>
                          _copyToClipboard(custPhone, 'Customer Phone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Payment Status & Delivery Fee Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Status',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                              : Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid
                              ? 'PAID ONLINE'
                              : (isBankPayment
                                    ? 'KHQR PENDING VERIFICATION'
                                    : 'CASH DUE ON DELIVERY'),
                          style: TextStyle(
                            color: isPaid
                                ? GlassTheme.primaryGreen
                                : Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Delivery Fee Earning',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+\$$deliveryFee ≈ ${KhmerCurrency.formatKhr(double.tryParse(deliveryFee) ?? 2.0)}',
                    style: const TextStyle(
                      color: GlassTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Order Total: \$$totalAmount',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary Step Action Button
          _buildStepActionButton(order, status),
          const SizedBox(height: 8),

          // Secondary Action (Cancel / Report Issue)
          TextButton(
            onPressed: () => _showCancelOrderDialog(order['id'].toString()),
            child: const Text(
              'Report Issue or Reassign',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildLifecycleStepper(String status) {
    final steps = [
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'at_restaurant', 'label': 'At Restaurant'},
      {'key': 'picked_up', 'label': 'Picked Up'},
      {'key': 'at_customer', 'label': 'At Customer'},
      {'key': 'delivered', 'label': 'Delivered'},
    ];

    int currentStepIndex = 0;
    if (status == 'assigned' || status == 'accepted') currentStepIndex = 0;
    if (status == 'arrived_at_restaurant') currentStepIndex = 1;
    if (status == 'picked_up' || status == 'on_the_way') currentStepIndex = 2;
    if (status == 'arrived' || status == 'driver_arrived') currentStepIndex = 3;
    if (status == 'delivered') currentStepIndex = 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isCompleted = i <= currentStepIndex;
          final isCurrent = i == currentStepIndex;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= currentStepIndex
                                ? GlassTheme.primaryGreen
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? GlassTheme.primaryGreen
                            : Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: Colors.white, width: 2)
                            : Border.all(
                                color: isCompleted
                                    ? GlassTheme.primaryGreen
                                    : Colors.white24,
                                width: 1,
                              ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: GlassTheme.primaryGreen.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.black,
                              )
                            : Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white60,
                                ),
                              ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i < currentStepIndex
                                ? GlassTheme.primaryGreen
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i]['label']!,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent
                        ? Colors.white
                        : (isCompleted
                              ? GlassTheme.primaryGreen
                              : Colors.white54),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepActionButton(Map<String, dynamic> order, String status) {
    if (status == 'assigned' || status == 'accepted') {
      return GlassButton(
        text: 'Arrived at Restaurant',
        icon: Icons.storefront,
        onPressed: () => _advanceDeliveryStep(order, status),
      );
    } else if (status == 'arrived_at_restaurant' ||
        status == 'ready' ||
        status == 'preparing') {
      return GlassButton(
        text: 'Confirm Food Picked Up',
        icon: Icons.takeout_dining,
        onPressed: () => _advanceDeliveryStep(order, status),
      );
    } else if (status == 'picked_up' || status == 'on_the_way') {
      return Row(
        children: [
          Expanded(
            child: GlassButton(
              text: 'Arrived at Customer',
              icon: Icons.place,
              onPressed: () => _advanceDeliveryStep(order, status),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Report Delivery Issue',
            icon: const Icon(
              Icons.report_problem_outlined,
              color: Colors.orangeAccent,
            ),
            onPressed: () => _reportFailedDelivery(order),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: GlassButton(
              text: 'Complete Delivery Handover',
              icon: Icons.check_circle,
              onPressed: () => _advanceDeliveryStep(order, status),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Report Delivery Issue',
            icon: const Icon(
              Icons.report_problem_outlined,
              color: Colors.orangeAccent,
            ),
            onPressed: () => _reportFailedDelivery(order),
          ),
        ],
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'assigned':
        return Colors.blueAccent;
      case 'arrived_at_restaurant':
        return Colors.purpleAccent;
      case 'picked_up':
      case 'on_the_way':
        return Colors.orangeAccent;
      case 'arrived':
      case 'driver_arrived':
        return Colors.tealAccent;
      case 'delivered':
        return GlassTheme.primaryGreen;
      default:
        return Colors.white70;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'arrived_at_restaurant':
        return 'AT RESTAURANT';
      case 'picked_up':
      case 'on_the_way':
        return 'ON THE WAY';
      case 'arrived':
      case 'driver_arrived':
        return 'AT DESTINATION';
      default:
        return status.toUpperCase();
    }
  }

  // ─────────────────────────────────────────────
  // TAB 1: AVAILABLE ORDERS
  // ─────────────────────────────────────────────
  Widget _buildAvailableOrdersTab() {
    if (!_isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.white30),
              const SizedBox(height: 16),
              const Text(
                'You are Currently Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Turn on your online status to receive live delivery requests.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.toggle_on),
                label: const Text('Go Online Now'),
                onPressed: () => _toggleOnline(true),
              ),
            ],
          ),
        ),
      );
    }

    if (_availableOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 56, color: Colors.white30),
              const SizedBox(height: 16),
              const Text(
                'No Available Orders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Waiting for incoming food orders from nearby restaurants.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final bool isPhoneVerified = _driverProfile?['is_phone_verified'] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isPhoneVerified) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Phone Verification Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'You must verify your Cambodian phone number (+855) via SMS OTP before accepting delivery assignments.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    PhoneVerificationModal.show(
                      context,
                      initialPhone: _driverProfile?['phone'],
                      purpose: 'driver_verification',
                      onVerified: _fetchDashboardData,
                    );
                  },
                  icon: const Icon(Icons.verified, size: 16),
                  label: const Text('Verify Phone via SMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ..._availableOrders.asMap().entries.map(
          (entry) => _buildAvailableOrderCard(
            entry.value,
          ).motionEntrance(staggerIndex: entry.key),
        ),
      ],
    );
  }

  Widget _buildAvailableOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final rest = order['restaurant'] is Map
        ? order['restaurant']
        : {'name': order['restaurant_name'] ?? 'Restaurant'};
    final restName = rest['name'] ?? 'Restaurant';
    final restAddress = rest['address'] ?? 'Phnom Penh';

    final addr = order['address'] is Map
        ? order['address']
        : {'street': order['delivery_address_snapshot'] ?? 'Phnom Penh'};
    final custStreet = addr['street'] ?? 'Delivery Address, Phnom Penh';

    final deliveryFee = order['delivery_fee_charged']?.toString() ?? '2.00';
    final totalAmount = order['total_amount']?.toString() ?? '0.00';
    final isPaid = order['payment_status'] == 'PAID';
    final rawProvider =
        (order['payment_info'] is Map
            ? order['payment_info']['provider']
            : null) ??
        order['payment_provider'] ??
        '';
    final provider = rawProvider.toString().toUpperCase();
    final isBankPayment = {
      'BAKONG',
      'ABA',
      'ACLEDA',
      'BAKONG_KHQR',
      'ABA_KHQR',
      'ACLEDA_KHQR',
      'KHQR',
    }.contains(provider);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                      : Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid
                      ? 'PAID'
                      : (isBankPayment ? 'KHQR PENDING' : 'COD DUE'),
                  style: TextStyle(
                    color: isPaid ? GlassTheme.primaryGreen : Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Restaurant Pickup Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.store, color: GlassTheme.primaryGreen, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      restAddress,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Customer Dropoff Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Destination',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      custStreet,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),

          // Fee & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Earning',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '+\$$deliveryFee ≈ ${KhmerCurrency.formatKhr(double.tryParse(deliveryFee) ?? 2.0)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Order: \$$totalAmount',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: GlassTheme.primaryGreen,
                      side: BorderSide(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    tooltip: 'Preview on Map',
                    onPressed: () =>
                        context.push('/map/$orderId?isDriver=true'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38, width: 1.2),
                      minimumSize: const Size(80, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _declineOrder(orderId),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(96, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Accept',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => _acceptOrder(orderId),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─────────────────────────────────────────────
  // TAB 2: TRIP HISTORY & EARNINGS
  // ─────────────────────────────────────────────
  Widget _buildEarningsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Earnings Stats Card
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: GlassTheme.borderRadiusSmall,
          customColor: GlassTheme.primaryGreen.withValues(alpha: 0.12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Earnings",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_todayEarningsUsd.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: GlassTheme.primaryGreen,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_completedDeliveries',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Trips',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  Column(
                    children: [
                      Text(
                        '\$${_totalEarningsUsd.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '≈ ${KhmerCurrency.formatKhr(_totalEarningsUsd)}',
                        style: TextStyle(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Lifetime Earned',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Completed Deliveries',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (_historyOrders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No completed deliveries yet.',
                style: TextStyle(color: GlassTheme.textMuted),
              ),
            ),
          )
        else
          ..._historyOrders.map((o) {
            final restName = o['restaurant'] is Map
                ? o['restaurant']['name']
                : o['restaurant_name'] ?? 'Restaurant';
            final fee = o['delivery_fee_charged']?.toString() ?? '2.00';
            final dateStr = o['created_at'] != null
                ? o['created_at'].toString().split('T').first
                : 'Recent';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: GlassTheme.primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${o['id']} · $restName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+\$$fee',
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TAB 3: DRIVER PROFILE
  // ─────────────────────────────────────────────
  Widget _buildDriverProfileTab() {
    final username = _driverProfile?['username'] ?? 'driver1';
    final fullName = _driverProfile?['full_name'] ?? username;
    final phone = _driverProfile?['phone'] ?? '+855 12 888 999';
    final vehicle =
        _driverProfile?['vehicle_type'] ?? 'Motorcycle (Honda Wave)';
    final plate = _driverProfile?['license_plate'] ?? 'PP-2026';
    final rating = (_driverProfile?['rating'] as num?)?.toDouble() ?? 4.9;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: GlassTheme.borderRadiusSmall,
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: GlassTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@$username',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$rating Rating',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle & Registration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildProfileRow(Icons.two_wheeler, 'Vehicle Type', vehicle),
              _buildProfileRow(Icons.badge, 'License Plate', plate),
              _buildProfileRow(Icons.phone, 'Contact Phone', phone),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phonelink_lock,
                      size: 18,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Phone Verification',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_driverProfile?['is_phone_verified'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.primaryGreen.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: GlassTheme.primaryGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified (+855)',
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: () {
                          PhoneVerificationModal.show(
                            context,
                            initialPhone: phone,
                            purpose: 'driver_verification',
                            onVerified: _fetchDashboardData,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verify Now',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildProfileRow(
                Icons.verified_user,
                'Account Approval',
                _isApproved ? 'Approved & Active' : 'Pending Review',
                valueColor: _isApproved
                    ? GlassTheme.primaryGreen
                    : Colors.amber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassButton(
          text: 'Edit Vehicle / Phone Info',
          icon: Icons.edit,
          onPressed: _showEditProfileDialog,
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
            foregroundColor: Colors.redAccent,
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text(
            'Log Out from Driver Portal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          onPressed: () => _confirmLogout(context),
        ),
      ],
    );
  }

  Widget _buildProfileRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final vehicleCtrl = TextEditingController(
      text: _driverProfile?['vehicle_type'] ?? 'Motorcycle',
    );
    final plateCtrl = TextEditingController(
      text: _driverProfile?['license_plate'] ?? 'PP-2026',
    );
    final phoneCtrl = TextEditingController(
      text: _driverProfile?['phone'] ?? '+855 12 888 999',
    );

    final vehicleOptions = [
      {'name': 'Motorcycle', 'icon': Icons.two_wheeler_rounded},
      {'name': 'Scooter', 'icon': Icons.electric_moped_rounded},
      {'name': 'Car', 'icon': Icons.directions_car_rounded},
      {'name': 'Bicycle', 'icon': Icons.pedal_bike_rounded},
    ];

    String selectedVehicle = vehicleCtrl.text.trim();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return ResponsiveBottomSheet(
              child: SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(modalCtx).size.height * 0.90,
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: GlassTheme.dialogDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: GlassTheme.limeAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                color: GlassTheme.limeAccent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Driver Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Update vehicle specifications and contact info',
                                    style: TextStyle(
                                      color: GlassTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(modalCtx),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Vehicle Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vehicleOptions.map((opt) {
                            final name = opt['name'] as String;
                            final icon = opt['icon'] as IconData;
                            final isSel =
                                selectedVehicle.toLowerCase() ==
                                name.toLowerCase();
                            return ChoiceChip(
                              avatar: Icon(
                                icon,
                                size: 16,
                                color: isSel ? Colors.black : Colors.white70,
                              ),
                              label: Text(
                                name,
                                style: TextStyle(
                                  color: isSel ? Colors.black : Colors.white70,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: GlassTheme.limeAccent,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
                              side: BorderSide(
                                color: isSel
                                    ? GlassTheme.limeAccent
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    selectedVehicle = name;
                                    vehicleCtrl.text = name;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: vehicleCtrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          onChanged: (text) {
                            setModalState(() {
                              selectedVehicle = text.trim();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Vehicle Specification',
                            labelStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.directions_bike,
                              color: GlassTheme.limeAccent,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GlassTheme.limeAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: plateCtrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'License Plate Number',
                            labelStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.pin,
                              color: GlassTheme.limeAccent,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GlassTheme.limeAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Contact Phone Number',
                            labelStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: GlassTheme.limeAccent,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: GlassTheme.limeAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(modalCtx),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setModalState(() {
                                          isSaving = true;
                                        });
                                        try {
                                          await _api.patch('drivers/me/', {
                                            'vehicle_type': vehicleCtrl.text
                                                .trim(),
                                            'license_plate': plateCtrl.text
                                                .trim(),
                                            'phone': phoneCtrl.text.trim(),
                                          });
                                          if (!modalCtx.mounted) return;
                                          Navigator.pop(modalCtx);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Driver profile updated successfully.',
                                              ),
                                              backgroundColor:
                                                  GlassTheme.primaryGreen,
                                            ),
                                          );
                                          _fetchDashboardData();
                                        } catch (e) {
                                          if (modalCtx.mounted) {
                                            setModalState(() {
                                              isSaving = false;
                                            });
                                          }
                                          if (!mounted) return;
                                          String err =
                                              'Failed to update driver profile. Please retry.';
                                          if (e is DioException &&
                                              e.response?.data is Map) {
                                            final data =
                                                e.response!.data as Map;
                                            err =
                                                (data['error'] ??
                                                        data['detail'] ??
                                                        data.values.first
                                                            ?.toString() ??
                                                        err)
                                                    .toString();
                                          } else if (e is DioException &&
                                              e.response?.statusCode == 401) {
                                            err =
                                                'Session expired. Please log in again.';
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(err),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlassTheme.primaryGreen,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
