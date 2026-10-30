import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/theme_provider.dart';

/// A rich, built-in themed skin backdrop that renders distinct visual styling,
/// atmospheric textures, geometric lattices, cyber grids, cultural ornaments,
/// and ambient glow meshes for every FoodGo theme skin (not just flat colors).
class ThemedSkinBackdrop extends StatelessWidget {
  final Widget child;
  final PaletteData? customPalette;
  final bool? enabled;

  const ThemedSkinBackdrop({
    super.key,
    required this.child,
    this.customPalette,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    ThemeProvider? themeProvider;
    try {
      themeProvider = context.watch<ThemeProvider>();
    } catch (_) {}

    final palette =
        customPalette ?? themeProvider?.paletteData ?? PaletteData.modernFoodGo;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBackdropActive =
        enabled ?? (themeProvider?.skinBackdropEnabled ?? true);

    // If an ancestor ThemedSkinBackdrop is already active and no custom palette is requested, avoid double-painting
    final parentScope = context
        .dependOnInheritedWidgetOfExactType<_ThemedSkinScope>();
    if (parentScope != null && customPalette == null) {
      return child;
    }

    final backgroundColor = isDark
        ? palette.backgroundDark
        : palette.backgroundLight;

    return _ThemedSkinScope(
      palette: palette,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Base Solid Themed Surface ─────────────────────────────────
          ColoredBox(color: backgroundColor),

          // ── 2. Themed Skin Backdrop Visuals ──────────────────────────────
          if (isBackdropActive)
            RepaintBoundary(
              child: CustomPaint(
                painter: ThemedSkinPainter(palette: palette, isDark: isDark),
              ),
            ),

          // ── 3. Child Screen Content ───────────────────────────────────────
          child,
        ],
      ),
    );
  }
}

class _ThemedSkinScope extends InheritedWidget {
  final PaletteData palette;

  const _ThemedSkinScope({required this.palette, required super.child});

  @override
  bool updateShouldNotify(covariant _ThemedSkinScope oldWidget) =>
      oldWidget.palette.id != palette.id;
}

/// Hardware-accelerated custom painter rendering unique atmospheric visuals
/// tailored to each [SkinBackdropStyle].
class ThemedSkinPainter extends CustomPainter {
  final PaletteData palette;
  final bool isDark;

