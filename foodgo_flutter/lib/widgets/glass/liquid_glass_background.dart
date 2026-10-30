import 'package:flutter/material.dart';

import 'themed_skin_backdrop.dart';

/// Atmospheric Themed Skin & Liquid Glass background that provides
/// ambient depth and distinct theme skin backdrops across all UI screens.
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ThemedSkinBackdrop(child: child);
  }
}
