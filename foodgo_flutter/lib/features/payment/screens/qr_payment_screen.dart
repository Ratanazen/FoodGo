import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../../../core/utils/khmer_currency.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/svg_icon.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class QRPaymentScreen extends StatefulWidget {
  final PaymentModel? payment;
  final int? paymentId;
  final FlutterPaymentService? paymentService;

  const QRPaymentScreen({
    super.key,
    this.payment,
    this.paymentId,
    this.paymentService,
  }) : assert(
         payment != null || paymentId != null,
         'Either payment or paymentId must be provided',
       );

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  late final FlutterPaymentService _paymentService;
  PaymentModel? _currentPayment;

  bool _isLoadingInitial = false;
  String? _initialError;

  Timer? _pollingTimer;
  Timer? _countdownTimer;
  StreamSubscription<PaymentModel>? _wsSubscription;

  int _secondsRemaining = 900; // 15 minutes standard session
  bool _isVerifying = false;
  bool _showRawPayload = false;
  bool _showOrderDetails = false;
  int _consecutivePollErrors = 0;

  @override
  void initState() {
    super.initState();
    _paymentService = widget.paymentService ?? FlutterPaymentService();

    if (widget.payment != null) {
      _currentPayment = widget.payment;
      _initSession();
    } else if (widget.paymentId != null) {
      _fetchInitialPayment(widget.paymentId!);
    }
  }

  Future<void> _fetchInitialPayment(int paymentId) async {
    setState(() {
      _isLoadingInitial = true;
      _initialError = null;
    });

    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (!mounted) return;
      setState(() {
        _currentPayment = payment;
        _isLoadingInitial = false;
      });
      _initSession();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _initialError = 'Unable to load payment details: $e';
      });
    }
  }

  void _initSession() {
    if (_currentPayment == null) return;

    _initCountdown();
    if (!_currentPayment!.isPaid &&
        !_currentPayment!.isExpired &&
        !_currentPayment!.isCancelled &&
        !_currentPayment!.isFailed) {
      _subscribeWebSocket();
      _startPolling();
    }
  }

  void _initCountdown() {
    _countdownTimer?.cancel();
    if (_currentPayment == null) return;

    if (_currentPayment!.expiresAt != null) {
      final diff = _currentPayment!.expiresAt!
          .difference(DateTime.now())
          .inSeconds;
      _secondsRemaining = diff > 0 ? diff : 0;
    } else {
      _secondsRemaining = 900; // 15 minutes default
    }

    if (_secondsRemaining <= 0) {
      if (_currentPayment!.isPending) {
        _currentPayment = _currentPayment!.copyWith(status: 'EXPIRED');
      }
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() {
          _secondsRemaining = 0;
          if (_currentPayment != null && _currentPayment!.isPending) {
            _currentPayment = _currentPayment!.copyWith(status: 'EXPIRED');
          }
        });
        _cleanupListeners();
      }
    });
  }

  void _subscribeWebSocket() {
    _wsSubscription?.cancel();
    if (_currentPayment == null) return;

    _wsSubscription = _paymentService
        .subscribePaymentStatus(_currentPayment!.id)
        .listen(
          (updated) {
            _handleStatusUpdate(updated);
          },
          onError: (err) {
            debugPrint(
              'Payment WebSocket error; relying on polling fallback: $err',
            );
          },
        );
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Rate-limited polling fallback: every 4 seconds with exponential backoff on errors
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && !_isVerifying && _currentPayment != null) {
        if (_consecutivePollErrors > 2 && _consecutivePollErrors % 2 != 0) {
          return;
        }
        _checkStatus(isBackground: true);
      }
    });
  }

  void _cleanupListeners() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    _wsSubscription?.cancel();
  }

  void _handleStatusUpdate(PaymentModel updated) {
    if (!mounted || _currentPayment == null) return;
    if (_currentPayment!.isPaid) return; // Prevent duplicate transitions

    setState(() {
      _currentPayment = _currentPayment!.copyWith(
        status: updated.status,
        transactionId: updated.transactionId ?? _currentPayment!.transactionId,
        merchantReference:
            updated.merchantReference ?? _currentPayment!.merchantReference,
        orderReference:
            updated.orderReference ?? _currentPayment!.orderReference,
        restaurantName:
            updated.restaurantName ?? _currentPayment!.restaurantName,
        paidAt: updated.paidAt ?? _currentPayment!.paidAt,
        amount: updated.amount > 0 ? updated.amount : _currentPayment!.amount,
        currency: updated.currency.isNotEmpty
            ? updated.currency
            : _currentPayment!.currency,
      );
      _isVerifying = false;
      _consecutivePollErrors = 0;
    });

    if (updated.isPaid) {
      _cleanupListeners();
      try {
        context.read<CartProvider>().clear();
      } catch (_) {}
    } else if (updated.isExpired || updated.isCancelled || updated.isFailed) {
      _cleanupListeners();
    }
  }

  Future<void> _checkStatus({bool isBackground = false}) async {
    if (_currentPayment == null) return;
    if (_currentPayment!.isCancelled ||
        _currentPayment!.isExpired ||
        _currentPayment!.isFailed ||
        _currentPayment!.isPaid) {
      _cleanupListeners();
      return;
    }

    if (!isBackground) {
      setState(() => _isVerifying = true);
    }

    try {
      final updated = await _paymentService.getPaymentStatus(
        _currentPayment!.id,
      );
      if (!mounted) return;

      _handleStatusUpdate(updated);

      if (!isBackground && !updated.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment not completed yet. Please scan and pay with your banking app.',
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _consecutivePollErrors++;
      setState(() => _isVerifying = false);

      if (!isBackground) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to check payment status due to network error. You can retry safely.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelPayment() async {
    _cleanupListeners();
    if (_currentPayment != null) {
      try {
        await _paymentService.cancelPayment(_currentPayment!.id);
      } catch (_) {}
    }
    if (mounted) context.pop();
  }

  Future<void> _retryPayment() async {
    if (_currentPayment == null) return;
    setState(() => _isVerifying = true);

    try {
      final newPayment = await _paymentService.createPayment(
        orderId: _currentPayment!.orderId,
        provider: _currentPayment!.provider,
        currency: _currentPayment!.currency,
      );
      if (!mounted) return;
      setState(() {
        _currentPayment = newPayment;
        _isVerifying = false;
      });
      _initSession();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to regenerate QR code: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _cleanupListeners();
    super.dispose();
  }

  Widget _buildStepRow(int step, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: GlassTheme.primaryGreen, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(
              color: GlassTheme.primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            instruction,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isHighlight ? GlassTheme.primaryGreen : Colors.white,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(PaymentModel payment) {
    final status = payment.status.toUpperCase();
    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String badgeText;
    String subtext;

    switch (status) {
      case 'CREATING':
        badgeColor = Colors.lightBlueAccent;
        badgeBg = Colors.lightBlueAccent.withValues(alpha: 0.15);
        badgeIcon = Icons.hourglass_top_rounded;
        badgeText = 'CREATING PAYMENT';
        subtext = 'Generating secure KHQR code...';
        break;
      case 'PAID':
        badgeColor = GlassTheme.primaryGreen;
        badgeBg = GlassTheme.primaryGreen.withValues(alpha: 0.18);
        badgeIcon = Icons.check_circle_rounded;
        badgeText = 'PAID · CONFIRMED';
        subtext = 'Payment confirmed! Server verified.';
        break;
      case 'PROCESSING':
        badgeColor = Colors.cyanAccent;
        badgeBg = Colors.cyanAccent.withValues(alpha: 0.15);
        badgeIcon = Icons.hourglass_bottom_rounded;
        badgeText = 'VERIFYING';
        subtext = 'Payment received! Verifying transaction...';
        break;
      case 'FAILED':
        badgeColor = Colors.redAccent;
        badgeBg = Colors.redAccent.withValues(alpha: 0.15);
        badgeIcon = Icons.error_outline_rounded;
        badgeText = 'PAYMENT FAILED';
        subtext = 'Transaction could not be completed.';
        break;
      case 'EXPIRED':
        badgeColor = Colors.deepOrangeAccent;
        badgeBg = Colors.deepOrangeAccent.withValues(alpha: 0.15);
        badgeIcon = Icons.timer_off_outlined;
        badgeText = 'QR EXPIRED';
        subtext = 'Payment session has expired.';
        break;
      case 'CANCELLED':
        badgeColor = Colors.grey;
        badgeBg = Colors.grey.withValues(alpha: 0.15);
        badgeIcon = Icons.cancel_outlined;
        badgeText = 'CANCELLED';
        subtext = 'This payment session was cancelled.';
        break;
      case 'PENDING':
      default:
        badgeColor = Colors.amberAccent;
        badgeBg = Colors.amberAccent.withValues(alpha: 0.15);
        badgeIcon = Icons.sync_rounded;
        badgeText = 'WAITING FOR PAYMENT';
        subtext = 'Scan QR code with your mobile banking app';
        break;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 16, color: badgeColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  badgeText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtext,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(
    PaymentModel payment,
    bool isBakong,
    String providerTitle,
    Color brandColor,
  ) {
    final orderSummary = payment.orderSummary;
    final restaurant =
        payment.restaurantName ??
        (orderSummary != null ? orderSummary['restaurant'] as String? : null) ??
        'FoodGo Restaurant';
    final items = orderSummary != null ? orderSummary['items'] as List? : null;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: GlassTheme.borderRadiusSmall,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgAssetIcon(
                assetName: isBakong ? 'bakong_logo' : 'khqr_logo',
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  payment.orderReference != null
                      ? 'Order #${payment.orderReference}'
                      : 'Order #${payment.orderId}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            restaurant,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: GlassTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ${KhmerCurrency.formatKhr(payment.amount)} KHR (អត្រា ៤,១០០)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.25),
              border: Border.all(color: brandColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 16,
                  color: brandColor == GlassTheme.bakongRed
                      ? Colors.redAccent
                      : Colors.white,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    providerTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (items != null && items.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () =>
                  setState(() => _showOrderDetails = !_showOrderDetails),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showOrderDetails
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: GlassTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _showOrderDetails
                            ? 'Hide Order Items (${items.length})'
                            : 'View Order Items (${items.length})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: GlassTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showOrderDetails) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: items.map<Widget>((item) {
                    final itemName = item['name'] ?? 'Item';
                    final qty = item['quantity'] ?? 1;
                    final price = item['price'] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '$itemName x$qty',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '\$${(double.tryParse(price.toString()) ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessCard(PaymentModel payment) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: GlassTheme.borderRadiusSmall,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: GlassTheme.primaryGreen.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: GlassTheme.primaryGreen, width: 2.5),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 50,
              color: GlassTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Confirmed!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ការទូទាត់ទទួលបានជោគជ័យ!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GlassTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your payment has been successfully confirmed. Order has been sent to the kitchen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _buildReceiptRow(
                  'Order Number',
                  payment.orderReference != null
                      ? '#${payment.orderReference}'
                      : '#${payment.orderId}',
                ),
                const Divider(color: Colors.white12, height: 16),
                _buildReceiptRow(
                  'Transaction ID',
                  payment.transactionId ??
                      payment.merchantReference ??
                      'CONFIRMED',
                ),
                const Divider(color: Colors.white12, height: 16),
                _buildReceiptRow(
                  'Amount Paid',
                  '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
                  isHighlight: true,
                ),
                const Divider(color: Colors.white12, height: 16),
                _buildReceiptRow(
                  'Payment Rail',
                  '${payment.provider.toUpperCase()} KHQR',
                ),
                if (payment.paidAt != null) ...[
                  const Divider(color: Colors.white12, height: 16),
                  _buildReceiptRow(
                    'Paid Timestamp',
                    _formatTimestamp(payment.paidAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: GlassButton(
              text: 'Track Order',
              icon: Icons.navigation_rounded,
              onPressed: () => context.go('/map/${payment.orderId}'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('View All Orders'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.go('/orders'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            icon: const Icon(
              Icons.home_outlined,
              size: 18,
              color: Colors.white70,
            ),
            label: const Text(
              'Return to Home',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return Scaffold(
        appBar: const GlassAppBar(title: 'Scan to Pay'),
        body: Container(
          decoration: const BoxDecoration(color: GlassTheme.backgroundDark),
          child: const Center(
            child: CircularProgressIndicator(color: GlassTheme.primaryGreen),
          ),
        ),
      );
    }

    if (_initialError != null || _currentPayment == null) {
      return Scaffold(
        appBar: const GlassAppBar(title: 'Scan to Pay'),
        body: Container(
          decoration: const BoxDecoration(color: GlassTheme.backgroundDark),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _initialError ?? 'Payment session not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                GlassButton(
                  text: 'Return to Orders',
                  icon: Icons.receipt_long,
                  onPressed: () => context.go('/orders'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payment = _currentPayment!;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive QR size clamped between 240.0 and 280.0 logical pixels for mobile & desktop
    final qrSize = (screenWidth * 0.68).clamp(240.0, 280.0);

    final providerUpper = payment.provider.toUpperCase();
    final bool isBakong = providerUpper == 'BAKONG';
    final bool isAba = providerUpper == 'ABA';
    final String providerTitle = isBakong
        ? 'Bakong KHQR (NBC Open API)'
        : (isAba ? 'ABA KHQR' : 'ACLEDA KHQR');
    final Color brandColor = isBakong
        ? GlassTheme.bakongRed
        : (isAba ? GlassTheme.abaBlue : GlassTheme.acledaNavy);

    final String qrString = payment.qrPayload ?? 'https://foodgo.app/khqr/pay';

    final bool isSessionPaid = payment.isPaid;
    final bool isSessionExpired = payment.isExpired || _secondsRemaining <= 0;
    final bool isSessionFailed = payment.isFailed;
    final bool isSessionCancelled = payment.isCancelled;
    final bool isSessionActive =
        !isSessionPaid &&
        !isSessionExpired &&
        !isSessionFailed &&
        !isSessionCancelled;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Scan to Pay',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: isSessionPaid ? () => context.go('/home') : _cancelPayment,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: GlassTheme.backgroundDark),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Status Badge
                    _buildStatusBadge(payment),
                    const SizedBox(height: 16),

                    if (isSessionPaid)
                      _buildSuccessCard(payment)
                    else ...[
                      // Order & Amount Summary Card
                      _buildOrderSummaryCard(
                            payment,
                            isBakong,
                            providerTitle,
                            brandColor,
                          )
                          .animate()
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 16),

                      // QR Code / Terminal State Card
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        child: Column(
                          children: [
                            if (isSessionFailed) ...[
                              const Icon(
                                Icons.error_outline,
                                size: 72,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Payment Failed',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The transaction could not be completed. Please check your bank balance or retry.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GlassButton(
                                text: 'Retry Payment',
                                icon: Icons.refresh,
                                isLoading: _isVerifying,
                                onPressed: _retryPayment,
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  'Back to Checkout',
                                  style: TextStyle(color: GlassTheme.textMuted),
                                ),
                              ),
                            ] else if (isSessionCancelled) ...[
                              const Icon(
                                Icons.cancel_outlined,
                                size: 72,
                                color: Colors.orangeAccent,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Payment Cancelled',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This payment session has been cancelled.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GlassButton(
                                text: 'Return to Orders',
                                icon: Icons.receipt_long,
                                onPressed: () => context.go('/orders'),
                              ),
                            ] else if (isSessionExpired) ...[
                              const Icon(
                                Icons.timer_off_outlined,
                                size: 72,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Payment QR Expired',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This payment code has expired. Generate a new code to complete your order.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GlassButton(
                                text: 'Regenerate QR Code',
                                icon: Icons.refresh,
                                isLoading: _isVerifying,
                                onPressed: _retryPayment,
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  'Back to Checkout',
                                  style: TextStyle(color: GlassTheme.textMuted),
                                ),
                              ),
                            ] else ...[
                              // KHQR Header Stand Banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: const BoxDecoration(
                                  color: GlassTheme.khqrBannerRed,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'KHQR · SCAN TO PAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // Pure White QR Code Graphic Frame (Quiet Zone: 20px padding)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: brandColor.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    QrImageView(
                                      data: qrString,
                                      version: QrVersions.auto,
                                      size: qrSize,
                                      backgroundColor: Colors.white,
                                      errorCorrectionLevel:
                                          QrErrorCorrectLevel.M,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${payment.currency} ${payment.amount.toStringAsFixed(2)} • ${KhmerCurrency.formatKhr(payment.amount)}',
                                      style: const TextStyle(
                                        color: GlassTheme.textDark,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${payment.restaurantName ?? 'FoodGo Restaurant'} · Phnom Penh',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Countdown Timer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: _secondsRemaining < 120
                                        ? Colors.redAccent
                                        : Colors.orangeAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Payment expires in: ${_formatTimer(_secondsRemaining)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _secondsRemaining < 120
                                            ? Colors.redAccent
                                            : Colors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Copy KHQR Payload Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: GlassTheme.primaryGreen,
                                ),
                                label: const Text(
                                  'Copy KHQR Payload',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: qrString),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'KHQR code payload copied to clipboard!',
                                      ),
                                      backgroundColor: GlassTheme.primaryGreen,
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),

                              // Collapsible Developer Payload Toggle
                              InkWell(
                                onTap: () => setState(
                                  () => _showRawPayload = !_showRawPayload,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _showRawPayload
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 18,
                                        color: GlassTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _showRawPayload
                                              ? 'Hide QR Payload Details'
                                              : 'Show All QR Payload Details',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: GlassTheme.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Monospace Payload Box
                              if (_showRawPayload) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'EMVCo KHQR Payload:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${qrString.length} chars',
                                            style: TextStyle(
                                              color: GlassTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        qrString,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: GlassTheme.primaryGreenAccent,
                                        ),
                                      ),
                                      if (payment.merchantReference !=
                                          null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Merchant Ref: ${payment.merchantReference}',
                                          style: TextStyle(
                                            color: GlassTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                      const SizedBox(height: 16),

                      // 3-Step Instruction Card (Active State)
                      if (isSessionActive) ...[
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: GlassTheme.borderRadiusSmall,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: GlassTheme.primaryGreen,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'How to pay with KHQR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildStepRow(
                                1,
                                'Open your banking app (Bakong, ABA, ACLEDA, etc.)',
                              ),
                              const SizedBox(height: 8),
                              _buildStepRow(
                                2,
                                'Scan this QR code from your mobile screen',
                              ),
                              const SizedBox(height: 8),
                              _buildStepRow(
                                3,
                                'Review the amount and confirm payment in banking app',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        SizedBox(
                          height: 52,
                          child: GlassButton(
                            text: _isVerifying
                                ? 'Checking Status...'
                                : 'Check Payment Status',
                            icon: Icons.check_circle_outline,
                            isLoading: _isVerifying,
                            onPressed: _isVerifying
                                ? null
                                : () => _checkStatus(isBackground: false),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sandbox Webhook Simulator for Web/Test Mode
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GlassTheme.primaryGreen,
                            side: BorderSide(
                              color: GlassTheme.primaryGreen.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.bolt, size: 18),
                          label: const Text(
                            'Simulate Webhook Pay (Test Mode)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isVerifying
                              ? null
                              : () async {
                                  setState(() => _isVerifying = true);
                                  try {
                                    final endpoint = isBakong
                                        ? 'payments/bakong/callback/'
                                        : (isAba
                                              ? 'payments/aba/callback/'
                                              : 'payments/acleda/callback/');
                                    await ApiService().post(endpoint, {
                                      'merchant_reference':
                                          payment.merchantReference,
                                      'amount': payment.amount.toStringAsFixed(
                                        2,
                                      ),
                                      'currency': payment.currency,
                                      'transaction_id':
                                          'TEST-SIM-${DateTime.now().millisecondsSinceEpoch}',
                                      'status': 'PAID',
                                    });
                                    await _checkStatus(isBackground: false);
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isVerifying = false);
                                    }
                                  }
                                },
                        ),
                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: _cancelPayment,
                          child: Text(
                            'Cancel Payment',
                            style: TextStyle(color: GlassTheme.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
