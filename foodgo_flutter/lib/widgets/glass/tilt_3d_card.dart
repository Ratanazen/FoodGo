import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// An interactive 3D perspective tilt container.
///
/// Features:
/// - Real 3D matrix transformation using [Matrix4] with depth perspective.
/// - Fluid touch/pan tracking that tilts the card toward finger movement.
/// - Physics spring-back animation to rest position when released.
/// - Subtle ambient idle floating rotation when untouched.
/// - Dynamic specular gloss shine that shifts with tilt angle.
/// - Fully respects system and in-app reduced motion preferences.
class Tilt3DCard extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle;
  final double perspective;
  final BorderRadius? borderRadius;
  final bool enableIdleAnimation;
  final bool enableGazeLight;

  const Tilt3DCard({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.08, // ~4.6 degrees
    this.perspective = 0.0012,
    this.borderRadius,
    this.enableIdleAnimation = true,
    this.enableGazeLight = true,
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard> with TickerProviderStateMixin {
  late final AnimationController _springController;
  late final AnimationController _idleController;

  double _rotX = 0.0;
  double _rotY = 0.0;
  double _startX = 0.0;
  double _startY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _springController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 380),
        )..addListener(() {
          setState(() {
            _rotX = _startX * (1.0 - _springController.value);
            _rotY = _startY * (1.0 - _springController.value);
          });
        });

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _springController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _springController.stop();
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = context.size ?? const Size(400, 600);
    final local = details.localPosition;

    final normX = ((local.dx - size.width / 2) / (size.width / 2)).clamp(
      -1.0,
      1.0,
    );
    final normY = ((local.dy - size.height / 2) / (size.height / 2)).clamp(
      -1.0,
      1.0,
    );

    setState(() {
      _rotY = normX * widget.maxTiltAngle;
      _rotX = -normY * widget.maxTiltAngle;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _startX = _rotX;
    _startY = _rotY;
    setState(() => _isDragging = false);
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.shouldReduceMotion(context);

    if (reduceMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, _) {
        final idleProgress = _idleController.value;
        final idleTiltY = widget.enableIdleAnimation && !_isDragging
            ? math.sin(idleProgress * 2 * math.pi) * 0.018
            : 0.0;
        final idleTiltX = widget.enableIdleAnimation && !_isDragging
            ? math.cos(idleProgress * 2 * math.pi) * 0.012
            : 0.0;

        final currentRotX = _rotX + idleTiltX;
        final currentRotY = _rotY + idleTiltY;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(currentRotX)
          ..rotateY(currentRotY);

        final lightAlignment = Alignment(
          (-currentRotY * 8).clamp(-1.0, 1.0),
          (currentRotX * 8).clamp(-1.0, 1.0),
        );

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: Transform(
            transform: transform,
            alignment: FractionalOffset.center,
            child: Stack(
              children: [
                widget.child,

                // Dynamic 3D specular sheen overlay
                if (widget.enableGazeLight)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              widget.borderRadius ?? BorderRadius.circular(24),
                          gradient: RadialGradient(
                            center: lightAlignment,
                            radius: 1.2,
                            colors: [
                              Colors.white.withValues(
                                alpha: _isDragging ? 0.08 : 0.04,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
