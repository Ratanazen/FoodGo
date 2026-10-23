import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/glass_theme.dart';
import '../../providers/cart_provider.dart';

class GlassBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const GlassBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? GlassTheme.borderDark : GlassTheme.borderLight;

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1.0,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? GlassTheme.liquidSurfaceDark
                        : GlassTheme.liquidSurfaceLight,
                    borderRadius: BorderRadius.circular(38),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      GlassTheme.liquidShadow,
                      BoxShadow(
                        color:
                            (isDark
                                    ? GlassTheme.deepSmalt
                                    : GlassTheme.paleSmalt)
                                .withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PillNavItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: selectedIndex == 0,
                        onTap: () => onDestinationSelected(0),
                      ),
                      _PillNavItem(
                        icon: Icons.favorite_outline,
                        selectedIcon: Icons.favorite_rounded,
                        label: 'Saved',
                        isSelected: selectedIndex == 1,
                        onTap: () => onDestinationSelected(1),
                      ),
                      _PillNavItem(
                        icon: Icons.shopping_bag_outlined,
                        selectedIcon: Icons.shopping_bag_rounded,
                        label: 'Cart',
                        badgeCount: cartCount,
                        isSelected: selectedIndex == 2,
                        onTap: () => onDestinationSelected(2),
                      ),
                      _PillNavItem(
                        icon: Icons.local_offer_outlined,
                        selectedIcon: Icons.local_offer_rounded,
                        label: 'Offers',
                        isSelected: selectedIndex == 3,
                        onTap: () => onDestinationSelected(3),
                      ),
                      _PillNavItem(
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: selectedIndex == 4,
                        onTap: () => onDestinationSelected(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _PillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<_PillNavItem> createState() => _PillNavItemState();
}

class _PillNavItemState extends State<_PillNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.90),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.90, end: 1.10),
            weight: 35,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.10, end: 1.0),
            weight: 25,
          ),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(covariant _PillNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isSelected && !oldWidget.isSelected) ||
        (widget.badgeCount != null &&
            oldWidget.badgeCount != null &&
            widget.badgeCount! > oldWidget.badgeCount!)) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activePillGradient = LinearGradient(
      colors: isDark
          ? const [GlassTheme.royalSmalt, GlassTheme.deepSmalt]
          : const [GlassTheme.royalSmalt, GlassTheme.cobaltSmalt],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final inactiveIconColor = isDark
        ? GlassTheme.smaltTint.withValues(alpha: 0.70)
        : GlassTheme.slateSmalt.withValues(alpha: 0.75);
    final inactiveTextColor = isDark
        ? GlassTheme.smaltTint.withValues(alpha: 0.70)
        : GlassTheme.slateSmalt.withValues(alpha: 0.75);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _bounceController.forward(from: 0.0);
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? activePillGradient : null,
              borderRadius: BorderRadius.circular(28),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: GlassTheme.royalSmalt.withValues(
                          alpha: isDark ? 0.45 : 0.30,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? widget.selectedIcon : widget.icon,
                        color: isSelected ? Colors.white : inactiveIconColor,
                        size: 20,
                      ),
                      if (widget.badgeCount != null && widget.badgeCount! > 0)
                        Positioned(
                          top: -3,
                          right: -7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: GlassTheme.foodpandaPink,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 3),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: isSelected ? Colors.white : inactiveTextColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 10.5,
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
