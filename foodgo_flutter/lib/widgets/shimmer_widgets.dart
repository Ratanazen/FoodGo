import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/glass_theme.dart';

/// Theme-aware shimmer wrapper that applies dark or light skeleton tones,
/// gracefully respecting reduced-motion accessibility settings.
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.shouldReduceMotion(context)) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? GlassTheme.dynamicShimmerBaseDark
          : GlassTheme.shimmerBaseLight,
      highlightColor: isDark
          ? GlassTheme.dynamicShimmerHighlightDark
          : GlassTheme.shimmerHighlightLight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A generic rounded placeholder box for shimmer loading.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: shape != null
          ? ShapeDecoration(shape: shape!, color: Colors.white)
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
    );
  }
}

/// Skeleton placeholder for [FoodDeliveryCard].
class ShimmerFoodCard extends StatelessWidget {
  final bool isHorizontal;

  const ShimmerFoodCard({super.key, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    final width = isHorizontal ? 260.0 : double.infinity;
    final imageHeight = isHorizontal ? 130.0 : 155.0;

    return ShimmerWrapper(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image banner skeleton
            ShimmerBox(
              width: double.infinity,
              height: imageHeight,
              borderRadius: 18,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 130, height: 16, borderRadius: 6),
                      ShimmerBox(width: 40, height: 16, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 170, height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 80, height: 12, borderRadius: 4),
                      ShimmerBox(width: 60, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for the circular category row.
class ShimmerCategoryRow extends StatelessWidget {
  const ShimmerCategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Column(
                children: const [
                  ShimmerBox(width: 56, height: 56, borderRadius: 28),
                  SizedBox(height: 8),
                  ShimmerBox(width: 44, height: 10, borderRadius: 4),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton placeholder for promotional banners.
class ShimmerPromoBanner extends StatelessWidget {
  const ShimmerPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        width: 300,
        height: 140,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Skeleton placeholder for order cards in [OrdersScreen].
class ShimmerOrderCard extends StatelessWidget {
  const ShimmerOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 120, height: 18, borderRadius: 6),
                ShimmerBox(width: 70, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerBox(width: 200, height: 14, borderRadius: 4),
            const SizedBox(height: 8),
            const ShimmerBox(width: 150, height: 12, borderRadius: 4),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 80, height: 18, borderRadius: 6),
                ShimmerBox(width: 100, height: 36, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for restaurant detail screen header.
class ShimmerDetailHeader extends StatelessWidget {
  const ShimmerDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: double.infinity, height: 220, borderRadius: 0),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: 180, height: 24, borderRadius: 6),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: 240, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
