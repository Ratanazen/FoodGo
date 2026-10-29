import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/glass_theme.dart';
import 'svg_icon.dart';

/// Full-screen modern glass loading screen for page-level data fetching.
class FoodGoLoadingScreen extends StatefulWidget {
  final String title;
  final String message;

  const FoodGoLoadingScreen({
    super.key,
    this.title = 'Loading FoodGo...',
    this.message = 'Fetching fresh organic meals & healthy options',
  });

  @override
  State<FoodGoLoadingScreen> createState() => _FoodGoLoadingScreenState();
}

class _FoodGoLoadingScreenState extends State<FoodGoLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = GlassTheme.activePalette;

    return Scaffold(
      backgroundColor: isDark ? palette.backgroundDark : palette.backgroundLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient glowing orbs with controlled controller
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Transform.scale(
                scale: 2.0 - _pulseAnimation.value,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlassTheme.dynamicPrimaryDark.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing pulsating logo card
                  AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.dynamicPrimaryColor.withValues(
                              alpha: 0.35 * _pulseAnimation.value,
                            ),
                            blurRadius: 36 * _pulseAnimation.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const FoodGoAppIcon(size: 72, borderRadius: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ).animate().fade(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Pulsing Emerald Loading Ring
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      GlassTheme.dynamicPrimaryColor,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ).animate().fade(delay: 300.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

/// A frosted glass overlay widget that dims and blurs background during processing.
class FoodGoLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const FoodGoLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: GlassTheme.dynamicSurfaceDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.15),
                          ),
                          child: const FoodGoAppIcon(size: 48, borderRadius: 12),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              GlassTheme.dynamicPrimaryColor,
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        if (message != null && message!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
