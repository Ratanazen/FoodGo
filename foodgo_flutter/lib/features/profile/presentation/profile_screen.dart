import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/my_qr_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to log out of your FoodGo account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ResponsiveWebContainer(
        maxWidth: 760,
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
              final String phone = user?['phone'] ?? '';
              final String? avatarUrl = user?['avatar_url'] ?? user?['avatar'];

              return Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: GlassTheme.limeAccent, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: GlassTheme.limeAccent.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  imageBuilder: (ctx, imageProvider) => CircleAvatar(
                                    radius: 40,
                                    backgroundImage: imageProvider,
                                  ),
                                  placeholder: (ctx, url) => CircleAvatar(
                                    radius: 40,
                                    backgroundColor: GlassTheme.limeAccent.withValues(alpha: 0.15),
                                    child: const CircularProgressIndicator(color: GlassTheme.limeAccent, strokeWidth: 2),
                                  ),
                                  errorWidget: (ctx, url, err) => CircleAvatar(
                                    radius: 40,
                                    backgroundColor: GlassTheme.limeAccent.withValues(alpha: 0.15),
                                    child: Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : 'G',
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: GlassTheme.limeAccent),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: GlassTheme.limeAccent.withValues(alpha: 0.15),
                                  child: Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : 'G',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: GlassTheme.limeAccent),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                        Text(username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: GlassTheme.textMuted, fontSize: 13)),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: GlassTheme.limeAccent),
                              const SizedBox(width: 6),
                              Text(
                                phone,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 18),
                        // Quick Action Shortcuts: Wallet, Orders, KHQR
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/wallet'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.account_balance_wallet_outlined, color: GlassTheme.limeAccent, size: 22),
                                      SizedBox(height: 6),
                                      Text('Wallet', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/orders'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, color: Colors.amberAccent, size: 22),
                                      SizedBox(height: 6),
                                      Text('Orders', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  final u = context.read<UserProvider>().user;
                                  MyQrModal.show(context, user: u);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.qr_code_2, color: Colors.redAccent, size: 22),
                                      SizedBox(height: 6),
                                      Text('My KHQR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (user?['role'] == 'restaurant_owner' || user?['role'] == 'admin') ...[
                    const SizedBox(height: 16),
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
                  if (user?['role'] == 'driver' || user?['role'] == 'admin') ...[
                    const SizedBox(height: 16),
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
          _ProfileOption(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Digital Wallet & KHQR Top-Up',
            onTap: () => context.push('/wallet'),
          ),
          _ProfileOption(
            icon: Icons.qr_code_2,
            title: 'My KHQR (Pay Me / ទទួលប្រាក់)',
            iconColor: Colors.redAccent,
            onTap: () {
              final user = context.read<UserProvider>().user;
              MyQrModal.show(context, user: user);
            },
          ),
          _ProfileOption(icon: Icons.person_outline, title: 'Edit Profile', onTap: () => context.push('/edit-profile')),
          _ProfileOption(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push('/notifications')),
          _ProfileOption(icon: Icons.location_on_outlined, title: 'Saved Addresses', onTap: () => context.push('/addresses')),
          _ProfileOption(icon: Icons.favorite_outline, title: 'Favorites', onTap: () => context.push('/favorites')),
          const SizedBox(height: 24),
          const Text('Settings & Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ProfileOption(icon: Icons.settings_outlined, title: 'General Settings', onTap: () => context.push('/settings')),
          _ProfileOption(
            icon: Icons.language,
            title: 'Language',
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: GlassTheme.dialogDark,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Select Language / ជ្រើសរើសភាសា', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('English (US)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.check, color: GlassTheme.primaryGreen),
                        onTap: () => Navigator.pop(ctx),
                      ),
                      ListTile(
                        title: const Text('ភាសាខ្មែរ (Khmer)', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ភាសាខ្មែរ ត្រូវបានជ្រើសរើស'), backgroundColor: GlassTheme.primaryGreen),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('Français (French)', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Langue française sélectionnée'), backgroundColor: GlassTheme.primaryGreen),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: GlassTheme.dialogDark,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('FoodGo 24/7 Support', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Get fast help with delivery, payments, or orders.', style: TextStyle(color: GlassTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: GlassTheme.primaryGreen),
                        title: const Text('Chat with Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Average reply time: 2 mins', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                        onTap: () => Navigator.pop(ctx),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: Colors.amber),
                        title: const Text('Hotline: +855 23 999 888', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Toll-free customer care', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isAuthenticated) {
                return _ProfileOption(
                  icon: Icons.logout, 
                  title: 'Logout', 
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _showLogoutDialog(context),
                );
              } else {
                return _ProfileOption(
                  icon: Icons.login, 
                  title: 'Login / Sign Up', 
                  textColor: GlassTheme.primaryGreen,
                  iconColor: GlassTheme.primaryGreen,
                  onTap: () => context.push('/login'),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text('FoodGo Enterprise Delivery v1.0.0', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Made with ❤️ in Phnom Penh, Cambodia', style: TextStyle(color: GlassTheme.textMuted.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 100), // spacing for bottom nav
        ],
      ),
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
    final effectiveColor = iconColor ?? GlassTheme.limeAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: effectiveColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor ?? Colors.white,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.35), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
