import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_palette.dart';
import '../providers/theme_provider.dart';

/// Lightweight particle for Christmas snowfall effect.
class _Snowflake {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double driftSpeed;
  final double driftPhase;
  final double opacity;

  const _Snowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.driftSpeed,
    required this.driftPhase,
    required this.opacity,
  });
}

/// High-performance canvas-based snowfall animation designed for Christmas Wonderland.
///
/// The animated canvas is only mounted while the Christmas theme is active and
/// the user has not disabled snowfall or reduced motion. Unmounting also stops
/// the underlying [AnimationController], so no frames are scheduled on other
/// themes or on low-power/reduced-motion devices.
class SnowfallEffect extends StatelessWidget {
  final int particleCount;

  const SnowfallEffect({super.key, this.particleCount = 35});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider?>();
    if (themeProvider == null) return const SizedBox.shrink();

    final palette = themeProvider.currentPalette;
    final isChristmas =
        palette == AppColorPalette.christmas ||
        palette == AppColorPalette.christmasWonderland;
    final platformReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!isChristmas ||
        !themeProvider.snowfallEnabled ||
        themeProvider.reducedMotion ||
        platformReducedMotion) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: _SnowfallCanvas(particleCount: particleCount),
        ),
      ),
    );
  }
}

class _SnowfallCanvas extends StatefulWidget {
  final int particleCount;

  const _SnowfallCanvas({required this.particleCount});

  @override
  State<_SnowfallCanvas> createState() => _SnowfallCanvasState();
}

class _SnowfallCanvasState extends State<_SnowfallCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Snowflake> _particles;

  @override
  void initState() {
    super.initState();
    final random = math.Random(
      1225,
    ); // Deterministic seed for Christmas date (12/25)
    _particles = List.generate(widget.particleCount, (index) {
      return _Snowflake(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 1.5 + random.nextDouble() * 2.5,
        speed: 0.15 + random.nextDouble() * 0.35,
        driftSpeed: 0.5 + random.nextDouble() * 1.5,
        driftPhase: random.nextDouble() * 2 * math.pi,
        opacity: 0.4 + random.nextDouble() * 0.5,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SnowfallPainter(
            particles: _particles,
            progress: _controller.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _SnowfallPainter extends CustomPainter {
  final List<_Snowflake> particles;
  final double progress;
  final bool isDark;

  _SnowfallPainter({
    required this.particles,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    for (final flake in particles) {
      // Calculate continuous falling y position
      final currentY = ((flake.y + progress * flake.speed) % 1.0) * size.height;
      // Gentle horizontal drift oscillation
      final drift =
          math.sin(
            progress * 2 * math.pi * flake.driftSpeed + flake.driftPhase,
          ) *
          12.0;
      final currentX = ((flake.x * size.width) + drift) % size.width;

      final flakeColor = isDark
          ? Colors.white.withValues(alpha: flake.opacity)
          : const Color(0xFF64748B).withValues(alpha: flake.opacity * 0.6);

      final paint = Paint()
        ..color = flakeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowfallPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
