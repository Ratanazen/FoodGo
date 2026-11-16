import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_spacing.dart';

/// Shimmer skeleton placeholder that automatically adapts to light and dark theme brightness.
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  /// Rectangular skeleton block with customizable corner radius.
  factory SkeletonLoader.rectangular({
    Key? key,
    double width = double.infinity,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm),
    );
  }

  /// Circular skeleton block for user avatars or circular badges.
  factory SkeletonLoader.circular({Key? key, required double diameter}) {
    return SkeletonLoader(
      key: key,
      width: diameter,
      height: diameter,
      shape: BoxShape.circle,
    );
  }

  /// Text line placeholder skeleton.
  factory SkeletonLoader.text({
    Key? key,
    double width = double.infinity,
    double height = 14.0,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4.0),
    );
  }

  /// Full card placeholder skeleton matching the 16px radius design token.
  factory SkeletonLoader.card({
    Key? key,
    double width = double.infinity,
    double height = 120.0,
  }) {
    return SkeletonLoader(
      key: key,
      width: width,
      height: height,
      borderRadius: AppSpacing.roundedCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : borderRadius,
        ),
      ),
    );
  }
}
