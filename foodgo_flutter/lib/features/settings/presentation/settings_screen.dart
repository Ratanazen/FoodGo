import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/currency_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _promoAlerts = true;
  String _selectedLanguage = 'English';
  String _selectedFontSize = 'Medium';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
        _orderUpdates = prefs.getBool('settings_order_updates') ?? true;
        _promoAlerts = prefs.getBool('settings_promo_alerts') ?? true;
        _selectedLanguage = prefs.getString('settings_language') ?? 'English';
        _selectedFontSize = prefs.getString('settings_font_size') ?? 'Medium';
      });
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, dynamic val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (val is bool) {
        await prefs.setBool(key, val);
      } else if (val is String) {
        await prefs.setString(key, val);
      }
    } catch (_) {}
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResponsiveBottomSheet(
        child: Container(
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
              const Text(
                'Select Language / ជ្រើសរើសភាសា',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                {'label': 'English (US)', 'name': 'English'},
                {'label': 'ភាសាខ្មែរ (Khmer)', 'name': 'Khmer'},
                {'label': 'Français (French)', 'name': 'French'},
              ].map((lang) {
                final isSel = _selectedLanguage == lang['name'];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      lang['label']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSel
                        ? const Icon(
                            Icons.check,
                            color: GlassTheme.primaryGreen,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedLanguage = lang['name']!);
                      _saveSetting('settings_language', lang['name']!);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language switched to ${lang['label']}',
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: GlassTheme.primaryGreen,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencyProvider = context.read<CurrencyProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResponsiveBottomSheet(
        child: Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Display Currency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '1 USD = ${currencyProvider.khrPerUsd.toInt()} KHR',
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...[
                {
                  'mode': DisplayCurrency.usd,
                  'title': r'USD ($)',
                  'subtitle': 'US Dollar (Default international standard)',
                },
                {
                  'mode': DisplayCurrency.khr,
                  'title': 'KHR (៛)',
                  'subtitle': 'Cambodian Riel (NBC customary retail rate)',
                },
                {
                  'mode': DisplayCurrency.dual,
                  'title': r'Dual Currency ($ / ៛)',
                  'subtitle':
                      'Shows both USD and estimated Riel simultaneously',
                },
              ].map((opt) {
                final mode = opt['mode'] as DisplayCurrency;
                final isSel = currencyProvider.currency == mode;
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      opt['title'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      opt['subtitle'] as String,
                      style: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSel
                        ? const Icon(
                            Icons.check_circle,
                            color: GlassTheme.primaryGreen,
                          )
                        : null,
                    onTap: () {
                      currencyProvider.setCurrency(mode);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Display currency set to ${opt['title']}',
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: GlassTheme.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Text & Font Size',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Small (90%)', 'Medium (Default 100%)', 'Large (115%)']
              .map((size) {
                final key = size.split(' ').first;
                final isSelected = _selectedFontSize == key;
                return ListTile(
                  title: Text(
                    size,
                    style: TextStyle(
                      color: isSelected
                          ? GlassTheme.primaryGreen
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: GlassTheme.primaryGreen)
                      : const Icon(
                          Icons.circle_outlined,
                          color: Colors.white38,
                        ),
                  onTap: () {
                    setState(() => _selectedFontSize = key);
                    _saveSetting('settings_font_size', key);
                    Navigator.pop(ctx);
                  },
                );
              })
              .toList(),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: ResponsiveBottomSheet(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GlassTheme.dialogDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Change Account Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentPw,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: TextStyle(color: GlassTheme.textMuted),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPw,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: GlassTheme.textMuted),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPw,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: TextStyle(color: GlassTheme.textMuted),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (currentPw.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter your current password',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            if (newPw.text.isEmpty ||
                                newPw.text != confirmPw.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Passwords do not match or are empty',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            if (newPw.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'New password must be at least 6 characters',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSubmitting = true);
                            try {
                              final api = ApiService();
                              await api.post('auth/change-password/', {
                                'current_password': currentPw.text,
                                'new_password': newPw.text,
                              });
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password updated successfully!',
                                  ),
                                  backgroundColor: GlassTheme.primaryGreen,
                                ),
                              );
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update password: $e',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save New Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: GlassTheme.dialogDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is irreversible. All your order history, saved addresses, and profile data will be permanently deleted.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Type "DELETE" to confirm:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:
                  (confirmController.text.trim() != 'DELETE' || isDeleting)
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final authProvider = context.read<AuthProvider>();
                        final api = ApiService();
                        await api.delete('auth/delete-account/');
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (!mounted) return;
                        await authProvider.logout();
                        if (!mounted) return;
                        context.go('/login');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account permanently deleted.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete account: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Delete Permanently',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRateUsDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: GlassTheme.dialogDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Rate FoodGo Experience',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How would you rate your delivery experience?',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                rating == 5
                    ? 'Outstanding! Highly Recommended'
                    : rating >= 4
                    ? 'Great food & fast delivery'
                    : 'Thanks for your feedback!',
                style: const TextStyle(
                  color: GlassTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.primaryGreen,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Thank you for rating FoodGo!'),
                      ],
                    ),
                    backgroundColor: GlassTheme.primaryGreen,
                  ),
                );
              },
              child: const Text(
                'Submit Rating',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      body: ResponsiveWebContainer(
        maxWidth: 800,
        child: ListView(
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
                    subtitle: isDark
                        ? 'Dark theme active'
                        : 'Light theme active',
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
                    subtitle: _selectedLanguage,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLanguageDialog,
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.text_fields,
                    iconColor: Colors.blueAccent,
                    title: 'Font Size',
                    subtitle: _selectedFontSize,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showFontSizeDialog,
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.currency_exchange,
                    iconColor: Colors.amberAccent,
                    title: 'Display Currency',
                    subtitle:
                        '${context.watch<CurrencyProvider>().currencySymbol} (${context.watch<CurrencyProvider>().currency.name.toUpperCase()}) • 1 USD = ${context.watch<CurrencyProvider>().khrPerUsd.toInt()} KHR',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCurrencyDialog(context),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
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
                          onChanged: (v) {
                            setState(() => _notificationsEnabled = v);
                            _saveSetting('settings_notifications', v);
                          },
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
                          onChanged: (v) {
                            setState(() => _orderUpdates = v);
                            _saveSetting('settings_order_updates', v);
                          },
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
                          onChanged: (v) {
                            setState(() => _promoAlerts = v);
                            _saveSetting('settings_promo_alerts', v);
                          },
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 80.ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
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
                        onTap: _showChangePasswordDialog,
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Colors.teal,
                        title: 'Privacy Policy',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/privacy'),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        iconColor: Colors.blue,
                        title: 'Terms of Service',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/terms'),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 140.ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
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
                        subtitle: '1.0.0 (Build 12) • Production Ready',
                        trailing: const SizedBox.shrink(),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.cloud_done_outlined,
                        iconColor: Colors.blueAccent,
                        title: 'Backend API Host',
                        subtitle:
                            'https://food-go-app.vercel.app (Vercel Production)',
                        trailing: const Icon(
                          Icons.check_circle,
                          color: GlassTheme.primaryGreen,
                          size: 18,
                        ),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.star_outline,
                        iconColor: Colors.amber,
                        title: 'Rate Us',
                        subtitle: 'Enjoying FoodGo? Let us know!',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showRateUsDialog,
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.support_agent,
                        iconColor: Colors.cyan,
                        title: 'Help & Support',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/support'),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 20),

            // ── Danger Zone ─────────────────────
            _SectionHeader(title: 'Danger Zone'),
            GlassContainer(
                  borderRadius: GlassTheme.borderRadius,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.delete_forever,
                        iconColor: Colors.redAccent,
                        title: 'Delete Account',
                        subtitle: 'Permanently remove account & all order data',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.redAccent,
                        ),
                        onTap: _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 260.ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 100),
          ],
        ),
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
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 56,
    endIndent: 0,
    color: GlassTheme.textMuted.withValues(alpha: 0.15),
  );
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
              )
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
      ),
    );
  }
}
