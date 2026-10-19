import 'package:flutter/material.dart';

enum AuthIllustrationType {
  signIn,
  signUp,
  forgotPassword,
}

class AuthIllustration extends StatelessWidget {
  final AuthIllustrationType type;
  final double size;

  const AuthIllustration({
    super.key,
    required this.type,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _AuthIllustrationPainter(type: type),
        ),
      ),
    );
  }
}

class _AuthIllustrationPainter extends CustomPainter {
  final AuthIllustrationType type;

  _AuthIllustrationPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 140.0;

    canvas.save();
    canvas.scale(scale, scale);

    // Soft pastel background decorative circles
    final bgPaint = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(70, 70), 54, bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;

    final bluePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final lightSkinPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final barChartPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    switch (type) {
      case AuthIllustrationType.signIn:
        // Chart bars on the right
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(96, 75, 8, 22), const Radius.circular(2)), barChartPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(108, 62, 8, 35), const Radius.circular(2)), barChartPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(120, 50, 8, 47), const Radius.circular(2)), barChartPaint);

        // Little sparkle stars
        _drawSparkle(canvas, const Offset(112, 38), const Color(0xFFF59E0B));
        _drawSparkle(canvas, const Offset(36, 42), const Color(0xFF3B82F6));

        // Body / Blue Shirt
        final bodyPath = Path()
          ..moveTo(40, 115)
          ..quadraticBezierTo(42, 85, 68, 82)
          ..quadraticBezierTo(94, 85, 96, 115)
          ..close();
        canvas.drawPath(bodyPath, bluePaint);
        canvas.drawPath(bodyPath, linePaint);

        // Head / Face
        canvas.drawCircle(const Offset(68, 60), 16, lightSkinPaint);
        canvas.drawCircle(const Offset(68, 60), 16, linePaint);

        // Eye and smile
        final eyePaint = Paint()..color = const Color(0xFF1E293B);
        canvas.drawCircle(const Offset(72, 60), 2, eyePaint);
        final smilePath = Path()
          ..moveTo(70, 66)
          ..quadraticBezierTo(74, 69, 78, 66);
        canvas.drawPath(smilePath, linePaint);

        // Yellow Hair (Curled top)
        final hairPath = Path()
          ..moveTo(52, 58)
          ..cubicTo(48, 42, 62, 36, 74, 38)
          ..cubicTo(84, 40, 88, 50, 84, 58)
          ..cubicTo(80, 50, 72, 46, 64, 48)
          ..cubicTo(56, 50, 54, 54, 52, 58)
          ..close();
        canvas.drawPath(hairPath, yellowPaint);
        canvas.drawPath(hairPath, linePaint);

        // Phone held in hand
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(78, 70, 14, 26), const Radius.circular(3)), lightSkinPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(78, 70, 14, 26), const Radius.circular(3)), linePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(80, 72, 10, 18), const Radius.circular(2)), bluePaint);
        break;

      case AuthIllustrationType.signUp:
        // Floating checklist / app card icons
        final card1Paint = Paint()..color = const Color(0xFF60A5FA);
        final card2Paint = Paint()..color = const Color(0xFFF472B6);
        final card3Paint = Paint()..color = const Color(0xFF34D399);

        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(86, 26, 14, 14), const Radius.circular(3)), card1Paint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(86, 26, 14, 14), const Radius.circular(3)), linePaint);

        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 36, 12, 12), const Radius.circular(3)), card2Paint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 36, 12, 12), const Radius.circular(3)), linePaint);

        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 18, 10, 10), const Radius.circular(2)), card3Paint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 18, 10, 10), const Radius.circular(2)), linePaint);

        // Body / Yellow Shirt
        final signUpBodyPath = Path()
          ..moveTo(42, 115)
          ..quadraticBezierTo(46, 85, 70, 84)
          ..quadraticBezierTo(94, 85, 98, 115)
          ..close();
        canvas.drawPath(signUpBodyPath, yellowPaint);
        canvas.drawPath(signUpBodyPath, linePaint);

        // Document board held
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 78, 20, 28), const Radius.circular(4)), whitePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 78, 20, 28), const Radius.circular(4)), linePaint);
        canvas.drawLine(const Offset(66, 84), const Offset(76, 84), linePaint);
        canvas.drawLine(const Offset(66, 89), const Offset(78, 89), linePaint);
        canvas.drawLine(const Offset(66, 94), const Offset(74, 94), linePaint);

        // Head / Face
        canvas.drawCircle(const Offset(70, 62), 15, lightSkinPaint);
        canvas.drawCircle(const Offset(70, 62), 15, linePaint);

        // Blue Hair (Wavy / flowy)
        final blueHairPath = Path()
          ..moveTo(54, 60)
          ..cubicTo(50, 44, 64, 38, 76, 40)
          ..cubicTo(90, 42, 94, 55, 88, 64)
          ..cubicTo(94, 72, 88, 80, 80, 78)
          ..cubicTo(82, 68, 74, 52, 66, 52)
          ..cubicTo(58, 52, 56, 56, 54, 60)
          ..close();
        canvas.drawPath(blueHairPath, bluePaint);
        canvas.drawPath(blueHairPath, linePaint);
        break;

      case AuthIllustrationType.forgotPassword:
        // Laptop
        final laptopBase = Path()
          ..moveTo(52, 108)
          ..lineTo(98, 108)
          ..lineTo(94, 112)
          ..lineTo(56, 112)
          ..close();
        canvas.drawPath(laptopBase, whitePaint);
        canvas.drawPath(laptopBase, linePaint);

        final laptopScreen = Path()
          ..moveTo(56, 108)
          ..lineTo(64, 88)
          ..lineTo(90, 88)
          ..lineTo(94, 108)
          ..close();
        canvas.drawPath(laptopScreen, whitePaint);
        canvas.drawPath(laptopScreen, linePaint);

        // Body / Yellow Sweater
        final fpBodyPath = Path()
          ..moveTo(48, 115)
          ..quadraticBezierTo(52, 86, 75, 84)
          ..quadraticBezierTo(98, 86, 102, 115)
          ..close();
        canvas.drawPath(fpBodyPath, yellowPaint);
        canvas.drawPath(fpBodyPath, linePaint);

        // Head / Face
        canvas.drawCircle(const Offset(75, 62), 14, lightSkinPaint);
        canvas.drawCircle(const Offset(75, 62), 14, linePaint);

        // Dark Bun Hair
        final darkHairPaint = Paint()..color = const Color(0xFF1E293B);
        canvas.drawCircle(const Offset(75, 42), 8, darkHairPaint);
        canvas.drawCircle(const Offset(75, 42), 8, linePaint);

        final hairBack = Path()
          ..moveTo(63, 62)
          ..cubicTo(60, 48, 72, 46, 80, 47)
          ..cubicTo(88, 48, 90, 58, 86, 64)
          ..cubicTo(80, 54, 70, 52, 63, 62)
          ..close();
        canvas.drawPath(hairBack, darkHairPaint);
        canvas.drawPath(hairBack, linePaint);

        // Glasses on Face
        canvas.drawCircle(const Offset(73, 62), 4, linePaint);
        canvas.drawCircle(const Offset(81, 62), 4, linePaint);
        canvas.drawLine(const Offset(77, 62), const Offset(77, 62), linePaint);
        break;
    }

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset offset, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(offset.dx - 4, offset.dy), Offset(offset.dx + 4, offset.dy), p);
    canvas.drawLine(Offset(offset.dx, offset.dy - 4), Offset(offset.dx, offset.dy + 4), p);
  }

  @override
  bool shouldRepaint(covariant _AuthIllustrationPainter oldDelegate) =>
      oldDelegate.type != type;
}
