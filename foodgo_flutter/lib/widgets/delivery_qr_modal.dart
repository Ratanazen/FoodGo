import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/config/app_config.dart';
import '../core/theme/glass_theme.dart';
import '../services/api_service.dart';
import 'delivery_scanner_modal.dart';
import 'glass_container.dart';
import 'responsive_layout.dart';

/// Delivery handover sheet.
///
/// The QR payload and handover PIN are *always* supplied by the backend.
/// The sheet never fabricates a code, PIN, or expiry: if the server does not
/// return a verified payload the user sees a retryable error state instead.
class DeliveryQrModal extends StatefulWidget {
  final String orderId;

  /// Backend-supplied PIN, when the order payload already contains one.
  final String? initialPin;

  /// Backend-supplied QR payload for callers that already fetched it.
  /// Only used when [autoFetch] is false.
  final String? initialQrPayload;

  final String? status;
  final String? restaurantName;
  final double? totalAmount;
  final bool isDriver;
  final bool autoFetch;
  final VoidCallback? onDelivered;

  const DeliveryQrModal({
    super.key,
    required this.orderId,
    this.initialPin,
    this.initialQrPayload,
    this.status,
    this.restaurantName,
    this.totalAmount,
    this.isDriver = true,
    this.autoFetch = true,
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
  String? _errorMessage;
  String? _qrPayload;
  String? _verificationPin;
  DateTime? _expiresAt;
  bool _isDelivered = false;
  String? _deliveryTimestamp;

  Timer? _countdownTimer;
  Timer? _pollingTimer;
  int _secondsRemaining = 0;

  /// Guards against stale responses from overlapping fetch/regenerate calls.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      _loadCode();
    } else {
      _applyVerifiedPayload(
        qrPayload: widget.initialQrPayload,
        pin: widget.initialPin,
        expiresAt: null,
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    super.dispose();
  }

  /// Applies a payload that the caller already received from the backend.
  /// Never invents data: a missing payload becomes an error state.
  void _applyVerifiedPayload({
    required String? qrPayload,
    required String? pin,
    required DateTime? expiresAt,
  }) {
    final payload = qrPayload?.trim();
    if (payload == null || payload.isEmpty) {
      setState(() {
        _isLoading = false;
        _qrPayload = null;
        _verificationPin = null;
        _errorMessage =
            'No verified delivery code was supplied for this order. '
            'A code can only be issued by FoodGo.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = null;
      _qrPayload = payload;
      _verificationPin = (pin?.trim().isEmpty ?? true) ? null : pin!.trim();
      _expiresAt = expiresAt;
      _secondsRemaining = _remainingSeconds(expiresAt);
    });

    _startCountdownIfNeeded();
  }

  int _remainingSeconds(DateTime? expiresAt) {
    if (expiresAt == null) return 0;
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<dynamic> _requestFirstAvailable({
    required List<({String method, String path})> candidates,
    required Map<String, dynamic> body,
  }) async {
    Object? lastError;
    for (final candidate in candidates) {
      try {
        if (candidate.method == 'GET') {
          return await _api.get(candidate.path);
        }
        return await _api.post(candidate.path, body);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) {
          continue;
        }
        rethrow;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    throw StateError('No delivery QR endpoint candidates succeeded.');
  }

  String _formatLoadError(Object error) {
    if (error is DioException && error.response?.statusCode == 404) {
      final apiHost = Uri.tryParse(AppConfig.apiBaseUrl)?.host;
      final serverNote = (apiHost != null && apiHost.isNotEmpty)
          ? ' on $apiHost'
          : '';
      return 'Order #${widget.orderId} or its verified delivery QR endpoint '
          'was not found$serverNote. Verify the order is active or enter the '
          '6-digit handover PIN manually.';
    }
    return ApiService.formatError(
      error,
      fallback:
          'Could not reach FoodGo to issue a verified delivery code. '
          'No handover can be confirmed until the code loads.',
    );
  }

  Future<void> _loadCode({bool regenerate = false}) async {
    final requestId = ++_requestId;
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isDelivered = false;
    });

    try {
      final body = regenerate ? {'regenerate': true} : <String, dynamic>{};
      final List<({String method, String path})> candidates;
      if (widget.isDriver) {
        candidates = [
          (method: 'POST', path: 'orders/${widget.orderId}/delivery_qr/'),
          (method: 'POST', path: 'orders/${widget.orderId}/delivery/qr/'),
        ];
      } else if (regenerate) {
        candidates = [
          (
            method: 'POST',
            path: 'orders/${widget.orderId}/customer_regenerate_delivery_qr/',
          ),
          (
            method: 'POST',
            path: 'orders/${widget.orderId}/customer-regenerate-delivery-qr/',
          ),
        ];
      } else {
        candidates = [
          (
            method: 'POST',
            path: 'orders/${widget.orderId}/customer_delivery_qr/',
          ),
          (
            method: 'POST',
            path: 'orders/${widget.orderId}/customer-delivery-qr/',
          ),
          (
            method: 'GET',
            path: 'orders/${widget.orderId}/customer_delivery_qr/',
          ),
          (
            method: 'GET',
            path: 'orders/${widget.orderId}/customer-delivery-qr/',
          ),
        ];
      }

      final data = await _requestFirstAvailable(
        candidates: candidates,
        body: body,
      );
      if (!mounted || requestId != _requestId) return;

      // Compose a payload only from server-issued values. A local placeholder
      // is never used.
      final serverPayload = data['qr_payload']?.toString().trim();
      final serverToken = data['token']?.toString().trim();
      final payload = (serverPayload != null && serverPayload.isNotEmpty)
          ? serverPayload
          : (serverToken != null && serverToken.isNotEmpty
                ? 'FOODGO:DELIVERY:CONFIRM:v1?order_id=${widget.orderId}'
                      '&token=$serverToken'
                : null);

      if (payload == null || payload.isEmpty) {
        setState(() {
          _isLoading = false;
          _qrPayload = null;
          _verificationPin = null;
          _expiresAt = null;
          _errorMessage =
              'FoodGo did not return a verified delivery code for this '
              'order. Check your connection and try again.';
        });
        return;
      }

      final pin = data['verification_pin']?.toString().trim();
      DateTime? expiresAt;
      final rawExpiry = data['expires_at']?.toString();
      if (rawExpiry != null && rawExpiry.isNotEmpty) {
        expiresAt = DateTime.tryParse(rawExpiry)?.toLocal();
      }

      _applyVerifiedPayload(
        qrPayload: payload,
        pin: (pin != null && pin.isNotEmpty) ? pin : widget.initialPin,
        expiresAt: expiresAt,
      );

      _startPollingConfirmation();
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _formatLoadError(error);
      });
    }
  }

  void _startCountdownIfNeeded() {
    _countdownTimer?.cancel();
    if (!mounted || _expiresAt == null) return;

    _updateRemainingSeconds();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateRemainingSeconds();
      if (_secondsRemaining <= 0) timer.cancel();
    });
  }

  void _updateRemainingSeconds() {
    if (!mounted || _expiresAt == null) return;
    final remaining = _remainingSeconds(_expiresAt);
    if (remaining != _secondsRemaining) {
      setState(() {
        _secondsRemaining = remaining;
      });
    }
  }

  void _startPollingConfirmation() {
    _pollingTimer?.cancel();
    if (!mounted) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isDelivered) {
        timer.cancel();
        return;
      }
      try {
        final orderData = await _api.get('orders/${widget.orderId}/');
        if (!mounted) return;

        final status = orderData['status']?.toString().toLowerCase();
        if (status == 'delivered' || status == 'completed') {
          timer.cancel();
          _markDelivered(orderData);
        }
      } catch (_) {
        // Polling failures are transient; keep the code usable and retry on
        // the next tick. The QR never claims delivery without a server status.
      }
    });
  }

  void _markDelivered(Map<String, dynamic> orderData) {
    final rawDeliveredAt = orderData['delivered_at']?.toString();
    final parsedDeliveredAt = rawDeliveredAt == null
        ? null
        : DateTime.tryParse(rawDeliveredAt)?.toLocal();

    setState(() {
      _isDelivered = true;
      _deliveryTimestamp = parsedDeliveredAt != null
          ? _formatTimestamp(parsedDeliveredAt)
          : _formatTimestamp(DateTime.now());
    });
    widget.onDelivered?.call();
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: _isDelivered ? _buildSuccessView() : _buildHandoverView(),
        ),
      ),
    );
  }

  Widget _buildSheetHandle(Color color) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(Icons.qr_code_2, color: scheme.primary, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isDriver
                    ? 'Delivery Handover QR'
                    : 'Delivery Confirmation QR',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.isDriver
                    ? 'Order #${widget.orderId} • Show to customer'
                    : 'Order #${widget.orderId} • Show to driver',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
          tooltip: 'Close delivery code',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildWarningBadge(ColorScheme scheme) {
    final amber = scheme.brightness == Brightness.dark
        ? const Color(0xFFFFC107)
        : const Color(0xFF8A5A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: amber, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Delivery Confirmation (Not Payment)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverView() {
    final scheme = Theme.of(context).colorScheme;
    final divider = scheme.outlineVariant.withValues(alpha: 0.4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSheetHandle(divider),
        const SizedBox(height: AppSpacing.md),
        _buildHeader(scheme),
        if (!widget.isDriver) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildWarningBadge(scheme),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        if (_isLoading)
          _buildLoadingState(scheme)
        else if (_qrPayload == null)
          _buildErrorState(scheme)
        else
          _buildQrState(scheme),

        const SizedBox(height: AppSpacing.md),
        _buildInstructionCard(scheme),

        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.onSurface,
            side: BorderSide(color: divider),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme scheme) {
    return Container(
      height: 240,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: scheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Requesting a verified handover code…',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme scheme) {
    final errorColor = scheme.error;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 40),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Verified code unavailable',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _errorMessage ?? 'The delivery code could not be loaded.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (widget.autoFetch) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
              ),
              onPressed: _isLoading ? null : () => _loadCode(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
              ),
              onPressed: () {
                final navigator = Navigator.of(context);
                final hostContext = navigator.context;
                if (navigator.canPop()) {
                  navigator.pop();
                }
                DeliveryScannerModal.show(
                  hostContext,
                  orderId: widget.orderId,
                  isDriver: widget.isDriver,
                  onConfirmed: widget.onDelivered,
                );
              },
              icon: const Icon(Icons.pin, size: 18),
              label: const Text('Enter 6-Digit PIN Instead'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrState(ColorScheme scheme) {
    final isExpired = _expiresAt != null && _secondsRemaining <= 0;
    final primary = scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null && !isExpired) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: scheme.error, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              boxShadow: [
                BoxShadow(
                  color: (isExpired ? scheme.error : primary).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Semantics(
                  label:
                      'Delivery confirmation QR code for order '
                      '${widget.orderId}',
                  child: ExcludeSemantics(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: _qrPayload!,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: GlassTheme.royalSmalt,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: GlassTheme.inkSmalt,
                          ),
                        ),
                        if (isExpired)
                          Container(
                            width: 200,
                            height: 200,
                            color: Colors.black.withValues(alpha: 0.8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.timer_off,
                                  color: Colors.redAccent,
                                  size: 40,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Code expired',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: scheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _loadCode(regenerate: true),
                                  child: Text(
                                    'Get new code',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_verificationPin != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      'HANDOVER PIN: $_verificationPin',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpired ? Icons.error_outline : Icons.timer,
              color: isExpired ? scheme.error : primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isExpired
                    ? 'Code expired. Request a new one.'
                    : (_expiresAt != null
                          ? 'Valid for ${_formatTimer(_secondsRemaining)} '
                                '• Auto-verifies upon scan'
                          : 'Secure code • Auto-verifies upon scan'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isExpired ? scheme.error : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!isExpired && widget.autoFetch) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                tooltip: 'Request a new code',
                onPressed: _isLoading
                    ? null
                    : () => _loadCode(regenerate: true),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: scheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.isDriver
                  ? 'Present this code at the customer doorstep. The customer '
                        'scans it in the FoodGo app; delivery is only marked '
                        'complete after FoodGo confirms it.'
                  : 'Show this code to your assigned FoodGo driver on arrival. '
                        'The driver scans it; delivery is only marked complete '
                        'after FoodGo confirms it.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSheetHandle(scheme.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.2),
            border: Border.all(color: primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: primary, size: 48),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          label: 'Delivery confirmed for order ${widget.orderId}',
          child: Text(
            'Delivery Confirmed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'FoodGo confirmed order #${widget.orderId} as delivered.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_deliveryTimestamp != null) ...[
          const SizedBox(height: 6),
          Text(
            'Confirmed at $_deliveryTimestamp',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            widget.isDriver ? 'Back to Dashboard' : 'Done',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
