import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/glass/glass_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Discover Delicious Food',
      'description': 'Find your favorite meals from nearby restaurants.',
      'icon': 'restaurant_menu',
    },
    {
      'title': 'Fast Delivery',
      'description': 'Track your order in real time.',
      'icon': 'delivery_dining',
    },
    {
      'title': 'Enjoy Your Meal',
      'description': 'Order easily and enjoy fresh food at your door.',
      'icon': 'sentiment_very_satisfied',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundLight,
      body: Stack(
        children: [
          // Background circles for glassmorphism effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text('Skip', style: TextStyle(color: GlassTheme.textMuted)),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassContainer(
                              padding: const EdgeInsets.all(40),
                              child: Icon(
                                _getIcon(_pages[index]['icon']!),
                                size: 100,
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              _pages[index]['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: GlassTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _pages[index]['description']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: GlassTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? GlassTheme.primaryGreen : GlassTheme.textMuted.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      GlassButton(
                        text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            context.go('/home');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.star;
    }
  }
}
