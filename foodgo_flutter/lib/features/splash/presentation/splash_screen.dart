import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../widgets/svg_icon.dart';

/// Highly-polished, modern Healthy & Organic FoodGo Splash & Loading Screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1. Progress animation (0.0 to 1.0 across 2.2 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 2. Continuous ambient breathing pulse for the hero brand icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _progressController.forward();

    // 3. Navigation after loading finishes with timeout and error resilience
    _navigationTimer = Timer(const Duration(milliseconds: 2450), () async {
      if (!mounted) return;
      try {
        final auth = context.read<AuthProvider>();
        final userProvider = context.read<UserProvider>();
        final isAuth = await auth.checkAuth().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
        if (!mounted) return;
        if (isAuth) {
          try {
            await userProvider.fetchUser().timeout(
              const Duration(seconds: 3),
              onTimeout: () {},
            );
          } catch (e) {
            debugPrint('Splash user fetch error: $e');
          }
          if (!mounted) return;
          final role = userProvider.user?['role']?.toString().toLowerCase();
          if (role == 'admin') {
            context.go('/admin-dashboard');
          } else if (role == 'driver') {
            context.go('/driver-dashboard');
          } else if (role == 'restaurant_owner') {
            context.go('/restaurant-dashboard');
          } else {
            context.go('/home');
          }
        } else {
          context.go('/login');
        }
      } catch (e) {
        debugPrint('Splash navigation fallback error: $e');
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getStatusText(double progress) {
    if (progress < 0.28) {
      return 'Preparing fresh organic kitchen...';
    } else if (progress < 0.60) {
      return 'Loading healthy farm-to-table dishes...';
    } else if (progress < 0.88) {
      return 'Connecting Bakong KHQR & fast delivery...';
    } else {
      return 'Welcome to FoodGo! Ready to serve.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = GlassTheme.activePalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? palette.backgroundDark : const Color(0xFF0B1710),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient Background Glow Orbs ────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.28),
                        GlassTheme.dynamicPrimaryDark.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -90,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => Transform.scale(
                scale: 2.0 - _pulseAnimation.value,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        GlassTheme.dynamicPrimaryDark.withValues(alpha: 0.25),
                        palette.primaryAccent.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Center Content (Overflow-safe and responsive) ───────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // 1. Hero Brand App Icon with Breathing Glow
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) {
                              return Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GlassTheme.dynamicPrimaryColor.withValues(
                                        alpha: 0.35 * _pulseAnimation.value,
                                      ),
                                      blurRadius: 40 * _pulseAnimation.value,
                                      spreadRadius: 3 * _pulseAnimation.value,
                                    ),
                                    BoxShadow(
                                      color: GlassTheme.dynamicPrimaryDark.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const FoodGoAppIcon(
                                  size: 96,
                                  borderRadius: 24,
                                ),
                              );
                            },
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.7, 0.7),
                                end: const Offset(1.0, 1.0),
                                duration: 750.ms,
                                curve: Curves.easeOutBack,
                              )
                              .fade(duration: 500.ms),

                          const SizedBox(height: 28),

                          // 2. Organic Fresh Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: GlassTheme.dynamicPrimaryColor.withValues(alpha: 0.38),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  palette.isFestive ? palette.icon : Icons.eco_rounded,
                                  size: 14,
                                  color: GlassTheme.dynamicPrimaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  palette.isFestive && palette.badgeText.isNotEmpty
                                      ? '100% FRESH & ORGANIC • ${palette.badgeText}'
                                      : '100% FRESH & ORGANIC',
                                  style: TextStyle(
                                    color: GlassTheme.dynamicPrimaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fade(delay: 200.ms, duration: 500.ms)
                              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                          const SizedBox(height: 16),

                          // 3. Brand Title
                          const Text(
                            'FoodGo',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Colors.white,
                            ),
                          )
                              .animate()
                              .fade(delay: 350.ms, duration: 600.ms)
                              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                          const SizedBox(height: 6),

                          // 4. Tagline
                          const Text(
                            'Healthy Food Delivery • Phnom Penh',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                              letterSpacing: 0.2,
                            ),
                          )
                              .animate()
                              .fade(delay: 500.ms, duration: 600.ms)
                              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                          const SizedBox(height: 44),

                          // 5. Interactive Progress Capsule with Percentage & Status
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, _) {
                              final progress = _progressAnimation.value.clamp(0.0, 1.0);
                              final percentage = (progress * 100).toInt();
                              final status = _getStatusText(progress);

                              return SizedBox(
                                width: 280,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Status caption & percentage counter
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              status,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$percentage%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: GlassTheme.dynamicPrimaryColor,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Custom gradient frosted progress bar
                                    Container(
                                      height: 8,
                                      width: 280,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          width: 1,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              gradient: palette.headerGradient,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: GlassTheme.dynamicPrimaryColor
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).animate().fade(delay: 600.ms, duration: 400.ms),

                          const Spacer(flex: 3),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 13,
                                  color: GlassTheme.dynamicPrimaryColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Powered by NBC Bakong KHQR • Real-time Delivery',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'FoodGo Organic Delivery v1.0.0 (Build 12)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
