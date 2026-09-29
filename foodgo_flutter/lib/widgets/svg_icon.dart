import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders the official FoodGo brand logo as a high-definition vector SVG.
class FoodGoLogo extends StatelessWidget {
  final double size;

  const FoodGoLogo({
    super.key,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/foodgo_logo.svg',
      width: size,
      height: size,
    );
  }
}

/// Helper widget to render custom vector SVGs from the assets/svg directory.
class SvgAssetIcon extends StatelessWidget {
  final String assetName;
  final double size;
  final Color? color;

  const SvgAssetIcon({
    super.key,
    required this.assetName,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/$assetName.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
