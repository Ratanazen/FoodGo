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
  final Border? customBorder;

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
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark ? GlassTheme.glassDarkLight : GlassTheme.glassWhiteLight;
    final fallbackBorderColor = isDark ? GlassTheme.borderDark : GlassTheme.borderLight;
    
    final radius = borderRadius ?? GlassTheme.borderRadius;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [GlassTheme.softShadow],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: customColor ?? fallbackColor,
              borderRadius: radius,
              border: customBorder ?? Border.all(
                color: fallbackBorderColor,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