  const ThemedSkinPainter({required this.palette, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Offset.zero & size;

    switch (palette.backdropStyle) {
      case SkinBackdropStyle.cyberGrid:
        _paintCyberGrid(canvas, size, rect);
        break;
      case SkinBackdropStyle.khmerLattice:
        _paintKhmerLattice(canvas, size, rect);
        break;
      case SkinBackdropStyle.luxuryStardust:
        _paintLuxuryStardust(canvas, size, rect);
        break;
      case SkinBackdropStyle.lanternRiver:
        _paintLanternRiver(canvas, size, rect);
        break;
      case SkinBackdropStyle.sacredLotus:
        _paintSacredLotus(canvas, size, rect);
        break;
      case SkinBackdropStyle.winterConstellation:
        _paintWinterConstellation(canvas, size, rect);
        break;
      case SkinBackdropStyle.fireworksGlitter:
        _paintFireworksGlitter(canvas, size, rect);
        break;
      case SkinBackdropStyle.festivePetals:
        _paintFestivePetals(canvas, size, rect);
        break;
      case SkinBackdropStyle.romanticPetals:
        _paintRomanticPetals(canvas, size, rect);
        break;
      case SkinBackdropStyle.mysticFog:
        _paintMysticFog(canvas, size, rect);
        break;
      case SkinBackdropStyle.celestialCrescent:
        _paintCelestialCrescent(canvas, size, rect);
        break;
      case SkinBackdropStyle.orientalClouds:
        _paintOrientalClouds(canvas, size, rect);
        break;
      case SkinBackdropStyle.tropicalBreeze:
        _paintTropicalBreeze(canvas, size, rect);
        break;
      case SkinBackdropStyle.springMeadow:
        _paintSpringMeadow(canvas, size, rect);
        break;
      case SkinBackdropStyle.forestCanopy:
        _paintForestCanopy(canvas, size, rect);
        break;
      case SkinBackdropStyle.liquidGlassPrism:
        _paintLiquidGlassPrism(canvas, size, rect);
        break;
      case SkinBackdropStyle.retroMemphis:
        _paintRetroMemphis(canvas, size, rect);
        break;
      case SkinBackdropStyle.botanicalAurora:
        _paintBotanicalAurora(canvas, size, rect);
        break;
      case SkinBackdropStyle.oceanicWaves:
        _paintOceanicWaves(canvas, size, rect);
        break;
      case SkinBackdropStyle.architecturalMinimal:
        _paintArchitecturalMinimal(canvas, size, rect);
        break;
      case SkinBackdropStyle.warmGlow:
        _paintWarmGlow(canvas, size, rect);
        break;
      case SkinBackdropStyle.liquidMesh:
        _paintLiquidMesh(canvas, size, rect);
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. Cyberpunk Perspective Laser Grid (Black Friday Cyber & Neon Night)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintCyberGrid(Canvas canvas, Size size, Rect rect) {
    final horizonY = size.height * 0.65;
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // Sky ambient neon glow
    final skyGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.6),
        radius: 1.2,
        colors: [
          accent.withValues(alpha: isDark ? 0.22 : 0.12),
          primary.withValues(alpha: isDark ? 0.12 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, skyGlow);

    // Glowing Horizon Line
    final horizonPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.45 : 0.25)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      horizonPaint,
    );

    final linePaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.16 : 0.09)
      ..strokeWidth = 1.0;

    // Perspective vanishing rays
    final vpX = size.width * 0.5;
    const rayCount = 12;
    for (int i = 0; i <= rayCount; i++) {
      final targetX = (size.width / rayCount) * i;
      canvas.drawLine(
        Offset(vpX, horizonY),
        Offset(targetX, size.height),
        linePaint,
      );
    }

    // Exponential horizontal lines
    final numHLines = 8;
    for (int i = 1; i <= numHLines; i++) {
      final progress = math.pow(i / numHLines, 2.2).toDouble();
      final y = horizonY + (size.height - horizonY) * progress;
      final alpha = (isDark ? 0.05 : 0.03) + (0.22 * progress);
      final hPaint = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hPaint);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. Angkor & Khmer Kbach Lotus Lattice (Angkor & Khmer Heritage)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintKhmerLattice(Canvas canvas, Size size, Rect rect) {
    final aura = palette.auraColor;
    final primary = palette.primary;

    // Central temple sunrise sandstone aura
    final centralAura = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.1,
        colors: [
          aura.withValues(alpha: isDark ? 0.24 : 0.14),
          primary.withValues(alpha: isDark ? 0.12 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, centralAura);

    // Delicate diamond kbach lattice
    final latticePaint = Paint()
      ..color = aura.withValues(alpha: isDark ? 0.07 : 0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        latticePaint,
      );
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        latticePaint,
      );
    }

    // Stylized lotus diamond center motes
    final dotPaint = Paint()
      ..color = aura.withValues(alpha: isDark ? 0.18 : 0.10)
      ..style = PaintingStyle.fill;

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. Imperial Gold Stardust (Dark Gold)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintLuxuryStardust(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // Deep obsidian royal aura
    final luxuryGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.6),
        radius: 1.3,
        colors: [
          accent.withValues(alpha: isDark ? 0.22 : 0.12),
          primary.withValues(alpha: isDark ? 0.14 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, luxuryGlow);

    // Golden stardust points
    final starPaint = Paint()..style = PaintingStyle.fill;
    final starCoordinates = [
      const Offset(0.15, 0.12),
      const Offset(0.35, 0.08),
      const Offset(0.68, 0.18),
      const Offset(0.85, 0.10),
      const Offset(0.20, 0.32),
      const Offset(0.55, 0.28),
      const Offset(0.88, 0.42),
      const Offset(0.12, 0.58),
      const Offset(0.42, 0.65),
      const Offset(0.75, 0.72),
      const Offset(0.28, 0.82),
      const Offset(0.62, 0.88),
      const Offset(0.92, 0.85),
    ];

    for (int i = 0; i < starCoordinates.length; i++) {
      final pos = Offset(
        starCoordinates[i].dx * size.width,
        starCoordinates[i].dy * size.height,
      );
      final isMajor = i % 3 == 0;
      final radius = isMajor ? 2.5 : 1.3;
      final starColor = (i % 2 == 0 ? accent : primary).withValues(
        alpha: isDark ? (isMajor ? 0.75 : 0.40) : (isMajor ? 0.50 : 0.25),
      );

      starPaint.color = starColor;
      canvas.drawCircle(pos, radius, starPaint);

      if (isMajor) {
        // Draw delicate 4-point sparkle cross
        final crossPaint = Paint()
          ..color = starColor.withValues(alpha: starColor.a * 0.6)
          ..strokeWidth = 0.8;
        canvas.drawLine(
          pos - const Offset(5, 0),
          pos + const Offset(5, 0),
          crossPaint,
        );
        canvas.drawLine(
          pos - const Offset(0, 5),
          pos + const Offset(0, 5),
          crossPaint,
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. Tonle Sap Floating Lantern River (Water Festival)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintLanternRiver(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // River water glow at lower screen
    final waterGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          primary.withValues(alpha: isDark ? 0.08 : 0.04),
          accent.withValues(alpha: isDark ? 0.20 : 0.10),
        ],
        stops: const [0.4, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, waterGlow);

    // Floating illuminated water lanterns
    final lanternCoords = [
      const Offset(0.18, 0.78),
      const Offset(0.42, 0.84),
      const Offset(0.68, 0.76),
      const Offset(0.85, 0.88),
      const Offset(0.30, 0.92),
      const Offset(0.55, 0.95),
      const Offset(0.78, 0.93),
      const Offset(0.12, 0.86),
    ];

    for (final coord in lanternCoords) {
      final pos = Offset(coord.dx * size.width, coord.dy * size.height);
      final lanternHalo = Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.55 : 0.35),
            primary.withValues(alpha: isDark ? 0.25 : 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: 24));
      canvas.drawCircle(pos, 24, lanternHalo);

      // Bright lantern core
      final corePaint = Paint()
        ..color = (isDark ? Colors.white : accent).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 2.8, corePaint);

      // Water reflection ripple
      final ripplePaint = Paint()
        ..color = accent.withValues(alpha: isDark ? 0.30 : 0.15)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        pos + const Offset(-8, 6),
        pos + const Offset(8, 6),
        ripplePaint,
      );
      canvas.drawLine(
        pos + const Offset(-4, 9),
        pos + const Offset(4, 9),
        ripplePaint,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. Sacred Lotus Candlelight (Pchum Ben)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintSacredLotus(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final aura = palette.auraColor;

    // Serene candlelight hearth glow from bottom
    final candleGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.85),
        radius: 1.1,
        colors: [
          aura.withValues(alpha: isDark ? 0.26 : 0.16),
          primary.withValues(alpha: isDark ? 0.12 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, candleGlow);

    // Ethereal rising lotus flower petals
    final lotusPaint = Paint()
      ..color = (isDark ? Colors.white : aura).withValues(
        alpha: isDark ? 0.08 : 0.05,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final centerX = size.width * 0.5;
    final baseY = size.height * 0.82;

    final path = Path()
      ..moveTo(centerX, baseY - 50)
      ..quadraticBezierTo(centerX - 40, baseY - 20, centerX, baseY)
      ..quadraticBezierTo(centerX + 40, baseY - 20, centerX, baseY - 50);

    canvas.drawPath(path, lotusPaint);

    final leftPetal = Path()
      ..moveTo(centerX - 15, baseY - 35)
      ..quadraticBezierTo(centerX - 55, baseY - 15, centerX - 10, baseY + 5);
    canvas.drawPath(leftPetal, lotusPaint);

    final rightPetal = Path()
      ..moveTo(centerX + 15, baseY - 35)
      ..quadraticBezierTo(centerX + 55, baseY - 15, centerX + 10, baseY + 5);
    canvas.drawPath(rightPetal, lotusPaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. Winter Constellation & Starlight (Christmas & Winter Wonderland)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintWinterConstellation(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // Winter twilight aura
    final winterAura = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.5, -0.7),
        radius: 1.2,
        colors: [
          accent.withValues(alpha: isDark ? 0.24 : 0.12),
          primary.withValues(alpha: isDark ? 0.15 : 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, winterAura);

    // Constellation lines & nodes
    final nodes = [
      Offset(size.width * 0.20, size.height * 0.15),
      Offset(size.width * 0.40, size.height * 0.12),
      Offset(size.width * 0.65, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.16),
      Offset(size.width * 0.50, size.height * 0.32),
      Offset(size.width * 0.32, size.height * 0.40),
    ];

    final linePaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(
        alpha: isDark ? 0.18 : 0.10,
      )
      ..strokeWidth = 0.9;

    for (int i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], linePaint);
    }
    canvas.drawLine(nodes[1], nodes[4], linePaint);

    final nodePaint = Paint()..style = PaintingStyle.fill;
    for (final node in nodes) {
      nodePaint.color = (isDark ? Colors.white : accent).withValues(
        alpha: isDark ? 0.70 : 0.45,
      );
      canvas.drawCircle(node, 2.4, nodePaint);

      nodePaint.color = accent.withValues(alpha: isDark ? 0.25 : 0.15);
      canvas.drawCircle(node, 6.0, nodePaint);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. Midnight Celebration Fireworks (New Year Celebration)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintFireworksGlitter(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    void drawBurst(Offset center, double radius, Color color) {
      final burstPaint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.28 : 0.15)
        ..strokeWidth = 1.0;

      const rays = 12;
      for (int i = 0; i < rays; i++) {
        final angle = (i * 2 * math.pi) / rays;
        final start = center + Offset(math.cos(angle) * 8, math.sin(angle) * 8);
        final end =
            center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        canvas.drawLine(start, end, burstPaint);

        // Glitter tip
        final tipPaint = Paint()
          ..color = color.withValues(alpha: isDark ? 0.65 : 0.40)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(end, 1.6, tipPaint);
      }
    }

    drawBurst(Offset(size.width * 0.80, size.height * 0.18), 38, accent);
    drawBurst(Offset(size.width * 0.22, size.height * 0.35), 28, primary);
    drawBurst(Offset(size.width * 0.70, size.height * 0.55), 32, accent);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. Jasmine Blossom Petals (Khmer New Year & Songkran)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintFestivePetals(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // Festive tropical sunshine warmth
    final sunGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.85),
        radius: 1.2,
        colors: [
          accent.withValues(alpha: isDark ? 0.26 : 0.15),
          primary.withValues(alpha: isDark ? 0.14 : 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, sunGlow);

    // Floating tropical jasmine petals
    final petalCoords = [
      const Offset(0.20, 0.18),
      const Offset(0.65, 0.12),
      const Offset(0.85, 0.28),
      const Offset(0.15, 0.45),
      const Offset(0.48, 0.55),
      const Offset(0.82, 0.68),
      const Offset(0.28, 0.80),
      const Offset(0.68, 0.88),
    ];

    final petalPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.22 : 0.14)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < petalCoords.length; i++) {
      final center = Offset(
        petalCoords[i].dx * size.width,
        petalCoords[i].dy * size.height,
      );
      final path = Path()
        ..moveTo(center.dx, center.dy - 8)
        ..quadraticBezierTo(center.dx + 6, center.dy, center.dx, center.dy + 8)
        ..quadraticBezierTo(center.dx - 6, center.dy, center.dx, center.dy - 8);
      canvas.drawPath(path, petalPaint);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 9. Romantic Rose Blush (Valentine's Day)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintRomanticPetals(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final roseNebula = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.1,
        colors: [
          accent.withValues(alpha: isDark ? 0.25 : 0.14),
          primary.withValues(alpha: isDark ? 0.15 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, roseNebula);

    // Soft heart & petal orbs
    final heartPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.18 : 0.10)
      ..style = PaintingStyle.fill;

    final heartPositions = [
      Offset(size.width * 0.25, size.height * 0.22),
      Offset(size.width * 0.78, size.height * 0.32),
      Offset(size.width * 0.35, size.height * 0.68),
      Offset(size.width * 0.82, size.height * 0.78),
    ];

    for (final pos in heartPositions) {
      canvas.drawCircle(pos, 8, heartPaint);
      canvas.drawCircle(pos + const Offset(10, 0), 8, heartPaint);
      final tri = Path()
        ..moveTo(pos.dx - 6, pos.dy + 3)
        ..lineTo(pos.dx + 16, pos.dy + 3)
        ..lineTo(pos.dx + 5, pos.dy + 15)
        ..close();
      canvas.drawPath(tri, heartPaint);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 10. Mystic Twilight Fog (Halloween Night)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintMysticFog(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final purpleMist = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.5),
        radius: 1.0,
        colors: [
          primary.withValues(alpha: isDark ? 0.28 : 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65],
      ).createShader(rect);
    canvas.drawRect(rect, purpleMist);

    final pumpkinGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, 0.4),
        radius: 0.9,
        colors: [
          accent.withValues(alpha: isDark ? 0.20 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6],
      ).createShader(rect);
    canvas.drawRect(rect, pumpkinGlow);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 11. Starlight Crescent & Arabesque (Ramadan Eid)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintCelestialCrescent(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // Indigo celestial sky
    final nightGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.75, -0.75),
        radius: 1.0,
        colors: [
          accent.withValues(alpha: isDark ? 0.25 : 0.14),
          primary.withValues(alpha: isDark ? 0.12 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, nightGlow);

    // Stylized Crescent Moon
    final moonCenter = Offset(size.width * 0.82, size.height * 0.14);
    final moonPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.45 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(moonCenter, 18, moonPaint);

    final maskColor = isDark ? palette.backgroundDark : palette.backgroundLight;
    final maskPaint = Paint()
      ..color = maskColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(moonCenter + const Offset(8, -4), 16, maskPaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 12. Auspicious Clouds & Red Lanterns (Lunar New Year)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintOrientalClouds(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final crimsonAura = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.7),
        radius: 1.1,
        colors: [
          primary.withValues(alpha: isDark ? 0.26 : 0.14),
          accent.withValues(alpha: isDark ? 0.14 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, crimsonAura);

    // Auspicious cloud swirl arcs
    final cloudPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.18 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void drawCloud(Offset pos) {
      final p = Path()
        ..moveTo(pos.dx - 20, pos.dy)
        ..arcToPoint(
          Offset(pos.dx - 5, pos.dy - 10),
          radius: const Radius.circular(10),
        )
        ..arcToPoint(
          Offset(pos.dx + 12, pos.dy - 8),
          radius: const Radius.circular(12),
        )
        ..arcToPoint(
          Offset(pos.dx + 25, pos.dy),
          radius: const Radius.circular(10),
        )
        ..lineTo(pos.dx - 20, pos.dy);
      canvas.drawPath(p, cloudPaint);
    }

    drawCloud(Offset(size.width * 0.25, size.height * 0.20));
    drawCloud(Offset(size.width * 0.75, size.height * 0.38));
    drawCloud(Offset(size.width * 0.30, size.height * 0.72));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 13. Turquoise Surf & Palm Shade (Summer Tropical)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintTropicalBreeze(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final oceanSurf = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: isDark ? 0.18 : 0.10),
          Colors.transparent,
          primary.withValues(alpha: isDark ? 0.22 : 0.12),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, oceanSurf);

    // Wave ripples at bottom
    final wavePaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.15 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final wavePath = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.84,
        size.width * 0.5,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.92,
        size.width,
        size.height * 0.88,
      );
    canvas.drawPath(wavePath, wavePaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 14. Sunlit Blossom Meadow (Easter Spring)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintSpringMeadow(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final springGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.8),
        radius: 1.2,
        colors: [
          accent.withValues(alpha: isDark ? 0.24 : 0.14),
          primary.withValues(alpha: isDark ? 0.14 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, springGlow);

    // Spring floral buds
    final budPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.20 : 0.12)
      ..style = PaintingStyle.fill;

    for (double i = 0.15; i <= 0.85; i += 0.22) {
      canvas.drawCircle(
        Offset(size.width * i, size.height * (0.3 + (i * 0.4))),
        4.0,
        budPaint,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 15. Forest Canopy Sunbeams (Nature Organic)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintForestCanopy(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final canopyGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, -0.9),
        radius: 1.1,
        colors: [
          accent.withValues(alpha: isDark ? 0.22 : 0.12),
          primary.withValues(alpha: isDark ? 0.16 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, canopyGlow);

    // Angled sunbeam light pillars
    final beamPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.06 : 0.04)
      ..style = PaintingStyle.fill;

    final beam = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.85, size.height)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(beam, beamPaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 16. Prismatic Glass Caustics (Glassmorphism)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintLiquidGlassPrism(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final prismGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.65),
        radius: 1.2,
        colors: [
          accent.withValues(alpha: isDark ? 0.28 : 0.16),
          primary.withValues(alpha: isDark ? 0.18 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, prismGlow);

    // Specular refraction glass streak
    final streakPaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(
        alpha: isDark ? 0.12 : 0.08,
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final streak = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.45,
        size.width,
        size.height * 0.38,
      );
    canvas.drawPath(streak, streakPaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 17. 80s Memphis Geometric Confetti (Retro Pop)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintRetroMemphis(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final retroGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.6),
        radius: 1.1,
        colors: [
          primary.withValues(alpha: isDark ? 0.22 : 0.12),
          accent.withValues(alpha: isDark ? 0.15 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, retroGlow);

    final glyphPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.20 : 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Mini triangles
    void drawTriangle(Offset pos) {
      final tri = Path()
        ..moveTo(pos.dx, pos.dy - 6)
        ..lineTo(pos.dx + 6, pos.dy + 6)
        ..lineTo(pos.dx - 6, pos.dy + 6)
        ..close();
      canvas.drawPath(tri, glyphPaint);
    }

    drawTriangle(Offset(size.width * 0.2, size.height * 0.25));
    drawTriangle(Offset(size.width * 0.8, size.height * 0.65));

    // Plus glyphs (+)
    void drawPlus(Offset pos) {
      canvas.drawLine(
        pos - const Offset(5, 0),
        pos + const Offset(5, 0),
        glyphPaint,
      );
      canvas.drawLine(
        pos - const Offset(0, 5),
        pos + const Offset(0, 5),
        glyphPaint,
      );
    }

    drawPlus(Offset(size.width * 0.75, size.height * 0.20));
    drawPlus(Offset(size.width * 0.25, size.height * 0.75));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 18. Botanical Aurora (Emerald Green)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintBotanicalAurora(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final auroraGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.8),
        radius: 1.2,
        colors: [
          accent.withValues(alpha: isDark ? 0.26 : 0.14),
          primary.withValues(alpha: isDark ? 0.16 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, auroraGlow);

    // Flowing sine wave curve
    final curvePaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.12 : 0.06)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final p = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.48,
        size.width,
        size.height * 0.42,
      );
    canvas.drawPath(p, curvePaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 19. Oceanic Cobalt Waves (Smalt Blue)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintOceanicWaves(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final oceanGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, 0.3),
        radius: 1.1,
        colors: [
          primary.withValues(alpha: isDark ? 0.24 : 0.14),
          accent.withValues(alpha: isDark ? 0.14 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, oceanGlow);

    // Liquid ocean wave bands
    final wavePaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.10 : 0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w1 = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.52,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(w1, wavePaint);

    final w2 = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.65,
        size.width,
        size.height * 0.72,
      );
    canvas.drawPath(w2, wavePaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 20. Architectural Studio Dot Matrix (Dark Premium, Minimal, Monochrome)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintArchitecturalMinimal(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;

    // Subtle edge vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [
          Colors.transparent,
          primary.withValues(alpha: isDark ? 0.08 : 0.03),
        ],
        stops: const [0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // Architectural 32px Dot Matrix
    final dotPaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.08 : 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    for (double y = spacing; y < size.height; y += spacing) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 21. Warm Hearth Glow (Warm Coral)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintWarmGlow(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    final hearth = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.75),
        radius: 1.15,
        colors: [
          primary.withValues(alpha: isDark ? 0.28 : 0.16),
          accent.withValues(alpha: isDark ? 0.16 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, hearth);

    final midWarmth = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, 0.35),
        radius: 0.95,
        colors: [
          accent.withValues(alpha: isDark ? 0.18 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect);
    canvas.drawRect(rect, midWarmth);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 22. Liquid Glass Mesh (Modern FoodGo / Default)
  // ──────────────────────────────────────────────────────────────────────────
  void _paintLiquidMesh(Canvas canvas, Size size, Rect rect) {
    final primary = palette.primary;
    final accent = palette.primaryAccent;

    // Top-Right Ambient Orb
    final topOrb = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.75),
        radius: 1.15,
        colors: [
          primary.withValues(alpha: isDark ? 0.28 : 0.14),
          accent.withValues(alpha: isDark ? 0.16 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, topOrb);

    // Mid-Left Ambient Orb
    final midOrb = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.95, 0.20),
        radius: 1.0,
        colors: [
          accent.withValues(alpha: isDark ? 0.20 : 0.10),
          primary.withValues(alpha: isDark ? 0.10 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, midOrb);

    // Bottom-Right Surface Depth Orb
    final bottomOrb = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, 0.95),
        radius: 1.0,
        colors: [
          primary.withValues(alpha: isDark ? 0.20 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55],
      ).createShader(rect);
    canvas.drawRect(rect, bottomOrb);

    // Subtle Specular Caustic Refraction Streak
    final causticPaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(
        alpha: isDark ? 0.05 : 0.03,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final causticPath = Path()
      ..moveTo(0, size.height * 0.42)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.38,
        size.width * 0.65,
        size.height * 0.46,
        size.width,
        size.height * 0.41,
      );
    canvas.drawPath(causticPath, causticPaint);
  }

  @override
  bool shouldRepaint(covariant ThemedSkinPainter oldDelegate) =>
      oldDelegate.palette.id != palette.id ||
      oldDelegate.isDark != isDark ||
      oldDelegate.palette.backdropStyle != palette.backdropStyle;
}
