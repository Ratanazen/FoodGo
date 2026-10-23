import 'package:flutter/material.dart';

import '../../core/theme/glass_theme.dart';

/// A fluid, atmospheric Liquid Glass background that provides organic
/// Smalt Blue ambient depth under transparent scaffolds and frosted glass components.
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Base Atmospheric Liquid Surface ─────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? GlassTheme.backgroundDark
                : GlassTheme.backgroundLight,
          ),
        ),

        // ── 2. Ambient Smalt Blue Liquid Glow Orbs ─────────────────────────
        CustomPaint(
          painter: _LiquidOrbsPainter(isDark: isDark),
        ),

        // ── 3. Child Screen Content ─────────────────────────────────────────
        child,
      ],
    );
  }
}

/// Lightweight hardware-accelerated painter for diffuse ambient liquid orbs
class _LiquidOrbsPainter extends CustomPainter {
  final bool isDark;

  const _LiquidOrbsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (isDark) {
      // Top-Right Ambient Orb: Deep Smalt Glow
      final topGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.85, -0.75),
          radius: 1.1,
          colors: [
            GlassTheme.deepSmalt.withValues(alpha: 0.38),
            GlassTheme.midnightSmalt.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, topGlow);

      // Mid-Left Ambient Orb: Royal Smalt Liquid Accent
      final midGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.95, 0.15),
          radius: 0.95,
          colors: [
            GlassTheme.royalSmalt.withValues(alpha: 0.22),
            GlassTheme.stormySmalt.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, midGlow);

      // Bottom-Right Ambient Orb: Twilight Smalt Depth
      final bottomGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.65, 0.95),
          radius: 1.0,
          colors: [
            GlassTheme.twilightSmalt.withValues(alpha: 0.32),
            GlassTheme.smaltShadow.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, bottomGlow);
    } else {
      // Light Mode: Luminous Frosted Smalt Diffusions
      final topGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.8, -0.8),
          radius: 1.0,
          colors: [
            GlassTheme.paleSmalt.withValues(alpha: 0.45),
            GlassTheme.smaltTint.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, topGlow);

      final midGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.85, 0.25),
          radius: 0.9,
          colors: [
            GlassTheme.smaltBlueMist.withValues(alpha: 0.30),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6],
        ).createShader(rect);
      canvas.drawRect(rect, midGlow);

      final bottomGlow = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.5, 0.9),
          radius: 0.95,
          colors: [
            GlassTheme.frostedSmalt.withValues(alpha: 0.25),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55],
        ).createShader(rect);
      canvas.drawRect(rect, bottomGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidOrbsPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
