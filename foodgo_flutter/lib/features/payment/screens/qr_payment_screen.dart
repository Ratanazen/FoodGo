import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/utils/khmer_currency.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/svg_icon.dart';
import '../../../shared/widgets/structured_summary_viewer.dart';
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
  });

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
    } else {
      _initialError = 'Payment session details are unavailable.';
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
        _initialError =
            'Unable to load payment details: ${ApiService.formatError(e)}';
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
      if (diff > 0) {
        _secondsRemaining = diff;
      } else if (_currentPayment!.isPending) {
        // Prevent premature expiration on freshly loaded pending orders due to client clock skew
        _secondsRemaining = 900;
      } else {
        _secondsRemaining = 0;
      }
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
        qrPayload: _currentPayment!.qrPayload,
      );
      if (!mounted) return;

      _handleStatusUpdate(updated);

      if (!isBackground && !updated.isPaid) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
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
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/orders');
      }
    }
  }

  Future<void> _retryPayment() async {
    if (_currentPayment == null) return;
    setState(() => _isVerifying = true);

    try {
      final newPayment = await _paymentService.createPayment(
        orderId: _currentPayment!.orderId,
        provider: _currentPayment!.provider,
        currency: _currentPayment!.currency,
        regenerate: true,
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
          content: Text(
            'Failed to regenerate QR code: ${ApiService.formatError(e)}',
          ),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accentGreen.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: accentGreen, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: textTheme.bodySmall?.copyWith(
              color: accentGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            instruction,
            style: textTheme.bodyMedium?.copyWith(
              color: primaryText.withValues(alpha: 0.9),
              height: 1.4,
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: secondaryText),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              color: isHighlight ? accentGreen : primaryText,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
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

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    switch (status) {
      case 'CREATING':
        badgeColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0369A1);
        badgeBg = badgeColor.withValues(alpha: 0.15);
        badgeIcon = AppIcons.loading;
        badgeText = 'CREATING PAYMENT';
        subtext = 'Generating secure KHQR code...';
        break;
      case 'PAID':
        badgeColor = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
        badgeBg = badgeColor.withValues(alpha: 0.16);
        badgeIcon = AppIcons.checkCircle;
        badgeText = 'PAID · CONFIRMED';
        subtext = 'Payment confirmed! Server verified.';
        break;
      case 'PROCESSING':
        badgeColor = isDark ? Colors.cyanAccent : const Color(0xFF0E7490);
        badgeBg = badgeColor.withValues(alpha: 0.15);
        badgeIcon = AppIcons.loading;
        badgeText = 'VERIFYING';
        subtext = 'Payment received! Verifying transaction...';
        break;
      case 'FAILED':
        badgeColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
        badgeBg = badgeColor.withValues(alpha: 0.15);
        badgeIcon = AppIcons.error;
        badgeText = 'PAYMENT FAILED';
        subtext = 'Transaction could not be completed.';
        break;
      case 'EXPIRED':
        badgeColor = isDark ? Colors.deepOrangeAccent : const Color(0xFFC2410C);
        badgeBg = badgeColor.withValues(alpha: 0.15);
        badgeIcon = AppIcons.loading;
        badgeText = 'QR EXPIRED';
        subtext = 'Payment session has expired.';
        break;
      case 'CANCELLED':
        badgeColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
        badgeBg = badgeColor.withValues(alpha: 0.15);
        badgeIcon = AppIcons.close;
        badgeText = 'CANCELLED';
        subtext = 'This payment session was cancelled.';
        break;
      case 'PENDING':
      default:
        badgeColor = isDark ? Colors.amberAccent : const Color(0xFFB45309);
        badgeBg = badgeColor.withValues(alpha: 0.15);
        badgeIcon = AppIcons.refresh;
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
                  style: textTheme.bodySmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
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
          style: textTheme.bodySmall?.copyWith(
            color: secondaryText,
            fontWeight: FontWeight.w500,
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final providerTextColor = isDark
        ? Colors.white
        : HSLColor.fromColor(brandColor).withLightness(0.32).toColor();
    final providerIconColor = brandColor == GlassTheme.bakongRed
        ? (isDark ? Colors.redAccent : const Color(0xFFB91C1C))
        : providerTextColor;
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
                  style: textTheme.titleMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            restaurant,
            style: textTheme.bodyMedium?.copyWith(
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
            style: textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ${KhmerCurrency.formatKhr(payment.amount)} KHR (អត្រា ៤,១០០)',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: primaryText,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: isDark ? 0.25 : 0.12),
              border: Border.all(color: brandColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.qrCode, size: 16, color: providerIconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    providerTitle,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: providerTextColor,
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
                      color: accentGreen,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _showOrderDetails
                            ? 'Hide Order Items (${items.length})'
                            : 'View Order Items (${items.length})',
                        style: textTheme.bodySmall?.copyWith(
                          color: accentGreen,
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
                  color: isDark
                      ? Colors.black26
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
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
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                          ),
                          Text(
                            '\$${(double.tryParse(price.toString()) ?? 0.0).toStringAsFixed(2)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: primaryText,
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

  Widget _buildLiveTimeCard() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final dangerColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
    final isLowTime = _secondsRemaining < 120;
    final progress = (_secondsRemaining / 900.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLowTime
            ? dangerColor.withValues(alpha: 0.12)
            : accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowTime
              ? dangerColor.withValues(alpha: 0.45)
              : accentGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isLowTime ? dangerColor : accentGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isLowTime ? dangerColor : accentGreen)
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'LIVE TIME',
                        style: textTheme.bodySmall?.copyWith(
                          color: isLowTime ? dangerColor : accentGreen,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sensors, size: 13, color: accentGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Live WebSocket',
                      style: textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                color: isLowTime ? dangerColor : primaryText,
                size: 26,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatTimer(_secondsRemaining),
                    style: textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isLowTime ? dangerColor : primaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLowTime ? dangerColor : accentGreen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLowTime
                ? 'Session expiring soon. Please confirm in your mobile banking app.'
                : 'Scanned payment is verified automatically in real time.',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: isLowTime ? dangerColor : secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedBanksCard() {
    const banks = [
      {
        'name': 'Bakong',
        'sub': 'NBC Rail',
        'color': Color(0xFFE12326),
        'icon': Icons.account_balance,
      },
      {
        'name': 'ABA Bank',
        'sub': 'ABA Mobile',
        'color': Color(0xFF004B87),
        'icon': Icons.account_balance_rounded,
      },
      {
        'name': 'ACLEDA',
        'sub': 'ACLEDA Mobile',
        'color': Color(0xFF1E3A8A),
        'icon': Icons.account_balance_outlined,
      },
      {
        'name': 'Wing Bank',
        'sub': 'Wing App',
        'color': Color(0xFF00A859),
        'icon': Icons.payments_rounded,
      },
      {
        'name': 'Canadia',
        'sub': 'Canadia App',
        'color': Color(0xFFC8102E),
        'icon': Icons.account_balance,
      },
      {
        'name': 'Sathapana',
        'sub': 'Mobile',
        'color': Color(0xFF003366),
        'icon': Icons.savings_outlined,
      },
      {
        'name': 'TrueMoney',
        'sub': 'Wallet',
        'color': Color(0xFFFF6600),
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'name': 'Prince Bank',
        'sub': 'Mobile',
        'color': Color(0xFF1A2B4C),
        'icon': Icons.account_balance_outlined,
      },
    ];

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusSmall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 18, color: accentGreen),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Supported Banks & Apps (ធនាគារស្កេនបាន)',
                  style: textTheme.titleSmall?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scan this KHQR with any Cambodian mobile banking app:',
            style: textTheme.labelSmall?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: banks.map((b) {
                final Color bColor = b['color'] as Color;
                final Color chipAccent = isDark
                    ? HSLColor.fromColor(bColor).withLightness(0.68).toColor()
                    : HSLColor.fromColor(bColor).withLightness(0.32).toColor();
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: chipAccent.withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: chipAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(b['icon'] as IconData, size: 16, color: chipAccent),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            b['name'] as String,
                            style: textTheme.bodySmall?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            b['sub'] as String,
                            style: textTheme.labelSmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(PaymentModel payment) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    final paidCard = GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: GlassTheme.borderRadiusSmall,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accentGreen.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: accentGreen, width: 2.5),
            ),
            child: Icon(AppIcons.checkCircle, size: 50, color: accentGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Confirmed!',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ការទូទាត់ទទួលបានជោគជ័យ!',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: accentGreen,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your payment has been successfully confirmed. Order has been sent to the kitchen.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black38
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              children: [
                _buildReceiptRow(
                  'Order Number',
                  payment.orderReference != null
                      ? '#${payment.orderReference}'
                      : '#${payment.orderId}',
                ),
                Divider(
                  color: isDark ? Colors.white12 : Colors.black12,
                  height: 16,
                ),
                _buildReceiptRow(
                  'Transaction ID',
                  payment.transactionId ??
                      payment.merchantReference ??
                      'CONFIRMED',
                ),
                Divider(
                  color: isDark ? Colors.white12 : Colors.black12,
                  height: 16,
                ),
                _buildReceiptRow(
                  'Amount Paid',
                  '${payment.currency} ${payment.amount.toStringAsFixed(2)}',
                  isHighlight: true,
                ),
                Divider(
                  color: isDark ? Colors.white12 : Colors.black12,
                  height: 16,
                ),
                _buildReceiptRow(
                  'Payment Rail',
                  '${payment.provider.toUpperCase()} KHQR',
                ),
                if (payment.paidAt != null) ...[
                  Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                    height: 16,
                  ),
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
              icon: AppIcons.route,
              onPressed: () => context.go('/map/${payment.orderId}'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              icon: Icon(Icons.copy_rounded, size: 17, color: accentGreen),
              label: const Text('Copy Payment Receipt TXT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryText,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final receiptTxt = [
                  '========================================',
                  'FOODGO KHQR PAYMENT RECEIPT (PAID)',
                  '========================================',
                  'Order Number   : ${payment.orderReference != null ? "#${payment.orderReference}" : "#${payment.orderId}"}',
                  'Transaction ID : ${payment.transactionId ?? payment.merchantReference ?? "CONFIRMED"}',
                  'Amount Paid    : ${payment.currency} ${payment.amount.toStringAsFixed(2)} (~${KhmerCurrency.formatKhr(payment.amount)} KHR)',
                  'Payment Rail   : ${payment.provider.toUpperCase()} KHQR',
                  if (payment.paidAt != null)
                    'Paid Timestamp : ${_formatTimestamp(payment.paidAt!)}',
                  '========================================',
                ].join('\n');
                Clipboard.setData(ClipboardData(text: receiptTxt));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment receipt TXT copied to clipboard!'),
                    backgroundColor: GlassTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              icon: const Icon(AppIcons.receipt, size: 18),
              label: const Text('View All Orders'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryText,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.go('/orders'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            icon: Icon(AppIcons.home, size: 18, color: secondaryText),
            label: Text(
              'Return to Home',
              style: textTheme.labelLarge?.copyWith(color: secondaryText),
            ),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );

    final reduceMotion = AppMotion.shouldReduceMotion(context);
    return reduceMotion
        ? paidCard
        : paidCard
              .animate()
              .fadeIn(duration: AppMotion.page, curve: AppMotion.enter)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: AppMotion.page,
                curve: AppMotion.enter,
              );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final dangerColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
    final warningAmber = isDark ? Colors.orangeAccent : const Color(0xFFB45309);

    if (_isLoadingInitial) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: context.tr('payment.qrTitle')),
        body: Center(child: CircularProgressIndicator(color: accentGreen)),
      );
    }

    if (_initialError != null || _currentPayment == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: context.tr('payment.qrTitle')),
        body: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: dangerColor),
                const SizedBox(height: 16),
                Text(
                  _initialError ?? 'Payment session not found.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: primaryText),
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

    // Responsive QR size clamped for mobile viewports (supports 320px screens without overflow)
    final qrSize = ((screenWidth - 80) * 0.88).clamp(200.0, 280.0);

    final providerUpper = payment.provider.toUpperCase();
    final bool isBakong = providerUpper == 'BAKONG';
    final bool isAba = providerUpper == 'ABA';
    final String providerTitle = isBakong
        ? 'Bakong KHQR (NBC Open API)'
        : (isAba ? 'ABA KHQR' : 'ACLEDA KHQR');
    final Color brandColor = isBakong
        ? GlassTheme.bakongRed
        : (isAba ? GlassTheme.abaBlue : GlassTheme.acledaNavy);
    final String qrString =
        (payment.qrPayload != null && payment.qrPayload!.trim().isNotEmpty)
        ? (PaymentModel.ensureDynamicKhqrExpiration(
                payment.qrPayload!.trim(),
                expiresAt: payment.expiresAt,
              ) ??
              payment.qrPayload!.trim())
        : '';
    final String? qrImageData =
        (payment.qrImage != null && payment.qrImage!.trim().isNotEmpty)
        ? payment.qrImage!.trim()
        : null;
    final bool hasValidQr = qrString.isNotEmpty || qrImageData != null;

    final bool isSessionPaid = payment.isPaid;
    final bool isSessionExpired = payment.isExpired || _secondsRemaining <= 0;
    final bool isSessionFailed = payment.isFailed;
    final bool isSessionCancelled = payment.isCancelled;
    final bool isSessionActive =
        !isSessionPaid &&
        !isSessionExpired &&
        !isSessionFailed &&
        !isSessionCancelled;

    final reduceMotion = AppMotion.shouldReduceMotion(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSessionPaid) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/orders');
          }
        } else {
          _cancelPayment();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: context.tr('payment.qrTitle'),
          leading: IconButton(
            icon: Icon(AppIcons.back, color: primaryText),
            onPressed: isSessionPaid
                ? () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/orders');
                    }
                  }
                : _cancelPayment,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
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
                        reduceMotion
                            ? _buildOrderSummaryCard(
                                payment,
                                isBakong,
                                providerTitle,
                                brandColor,
                              )
                            : _buildOrderSummaryCard(
                                    payment,
                                    isBakong,
                                    providerTitle,
                                    brandColor,
                                  )
                                  .animate()
                                  .fadeIn(duration: AppMotion.shortDuration)
                                  .slideY(
                                    begin: 0.04,
                                    end: 0,
                                    duration: AppMotion.shortDuration,
                                  ),
                        const SizedBox(height: 16),

                        // QR Code / Terminal State Card
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: GlassTheme.borderRadiusSmall,
                          child: Column(
                            children: [
                              if (isSessionFailed) ...[
                                Icon(
                                  AppIcons.error,
                                  size: 72,
                                  color: dangerColor,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Payment Failed',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: dangerColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'The transaction could not be completed. Please check your bank balance or retry.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GlassButton(
                                  text: 'Retry Payment',
                                  icon: AppIcons.refresh,
                                  isLoading: _isVerifying,
                                  onPressed: _retryPayment,
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go('/orders'),
                                  child: Text(
                                    'Back to Checkout',
                                    style: TextStyle(color: secondaryText),
                                  ),
                                ),
                              ] else if (isSessionCancelled) ...[
                                Icon(
                                  AppIcons.close,
                                  size: 72,
                                  color: warningAmber,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Payment Cancelled',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: warningAmber,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This payment session has been cancelled.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GlassButton(
                                  text: 'Return to Orders',
                                  icon: AppIcons.receipt,
                                  onPressed: () => context.go('/orders'),
                                ),
                              ] else if (isSessionExpired) ...[
                                Icon(
                                  AppIcons.loading,
                                  size: 72,
                                  color: dangerColor,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Payment QR Expired',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: dangerColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This payment code has expired. Generate a new code to complete your order.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GlassButton(
                                  text: 'Regenerate QR Code',
                                  icon: AppIcons.refresh,
                                  isLoading: _isVerifying,
                                  onPressed: _retryPayment,
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go('/orders'),
                                  child: Text(
                                    'Back to Checkout',
                                    style: TextStyle(color: secondaryText),
                                  ),
                                ),
                              ] else if (!hasValidQr) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: dangerColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: dangerColor.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 64,
                                        color: dangerColor,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'KHQR Code Unavailable',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'The payment gateway did not return a valid payable KHQR payload for this order. Please retry generating a code or choose a different payment option.',
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: secondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      GlassButton(
                                        text: 'Regenerate KHQR Code',
                                        icon: AppIcons.refresh,
                                        isLoading: _isVerifying,
                                        onPressed: _retryPayment,
                                      ),
                                    ],
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
                                  child: Center(
                                    child: Text(
                                      'KHQR · SCAN TO PAY',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
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
                                        color: brandColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      if (qrString.isNotEmpty)
                                        QrImageView(
                                          data: qrString,
                                          version: QrVersions.auto,
                                          size: qrSize,
                                          backgroundColor: Colors.white,
                                          errorCorrectionLevel:
                                              QrErrorCorrectLevel.M,
                                        )
                                      else if (qrImageData != null)
                                        _buildQrImageFromBase64(
                                          qrImageData,
                                          qrSize,
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${payment.currency} ${payment.amount.toStringAsFixed(2)} • ${KhmerCurrency.formatKhr(payment.amount)}',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: GlassTheme.textDark,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${payment.restaurantName ?? 'FoodGo Restaurant'} · Phnom Penh',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: const Color(0xFF4B5563),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Live Time Real-Time Status & Countdown
                                _buildLiveTimeCard(),
                                const SizedBox(height: 16),

                                // Copy KHQR Payload Button
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryText,
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.black26,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: Icon(
                                    AppIcons.copy,
                                    size: 16,
                                    color: accentGreen,
                                  ),
                                  label: Text(
                                    'Copy KHQR Payload',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: qrString),
                                    );
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'KHQR code payload copied to clipboard!',
                                          ),
                                          backgroundColor:
                                              GlassTheme.primaryGreen,
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
                                          color: secondaryText,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _showRawPayload
                                                ? 'Hide QR Payload Details'
                                                : 'Show All QR Payload Details',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: secondaryText,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Monospace Payload & Structured TLV Summary Box
                                if (_showRawPayload) ...[
                                  const SizedBox(height: 10),
                                  Builder(
                                    builder: (context) {
                                      final parsedTlv =
                                          StructuredSummaryViewer.parseEmvcoKhqrSummary(
                                            qrString,
                                          );
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.black45
                                              : Colors.black.withValues(
                                                  alpha: 0.04,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.black12,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Structured EMVCo KHQR Summary:',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: accentGreen,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            ...parsedTlv.entries.map(
                                              (entry) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      flex: 2,
                                                      child: Text(
                                                        entry.key,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  secondaryText,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      flex: 3,
                                                      child: SelectableText(
                                                        entry.value,
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color:
                                                                  primaryText,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Divider(
                                              color: isDark
                                                  ? Colors.white12
                                                  : Colors.black12,
                                              height: 16,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'EMVCo KHQR Payload:',
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                          color: primaryText
                                                              .withValues(
                                                                alpha: 0.85,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${qrString.length} chars',
                                                  style: textTheme.labelSmall
                                                      ?.copyWith(
                                                        color: secondaryText,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            SelectableText(
                                              qrString,
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontFamily: 'monospace',
                                                    color: accentGreen,
                                                  ),
                                            ),
                                            if (payment.merchantReference !=
                                                null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'Merchant Ref: ${payment.merchantReference}',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: secondaryText,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                        const SizedBox(height: 16),

                        // Supported Banks Showcase (Active State)
                        if (isSessionActive) ...[
                          _buildSupportedBanksCard().animate().fadeIn(
                            duration: 400.ms,
                            delay: 100.ms,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3-Step Instruction Card (Active State)
                        if (isSessionActive) ...[
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: GlassTheme.borderRadiusSmall,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      AppIcons.info,
                                      size: 18,
                                      color: accentGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How to pay with KHQR',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.bold,
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
                              icon: AppIcons.checkCircle,
                              isLoading: _isVerifying,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onPressed: _isVerifying
                                  ? null
                                  : () => _checkStatus(isBackground: false),
                            ),
                          ),
                          const SizedBox(height: 22),

                          TextButton(
                            onPressed: _cancelPayment,
                            child: Text(
                              'Cancel Payment',
                              style: textTheme.labelLarge?.copyWith(
                                color: secondaryText,
                              ),
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
      ),
    );
  }

  Widget _buildQrImageFromBase64(String base64Data, double size) {
    try {
      final cleanBase64 = base64Data.contains(',')
          ? base64Data.split(',').last
          : base64Data;
      final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.redAccent,
          ),
        ),
      );
    } catch (_) {
      return const Icon(
        Icons.broken_image_outlined,
        size: 64,
        color: Colors.redAccent,
      );
    }
  }
}
