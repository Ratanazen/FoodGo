import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../widgets/glass/animated_pressable.dart';

/// Live Order Delivery State for the Floating Mini-Tracker
enum MiniTrackerDeliveryStatus { confirmed, preparing, onTheWay, arrived }

/// A Spotify Mini-Player equivalent for active food deliveries in FoodGo.
///
/// Features:
/// - Floating glassmorphic pill docked above bottom navigation.
/// - Live progress micro-bar with ETA countdown pill.
/// - Pulsing courier animation with status chip.
/// - Expandable drawer / 1-tap navigation to full Live GPS Map.
/// - Zero emojis, 100% accessible touch targets (>= 48x48dp).
class FloatingOrderMiniTracker extends StatefulWidget {
  final int orderId;
  final String restaurantName;
  final String? deliveryAddress;
  final double totalAmount;
  final int etaMinutes;
  final MiniTrackerDeliveryStatus status;
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatar;
  final double? driverSpeedKmH;
  final VoidCallback? onDismiss;

  const FloatingOrderMiniTracker({
    super.key,
    required this.orderId,
    required this.restaurantName,
    this.deliveryAddress,
    required this.totalAmount,
    this.etaMinutes = 18,
    this.status = MiniTrackerDeliveryStatus.onTheWay,
    this.driverName,
    this.driverPhone,
    this.driverAvatar,
    this.driverSpeedKmH = 32.0,
    this.onDismiss,
  });

  @override
  State<FloatingOrderMiniTracker> createState() =>
      _FloatingOrderMiniTrackerState();
}

class _FloatingOrderMiniTrackerState extends State<FloatingOrderMiniTracker> {
  bool _isDismissed = false;

  double get _progress {
    switch (widget.status) {
      case MiniTrackerDeliveryStatus.confirmed:
        return 0.25;
      case MiniTrackerDeliveryStatus.preparing:
        return 0.50;
      case MiniTrackerDeliveryStatus.onTheWay:
        return 0.78;
      case MiniTrackerDeliveryStatus.arrived:
        return 1.00;
    }
  }

  String get _statusTitle {
    switch (widget.status) {
      case MiniTrackerDeliveryStatus.confirmed:
        return 'Order Confirmed';
      case MiniTrackerDeliveryStatus.preparing:
        return 'Kitchen is Preparing';
      case MiniTrackerDeliveryStatus.onTheWay:
        return 'Courier is On The Way';
      case MiniTrackerDeliveryStatus.arrived:
        return 'Rider Has Arrived!';
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case MiniTrackerDeliveryStatus.confirmed:
        return AppIcons.successFilled;
      case MiniTrackerDeliveryStatus.preparing:
        return AppIcons.foodCategory;
      case MiniTrackerDeliveryStatus.onTheWay:
        return AppIcons.fastDelivery;
      case MiniTrackerDeliveryStatus.arrived:
        return AppIcons.locationOutline;
    }
  }

  Color get _statusColor {
    switch (widget.status) {
      case MiniTrackerDeliveryStatus.confirmed:
        return const Color(0xFF60A5FA); // Blue
      case MiniTrackerDeliveryStatus.preparing:
        return const Color(0xFFF59E0B); // Amber
      case MiniTrackerDeliveryStatus.onTheWay:
        return GlassTheme.primaryGreen; // Lush Emerald
      case MiniTrackerDeliveryStatus.arrived:
        return const Color(0xFF10B981); // Bright Green
    }
  }

  Color _statusTextColor(bool isDark) {
    if (isDark) return _statusColor;
    switch (widget.status) {
      case MiniTrackerDeliveryStatus.confirmed:
        return const Color(0xFF1D4ED8);
      case MiniTrackerDeliveryStatus.preparing:
        return const Color(0xFFB45309);
      case MiniTrackerDeliveryStatus.onTheWay:
      case MiniTrackerDeliveryStatus.arrived:
        return const Color(0xFF15803D);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final statusTextColor = _statusTextColor(isDark);
    final primary = theme.colorScheme.primary;
    final actionColor = isDark ? primary : const Color(0xFF15803D);

    return Dismissible(
      key: ValueKey('order_mini_tracker_${widget.orderId}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() => _isDismissed = true);
        widget.onDismiss?.call();
      },
      child: AnimatedPressable(
        pressedScale: 0.98,
        onTap: () => context.push('/map/${widget.orderId}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _statusColor.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: _statusColor.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top Micro-Progress Bar (Spotify Mini-Player Style) ──
                  Stack(
                    children: [
                      Container(
                        height: 3.5,
                        width: double.infinity,
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          return Container(
                            height: 3.5,
                            width: constraints.maxWidth * _progress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _statusColor.withValues(alpha: 0.8),
                                  _statusColor,
                                ],
                              ),
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // ── Main Content Body ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        // Animated Status Icon with Pulsing Halo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _statusColor.withValues(alpha: 0.18),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1.15, 1.15),
                                  duration: 1000.ms,
                                ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor.withValues(alpha: 0.25),
                                border: Border.all(
                                  color: _statusColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                _statusIcon,
                                color: _statusColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Title, Restaurant, and ETA
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _statusTitle,
                                      maxLines: 2,
                                      style: textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: primaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${widget.orderId}',
                                      style: textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: statusTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.restaurantName,
                                      maxLines: 2,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' • \$${widget.totalAmount.toStringAsFixed(2)}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right CTA: ETA Pill + "Track Live" Action Button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _statusColor.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.eta,
                                    size: 11,
                                    color: statusTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.etaMinutes} min',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: statusTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Live Map',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: actionColor,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: actionColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
