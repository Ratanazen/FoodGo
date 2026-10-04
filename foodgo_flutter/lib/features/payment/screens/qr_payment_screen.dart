import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/svg_icon.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../../../../services/api_service.dart';

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
    if (_currentPayment.expiresAt != null) {
      final diff = _currentPayment.expiresAt!.difference(DateTime.now()).inSeconds;
      _secondsRemaining = diff > 0 ? diff : 0;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
        _checkStatus();
      }
    });
  }

  void _startPolling() {
    // Polls status safely every 5 seconds without aggressive looping
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isVerifying) {
        _checkStatus(isBackground: true);
      }
    });
  }

  Future<void> _checkStatus({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() => _isVerifying = true);
    }
    try {
      final updated = await _paymentService.getPaymentStatus(_currentPayment.id);
      if (!mounted) return;
      setState(() {
        _currentPayment = updated;
        _isVerifying = false;
      });

      if (updated.isPaid) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
        if (mounted) {
          // Clear cart now that payment is confirmed
          context.read<CartProvider>().clear();
          context.go('/order-success', extra: _currentPayment.orderId);
        }
      } else if (updated.isExpired || updated.isCancelled) {
        _pollingTimer?.cancel();
        _countdownTimer?.cancel();
      } else if (!isBackground) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not completed yet. Please scan and pay with your banking app.'),
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
    try {
      await _paymentService.cancelPayment(_currentPayment.id);
    } catch (_) {}
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) context.pop();
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

  @override
  Widget build(BuildContext context) {
    final providerUpper = _currentPayment.provider.toUpperCase();
    final bool isBakong = providerUpper == 'BAKONG';
    final bool isAba = providerUpper == 'ABA';
    final String providerTitle = isBakong
        ? 'Bakong KHQR (NBC Open API)'
        : (isAba ? 'ABA KHQR' : 'ACLEDA KHQR');
    final Color brandColor = isBakong
        ? GlassTheme.bakongRed
        : (isAba ? GlassTheme.abaBlue : GlassTheme.acledaNavy);

    final String qrString = _currentPayment.qrPayload ?? 'https://foodgo.app/khqr/pay';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'KHQR Payment',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelPayment,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: GlassTheme.backgroundDark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
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
                            assetName: isBakong ? 'bakong_logo' : 'khqr_logo',
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order #${_currentPayment.orderId}',
                            style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentPayment.currency} ${_currentPayment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: GlassTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            Icon(Icons.qr_code_2, size: 16, color: brandColor == GlassTheme.bakongRed ? Colors.redAccent : Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              providerTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code Display Card
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: GlassTheme.borderRadiusSmall,
                  child: Column(
                    children: [
                      if (_currentPayment.isExpired || _secondsRemaining <= 0) ...[
                        const Icon(Icons.timer_off_outlined, size: 80, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Payment QR Expired',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please return to checkout and generate a new payment code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: GlassTheme.textMuted),
                        ),
                        const SizedBox(height: 20),
                        GlassButton(
                          text: 'Back to Checkout',
                          icon: Icons.refresh,
                          onPressed: () => context.pop(),
                        ),
                      ] else ...[
                        // KHQR Header Stand Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            color: GlassTheme.khqrBannerRed,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Center(
                            child: Text(
                              'KHQR · SCAN TO PAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),

                        // QR Graphic Frame
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            boxShadow: [
                              BoxShadow(
                                color: brandColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrString,
                                version: QrVersions.auto,
                                size: 220.0,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currentPayment.currency} ${_currentPayment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: GlassTheme.textDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Countdown Timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Payment expires in: ${_formatTimer(_secondsRemaining)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Scan this dynamic KHQR with ABA Mobile, ACLEDA mobile, Bakong, or any Cambodian banking app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // Copy KHQR Payload Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 16, color: GlassTheme.primaryGreen),
                          label: const Text('Copy KHQR Payload', style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: qrString));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('KHQR code payload copied to clipboard!'),
                                backgroundColor: GlassTheme.primaryGreen,
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Show/Hide QR Payload Details Toggle ("qr play show all")
                        InkWell(
                          onTap: () => setState(() => _showRawPayload = !_showRawPayload),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showRawPayload ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: GlassTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showRawPayload ? 'Hide QR Payload Details' : 'Show All QR Payload Details',
                                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Raw QR Payload Box (Shown when toggled)
                        if (_showRawPayload) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'EMVCo KHQR Payload:',
                                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${qrString.length} chars',
                                      style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
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
                                if (_currentPayment.merchantReference != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Merchant Ref: ${_currentPayment.merchantReference}',
                                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                if (!_currentPayment.isExpired && _secondsRemaining > 0) ...[
                  SizedBox(
                    height: 54,
                    child: GlassButton(
                      text: _isVerifying ? 'Checking Status...' : "I've Paid (Verify)",
                      icon: Icons.check_circle_outline,
                      onPressed: _isVerifying ? () {} : () => _checkStatus(isBackground: false),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Simulation Button for Browser/Sandbox Testing
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GlassTheme.primaryGreen,
                      side: BorderSide(color: GlassTheme.primaryGreen.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.bolt, size: 20),
                    label: const Text('Simulate Webhook Pay (Test Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isVerifying
                        ? null
                        : () async {
                            setState(() => _isVerifying = true);
                            try {
                              final isBakong = _currentPayment.provider.toUpperCase() == 'BAKONG';
                              final isAba = _currentPayment.provider.toUpperCase() == 'ABA';
                              final endpoint = isBakong
                                  ? 'payments/bakong/callback/'
                                  : (isAba ? 'payments/aba/callback/' : 'payments/acleda/callback/');
                              await ApiService().post(endpoint, {
                                'merchant_reference': _currentPayment.merchantReference,
                                'amount': _currentPayment.amount.toStringAsFixed(2),
                                'currency': _currentPayment.currency,
                                'transaction_id': 'TEST-SIM-${DateTime.now().millisecondsSinceEpoch}',
                                'status': 'PAID',
                              });
                              await _checkStatus(isBackground: false);
                            } catch (e) {
                              if (mounted) setState(() => _isVerifying = false);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _cancelPayment,
                    child: Text('Cancel Payment', style: TextStyle(color: GlassTheme.textMuted)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
