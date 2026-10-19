import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/glass_theme.dart';

/// Centralized manager for Lottie animations with graceful offline/loading fallback.
class LottieAsset extends StatelessWidget {
  final String url;
  final double size;
  final bool repeat;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  const LottieAsset({
    super.key,
    required this.url,
    this.size = 120.0,
    this.repeat = true,
    this.fallbackIcon = Icons.animation,
    this.fallbackColor,
  });

  /// 🏍️ Animated delivery motorcycle for map & tracking
  factory LottieAsset.deliveryBike({double size = 140.0, bool repeat = true}) {
    return LottieAsset(
      url: 'https://assets5.lottiefiles.com/packages/lf20_j1adxtyb.json',
      size: size,
      repeat: repeat,
      fallbackIcon: Icons.moped,
      fallbackColor: GlassTheme.primaryGreen,
    );
  }

  /// 🍳 Cooking / food preparation animation
  factory LottieAsset.cooking({double size = 120.0, bool repeat = true}) {
    return LottieAsset(
      url: 'https://assets4.lottiefiles.com/packages/lf20_x2wv18tb.json',
      size: size,
      repeat: repeat,
      fallbackIcon: Icons.outdoor_grill,
      fallbackColor: GlassTheme.accentOrange,
    );
  }

  /// ✅ Verified order success checkmark
  factory LottieAsset.success({double size = 130.0, bool repeat = false}) {
    return LottieAsset(
      url: 'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
      size: size,
      repeat: repeat,
      fallbackIcon: Icons.check_circle_rounded,
      fallbackColor: GlassTheme.primaryGreen,
    );
  }

  /// 📦 Empty box animation for empty carts and no orders
  factory LottieAsset.emptyBox({double size = 160.0, bool repeat = true}) {
    return LottieAsset(
      url: 'https://assets10.lottiefiles.com/packages/lf20_mz991f8p.json',
      size: size,
      repeat: repeat,
      fallbackIcon: Icons.remove_shopping_cart_outlined,
      fallbackColor: GlassTheme.textMuted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.network(
        url,
        repeat: repeat,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              fallbackIcon,
              size: size * 0.5,
              color: fallbackColor ?? GlassTheme.primaryGreen,
            ),
          );
        },
        frameBuilder: (context, child, composition) {
          if (composition == null) {
            return Center(
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fallbackColor ?? GlassTheme.primaryGreen,
                ),
              ),
            );
          }
          return child;
        },
      ),
    );
  }
}
