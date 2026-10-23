import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/glass_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Color? customColor;
  final Gradient? customGradient;
  final Border? customBorder;
  final List<BoxShadow>? customShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = GlassTheme.blurSigma,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.customColor,
    this.customGradient,
    this.customBorder,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark
        ? GlassTheme.glassDarkLight
        : GlassTheme.glassWhiteLight;
    final fallbackBorderColor = isDark
        ? GlassTheme.borderDark
        : GlassTheme.borderLight;

    final radius = borderRadius ?? GlassTheme.borderRadius;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: customShadow ?? [GlassTheme.softShadow],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: customGradient == null
                  ? (customColor ?? fallbackColor)
                  : null,
              gradient: customGradient,
              borderRadius: radius,
              border:
                  customBorder ??
                  Border.all(color: fallbackBorderColor, width: 1.1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A specialized Liquid Glass card with enhanced specular border highlights,
/// deep fluid refraction, and Smalt Blue ambient shadows.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(GlassTheme.radius);

    final widget = GlassContainer(
      blur: GlassTheme.liquidBlurSigma,
      borderRadius: effectiveRadius,
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      customGradient: isDark
          ? GlassTheme.liquidSurfaceDark
          : GlassTheme.liquidSurfaceLight,
      customBorder: Border.all(
        color: isDark ? GlassTheme.borderDark : GlassTheme.borderLight,
        width: 1.2,
      ),
      customShadow: [
        GlassTheme.liquidShadow,
        BoxShadow(
          color: (isDark ? GlassTheme.deepSmalt : GlassTheme.paleSmalt)
              .withValues(alpha: 0.15),
          blurRadius: 14,
          offset: const Offset(0, 2),
        ),
      ],
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: GlassTheme.royalSmalt.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: widget,
        ),
      );
    }

    return widget;
  }
}
