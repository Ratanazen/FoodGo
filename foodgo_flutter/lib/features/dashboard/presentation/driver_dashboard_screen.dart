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
              double.tryParse(
                earningsRes['today_earnings_usd']?.toString() ?? '',
              ) ??
              0.0;
          _totalEarningsUsd =
              double.tryParse(
                earningsRes['total_earnings_usd']?.toString() ?? '',
              ) ??
              0.0;
          _completedDeliveries =
              int.tryParse(earningsRes['completed_trips']?.toString() ?? '') ??
              0;
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
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DriverFailedDeliveryDialog(),
    );

    if (reason != null && mounted) {
      try {
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
          SnackBar(
            content: Text(
              ApiService.formatError(e, fallback: 'Failed to log issue.'),
            ),
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

    final sheetBrightness = Theme.of(context).brightness;
    final sheetIsDark = sheetBrightness == Brightness.dark;
    final sheetPrimaryText = AppTypography.primaryTextColor(sheetBrightness);
    final sheetSecondaryText = AppTypography.secondaryTextColor(
      sheetBrightness,
    );
    final warningTextColor = sheetIsDark
        ? Colors.amber
        : const Color(0xFFB45309);

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
                    color: sheetIsDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Delivery #$orderId',
                style: TextStyle(
                  color: sheetPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (isUnpaid && isBankPayment) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2, color: warningTextColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank QR Pending Verification',
                              style: TextStyle(
                                color: warningTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Customer must complete payment in their banking app or scan the KHQR code before delivery.',
                              style: TextStyle(
                                color: sheetSecondaryText,
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
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments_outlined, color: warningTextColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Due Upon Delivery',
                              style: TextStyle(
                                color: warningTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Collect \$${order['total_amount']} (≈ ${KhmerCurrency.formatKhr(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0)}) cash from customer',
                              style: TextStyle(
                                color: sheetSecondaryText,
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
                style: TextStyle(color: sheetSecondaryText, fontSize: 13),
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
                title: Text(
                  'Scan Customer Delivery QR Code',
                  style: TextStyle(
                    color: sheetPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Scan QR from customer\'s FoodGo app or enter PIN',
                  style: TextStyle(color: sheetSecondaryText, fontSize: 12),
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
                tileColor: sheetIsDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: sheetIsDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                leading: Icon(AppIcons.qrCode, color: sheetSecondaryText),
                title: Text(
                  'Show Driver Handover QR',
                  style: TextStyle(
                    color: sheetPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Customer scans code displayed on your screen',
                  style: TextStyle(color: sheetSecondaryText, fontSize: 12),
                ),
                trailing: Icon(
                  AppIcons.chevronRight,
                  color: sheetSecondaryText,
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
                tileColor: sheetIsDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: sheetIsDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                leading: const Icon(
                  AppIcons.checkCircle,
                  color: GlassTheme.primaryGreen,
                ),
                title: Text(
                  'Direct Handover Confirmation',
                  style: TextStyle(
                    color: sheetPrimaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Confirm package handed to customer directly',
                  style: TextStyle(color: sheetSecondaryText, fontSize: 12),
                ),
                trailing: Icon(
                  AppIcons.chevronRight,
                  color: sheetSecondaryText,
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canConfirm = !paymentDue || cashCollected;
          return AlertDialog(
            backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
              ),
            ),
            title: Text(
              'Confirm delivery #$orderId',
              style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This marks the order as delivered on FoodGo and cannot be '
                  'undone from the app. Only continue once the customer has '
                  'the package in hand.',
                  style: TextStyle(color: secondaryText),
                ),
                if (paymentDue) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Cash payment due: \$${amount ?? '—'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: cashCollected,
                    onChanged: (value) {
                      setDialogState(() => cashCollected = value ?? false);
                    },
                    title: Text(
                      'I collected the cash payment from the customer',
                      style: TextStyle(color: primaryText, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: secondaryText)),
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

  Future<void> _showCancelOrderDialog(String orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DriverCancelOrderDialog(),
    );
    if (reason == null || !mounted) return;
    try {
      await _api.post('drivers/orders/$orderId/cancel/', {'reason': reason});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery cancelled and reported.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _fetchDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.formatError(
              e,
              fallback: 'Failed to cancel delivery. Please try again.',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        title: Text(
          'Driver Log Out',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out of the Driver Portal?',
          style: TextStyle(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: secondaryText)),
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
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? GlassTheme.backgroundDark
                              : Colors.white,
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final amberTextColor = isDark ? Colors.amber : const Color(0xFFB45309);
    final rating =
        double.tryParse(_driverProfile?['rating']?.toString() ?? '') ?? 4.9;
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
                              Icon(Icons.star, color: amberTextColor, size: 11),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: amberTextColor,
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
                            child: Text(
                              'Pending Approval',
                              style: TextStyle(
                                color: amberTextColor,
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
            Divider(
              color: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.08),
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: Text(
                          context.tr('driver.onlineAvailable'),
                          style: const TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _broadcastLocation,
                  ),
                ],
              ),
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
                      ? Theme.of(context).colorScheme.primary.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        )
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
    final restLat = double.tryParse(rest['lat']?.toString() ?? '') ?? 11.5564;
    final restLng = double.tryParse(rest['lng']?.toString() ?? '') ?? 104.9282;

    final addr = order['address'] is Map
        ? order['address']
        : {'street': order['delivery_address_snapshot'] ?? 'Phnom Penh'};
    final custStreet = addr['street'] ?? 'Delivery Address, Phnom Penh';
    final custLat = double.tryParse(addr['lat']?.toString() ?? '') ?? 11.5621;
    final custLng = double.tryParse(addr['lng']?.toString() ?? '') ?? 104.9160;

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

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final amberTextColor = isDark ? Colors.amber : const Color(0xFFB45309);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order['id']}',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (order['order_reference'] != null) ...[
            const SizedBox(height: 2),
            Text(
              order['order_reference'],
              style: TextStyle(color: secondaryText, fontSize: 11),
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.08),
              ),
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
                        style: TextStyle(
                          color: primaryText,
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
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlassTheme.primaryGreen,
                        side: const BorderSide(color: GlassTheme.primaryGreen),
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
                        foregroundColor: secondaryText,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : secondaryText.withValues(alpha: 0.35),
                        ),
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
                        foregroundColor: secondaryText,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : secondaryText.withValues(alpha: 0.35),
                        ),
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.08),
              ),
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
                        style: TextStyle(
                          color: primaryText,
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
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                if (order['special_instructions'] != null &&
                    order['special_instructions']
                        .toString()
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${order['special_instructions']}',
                    style: TextStyle(color: amberTextColor, fontSize: 11),
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
                        foregroundColor: secondaryText,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : secondaryText.withValues(alpha: 0.35),
                        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Status',
                      style: TextStyle(color: secondaryText, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
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
                              : amberTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Delivery Fee Earning',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: secondaryText, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+\$$deliveryFee ≈ ${KhmerCurrency.formatKhr(double.tryParse(deliveryFee) ?? 2.0)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Order Total: \$$totalAmount',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: secondaryText, fontSize: 11),
                    ),
                  ],
                ),
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
            child: Text(
              'Report Issue or Reassign',
              style: TextStyle(color: secondaryText, fontSize: 12),
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

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
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
                                : (isDark
                                      ? Colors.white12
                                      : Colors.black.withValues(alpha: 0.1)),
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
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06)),
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: isDark
                                    ? Colors.white
                                    : GlassTheme.primaryGreenDark,
                                width: 2,
                              )
                            : Border.all(
                                color: isCompleted
                                    ? GlassTheme.primaryGreen
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.black26),
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
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryText,
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
                                : (isDark
                                      ? Colors.white12
                                      : Colors.black.withValues(alpha: 0.1)),
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
                        ? primaryText
                        : (isCompleted
                              ? GlassTheme.primaryGreen
                              : secondaryText),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'accepted':
      case 'assigned':
        return Colors.blueAccent;
      case 'arrived_at_restaurant':
        return Colors.purpleAccent;
      case 'picked_up':
      case 'on_the_way':
        return isDark ? Colors.orangeAccent : const Color(0xFFC2410C);
      case 'arrived':
      case 'driver_arrived':
        return isDark ? Colors.tealAccent : const Color(0xFF0F766E);
      case 'delivered':
        return GlassTheme.primaryGreen;
      default:
        return AppTypography.secondaryTextColor(Theme.of(context).brightness);
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    if (!_isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 56,
                color: secondaryText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'You are Currently Offline',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Turn on your online status to receive live delivery requests.',
                style: TextStyle(color: secondaryText, fontSize: 13),
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
              Icon(
                Icons.inbox,
                size: 56,
                color: secondaryText.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No Available Orders',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Waiting for incoming food orders from nearby restaurants.',
                style: TextStyle(color: secondaryText, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final bool isPhoneVerified = _driverProfile?['is_phone_verified'] == true;
    final warningTextColor = isDark ? Colors.amber : const Color(0xFFB45309);

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
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: warningTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phone Verification Required',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'You must verify your Cambodian phone number (+855) via SMS OTP before accepting delivery assignments.',
                  style: TextStyle(color: secondaryText, fontSize: 12),
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

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final amberTextColor = isDark ? Colors.amber : const Color(0xFFB45309);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #$orderId',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                      color: isPaid ? GlassTheme.primaryGreen : amberTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              const Icon(Icons.store, color: GlassTheme.primaryGreen, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restName,
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      restAddress,
                      style: TextStyle(color: secondaryText, fontSize: 11),
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
                    Text(
                      'Delivery Destination',
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      custStreet,
                      style: TextStyle(color: secondaryText, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.08),
            height: 20,
          ),

          // Fee & Action Buttons (responsive on 360px phones)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Earning',
                    style: TextStyle(color: secondaryText, fontSize: 11),
                  ),
                  Text(
                    '+\$$deliveryFee ≈ ${KhmerCurrency.formatKhr(double.tryParse(deliveryFee) ?? 2.0)}',
                    style: const TextStyle(
                      color: GlassTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Order: \$$totalAmount',
                    style: TextStyle(color: secondaryText, fontSize: 11),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white38
                            : secondaryText.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
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
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

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
                      Text(
                        "Today's Earnings",
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_todayEarningsUsd.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: primaryText,
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
              Divider(
                color: isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.08),
                height: 24,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_completedDeliveries',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Trips',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '\$${_totalEarningsUsd.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '≈ ${KhmerCurrency.formatKhr(_totalEarningsUsd)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.9,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lifetime Earned',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Completed Deliveries',
          style: TextStyle(
            color: primaryText,
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
                style: TextStyle(color: secondaryText),
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
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: secondaryText,
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
    final rating =
        double.tryParse(_driverProfile?['rating']?.toString() ?? '') ?? 4.9;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final warningTextColor = isDark ? Colors.amber : const Color(0xFFB45309);

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
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@$username',
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: warningTextColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$rating Rating',
                      style: TextStyle(
                        color: primaryText,
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
              Text(
                'Vehicle & Registration',
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Divider(
                color: isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.08),
                height: 20,
              ),
              _buildProfileRow(Icons.two_wheeler, 'Vehicle Type', vehicle),
              _buildProfileRow(Icons.badge, 'License Plate', plate),
              _buildProfileRow(Icons.phone, 'Contact Phone', phone),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.phonelink_lock, size: 18, color: secondaryText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phone Verification',
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: warningTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verify Now',
                                style: TextStyle(
                                  color: warningTextColor,
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
                    : warningTextColor,
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
    final brightness = Theme.of(context).brightness;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondaryText),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: secondaryText, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DriverEditProfileSheet(
        api: _api,
        initialVehicleType: (_driverProfile?['vehicle_type'] ?? 'Motorcycle')
            .toString(),
        initialPlate: (_driverProfile?['license_plate'] ?? 'PP-2026')
            .toString(),
        initialPhone: (_driverProfile?['phone'] ?? '+855 12 888 999')
            .toString(),
        onSaved: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver profile updated successfully.'),
              backgroundColor: GlassTheme.primaryGreen,
            ),
          );
          _fetchDashboardData();
        },
        onError: (err) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
          );
        },
      ),
    );
  }
}

class _DriverFailedDeliveryDialog extends StatefulWidget {
  const _DriverFailedDeliveryDialog();

  @override
  State<_DriverFailedDeliveryDialog> createState() =>
      _DriverFailedDeliveryDialogState();
}

class _DriverFailedDeliveryDialogState
    extends State<_DriverFailedDeliveryDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      title: Text(
        'Report Delivery Issue',
        style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specify reason (e.g., Customer unreachable, wrong address, gate locked):',
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Customer phone unreachable',
              hintStyle: TextStyle(color: secondaryText),
              filled: true,
              fillColor: isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFD1D5DB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFD1D5DB),
                ),
              ),
            ),
            style: TextStyle(color: primaryText),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: secondaryText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            final reason = _reasonController.text.trim().isEmpty
                ? 'Customer unreachable after multiple attempts'
                : _reasonController.text.trim();
            Navigator.pop(context, reason);
          },
          child: const Text(
            'Submit Report',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DriverCancelOrderDialog extends StatefulWidget {
  const _DriverCancelOrderDialog();

  @override
  State<_DriverCancelOrderDialog> createState() =>
      _DriverCancelOrderDialogState();
}

class _DriverCancelOrderDialogState extends State<_DriverCancelOrderDialog> {
  final TextEditingController _reasonController = TextEditingController(
    text: 'Vehicle breakdown or emergency',
  );

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      title: Text(
        'Report Issue / Cancel',
        style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to release this delivery? If not picked up yet, it will be reassigned to another driver.',
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: 'Reason for cancellation',
              labelStyle: TextStyle(color: secondaryText),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Keep Delivery', style: TextStyle(color: secondaryText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () =>
              Navigator.pop(context, _reasonController.text.trim()),
          child: const Text(
            'Confirm Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DriverEditProfileSheet extends StatefulWidget {
  final ApiService api;
  final String initialVehicleType;
  final String initialPlate;
  final String initialPhone;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _DriverEditProfileSheet({
    required this.api,
    required this.initialVehicleType,
    required this.initialPlate,
    required this.initialPhone,
    required this.onSaved,
    required this.onError,
  });

  @override
  State<_DriverEditProfileSheet> createState() =>
      _DriverEditProfileSheetState();
}

class _DriverEditProfileSheetState extends State<_DriverEditProfileSheet> {
  static const List<Map<String, Object>> _vehicleOptions = [
    {'name': 'Motorcycle', 'icon': Icons.two_wheeler_rounded},
    {'name': 'Scooter', 'icon': Icons.electric_moped_rounded},
    {'name': 'Car', 'icon': Icons.directions_car_rounded},
    {'name': 'Bicycle', 'icon': Icons.pedal_bike_rounded},
  ];

  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _phoneCtrl;
  late String _selectedVehicle;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _vehicleCtrl = TextEditingController(text: widget.initialVehicleType);
    _plateCtrl = TextEditingController(text: widget.initialPlate);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _selectedVehicle = _vehicleCtrl.text.trim();
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await widget.api.patch('drivers/me/', {
        'vehicle_type': _vehicleCtrl.text.trim(),
        'license_plate': _plateCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      widget.onError(
        ApiService.formatError(
          e,
          fallback: 'Failed to update driver profile. Please retry.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentColor = isDark
        ? GlassTheme.limeAccent
        : GlassTheme.primaryGreenDark;

    return ResponsiveBottomSheet(
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.dialogDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
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
                      color: isDark ? Colors.white24 : Colors.black12,
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Driver Profile',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update vehicle specifications and contact info',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: secondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Vehicle Type',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vehicleOptions.map((opt) {
                    final name = opt['name'] as String;
                    final icon = opt['icon'] as IconData;
                    final isSel =
                        _selectedVehicle.toLowerCase() == name.toLowerCase();
                    return ChoiceChip(
                      avatar: Icon(
                        icon,
                        size: 16,
                        color: isSel ? Colors.black : secondaryText,
                      ),
                      label: Text(
                        name,
                        style: TextStyle(
                          color: isSel ? Colors.black : secondaryText,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: GlassTheme.limeAccent,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      side: BorderSide(
                        color: isSel
                            ? GlassTheme.limeAccent
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.12)),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedVehicle = name;
                            _vehicleCtrl.text = name;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _vehicleCtrl,
                  style: TextStyle(color: primaryText, fontSize: 14),
                  onChanged: (text) {
                    setState(() {
                      _selectedVehicle = text.trim();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Vehicle Specification',
                    labelStyle: TextStyle(color: secondaryText, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.directions_bike,
                      color: accentColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _plateCtrl,
                  style: TextStyle(color: primaryText, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'License Plate Number',
                    labelStyle: TextStyle(color: secondaryText, fontSize: 13),
                    prefixIcon: Icon(Icons.pin, color: accentColor, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: primaryText, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Contact Phone Number',
                    labelStyle: TextStyle(color: secondaryText, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: accentColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFFD1D5DB),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
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
  }
}
