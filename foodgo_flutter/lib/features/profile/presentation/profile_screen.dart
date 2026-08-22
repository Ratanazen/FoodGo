import 'package:flutter/material.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(32),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, size: 40, color: GlassTheme.primaryGreen),
                ),
                const SizedBox(height: 16),
                const Text('John Doe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('johndoe@example.com', style: TextStyle(color: GlassTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ProfileOption(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
          _ProfileOption(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push('/notifications')),
          _ProfileOption(icon: Icons.location_on_outlined, title: 'Saved Addresses', onTap: () => context.push('/addresses')),
          _ProfileOption(icon: Icons.payment_outlined, title: 'Payment Methods', onTap: () => context.push('/payments')),
          _ProfileOption(icon: Icons.favorite_outline, title: 'Favorites', onTap: () {}),
          const SizedBox(height: 24),
          const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ProfileOption(icon: Icons.settings_outlined, title: 'General Settings', onTap: () => context.push('/settings')),
          _ProfileOption(icon: Icons.language, title: 'Language', onTap: () {}),
          _ProfileOption(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
          _ProfileOption(
            icon: Icons.logout, 
            title: 'Logout', 
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            }
          ),
          const SizedBox(height: 100), // spacing for bottom nav
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? GlassTheme.primaryGreen),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            Icon(Icons.chevron_right, color: GlassTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
