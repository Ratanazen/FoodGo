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
  final PaymentModel payment;

  const QRPaymentScreen({super.key, required this.payment});

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  final FlutterPaymentService _paymentService = FlutterPaymentService();
  late PaymentModel _currentPayment;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes default
  bool _isVerifying = false;
  bool _showRawPayload = false;

  @override
  void initState() {
    super.initState();
    _currentPayment = widget.payment;
    _initCountdown();
    _startPolling();
  }

  void _initCountdown() {
    _countdownTimer?.cancel();
    if (_currentPayment.expiresAt != null) {
      final diff = _currentPayment.expiresAt!
          .difference(DateTime.now())
          .inSeconds;
      _secondsRemaining = diff > 0 ? diff : 0;
    } else {
      _secondsRemaining = 300;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
        _checkStatus(isBackground: true);
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll status every 5 seconds without aggressive loops
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isVerifying) {
        _checkStatus(isBackground: true);
      }
    });
  }

  Future<void> _checkStatus({bool isBackground = false}) async {
    if (_currentPayment.isCancelled ||
        _currentPayment.isExpired ||
        _currentPayment.isFailed) {
      _pollingTimer?.cancel();
      _countdownTimer?.cancel();
      return;
    }

    if (!isBackground) {
      setState(() => _isVerifying = true);
    }

    try {
      final updated = await _paymentService.getPaymentStatus(
        _currentPayment.id,
      );
      if (!mounted) return;

      // Late async check: if session was cancelled in the meantime, ignore response
      if (_currentPayment.isCancelled) return;

      setState(() {
        _currentPayment = updated;
        _isVerifying = false;
      });

      if (updated.isPaid) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        if (mounted) {
          // Clear cart on successful payment confirmation
          context.read<CartProvider>().clear();
          context.go('/order-success', extra: _currentPayment.orderId);
        }
      } else if (updated.isExpired || updated.isCancelled || updated.isFailed) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
      } else if (!isBackground) {
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
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _cancelPayment() async {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    try {
      await _paymentService.cancelPayment(_currentPayment.id);
    } catch (_) {}
    if (mounted) context.pop();
  }

  Future<void> _retryPayment() async {
    setState(() => _isVerifying = true);
    try {
      final newPayment = await _paymentService.createPayment(
        orderId: _currentPayment.orderId,
        provider: _currentPayment.provider,
        currency: _currentPayment.currency,
      );
      if (!mounted) return;
      setState(() {
        _currentPayment = newPayment;
        _isVerifying = false;
      });
      _initCountdown();
      _startPolling();
    } catch (e) {
      if (mounted) {
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
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive QR size clamped between 200 and 260 logical pixels
    final qrSize = (screenWidth * 0.55).clamp(200.0, 260.0);

    final providerUpper = _currentPayment.provider.toUpperCase();
    final bool isBakong = providerUpper == 'BAKONG';
    final bool isAba = providerUpper == 'ABA';
    final String providerTitle = isBakong
        ? 'Bakong KHQR (NBC Open API)'
        : (isAba ? 'ABA KHQR' : 'ACLEDA KHQR');
    final Color brandColor = isBakong
        ? GlassTheme.bakongRed
        : (isAba ? GlassTheme.abaBlue : GlassTheme.acledaNavy);

    final String qrString =
        _currentPayment.qrPayload ?? 'https://foodgo.app/khqr/pay';

    final bool isSessionExpired =
        _currentPayment.isExpired || _secondsRemaining <= 0;
    final bool isSessionFailed = _currentPayment.isFailed;
    final bool isSessionCancelled = _currentPayment.isCancelled;
    final bool isSessionActive =
        !isSessionExpired && !isSessionFailed && !isSessionCancelled;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Scan to Pay',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelPayment,
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
                    // Order & Amount Summary Card
                    GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: GlassTheme.borderRadiusSmall,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgAssetIcon(
                                    assetName: isBakong
                                        ? 'bakong_logo'
                                        : 'khqr_logo',
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order #${_currentPayment.orderId}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${_currentPayment.currency} ${_currentPayment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: GlassTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${KhmerCurrency.formatKhr(_currentPayment.amount)} KHR (អត្រា ៤,១០០)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
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
                                    Text(
                                      providerTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        ),
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
                                    style: TextStyle(
                                      color: GlassTheme.textMuted,
                                    ),
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
                                    style: TextStyle(
                                      color: GlassTheme.textMuted,
                                    ),
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

                                // Pure White QR Code Graphic Frame (Quiet Zone)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
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
                                        '${_currentPayment.currency} ${_currentPayment.amount.toStringAsFixed(2)} • ${KhmerCurrency.formatKhr(_currentPayment.amount)}',
                                        style: const TextStyle(
                                          color: GlassTheme.textDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'FoodGo Restaurant · Phnom Penh',
                                        style: TextStyle(
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
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: Colors.orangeAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Payment expires in: ${_formatTimer(_secondsRemaining)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orangeAccent,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                          color: GlassTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _showRawPayload
                                              ? 'Hide QR Payload Details'
                                              : 'Show All QR Payload Details',
                                          style: TextStyle(
                                            color: GlassTheme.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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
                                            color:
                                                GlassTheme.primaryGreenAccent,
                                          ),
                                        ),
                                        if (_currentPayment.merchantReference !=
                                            null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Merchant Ref: ${_currentPayment.merchantReference}',
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
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: 80.ms,
                          curve: Curves.easeOut,
                        )
                        .scale(
                          begin: const Offset(0.97, 0.97),
                          end: const Offset(1, 1),
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
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
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: GlassTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                const Text(
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
                                        _currentPayment.merchantReference,
                                    'amount': _currentPayment.amount
                                        .toStringAsFixed(2),
                                    'currency': _currentPayment.currency,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
