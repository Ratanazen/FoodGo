import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A universal, springy micro-interaction wrapper that provides smooth
/// scale-down on press, spring bounce on release, web hover states,
/// and tactile haptic feedback.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final double hoverScale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const AnimatedPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.hoverScale = 1.02,
    this.duration = const Duration(milliseconds: 140),
    this.curve = Curves.easeOutCubic,
    this.enableHaptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller.duration = reduceMotion ? Duration.zero : widget.duration;
  }

  @override
  void didUpdateWidget(covariant AnimatedPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      _controller.duration = reduceMotion ? Duration.zero : widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    _controller.reverse();
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null || widget.onLongPress != null;

    Widget childWidget = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final currentScale =
            _isHovered && !_controller.isAnimating && _controller.value == 0
            ? widget.hoverScale
            : _scaleAnimation.value;
        return Transform.scale(
          scale: currentScale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );

    if (kIsWeb) {
      childWidget = MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (isInteractive && mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (isInteractive && mounted) setState(() => _isHovered = false);
        },
        child: childWidget,
      );
    }

    if (!isInteractive) return childWidget;

    final focusColor = Theme.of(context).colorScheme.primary;
    Widget interactiveChild = GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress,
      child: childWidget,
    );

    if (_isFocused) {
      interactiveChild = Container(
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: focusColor, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: interactiveChild,
      );
    }

    return Semantics(
      button: true,
      enabled: true,
      child: FocusableActionDetector(
        enabled: true,
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (focused) {
          if (mounted && _isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: interactiveChild,
      ),
    );
  }
}

/// A beautifully styled icon button with frosted glass backdrop, crisp specular
/// border, spring press feedback, and optional badge or notification indicator.
class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? badge;
  final String? tooltip;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final bool isLoading;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.iconColor,
    this.borderColor,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.margin,
    this.padding,
    this.badge,
    this.tooltip,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.85);
    final fallbackBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);
    final fallbackIconColor = isDark ? Colors.white : const Color(0xFF1A2653);

    final effectiveRadius =
        borderRadius ??
        (shape == BoxShape.circle
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(14));

    Widget buttonContent = Container(
      margin: margin,
      width: size,
      height: size,
      padding: padding ?? const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color ?? fallbackBg,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? effectiveRadius : null,
        border: Border.all(color: borderColor ?? fallbackBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isLoading)
            SizedBox(
              width: iconSize * 0.8,
              height: iconSize * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor ?? fallbackIconColor,
              ),
            )
          else
            Icon(icon, size: iconSize, color: iconColor ?? fallbackIconColor),
          if (badge != null) Positioned(top: -2, right: -2, child: badge!),
        ],
      ),
    );

    if (tooltip != null) {
      buttonContent = Tooltip(message: tooltip!, child: buttonContent);
    }

    return AnimatedPressable(onTap: onPressed, child: buttonContent);
  }
}
