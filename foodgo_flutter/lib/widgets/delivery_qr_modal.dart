import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/glass_theme.dart';
import '../services/api_service.dart';
import 'glass_container.dart';
import 'responsive_layout.dart';

class DeliveryQrModal extends StatefulWidget {
  final String orderId;
  final String? initialPin;
  final String? status;
  final String? restaurantName;
  final double? totalAmount;
  final bool isDriver;
  final VoidCallback? onDelivered;

  const DeliveryQrModal({
    super.key,
    required this.orderId,
    this.initialPin,
    this.status,
    this.restaurantName,
    this.totalAmount,
    this.isDriver = true,
    this.onDelivered,
  });

  static void show(
    BuildContext context, {
    required String orderId,
    String? pin,
    String? status,
    String? restaurantName,
    double? totalAmount,
    bool isDriver = true,
    VoidCallback? onDelivered,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryQrModal(
        orderId: orderId,
        initialPin: pin,
        status: status,
        restaurantName: restaurantName,
        totalAmount: totalAmount,
        isDriver: isDriver,
        onDelivered: onDelivered,
      ),
    );
  }

  @override
  State<DeliveryQrModal> createState() => _DeliveryQrModalState();
}

class _DeliveryQrModalState extends State<DeliveryQrModal> {
  final ApiService _api = ApiService();
  bool _isLoading = true;

  String? _qrPayload;
  String? _verificationPin;
  DateTime? _expiresAt;
  bool _isDelivered = false;
  String? _deliveryTimestamp;

  Timer? _countdownTimer;
  Timer? _pollingTimer;
  int _secondsRemaining = 900; // 15 mins default

  @override
  void initState() {
    super.initState();
    _fetchOrInitToken();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrInitToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _api.post('orders/${widget.orderId}/delivery_qr/', {});
      if (!mounted) return;

      final payload =
          data['qr_payload']?.toString() ??
          'FOODGO:DELIVERY:CONFIRM:v1?order_id=${widget.orderId}&token=${data['token']}';
      final pin =
          data['verification_pin']?.toString() ??
          widget.initialPin ??
          '${(int.tryParse(widget.orderId) ?? 1) * 73 % 900000 + 100000}';

      DateTime? exp;
      if (data['expires_at'] != null) {
        exp = DateTime.tryParse(data['expires_at'].toString())?.toLocal();
      }

      setState(() {
        _qrPayload = payload;
        _verificationPin = pin;
        _expiresAt = exp;
        _isLoading = false;
      });

      _startCountdown();
      _startPollingConfirmation();
    } catch (e) {
      if (!mounted) return;
      // Fallback local display if offline or network issue
      final fallbackPin =
          widget.initialPin ??
          '${(int.tryParse(widget.orderId) ?? 1) * 73 % 900000 + 100000}';
      final fallbackPayload =
          'FOODGO:DELIVERY:CONFIRM:v1?order_id=${widget.orderId}&token=demo-token-${widget.orderId}';

      setState(() {
        _qrPayload = fallbackPayload;
        _verificationPin = fallbackPin;
        _expiresAt = DateTime.now().add(const Duration(minutes: 15));
        _isLoading = false;
      });

      _startCountdown();
      _startPollingConfirmation();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateRemainingSeconds();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemainingSeconds();
    });
  }

  void _updateRemainingSeconds() {
    if (_expiresAt == null) return;
    final diff = _expiresAt!.difference(DateTime.now()).inSeconds;
    setState(() {
      _secondsRemaining = diff > 0 ? diff : 0;
    });
  }

  void _startPollingConfirmation() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isDelivered) {
        timer.cancel();
        return;
      }
      try {
        final orderData = await _api.get('orders/${widget.orderId}/');
        if (!mounted) return;
        if (orderData['status'] == 'delivered') {
          timer.cancel();
          setState(() {
            _isDelivered = true;
            _deliveryTimestamp = DateTime.now().toIso8601String();
          });
          widget.onDelivered?.call();
        }
      } catch (_) {}
    });
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBottomSheet(
      child: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _isDelivered ? _buildSuccessView() : _buildActiveQrView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
            border: Border.all(color: GlassTheme.primaryGreen, width: 3),
            boxShadow: [
              BoxShadow(
                color: GlassTheme.primaryGreen.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: GlassTheme.primaryGreen,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Delivery Confirmed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customer scanned QR code. Order #${widget.orderId} is complete.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        if (_deliveryTimestamp != null) ...[
          const SizedBox(height: 6),
          Text(
            'Timestamp: $_deliveryTimestamp',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GlassTheme.primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GlassTheme.primaryGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Back to Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActiveQrView() {
    final isExpired = _secondsRemaining <= 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                  child: const Icon(
                    Icons.qr_code_2,
                    color: GlassTheme.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Handover QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order #${widget.orderId} • Show to customer',
                      style: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white60),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          Container(
            height: 260,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: GlassTheme.primaryGreen,
            ),
          )
        else ...[
          // QR Code Card
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isExpired
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : GlassTheme.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data:
                            _qrPayload ??
                            'FOODGO:HANDOVER:ORDER#${widget.orderId}',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1B5E20),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0E1511),
                        ),
                      ),
                      if (isExpired)
                        Container(
                          width: 200,
                          height: 200,
                          color: Colors.black87.withValues(alpha: 0.8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_off,
                                color: Colors.redAccent,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'QR Expired',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlassTheme.primaryGreen,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: _fetchOrInitToken,
                                child: const Text(
                                  'Refresh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'BACKUP PIN: ${_verificationPin ?? "------"}',
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Expiration and Live Polling Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.timer,
                color: isExpired ? Colors.redAccent : GlassTheme.primaryGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isExpired
                    ? 'Token expired. Tap refresh.'
                    : 'Valid for ${_formatTimer(_secondsRemaining)} • Auto-verifies upon scan',
                style: TextStyle(
                  color: isExpired ? Colors.redAccent : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isExpired) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.white60,
                  ),
                  tooltip: 'Regenerate QR',
                  onPressed: _fetchOrInitToken,
                ),
              ],
            ],
          ),
        ],

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: GlassTheme.primaryGreen,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Present this code at customer doorstep. Customer will scan with FoodGo app to confirm handover.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
