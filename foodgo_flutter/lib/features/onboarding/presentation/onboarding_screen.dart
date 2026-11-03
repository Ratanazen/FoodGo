import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/responsive_layout.dart';
import '../../../../widgets/onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Discover Delicious Food',
      'titleKh': 'ស្វែងរកអាហារឆ្ងាញ់ៗ',
      'description':
          'Find your favorite meals from top-rated restaurants across Phnom Penh and Cambodia.',
      'scene': OnboardingScene.culinaryDiscovery,
      'accent': GlassTheme.limeAccent,
      'glow': GlassTheme.royalSmalt,
    },
    {
      'title': 'Fast & Live Delivery',
      'titleKh': 'ដឹកជញ្ជូនរហ័សទាន់ចិត្ត',
      'description':
          'Real-time GPS tracking from the kitchen to your doorstep with instant milestone updates.',
      'scene': OnboardingScene.liveDelivery,
      'accent': GlassTheme.primaryGreen,
      'glow': GlassTheme.cobaltSmalt,
    },
    {
      'title': 'Seamless Payments & COD',
      'titleKh': 'ទូទាត់ប្រាក់ងាយស្រួល និងសុវត្ថិភាព',
      'description':
          'Pay instantly via NBC Bakong KHQR, ABA Mobile, ACLEDA, or Cash on Delivery.',
      'scene': OnboardingScene.securePayments,
      'accent': GlassTheme.limeAccent,
      'glow': GlassTheme.royalSmalt,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage == _pages.length - 1) {
      context.go('/login');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final Color currentAccent = page['accent'] as Color;
    final Color currentGlow = page['glow'] as Color;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Ambient Radial Light 1 (Top Left)
          Positioned(
            top: -120,
            left: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentGlow.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ambient Radial Light 2 (Bottom Right)
          Positioned(
            bottom: -100,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentAccent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ResponsiveWebContainer(
              maxWidth: 640,
              child: Column(
                children: [
                  // Top Navigation Bar (Logo & Skip)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: GlassTheme.primaryGreen.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: GlassTheme.limeAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                AppIcons.snack,
                                color: GlassTheme.limeAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'FoodGo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.go('/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                AppIcons.chevronRight,
                                size: 18,
                                color: Colors.white60,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Carousel Content Area
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final item = _pages[index];
                        final OnboardingScene scene = item['scene'] as OnboardingScene;
                        final Color itemAccent = item['accent'] as Color;
                        final Color itemGlow = item['glow'] as Color;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hero Vector Scene Illustration
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Back Glow Pulse
                                  Container(
                                    width: 240,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: itemGlow.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 60,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  GlassContainer(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    child: OnboardingIllustration(
                                      scene: scene,
                                      width: 250,
                                      height: 170,
                                      primaryColor: itemAccent,
                                    ),
                                  ).animate().scale(
                                    duration: 500.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),

                              // Khmer Subtitle Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: itemAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: itemAccent.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  item['titleKh'] as String,
                                  style: TextStyle(
                                    color: itemAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ).animate().fadeIn(duration: 350.ms),
                              const SizedBox(height: 14),

                              // Main English Title
                              Text(
                                    item['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.25,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, end: 0),
                              const SizedBox(height: 14),

                              // Body Description
                              Text(
                                item['description'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w400,
                                ),
                              ).animate().fadeIn(
                                delay: 100.ms,
                                duration: 400.ms,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Controls (Pill Indicators + Primary Button)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dynamic Animated Indicator Stepper
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              width: _currentPage == index ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? currentAccent
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: _currentPage == index
                                    ? [
                                        BoxShadow(
                                          color: currentAccent.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        // Action Button (52px Touch Target with Haptic Feedback)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          child: ElevatedButton(
                            onPressed: _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(140, 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              elevation: 6,
                              shadowColor: currentAccent.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? AppIcons.checkCircle
                                      : AppIcons.arrowForward,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
