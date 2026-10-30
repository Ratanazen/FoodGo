import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

/// Centralized animation design tokens and accessibility-aware motion utilities
/// for the FoodGo design system.
///
/// Principles:
/// - Smooth and minimal: Restrained micro-movements (4-12px) and rapid settling (140-280ms).
/// - Contrast & clarity: Never distract from core ordering and payment actions.
/// - Accessibility first: Fully honors system and in-app `reducedMotion` settings.
abstract final class AppMotion {
  // ── Animation Durations ──────────────────────────────────────────────────
  /// 140ms: Tap release, switch toggles, checkmark ticks, subtle icon shifts
  static const Duration micro = Duration(milliseconds: 140);

  /// 180ms: Tab indicator slides, button hover states, chip selections
  static const Duration shortDuration = Duration(milliseconds: 180);

  /// 240ms: Modal bottom sheet entrances, card appearance, accordion unfolds
  static const Duration medium = Duration(milliseconds: 240);

  /// 280ms: Route transitions, large content section switches
  static const Duration page = Duration(milliseconds: 280);

  /// 380ms: Hero showcases, brand badge splash reveals
  static const Duration extended = Duration(milliseconds: 380);

  // ── Easings / Curves ─────────────────────────────────────────────────────
  /// Deceleration curve for elements entering the viewport
  static const Curve enter = Curves.easeOutCubic;

  /// Acceleration curve for elements exiting the viewport
  static const Curve exit = Curves.easeInCubic;

  /// Balanced symmetric curve for state transitions (e.g. color, height)
  static const Curve standard = Curves.easeInOutCubic;

  /// Restrained spring curve for tactile micro-interactions (pressables, badges)
  static const Curve emphasized = Curves.easeOutBack;

  // ── Movement Distances (Logical Pixels) ──────────────────────────────────
  static const double subtleDistance = 6.0;
  static const double standardDistance = 10.0;
  static const double modalDistance = 24.0;

  // ── Reduced Motion Detection ─────────────────────────────────────────────
  /// Determines if animations should be minimized or disabled based on
  /// system accessibility settings (`MediaQuery.disableAnimations`) or
  /// in-app user preference (`ThemeProvider.reducedMotion`).
  static bool shouldReduceMotion(BuildContext context) {
    try {
      final systemReduced =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final provider = context.read<ThemeProvider?>();
      final userReduced = provider?.reducedMotion ?? false;
      return systemReduced || userReduced;
    } catch (_) {
      return false;
    }
  }

  /// Returns [Duration.zero] if reduced motion is requested, else returns [base].
  static Duration adaptiveDuration(BuildContext context, Duration base) {
    return shouldReduceMotion(context) ? Duration.zero : base;
  }
}

/// A lightweight entrance container that applies a subtle vertical slide
/// and fade with automatic reduced-motion bypass and optional stagger indexing.
class MotionEntrance extends StatelessWidget {
  final Widget child;
  final int staggerIndex;
  final double offsetY;
  final Duration? duration;
  final Duration? delay;

  const MotionEntrance({
    super.key,
    required this.child,
    this.staggerIndex = 0,
    this.offsetY = AppMotion.subtleDistance,
    this.duration,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    if (reduceMotion) return child;

    final baseDelay =
        delay ?? Duration(milliseconds: (staggerIndex.clamp(0, 6) * 35));
    final effDuration = duration ?? AppMotion.medium;

    return child
        .animate(delay: baseDelay)
        .fadeIn(duration: effDuration, curve: AppMotion.enter)
        .slideY(
          begin: offsetY / 100.0,
          end: 0,
          duration: effDuration,
          curve: AppMotion.enter,
        );
  }
}

/// Convenience extension for wrapping widgets directly into entrance motions.
extension MotionEntranceExtension on Widget {
  Widget motionEntrance({
    int staggerIndex = 0,
    double offsetY = AppMotion.subtleDistance,
    Duration? duration,
    Duration? delay,
  }) {
    return MotionEntrance(
      staggerIndex: staggerIndex,
      offsetY: offsetY,
      duration: duration,
      delay: delay,
      child: this,
    );
  }
}
