import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../widgets/svg_icon.dart';

/// Highly-polished, modern FoodGo Splash & Loading Screen
/// featuring animated brand logo reveal, delicate ambient food patterns,
/// accessible light/dark modes, and graceful connection timeout/retry states.
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
  bool _hasError = false;
  String? _errorMessage;

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
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _startInitialization();
  }

  void _startInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _progressController.reset();
    _progressController.forward();

    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 2450), () async {
      if (!mounted) return;
      try {
        final auth = context.read<AuthProvider>();
        final userProvider = context.read<UserProvider>();
        final isAuth = await auth.checkAuth().timeout(
          const Duration(seconds: 4),
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
          setState(() {
            _hasError = true;
            _errorMessage =
                'Unable to establish server connection. Tap retry or continue to login.';
          });
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

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final captionColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF64748B);
    final versionColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Delicate Ambient Floating Food Silhouettes ───────────────
          CustomPaint(
            painter: _FoodPatternPainter(
              color: (isDark ? Colors.white : palette.primary).withValues(
                alpha: isDark ? 0.05 : 0.04,
              ),
            ),
          ),

          // ── 2. Ambient Background Glow Orbs ─────────────────────────────
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
                        palette.primary.withValues(alpha: isDark ? 0.28 : 0.12),
                        palette.primaryDark.withValues(
                          alpha: isDark ? 0.10 : 0.04,
                        ),
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
                        palette.primaryDark.withValues(
                          alpha: isDark ? 0.25 : 0.10,
                        ),
                        palette.primaryAccent.withValues(
                          alpha: isDark ? 0.08 : 0.03,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Center Content (Overflow-safe and responsive) ────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // Hero Brand App Icon with Breathing Glow
                          AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, _) {
                                  return Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.16,
                                              )
                                            : palette.primary.withValues(
                                                alpha: 0.20,
                                              ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: palette.primary.withValues(
                                            alpha: isDark
                                                ? (0.35 * _pulseAnimation.value)
                                                : 0.16,
                                          ),
                                          blurRadius:
                                              38 * _pulseAnimation.value,
                                          spreadRadius:
                                              2 * _pulseAnimation.value,
                                        ),
                                        if (!isDark)
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
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

                          // Organic Fresh Badge Pill
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(
                                    alpha: isDark ? 0.14 : 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: palette.primary.withValues(
                                      alpha: 0.38,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      palette.isFestive
                                          ? palette.icon
                                          : AppIcons.salad,
                                      size: 14,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      palette.isFestive &&
                                              palette.badgeText.isNotEmpty
                                          ? '100% FRESH & ORGANIC • ${palette.badgeText}'
                                          : '100% FRESH & ORGANIC',
                                      style: TextStyle(
                                        color: palette.primary,
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
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 16),

                          // Brand Title
                          Text(
                                'FoodGo',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: titleColor,
                                ),
                              )
                              .animate()
                              .fade(delay: 350.ms, duration: 600.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 6),

                          // Tagline
                          Text(
                                'Healthy Food Delivery • Phnom Penh',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                  letterSpacing: 0.2,
                                ),
                              )
                              .animate()
                              .fade(delay: 500.ms, duration: 600.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 40),

                          // Error Notice or Interactive Progress Capsule
                          if (_hasError) ...[
                            Container(
                              width: 300,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        AppIcons.warning,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Connection Notice',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: titleColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _errorMessage ??
                                        'Unable to connect to FoodGo servers.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            if (mounted) context.go('/login');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Continue',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _startInitialization,
                                          icon: const Icon(
                                            AppIcons.refresh,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Retry',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: palette.primary,
                                            foregroundColor: palette.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fade(duration: 300.ms),
                          ] else ...[
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, _) {
                                final progress = _progressAnimation.value.clamp(
                                  0.0,
                                  1.0,
                                );
                                final percentage = (progress * 100).toInt();
                                final status = _getStatusText(progress);

                                return SizedBox(
                                  width: 280,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Status caption & percentage counter
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                status,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: subtitleColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$percentage%',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: palette.primary,
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
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.06,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.08,
                                                  ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: progress,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                gradient:
                                                    palette.headerGradient,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: palette.primary
                                                        .withValues(alpha: 0.5),
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
                          ],

                          const Spacer(flex: 3),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.security,
                                  size: 13,
                                  color: palette.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Powered by NBC Bakong KHQR • Real-time Delivery',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: captionColor,
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
                            style: TextStyle(fontSize: 10, color: versionColor),
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

class _FoodPatternPainter extends CustomPainter {
  final Color color;

  const _FoodPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.fill;

    _drawBurger(canvas, Offset(size.width * 0.12, size.height * 0.18), stroke);
    _drawDrinkCup(
      canvas,
      Offset(size.width * 0.86, size.height * 0.16),
      stroke,
    );
    _drawPizzaSlice(
      canvas,
      Offset(size.width * 0.08, size.height * 0.52),
      stroke,
    );
    _drawAvocado(
      canvas,
      Offset(size.width * 0.90, size.height * 0.50),
      stroke,
      fill,
    );
    _drawBowl(canvas, Offset(size.width * 0.14, size.height * 0.82), stroke);
    _drawLeaf(canvas, Offset(size.width * 0.84, size.height * 0.84), stroke);
  }

  void _drawBurger(Canvas canvas, Offset center, Paint stroke) {
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(0, -4), width: 32, height: 18),
      3.14,
      3.14,
      false,
      stroke,
    );
    canvas.drawLine(center.translate(-14, 0), center.translate(14, 0), stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 6), width: 28, height: 8),
        const Radius.circular(4),
      ),
      stroke,
    );
  }

  void _drawDrinkCup(Canvas canvas, Offset center, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - 10, center.dy - 12)
      ..lineTo(center.dx + 10, center.dy - 12)
      ..lineTo(center.dx + 7, center.dy + 14)
      ..lineTo(center.dx - 7, center.dy + 14)
      ..close();
    canvas.drawPath(path, stroke);
    canvas.drawLine(center.translate(2, -12), center.translate(6, -20), stroke);
  }

  void _drawPizzaSlice(Canvas canvas, Offset center, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx, center.dy + 14)
      ..lineTo(center.dx - 12, center.dy - 10)
      ..arcToPoint(
        center.translate(12, -10),
        radius: const Radius.circular(22),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(path, stroke);
  }

  void _drawAvocado(Canvas canvas, Offset center, Paint stroke, Paint fill) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 20, height: 28),
      stroke,
    );
    canvas.drawCircle(center.translate(0, 4), 5, fill);
  }

  void _drawBowl(Canvas canvas, Offset center, Paint stroke) {
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 28, height: 20),
      0,
      3.14,
      false,
      stroke,
    );
    canvas.drawLine(center.translate(-14, 0), center.translate(14, 0), stroke);
  }

  void _drawLeaf(Canvas canvas, Offset center, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - 10, center.dy + 8)
      ..quadraticBezierTo(
        center.dx - 12,
        center.dy - 10,
        center.dx + 10,
        center.dy - 10,
      )
      ..quadraticBezierTo(
        center.dx + 12,
        center.dy + 8,
        center.dx - 10,
        center.dy + 8,
      );
    canvas.drawPath(path, stroke);
    canvas.drawLine(center.translate(-8, 6), center.translate(8, -8), stroke);
  }

  @override
  bool shouldRepaint(covariant _FoodPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
