import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/glass_theme.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? GlassTheme.glassDarkLight 
                    : GlassTheme.glassWhiteLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? GlassTheme.borderDark 
                      : GlassTheme.borderLight,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', isSelected: selectedIndex == 0, onTap: () => onDestinationSelected(0)),
                  _NavItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Explore', isSelected: selectedIndex == 1, onTap: () => onDestinationSelected(1)),
                  _NavItem(icon: Icons.shopping_cart_outlined, selectedIcon: Icons.shopping_cart, label: 'Cart', isSelected: selectedIndex == 2, onTap: () => onDestinationSelected(2)),
                  _NavItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders', isSelected: selectedIndex == 3, onTap: () => onDestinationSelected(3)),
                  _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', isSelected: selectedIndex == 4, onTap: () => onDestinationSelected(4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlassTheme.primaryGreen.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(isSelected ? selectedIcon : icon, color: isSelected ? GlassTheme.primaryGreen : GlassTheme.textMuted, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: GlassTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
