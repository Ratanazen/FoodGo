import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/glass_theme.dart';
import '../services/api_service.dart';
import 'glass_container.dart';
import 'responsive_layout.dart';

/// QR / PIN verification sheet for the delivery handover.
///
/// Success is only shown after the backend confirms the delivery. The sheet
/// never falls back to a local confirmation or a made-up timestamp.
class DeliveryScannerModal extends StatefulWidget {
  final String orderId;
  final bool isDriver;
  final VoidCallback? onConfirmed;
  final ValueChanged<String>? onDeliveryTimeConfirmed;

  const DeliveryScannerModal({
    super.key,
    required this.orderId,
    this.isDriver = true,
    this.onConfirmed,
    this.onDeliveryTimeConfirmed,
  });

  static void show(
    BuildContext context, {
    required String orderId,
    bool isDriver = true,
    VoidCallback? onConfirmed,
    ValueChanged<String>? onDeliveryTimeConfirmed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryScannerModal(
        orderId: orderId,
        isDriver: isDriver,
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

  MobileScannerController? _scannerController;
  bool _isTorchOn = false;

  int _selectedTab = 0; // 0: Camera / QR, 1: 6-digit PIN
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isDelivered = false;
  bool _wasAlreadyDelivered = false;
  String? _confirmedDeliveryTime;
  String? _confirmedDriverName;

  bool _reduceMotion = false;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  ColorScheme get _scheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (reduceMotion || _isDelivered) {
        _laserController.stop();
      } else {
        _laserController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _laserController.dispose();
    _pinController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitConfirmation({
    String? directToken,
    String? directPin,
  }) async {
    final token = (directToken ?? _tokenController.text).trim();
    final pin = (directPin ?? _pinController.text).trim();

    if (token.isEmpty && pin.isEmpty) {
      setState(() {
        _errorMessage =
            'Scan the delivery QR code or enter the 6-digit handover PIN.';
      });
      return;
    }

    if (token.isEmpty && pin.length != 6) {
      setState(() {
        _errorMessage = 'The handover PIN must be exactly 6 digits.';
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

      final alreadyDelivered =
          response['status']?.toString() == 'ALREADY_DELIVERED';
      final deliveryTime = response['delivery_time']?.toString();
      final driverName = response['driver_name']?.toString();

      _laserController.stop();
      setState(() {
        _isSubmitting = false;
        _isDelivered = true;
        _wasAlreadyDelivered = alreadyDelivered;
        _confirmedDeliveryTime =
            (deliveryTime != null && deliveryTime.isNotEmpty)
            ? deliveryTime
            : null;
        _confirmedDriverName = (driverName != null && driverName.isNotEmpty)
            ? driverName
            : null;
      });

      widget.onConfirmed?.call();
      if (widget.onDeliveryTimeConfirmed != null &&
          _confirmedDeliveryTime != null) {
        widget.onDeliveryTimeConfirmed!(_confirmedDeliveryTime!);
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _friendlyError(dioErr);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'FoodGo could not verify this code. Nothing was marked '
            'delivered. Please retry.';
      });
    }
  }

  String _friendlyError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      for (final key in ['detail', 'error', 'message']) {
        final value = data[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'FoodGo rejected this code. Check the QR or PIN and try again.';
      case 401:
      case 403:
        return 'Your session is not authorized to confirm this delivery. '
            'Sign in again with the assigned account.';
      case 404:
        return 'No delivery assignment was found for this order.';
      case 409:
        return 'This delivery code has already been used.';
      case 410:
        return 'This delivery code has expired. Ask the other device for a '
            'new code.';
      default:
        break;
    }

    final isNetwork =
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
    if (isNetwork) {
      return 'Could not reach FoodGo. Check your connection and retry — '
          'nothing was marked delivered.';
    }

    return 'FoodGo could not verify this code. Nothing was marked delivered. '
        'Please retry.';
  }

  void _pasteQrPayload() {
    Clipboard.getData('text/plain').then((clip) {
      if (!mounted) return;
      final text = clip?.text?.trim() ?? '';
      if (text.contains('FOODGO:DELIVERY:CONFIRM')) {
        _tokenController.text = text;
        _submitConfirmation(directToken: text);
      } else {
        final pasteCtrl = TextEditingController(text: text);
        showDialog(
          context: context,
          builder: (ctx) {
            final scheme = Theme.of(ctx).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              title: const Text('Enter scanned QR data'),
              content: TextField(
                controller: pasteCtrl,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'FOODGO:DELIVERY:CONFIRM:v1?... or token',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _tokenController.text = pasteCtrl.text.trim();
                    _submitConfirmation(directToken: pasteCtrl.text.trim());
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        ).whenComplete(pasteCtrl.dispose);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ResponsiveBottomSheet(
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: _isDelivered ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: _scheme.outlineVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final scheme = _scheme;
    String? formattedTime;
    if (_confirmedDeliveryTime != null) {
      try {
        final dt = DateTime.parse(_confirmedDeliveryTime!).toLocal();
        formattedTime =
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}:'
            '${dt.second.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedTime = _confirmedDeliveryTime;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHandle(),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.2),
            border: Border.all(color: scheme.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: scheme.primary, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          label: 'Delivery confirmed for order ${widget.orderId}',
          child: Text(
            _wasAlreadyDelivered ? 'Already Delivered' : 'Delivery Confirmed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _wasAlreadyDelivered
              ? 'FoodGo had already recorded order #${widget.orderId} as '
                    'delivered.'
              : 'FoodGo verified the handover for order #${widget.orderId}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              _buildReceiptRow(
                'Status',
                'DELIVERED',
                valueColor: scheme.primary,
              ),
              if (formattedTime != null) ...[
                Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  height: 16,
                ),
                _buildReceiptRow('Confirmed at', formattedTime),
              ],
              if (_confirmedDriverName != null) ...[
                Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  height: 16,
                ),
                _buildReceiptRow('Driver', _confirmedDriverName!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    final scheme = _scheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? scheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    final scheme = _scheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHandle(),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isDriver ? 'Scan Customer QR' : 'Confirm Delivery',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isDriver
                        ? 'Order #${widget.orderId} • Customer QR Verification'
                        : 'Order #${widget.orderId} • Customer Verification',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
              tooltip: 'Close delivery verification',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Container(
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildTab(
                  index: 0,
                  label: widget.isDriver ? 'Camera Scanner' : 'Scan Driver QR',
                ),
              ),
              Expanded(
                child: _buildTab(
                  index: 1,
                  label: widget.isDriver
                      ? 'Enter Customer PIN'
                      : 'Enter 6-Digit PIN',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (_errorMessage != null) ...[
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_selectedTab == 0)
          _buildCameraViewfinder()
        else
          _buildPinEntryView(),

        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
            onPressed: _isSubmitting ? null : () => _submitConfirmation(),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: scheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _selectedTab == 0
                        ? 'Verify Scanned Code'
                        : 'Submit 6-Digit PIN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildTab({required int index, required String label}) {
    final scheme = _scheme;
    final selected = _selectedTab == index;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.small - 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.small - 2),
          onTap: () => setState(() => _selectedTab = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDetectedBarcode(String raw) {
    if (_isSubmitting || _isDelivered) return;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    // Reject Bakong payment QR from being scanned as delivery confirmation
    if (trimmed.toLowerCase().contains('bakong') ||
        trimmed.toLowerCase().contains('khqr') ||
        trimmed.startsWith('00020101')) {
      setState(() {
        _errorMessage =
            'That is a Bakong payment QR. Scan the customer\'s delivery '
            'confirmation QR instead.';
      });
      return;
    }

    String token = trimmed;
    if (token.contains('token=')) {
      try {
        token = token.split('token=')[1].split('&')[0];
      } catch (_) {}
    }

    _tokenController.text = token;
    _submitConfirmation(directToken: token);
  }

  Widget _buildCameraViewfinder() {
    final scheme = _scheme;

    return Column(
      children: [
        Container(
          width: 260,
          height: 230,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.medium - 2),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      final val = barcode.rawValue;
                      if (val != null && val.isNotEmpty) {
                        _handleDetectedBarcode(val);
                        break;
                      }
                    }
                  },
                  errorBuilder: (context, error) {
                    return _buildCameraErrorView(error);
                  },
                ),

                Positioned(
                  top: 8,
                  left: 8,
                  child: _corner(isTop: true, isLeft: true),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _corner(isTop: true, isLeft: false),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _corner(isTop: false, isLeft: true),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _corner(isTop: false, isLeft: false),
                ),

                if (!_reduceMotion)
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnimation.value * 210,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.9),
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
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: IconButton(
                          iconSize: 18,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          tooltip: _isTorchOn
                              ? 'Turn torch off'
                              : 'Turn torch on',
                          icon: Icon(
                            _isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: _isTorchOn ? Colors.amber : Colors.white,
                          ),
                          onPressed: () async {
                            await _scannerController?.toggleTorch();
                            if (!mounted) return;
                            setState(() => _isTorchOn = !_isTorchOn);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: IconButton(
                          iconSize: 18,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          tooltip: 'Switch camera',
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => _scannerController?.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      widget.isDriver
                          ? 'ALIGN CUSTOMER DELIVERY QR'
                          : 'ALIGN DRIVER QR',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                if (_isSubmitting)
                  Container(
                    color: Colors.black87,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: scheme.primary),
                        const SizedBox(height: 12),
                        const Text(
                          'Verifying delivery with FoodGo…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.isDriver
              ? 'Scan the delivery confirmation QR displayed on the '
                    'customer\'s screen.'
              : 'Scan the delivery QR code displayed on your driver\'s '
                    'screen.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              icon: const Icon(Icons.paste, size: 16),
              label: const Text(
                'Paste / Enter QR Data',
                style: TextStyle(fontSize: 12),
              ),
              onPressed: _pasteQrPayload,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraErrorView(MobileScannerException error) {
    final isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(14),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.amber, size: 32),
          const SizedBox(height: 8),
          Text(
            isPermission ? 'Camera Permission Denied' : 'Camera Unavailable',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPermission
                ? 'Camera access is disabled. Enter the 6-digit handover '
                      'PIN instead.'
                : 'Could not access the device camera '
                      '(${error.errorCode.name}).',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _scheme.primary,
              foregroundColor: _scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small - 2),
              ),
            ),
            icon: const Icon(Icons.pin, size: 16),
            label: const Text(
              'Enter PIN Instead',
              style: TextStyle(fontSize: 12),
            ),
            onPressed: () => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPinEntryView() {
    final scheme = _scheme;

    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          widget.isDriver
              ? 'Ask the customer for the 6-digit handover PIN shown on '
                    'their FoodGo order screen:'
              : 'Ask your driver for the 6-digit handover PIN shown in '
                    'their FoodGo driver app:',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              letterSpacing: 8,
              fontSize: 24,
            ),
            filled: true,
            fillColor: scheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium - 2),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium - 2),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The PIN is single-use and expires after 15 minutes.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }

  Widget _corner({required bool isTop, required bool isLeft}) {
    final color = _scheme.primary;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
