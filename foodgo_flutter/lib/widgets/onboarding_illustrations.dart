import 'package:flutter/material.dart';
import '../core/theme/glass_theme.dart';

enum OnboardingScene { culinaryDiscovery, liveDelivery, securePayments }

/// Custom vector illustration painter for high-resolution, offline-capable Onboarding scenes.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingScene scene;
  final double width;
  final double height;
  final Color? primaryColor;
  final Color? accentColor;

  const OnboardingIllustration({
    super.key,
    required this.scene,
    this.width = 280.0,
    this.height = 200.0,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = primaryColor ?? GlassTheme.dynamicPrimaryColor;
    final accent =
        accentColor ??
        (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _OnboardingPainter(
          scene: scene,
          primaryColor: primary,
          accentColor: accent,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _OnboardingPainter extends CustomPainter {
  final OnboardingScene scene;
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;

  _OnboardingPainter({
    required this.scene,
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 280.0;
    final scaleY = size.height / 200.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
    canvas.translate(
      (size.width - 280.0 * scale) / 2,
      (size.height - 200.0 * scale) / 2,
    );
    canvas.scale(scale, scale);

    // Decorative backdrop halo
    final haloPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.10 : 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(140, 100), 85, haloPaint);

    final secondaryHalo = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(180, 80), 55, secondaryHalo);

    switch (scene) {
      case OnboardingScene.culinaryDiscovery:
        _paintCulinaryDiscovery(canvas);
        break;
      case OnboardingScene.liveDelivery:
        _paintLiveDelivery(canvas);
        break;
      case OnboardingScene.securePayments:
        _paintSecurePayments(canvas);
        break;
    }

    canvas.restore();
  }

  void _paintCulinaryDiscovery(Canvas canvas) {
    final outlinePaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final primaryFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Organic Bowl
    final bowlPath = Path()
      ..moveTo(60, 110)
      ..lineTo(220, 110)
      ..cubicTo(210, 165, 70, 165, 60, 110)
      ..close();
    canvas.drawPath(bowlPath, primaryFill);
    canvas.drawPath(bowlPath, outlinePaint);

    // Salad / Greens inside bowl
    final greensPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(105, 105), 18, greensPaint);
    canvas.drawCircle(const Offset(140, 100), 22, greensPaint);
    canvas.drawCircle(const Offset(175, 105), 18, greensPaint);

    // Sliced Tomato / Avocado
    final tomatoPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(120, 95), 10, tomatoPaint);
    final avoPaint = Paint()
      ..color = const Color(0xFF84CC16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(160, 95), 12, avoPaint);

    // Chopsticks / Fork angled
    final forkPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(190, 60), const Offset(150, 115), forkPaint);
    canvas.drawLine(const Offset(205, 65), const Offset(165, 120), forkPaint);

    // Steaming culinary aroma waves
    final aromaPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final aroma1 = Path()
      ..moveTo(110, 80)
      ..quadraticBezierTo(115, 65, 110, 50);
    final aroma2 = Path()
      ..moveTo(140, 75)
      ..quadraticBezierTo(145, 60, 140, 45);
    canvas.drawPath(aroma1, aromaPaint);
    canvas.drawPath(aroma2, aromaPaint);

    // Floating spices / sesame seeds
    final seedPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(85, 80), 2.5, seedPaint);
    canvas.drawCircle(const Offset(130, 40), 3.0, seedPaint);
    canvas.drawCircle(const Offset(195, 45), 2.8, seedPaint);
  }

  void _paintLiveDelivery(Canvas canvas) {
    final outlinePaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Road dashed line
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white30 : Colors.black26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, 155), const Offset(240, 155), roadPaint);

    // Wheels of scooter
    final wheelPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.87)
          : const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(const Offset(95, 145), 18, wheelPaint);
    canvas.drawCircle(const Offset(185, 145), 18, wheelPaint);

    // Inner wheel hub
    canvas.drawCircle(const Offset(95, 145), 6, primaryPaint);
    canvas.drawCircle(const Offset(185, 145), 6, primaryPaint);

    // Scooter chassis / frame
    final frame = Path()
      ..moveTo(95, 145)
      ..lineTo(135, 145)
      ..lineTo(145, 115)
      ..lineTo(175, 115)
      ..lineTo(185, 145);
    canvas.drawPath(frame, outlinePaint);

    // Scooter front handlebar
    final handlebar = Path()
      ..moveTo(175, 115)
      ..lineTo(165, 80)
      ..lineTo(155, 80);
    canvas.drawPath(handlebar, outlinePaint);

    // Thermal Delivery Bag on rear rack
    final bagRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(100, 85, 40, 40),
      const Radius.circular(6),
    );
    canvas.drawRRect(bagRect, primaryPaint);
    canvas.drawRRect(bagRect, outlinePaint);

    // FoodGo bag emblem
    canvas.drawCircle(
      const Offset(120, 105),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Wind motion streaks
    final windPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(55, 95), const Offset(85, 95), windPaint);
    canvas.drawLine(const Offset(45, 110), const Offset(80, 110), windPaint);

    // GPS Location Pin in top right
    final pinPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final pinPath = Path()
      ..moveTo(220, 55)
      ..cubicTo(205, 55, 205, 75, 220, 95)
      ..cubicTo(235, 75, 235, 55, 220, 55)
      ..close();
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(
      const Offset(220, 68),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  void _paintSecurePayments(Canvas canvas) {
    final outlinePaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shieldFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    // Security Shield
    final shield = Path()
      ..moveTo(140, 40)
      ..lineTo(195, 60)
      ..cubicTo(195, 115, 140, 155, 140, 160)
      ..cubicTo(140, 155, 85, 115, 85, 60)
      ..close();
    canvas.drawPath(shield, shieldFill);
    canvas.drawPath(shield, outlinePaint);

    // KHQR / Bank code pattern grid inside shield
    final qrPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    // Corner squares
    canvas.drawRect(const Rect.fromLTWH(105, 75, 18, 18), qrPaint);
    canvas.drawRect(const Rect.fromLTWH(157, 75, 18, 18), qrPaint);
    canvas.drawRect(const Rect.fromLTWH(105, 110, 18, 18), qrPaint);
    // Inner holes
    canvas.drawRect(
      const Rect.fromLTWH(110, 80, 8, 8),
      Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(162, 80, 8, 8),
      Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(110, 115, 8, 8),
      Paint()..color = isDark ? const Color(0xFF0F172A) : Colors.white,
    );

    // Center check badge
    final badgePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(140, 102), 16, badgePaint);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(133, 102)
      ..lineTo(138, 107)
      ..lineTo(147, 96);
    canvas.drawPath(checkPath, checkPaint);

    // Currency Badges (USD & KHR) floating
    final badgeUsd = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(65, 85), 18, badgeUsd);
    final textPainterUsd = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterUsd.paint(canvas, const Offset(59, 74));

    final badgeKhr = Paint()
      ..color = const Color(0xFFEAB308)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(215, 115), 18, badgeKhr);
    final textPainterKhr = TextPainter(
      text: const TextSpan(
        text: '៛',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterKhr.paint(canvas, const Offset(209, 103));
  }

  @override
  bool shouldRepaint(covariant _OnboardingPainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
