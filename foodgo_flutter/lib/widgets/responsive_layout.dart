import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_typography.dart';
import '../core/theme/glass_theme.dart';
import '../core/localization/localization.dart';
import '../providers/cart_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'svg_icon.dart';

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
    final primaryColor = Theme.of(context).colorScheme.primary;

    final screenWidth = MediaQuery.of(context).size.width;
    final compactWide = screenWidth < ResponsiveBreakpoints.tabletMax;

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: compactWide ? 14.0 : 28.0),
      decoration: BoxDecoration(
        color: isDark ? GlassTheme.dynamicSurfaceCardDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? GlassTheme.dynamicBorderDark
                : GlassTheme.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [GlassTheme.dynamicSoftShadow(isDark: isDark)],
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
                    const FoodGoLogo(size: 36),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Food',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppTypography.primaryTextColor(
                                        isDark
                                            ? Brightness.dark
                                            : Brightness.light,
                                      ),
                                    ),
                              ),
                              TextSpan(
                                text: 'Go',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Web Edition',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTypography.secondaryTextColor(
                                  isDark ? Brightness.dark : Brightness.light,
                                ),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: compactWide ? 12 : 36),

              // ── Navigation Links ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _WebNavLink(
                        label: context.tr('nav.home'),
                        icon: Icons.home_rounded,
                        isSelected: selectedIndex == 0,
                        onTap: () => onDestinationSelected(0),
                      ),
                      _WebNavLink(
                        label: context.tr('nav.explore'),
                        icon: Icons.explore_rounded,
                        isSelected: selectedIndex == 3,
                        onTap: () => onDestinationSelected(3),
                      ),
                      _WebNavLink(
                        label: context.tr('nav.saved'),
                        icon: Icons.favorite_rounded,
                        isSelected: selectedIndex == 1,
                        onTap: () => onDestinationSelected(1),
                      ),
                      _WebNavLink(
                        label: context.tr('nav.orders'),
                        icon: Icons.receipt_long_rounded,
                        isSelected: false,
                        onTap: () => context.push('/orders'),
                      ),
                      if (role == 'driver')
                        _WebNavLink(
                          label: context.tr('driver.dashboard'),
                          icon: Icons.two_wheeler_rounded,
                          isSelected: false,
                          onTap: () => context.push('/driver-dashboard'),
                          highlightColor: Colors.orangeAccent,
                        ),
                      if (role == 'restaurant_owner' || role == 'admin')
                        _WebNavLink(
                          label: context.tr('admin.dashboard'),
                          icon: Icons.storefront_rounded,
                          isSelected: false,
                          onTap: () => context.push('/restaurant-dashboard'),
                          highlightColor: Colors.cyanAccent,
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: compactWide ? 8 : 12),

              // ── Right Actions: Search, Cart, Language, Theme, Profile ─────────
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
                    icon: Icon(Icons.map_outlined, color: primaryColor),
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
                                ? primaryColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedIndex == 2
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 20,
                                color: selectedIndex == 2
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('nav.cart'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: selectedIndex == 2
                                          ? primaryColor
                                          : AppTypography.secondaryTextColor(
                                              isDark
                                                  ? Brightness.dark
                                                  : Brightness.light,
                                            ),
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
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$cartCount',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Language Toggle Button
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      return InkWell(
                        onTap: () => localeProvider.toggleLanguage(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            localeProvider.isKhmer ? 'KH ខ្មែរ' : 'EN',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      );
                    },
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
                            ? primaryColor.withValues(alpha: 0.2)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selectedIndex == 4
                              ? primaryColor
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: primaryColor,
                            child: Text(
                              (user?['username'] != null &&
                                      user!['username'].toString().isNotEmpty)
                                  ? user['username'].toString()[0].toUpperCase()
                                  : 'U',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              user?['username'] ?? context.tr('nav.profile'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: selectedIndex == 4
                                        ? primaryColor
                                        : AppTypography.primaryTextColor(
                                            isDark
                                                ? Brightness.dark
                                                : Brightness.light,
                                          ),
                                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = highlightColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = AppTypography.secondaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );

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
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? GlassTheme.outerBackground : const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
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
                    label: context.tr('nav.trackOrder'),
                    isDark: isDark,
                    onTap: () => context.push('/track'),
                  ),
                  _FooterLink(
                    label: context.tr('nav.helpSupport'),
                    isDark: isDark,
                    onTap: () => context.push('/support'),
                  ),
                  _FooterLink(
                    label: context.tr('nav.termsOfService'),
                    isDark: isDark,
                    onTap: () => context.push('/terms'),
                  ),
                  _FooterLink(
                    label: context.tr('nav.privacyPolicy'),
                    isDark: isDark,
                    onTap: () => context.push('/privacy'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'FoodGo Delivery Ecosystem • Kingdom of Cambodia',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTypography.secondaryTextColor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Powered by National Bank of Cambodia Bakong KHQR & Real Cambodian SMS OTP',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTypography.secondaryTextColor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
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
  final bool isDark;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTypography.primaryTextColor(
              isDark ? Brightness.dark : Brightness.light,
            ),
          ),
        ),
      ),
    );
  }
}
