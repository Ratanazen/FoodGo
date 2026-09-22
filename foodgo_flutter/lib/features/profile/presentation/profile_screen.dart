import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              if (userProvider.isLoading) {
                return const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen));
              }
              final String username = user?['username'] ?? 'Guest';
              final String email = user?['email'] ?? 'guest@example.com';
              return Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'G',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: GlassTheme.textMuted)),
                      ],
                    ),
                  ),
                  if (user?['role'] == 'restaurant_owner') ...[
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(4),
                      borderRadius: GlassTheme.borderRadiusSmall,
                      child: ListTile(
                        leading: const Icon(Icons.store, color: GlassTheme.primaryGreen),
                        title: const Text('Restaurant Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () => context.push('/restaurant-dashboard'),
                      ),
                    ),
                  ],
                  if (user?['role'] == 'driver') ...[
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(4),
                      borderRadius: GlassTheme.borderRadiusSmall,
                      child: ListTile(
                        leading: const Icon(Icons.delivery_dining, color: GlassTheme.primaryGreen),
                        title: const Text('Driver Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () => context.push('/driver-dashboard'),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
