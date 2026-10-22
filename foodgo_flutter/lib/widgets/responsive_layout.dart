import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/glass_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

/// Screen breakpoint helpers for responsive design
class ResponsiveBreakpoints {
  static const double mobileMax = 650.0;
  static const double tabletMax = 1050.0;
  static const double wideThreshold = 800.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= wideThreshold;
}

/// A container that centers its content and constrains its maximum width
/// on wide viewports (tablets, desktops, ultra-wide displays).
class ResponsiveWebContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveWebContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultPadding = screenWidth > 800
        ? const EdgeInsets.symmetric(horizontal: 24.0)
        : EdgeInsets.zero;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding ?? defaultPadding, child: child),
      ),
    );
  }
}

/// A responsive bottom sheet wrapper that centers its content and constrains
/// its maximum width on wide viewports (tablets, desktops, ultra-wide) while
/// filling full-width on mobile screens.
class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.maxWidth = 540,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A responsive grid that automatically lays out cards in 1, 2, 3, or 4 columns
/// based on available width.
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minCardWidth;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.minCardWidth = 320.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int columns = (availableWidth / minCardWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > 4) columns = 4;

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map(
                  (child) => Padding(
                    padding: EdgeInsets.only(bottom: runSpacing),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        // Calculate card width considering spacing
        final itemWidth =
            (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

/// Desktop / Tablet Top Navigation Bar for Web viewports (>= 800px)
class WebHeaderNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const WebHeaderNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isDark =
        themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final user = userProvider.user;
    final role = user?['role']?.toString().toLowerCase();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      decoration: BoxDecoration(
        color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // ── Brand Logo ──────────────────────────────────────────
              InkWell(
                onTap: () => onDestinationSelected(0),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lunch_dining_rounded,
                        color: GlassTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Food',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Go',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: GlassTheme.primaryGreen,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Web Edition',
                          style: TextStyle(
                            fontSize: 10,
                            color: GlassTheme.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 36),

              // ── Navigation Links ────────────────────────────────────
              Expanded(
                child: Row(
                  children: [
                    _WebNavLink(
                      label: 'Home',
                      icon: Icons.home_rounded,
                      isSelected: selectedIndex == 0,
                      onTap: () => onDestinationSelected(0),
                    ),
                    _WebNavLink(
                      label: 'Explore',
                      icon: Icons.explore_rounded,
                      isSelected: selectedIndex == 1,
                      onTap: () => onDestinationSelected(1),
                    ),
                    _WebNavLink(
                      label: 'Orders',
                      icon: Icons.receipt_long_rounded,
                      isSelected: selectedIndex == 3,
                      onTap: () => onDestinationSelected(3),
                    ),
                    if (role == 'driver')
                      _WebNavLink(
                        label: 'Driver Portal',
                        icon: Icons.two_wheeler_rounded,
                        isSelected: false,
                        onTap: () => context.push('/driver-dashboard'),
                        highlightColor: Colors.orangeAccent,
                      ),
                    if (role == 'restaurant_owner' || role == 'admin')
                      _WebNavLink(
                        label: 'Dashboard',
                        icon: Icons.storefront_rounded,
                        isSelected: false,
                        onTap: () => context.push('/restaurant-dashboard'),
                        highlightColor: Colors.cyanAccent,
                      ),
                  ],
                ),
              ),

              // ── Right Actions: Search, Cart, Theme, Profile ─────────
              Row(
                children: [
                  // Search Quick Button
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'Search Food & Restaurants',
                    onPressed: () => context.push('/search'),
                  ),
                  const SizedBox(width: 4),

                  // Map Shortcut
                  IconButton(
                    icon: const Icon(
                      Icons.map_outlined,
                      color: GlassTheme.primaryGreen,
                    ),
                    tooltip: 'Live Delivery Map',
                    onPressed: () => context.push('/map'),
                  ),
                  const SizedBox(width: 4),

                  // Cart with Counter Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      InkWell(
                        onTap: () => onDestinationSelected(2),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedIndex == 2
                                ? GlassTheme.primaryGreen.withValues(
                                    alpha: 0.15,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedIndex == 2
                                  ? GlassTheme.primaryGreen
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 20,
                                color: selectedIndex == 2
                                    ? GlassTheme.primaryGreen
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cart',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selectedIndex == 2
                                      ? GlassTheme.primaryGreen
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GlassTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Theme Toggle Button
                  IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                    tooltip: isDark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                  const SizedBox(width: 8),

                  // Profile Button / Avatar
                  InkWell(
                    onTap: () => onDestinationSelected(4),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectedIndex == 4
                            ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedIndex == 4
                              ? GlassTheme.primaryGreen
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: GlassTheme.primaryGreen,
                            child: Text(
                              (user?['username'] != null &&
                                      user!['username'].toString().isNotEmpty)
                                  ? user['username'].toString()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?['username'] ?? 'Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selectedIndex == 4
                                  ? GlassTheme.primaryGreen
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebNavLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? highlightColor;

  const _WebNavLink({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = highlightColor ?? GlassTheme.primaryGreen;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive Web Footer with links to legal, support, and public tracking
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0C120F),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  _FooterLink(
                    label: 'Track Order',
                    onTap: () => context.push('/track'),
                  ),
                  _FooterLink(
                    label: 'Help & Support',
                    onTap: () => context.push('/support'),
                  ),
                  _FooterLink(
                    label: 'Terms of Service',
                    onTap: () => context.push('/terms'),
                  ),
                  _FooterLink(
                    label: 'Privacy Policy',
                    onTap: () => context.push('/privacy'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'FoodGo Delivery Ecosystem • Kingdom of Cambodia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Powered by National Bank of Cambodia Bakong KHQR & Real Cambodian SMS OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
