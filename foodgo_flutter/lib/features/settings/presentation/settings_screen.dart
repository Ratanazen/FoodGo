import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: GlassAppBar(
        title: 'Settings',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection(
            'Account',
            [
              _buildSettingsTile(context, 'Edit Profile', Icons.person),
              _buildSettingsTile(context, 'Change Password', Icons.lock),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Preferences',
            [
              _buildSettingsTile(context, 'Notifications', Icons.notifications),
              _buildSettingsTile(context, 'Language', Icons.language),
              _buildSettingsTile(context, 'Dark Mode', Icons.dark_mode, hasSwitch: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Other',
            [
              _buildSettingsTile(context, 'Privacy Policy', Icons.privacy_tip),
              _buildSettingsTile(context, 'Terms of Service', Icons.description),
            ],
          ),
          const SizedBox(height: 32),
          GlassButton(
            text: 'Log Out',
            icon: Icons.logout,
            color: Colors.redAccent.withValues(alpha: 0.8),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GlassTheme.textMuted,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, {bool hasSwitch = false}) {
    if (hasSwitch && title == 'Dark Mode') {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.themeMode == ThemeMode.dark || 
                         (themeProvider.themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
          return ListTile(
            leading: Icon(icon, color: GlassTheme.primaryGreen),
            title: Text(title),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                themeProvider.toggleTheme();
              },
              activeThumbColor: GlassTheme.primaryGreen,
            ),
          );
        },
      );
    }
    
    return ListTile(
      leading: Icon(icon, color: GlassTheme.primaryGreen),
      title: Text(title),
      trailing: hasSwitch
          ? Switch(
              value: true,
              onChanged: (val) {},
              activeThumbColor: GlassTheme.primaryGreen,
            )
          : Icon(Icons.chevron_right, color: GlassTheme.textMuted),
      onTap: hasSwitch ? null : () {},
    );
  }
}
