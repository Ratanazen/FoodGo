import 'package:flutter/material.dart';
import '../core/theme/glass_theme.dart';

enum VectorIllustrationType {
  emptyCart,
  emptyOrders,
  noSearchResults,
  networkOffline,
  orderSuccess,
}

/// High-performance offline vector illustration widget rendered via [CustomPainter].
/// Guarantees instant 60/120fps display without remote network or Lottie CDN dependencies.
class VectorIllustration extends StatelessWidget {
  final VectorIllustrationType type;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const VectorIllustration({
    super.key,
    required this.type,
    this.size = 160.0,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = primaryColor ?? GlassTheme.dynamicPrimaryColor;
    final secondary = secondaryColor ?? (isDark ? Colors.white70 : const Color(0xFF475569));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _VectorIllustrationPainter(
          type: type,
          primaryColor: primary,
          secondaryColor: secondary,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _VectorIllustrationPainter extends CustomPainter {
  final VectorIllustrationType type;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _VectorIllustrationPainter({
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 160.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Subtle ambient background halo
    final haloPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.08 : 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(80, 80), 65, haloPaint);

    switch (type) {
      case VectorIllustrationType.emptyCart:
        _paintEmptyCart(canvas);
        break;
      case VectorIllustrationType.emptyOrders:
        _paintEmptyOrders(canvas);
        break;
      case VectorIllustrationType.noSearchResults:
        _paintNoSearchResults(canvas);
        break;
      case VectorIllustrationType.networkOffline:
        _paintNetworkOffline(canvas);
        break;
      case VectorIllustrationType.orderSuccess:
        _paintOrderSuccess(canvas);
        break;
    }

    canvas.restore();
  }

  void _paintEmptyCart(Canvas canvas) {
    final strokePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final primaryStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Basket body trapezoid
    final basketPath = Path()
      ..moveTo(45, 65)
      ..lineTo(115, 65)
      ..lineTo(105, 115)
      ..lineTo(55, 115)
      ..close();
    canvas.drawPath(basketPath, fillPaint);
    canvas.drawPath(basketPath, strokePaint);

    // Basket grid lines
    canvas.drawLine(const Offset(65, 65), const Offset(70, 115), strokePaint);
    canvas.drawLine(const Offset(95, 65), const Offset(90, 115), strokePaint);
    canvas.drawLine(const Offset(50, 90), const Offset(110, 90), strokePaint);

    // Basket handles
    final handlePath = Path()
      ..moveTo(55, 65)
      ..cubicTo(60, 35, 100, 35, 105, 65);
    canvas.drawPath(handlePath, primaryStroke);

    // Floating organic apple / tomato at top
    final fruitPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(80, 52), 12, fruitPaint);

    // Leaf on fruit
    final leafPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    final leafPath = Path()
      ..moveTo(80, 42)
      ..quadraticBezierTo(86, 36, 88, 38)
      ..quadraticBezierTo(84, 42, 80, 42);
    canvas.drawPath(leafPath, leafPaint);

    // Shadow below basket
    final shadowPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(50, 122, 60, 8), shadowPaint);
  }

  void _paintEmptyOrders(Canvas canvas) {
    final strokePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Clipboard body
    final clipRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 45, 60, 80),
      const Radius.circular(8),
    );
    canvas.drawRRect(clipRect, fillPaint);
    canvas.drawRRect(clipRect, strokePaint);

    // Clip top
    final clipTop = RRect.fromRectAndRadius(
      const Rect.fromLTWH(65, 38, 30, 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(clipTop, Paint()..color = primaryColor..style = PaintingStyle.fill);

    // Receipt text lines
    final linePaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(62, 65), const Offset(98, 65), linePaint);
    canvas.drawLine(const Offset(62, 77), const Offset(90, 77), linePaint);
    canvas.drawLine(const Offset(62, 89), const Offset(95, 89), linePaint);

    // Small clock circle in bottom corner
    final clockBg = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(105, 115), 14, clockBg);

    final clockHands = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(105, 115), const Offset(105, 107), clockHands);
    canvas.drawLine(const Offset(105, 115), const Offset(111, 115), clockHands);
  }

  void _paintNoSearchResults(Canvas canvas) {
    final primaryStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final secondaryStroke = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final bowlFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Noodle bowl outline
    final bowlPath = Path()
      ..moveTo(40, 85)
      ..lineTo(100, 85)
      ..cubicTo(95, 115, 45, 115, 40, 85)
      ..close();
    canvas.drawPath(bowlPath, bowlFill);
    canvas.drawPath(bowlPath, secondaryStroke);

    // Steam waves above bowl
    final steamPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final steam1 = Path()
      ..moveTo(55, 78)
      ..quadraticBezierTo(58, 70, 55, 62);
    final steam2 = Path()
      ..moveTo(70, 78)
      ..quadraticBezierTo(73, 68, 70, 58);
    final steam3 = Path()
      ..moveTo(85, 78)
      ..quadraticBezierTo(88, 70, 85, 62);
    canvas.drawPath(steam1, steamPaint);
    canvas.drawPath(steam2, steamPaint);
    canvas.drawPath(steam3, steamPaint);

    // Magnifying glass over the scene
    final lensFill = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.15 : 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(100, 60), 22, lensFill);
    canvas.drawCircle(const Offset(100, 60), 22, primaryStroke);

    // Magnifying glass handle
    canvas.drawLine(const Offset(116, 76), const Offset(132, 92), Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round);
  }

  void _paintNetworkOffline(Canvas canvas) {
    final strokePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cloudFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Cloud silhouette
    final cloud = Path()
      ..moveTo(50, 90)
      ..lineTo(110, 90)
      ..cubicTo(120, 90, 125, 80, 120, 70)
      ..cubicTo(120, 58, 105, 52, 98, 56)
      ..cubicTo(94, 42, 70, 42, 64, 56)
      ..cubicTo(55, 54, 42, 65, 45, 76)
      ..cubicTo(40, 82, 44, 90, 50, 90)
      ..close();
    canvas.drawPath(cloud, cloudFill);
    canvas.drawPath(cloud, strokePaint);

    // Lightning strike slash through cloud
    final slashPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(45, 45), const Offset(115, 115), slashPaint);

    // Small exclamation pill
    final alertBg = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(80, 105), 12, alertBg);

    final alertExclaim = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(80, 99), const Offset(80, 106), alertExclaim);
    canvas.drawCircle(const Offset(80, 110), 1.2, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  void _paintOrderSuccess(Canvas canvas) {
    final primaryFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final primaryStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Circle shield
    canvas.drawCircle(const Offset(80, 80), 45, primaryFill);
    canvas.drawCircle(const Offset(80, 80), 45, primaryStroke);

    // Big green checkmark
    final checkPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(62, 80)
      ..lineTo(74, 92)
      ..lineTo(98, 68);
    canvas.drawPath(checkPath, checkPaint);

    // Confetti particles around
    final confetti1 = Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.fill;
    final confetti2 = Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.fill;
    final confetti3 = Paint()..color = const Color(0xFFEC4899)..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(42, 45), 3, confetti1);
    canvas.drawCircle(const Offset(120, 48), 3.5, confetti2);
    canvas.drawCircle(const Offset(128, 98), 2.8, confetti3);
    canvas.drawCircle(const Offset(35, 105), 3.2, confetti2);
  }

  @override
  bool shouldRepaint(covariant _VectorIllustrationPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}
