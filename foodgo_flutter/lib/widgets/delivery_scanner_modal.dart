import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/glass_theme.dart';
import '../services/api_service.dart';
import 'glass_container.dart';

class DeliveryScannerModal extends StatefulWidget {
  final String orderId;
  final VoidCallback? onConfirmed;
  final ValueChanged<String>? onDeliveryTimeConfirmed;

  const DeliveryScannerModal({
    super.key,
    required this.orderId,
    this.onConfirmed,
    this.onDeliveryTimeConfirmed,
  });

  static void show(
    BuildContext context, {
    required String orderId,
    VoidCallback? onConfirmed,
    ValueChanged<String>? onDeliveryTimeConfirmed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryScannerModal(
        orderId: orderId,
        onConfirmed: onConfirmed,
        onDeliveryTimeConfirmed: onDeliveryTimeConfirmed,
      ),
    );
  }

  @override
  State<DeliveryScannerModal> createState() => _DeliveryScannerModalState();
}

class _DeliveryScannerModalState extends State<DeliveryScannerModal>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  int _selectedTab = 0; // 0: Camera / QR, 1: 6-Digit PIN
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isDelivered = false;
  String? _confirmedDeliveryTime;
  String? _confirmedDriverName;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _pinController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitConfirmation({String? directToken, String? directPin}) async {
    final token = (directToken ?? _tokenController.text).trim();
    final pin = (directPin ?? _pinController.text).trim();

    if (token.isEmpty && pin.isEmpty) {
      setState(() {
        _errorMessage = 'Please scan driver QR or enter the 6-digit PIN.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{};
      if (token.isNotEmpty) {
        payload['token'] = token;
      }
      if (pin.isNotEmpty) {
        payload['verification_pin'] = pin;
      }

      final response = await _api.post(
        'orders/${widget.orderId}/confirm_delivery/',
        payload,
      );

      if (!mounted) return;

      final deliveryTime = response['delivery_time']?.toString() ??
          DateTime.now().toIso8601String();
      final driverName = response['driver_name']?.toString() ?? 'Assigned Driver';

      setState(() {
        _isSubmitting = false;
        _isDelivered = true;
        _confirmedDeliveryTime = deliveryTime;
        _confirmedDriverName = driverName;
      });

      widget.onConfirmed?.call();
      if (widget.onDeliveryTimeConfirmed != null) {
        widget.onDeliveryTimeConfirmed!(deliveryTime);
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      String err = 'Delivery confirmation failed. Please try again.';
      final respData = dioErr.response?.data;
      if (respData is Map) {
        if (respData['detail'] != null) {
          err = respData['detail'].toString();
        } else if (respData['error'] != null) {
          err = respData['error'].toString();
        } else if (respData['message'] != null) {
          err = respData['message'].toString();
        }
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = err;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _simulateScanDriverPayload() {
    Clipboard.getData('text/plain').then((clip) {
      if (!mounted) return;
      final text = clip?.text?.trim() ?? '';
      if (text.contains('FOODGO:DELIVERY:CONFIRM')) {
        _tokenController.text = text;
        _submitConfirmation(directToken: text);
      } else {
        showDialog(
          context: context,
          builder: (ctx) {
            final pasteCtrl = TextEditingController(text: text);
            return AlertDialog(
              backgroundColor: GlassTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Paste Scanned QR Data', style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: pasteCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'FOODGO:DELIVERY:CONFIRM:v1?... or token',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.primaryGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _tokenController.text = pasteCtrl.text.trim();
                    _submitConfirmation(directToken: pasteCtrl.text.trim());
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _isDelivered ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    String formattedTime = _confirmedDeliveryTime ?? '';
    try {
      final dt = DateTime.parse(formattedTime).toLocal();
      formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {}

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
          child: const Icon(Icons.check_rounded, color: GlassTheme.primaryGreen, size: 48),
        ),
        const SizedBox(height: 20),
        const Text(
          'Delivery Confirmed! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Order #${widget.orderId} handover has been securely verified.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildReceiptRow('Status', 'DELIVERED', valueColor: GlassTheme.primaryGreen),
              const Divider(color: Colors.white10, height: 16),
              _buildReceiptRow('Confirmed At', formattedTime),
              if (_confirmedDriverName != null) ...[
                const Divider(color: Colors.white10, height: 16),
                _buildReceiptRow('Driver', _confirmedDriverName!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GlassTheme.primaryGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
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
                  child: const Icon(Icons.qr_code_scanner, color: GlassTheme.primaryGreen, size: 22),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm Delivery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order #${widget.orderId} • Customer Verification',
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
        const SizedBox(height: 18),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? GlassTheme.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Scan Driver QR',
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? GlassTheme.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Enter 6-Digit PIN',
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_selectedTab == 0) _buildCameraViewfinder() else _buildPinEntryView(),

        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSubmitting ? null : () => _submitConfirmation(),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                : Text(
                    _selectedTab == 0 ? 'Verify Scanned Code' : 'Submit 6-Digit PIN',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCameraViewfinder() {
    return Column(
      children: [
        Container(
          width: 220,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GlassTheme.primaryGreen.withValues(alpha: 0.8), width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(top: 8, left: 8, child: _corner(isTop: true, isLeft: true)),
              Positioned(top: 8, right: 8, child: _corner(isTop: true, isLeft: false)),
              Positioned(bottom: 8, left: 8, child: _corner(isTop: false, isLeft: true)),
              Positioned(bottom: 8, right: 8, child: _corner(isTop: false, isLeft: false)),

              Icon(Icons.qr_code_2, size: 84, color: Colors.white.withValues(alpha: 0.2)),

              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: _laserAnimation.value * 180,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen,
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.primaryGreen.withValues(alpha: 0.9),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ALIGN DRIVER QR',
                    style: TextStyle(
                      color: GlassTheme.primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Scan the delivery QR code displayed on your driver\'s screen.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: GlassTheme.primaryGreen,
              ),
              icon: const Icon(Icons.paste, size: 16),
              label: const Text('Paste / Enter QR Data', style: TextStyle(fontSize: 12)),
              onPressed: _simulateScanDriverPayload,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinEntryView() {
    return Column(
      children: [
        const SizedBox(height: 6),
        const Text(
          'Ask your driver for the 6-digit confirmation PIN shown on their FoodGo driver app:',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8, fontSize: 24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: GlassTheme.primaryGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Single-use PIN expires after 15 minutes',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _corner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 16,
      height: 16,
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
}
