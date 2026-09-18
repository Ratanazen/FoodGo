import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _promoAlerts = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ──────────────────────
          _SectionHeader(title: 'Appearance'),
          GlassContainer(
            borderRadius: GlassTheme.borderRadius,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  iconColor: isDark ? Colors.indigo : Colors.amber,
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Dark theme active' : 'Light theme active',
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeTrackColor: GlassTheme.primaryGreen,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.language,
                  iconColor: GlassTheme.primaryGreen,
                  title: 'Language',
                  subtitle: 'English',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.text_fields,
                  iconColor: Colors.blueAccent,
                  title: 'Font Size',
                  subtitle: 'Medium',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Notifications ───────────────────
          _SectionHeader(title: 'Notifications'),
          GlassContainer(
            borderRadius: GlassTheme.borderRadius,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_active,
                  iconColor: Colors.orange,
                  title: 'Push Notifications',
                  subtitle: 'Receive all app notifications',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeTrackColor: GlassTheme.primaryGreen,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.delivery_dining,
                  iconColor: GlassTheme.primaryGreen,
                  title: 'Order Updates',
                  subtitle: 'Status changes for your orders',
                  trailing: Switch.adaptive(
                    value: _orderUpdates,
                    activeTrackColor: GlassTheme.primaryGreen,
                    onChanged: (v) => setState(() => _orderUpdates = v),
                  ),
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.local_offer,
                  iconColor: Colors.redAccent,
                  title: 'Promotions & Offers',
                  subtitle: 'Deals, discounts & coupons',
                  trailing: Switch.adaptive(
                    value: _promoAlerts,
                    activeTrackColor: GlassTheme.primaryGreen,
                    onChanged: (v) => setState(() => _promoAlerts = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Privacy & Security ──────────────
          _SectionHeader(title: 'Privacy & Security'),
          GlassContainer(
            borderRadius: GlassTheme.borderRadius,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline,
                  iconColor: Colors.purple,
                  title: 'Change Password',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.teal,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.blue,
                  title: 'Terms of Service',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ───────────────────────────
          _SectionHeader(title: 'About'),
          GlassContainer(
            borderRadius: GlassTheme.borderRadius,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: GlassTheme.primaryGreen,
                  title: 'App Version',
                  subtitle: '1.0.0 (Build 1)',
                  trailing: const SizedBox.shrink(),
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.star_outline,
                  iconColor: Colors.amber,
                  title: 'Rate Us',
                  subtitle: 'Enjoying FoodGo? Let us know!',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  icon: Icons.support_agent,
                  iconColor: Colors.cyan,
                  title: 'Help & Support',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: GlassTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, endIndent: 0, color: GlassTheme.textMuted.withValues(alpha: 0.15));
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: GlassTheme.textMuted, fontSize: 12))
          : null,
      trailing: trailing != null
          ? DefaultTextStyle(
              style: TextStyle(color: GlassTheme.textMuted),
              child: IconTheme(
                data: IconThemeData(color: GlassTheme.textMuted, size: 20),
                child: trailing!,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
