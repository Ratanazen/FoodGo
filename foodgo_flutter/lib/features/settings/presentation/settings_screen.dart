import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/svg_icon.dart';
import '../../../widgets/about_foodgo_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _promoAlerts = true;

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
      });
    } catch (_) {}
  }

  String _describeActiveApiHost() {
    final url = AppConfig.apiBaseUrl;
    if (url.contains('127.0.0.1') || url.contains('localhost')) {
      return '$url (Local ADB / Host)';
    }
    if (url.contains('10.0.2.2')) {
      return '$url (Emulator Host)';
    }
    if (url.contains('workers.dev')) {
      return '$url (Cloudflare Edge Failover)';
    }
    return '$url (Vercel Production)';
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
    final LocaleProvider localeProvider;
    try {
      localeProvider = context.read<LocaleProvider>();
    } catch (_) {
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(ctx).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final accentGreen = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
        final isKhmer = Localizations.localeOf(ctx).languageCode == 'km';
        return ResponsiveBottomSheet(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: isDark
                    ? GlassTheme.dynamicBorderDark
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('settings.selectLanguage'),
                  style: textTheme.titleLarge?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    height: isKhmer ? 1.5 : null,
                    letterSpacing: isKhmer ? 0 : null,
                  ),
                ),
                const SizedBox(height: 16),
                ...[
                  {'lang': AppLanguage.english, 'label': 'English (US)'},
                  {'lang': AppLanguage.khmer, 'label': 'ភាសាខ្មែរ (Khmer)'},
                ].map((item) {
                  final lang = item['lang'] as AppLanguage;
                  final isSel = localeProvider.language == lang;
                  final itemIsKhmer = lang == AppLanguage.khmer;
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        item['label'] as String,
                        style: textTheme.bodyLarge?.copyWith(
                          color: primaryText,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          height: itemIsKhmer ? 1.5 : null,
                          letterSpacing: itemIsKhmer ? 0 : null,
                        ),
                      ),
                      trailing: isSel
                          ? Icon(Icons.check, color: accentGreen)
                          : null,
                      onTap: () async {
                        await localeProvider.setLanguage(lang);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Language switched to ${item['label']}',
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF15803D),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencyProvider = context.read<CurrencyProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryText = AppTypography.primaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        final secondaryText = AppTypography.secondaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        final accentGreen = isDark
            ? GlassTheme.primaryGreen
            : GlassTheme.primaryGreenDark;
        return ResponsiveBottomSheet(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: isDark
                    ? GlassTheme.dynamicBorderDark
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Builder(
              builder: (sheetCtx) {
                final textTheme = Theme.of(sheetCtx).textTheme;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Display Currency',
                              style: textTheme.titleLarge?.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: GlassTheme.primaryGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '1 USD = ${currencyProvider.khrPerUsd.toInt()} KHR',
                              style: textTheme.labelSmall?.copyWith(
                                color: accentGreen,
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
                          'subtitle':
                              'US Dollar (Default international standard)',
                        },
                        {
                          'mode': DisplayCurrency.khr,
                          'title': 'KHR (៛)',
                          'subtitle':
                              'Cambodian Riel (NBC customary retail rate)',
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
                              style: textTheme.bodyLarge?.copyWith(
                                color: primaryText,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              opt['subtitle'] as String,
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                            trailing: isSel
                                ? Icon(Icons.check_circle, color: accentGreen)
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showColorPaletteDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final current = themeProvider.currentPalette;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryText = AppTypography.primaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        final secondaryText = AppTypography.secondaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        return Builder(
          builder: (dialogCtx) {
            final textTheme = Theme.of(dialogCtx).textTheme;
            return AlertDialog(
              backgroundColor: isDark
                  ? GlassTheme.dynamicDialogDark
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isDark
                      ? GlassTheme.dynamicBorderDark
                      : GlassTheme.borderLight,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.paletteData.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette,
                      color: themeProvider.paletteData.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme & Festivals',
                          style: textTheme.titleLarge?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'រចនាបថ និងពិធីបុណ្យជាតិ',
                          style: textTheme.bodySmall?.copyWith(
                            color: secondaryText,
                            height: 1.5,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.72,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Khmer & Seasonal Festivals
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: 8,
                            top: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.celebration,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFB45309),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Khmer & Seasonal Festivals / ពិធីបុណ្យជាតិ',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...PaletteData.allPalettes
                            .where((p) => p.isFestive)
                            .map(
                              (palette) => _buildPaletteCard(
                                ctx,
                                palette,
                                current,
                                themeProvider,
                              ),
                            ),

                        const SizedBox(height: 12),

                        // Section 2: Classic Signature Themes
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF15803D),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Classic Signature Themes / រចនាបថដើម',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...PaletteData.allPalettes
                            .where((p) => !p.isFestive)
                            .map(
                              (palette) => _buildPaletteCard(
                                ctx,
                                palette,
                                current,
                                themeProvider,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close / បិទ',
                    style: textTheme.labelLarge?.copyWith(
                      color: secondaryText,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPaletteCard(
    BuildContext ctx,
    PaletteData palette,
    AppColorPalette current,
    ThemeProvider themeProvider,
  ) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final textTheme = Theme.of(ctx).textTheme;
    final primaryText = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final secondaryText = AppTypography.secondaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final isSelected = palette.id == current;
    final badgeFg = isDark
        ? (palette.primaryAccent.computeLuminance() < 0.25
              ? Colors.white
              : palette.primaryAccent)
        : HSLColor.fromColor(palette.primary).withLightness(0.30).toColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? palette.primary.withValues(alpha: 0.18)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
        border: Border.all(
          color: isSelected
              ? palette.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: palette.headerGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.5,
            ),
          ),
          child: Icon(palette.icon, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                palette.nameEn,
                style: textTheme.bodyMedium?.copyWith(
                  color: primaryText,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            if (palette.badgeText.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  palette.badgeText,
                  style: textTheme.labelSmall?.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                palette.nameKh,
                style: textTheme.labelSmall?.copyWith(
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
              Text(
                palette.descriptionEn,
                style: textTheme.labelSmall?.copyWith(color: secondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: palette.primary.computeLuminance() > 0.45
                      ? Colors.black87
                      : Colors.white,
                  size: 16,
                ),
              )
            : Icon(
                Icons.circle_outlined,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black26,
                size: 20,
              ),
        onTap: () {
          themeProvider.setPalette(palette.id);
          Navigator.pop(ctx);
          final snackFg = palette.primary.computeLuminance() > 0.45
              ? Colors.black87
              : Colors.white;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(palette.icon, color: snackFg, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Theme updated to ${palette.nameEn} (${palette.nameKh})',
                      style: textTheme.bodyMedium?.copyWith(
                        color: snackFg,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: palette.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFontSizeDialog() {
    final LocaleProvider localeProvider;
    try {
      localeProvider = context.read<LocaleProvider>();
    } catch (_) {
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textTheme = Theme.of(ctx).textTheme;
        final primaryText = AppTypography.primaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        final secondaryText = AppTypography.secondaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        final accentGreen = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
        return AlertDialog(
          backgroundColor: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? GlassTheme.dynamicBorderDark
                  : GlassTheme.borderLight,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.tr('settings.textSize'),
                  style: textTheme.titleLarge?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  localeProvider.setTextScale(AppTextScale.standard);
                  Navigator.pop(ctx);
                },
                child: Text(
                  context.tr('common.reset'),
                  style: textTheme.labelLarge?.copyWith(
                    color: accentGreen,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppTextScale.values.map((scale) {
              final isSelected = localeProvider.textScale == scale;
              return ListTile(
                title: Text(
                  scale.label(localeProvider.isKhmer),
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected ? accentGreen : primaryText,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
                subtitle: MediaQuery(
                  data: MediaQuery.of(
                    ctx,
                  ).copyWith(textScaler: TextScaler.linear(scale.factor)),
                  child: Text(
                    'Sample text • អក្សរគំរូ',
                    style: textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: accentGreen)
                    : Icon(
                        Icons.circle_outlined,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                onTap: () {
                  localeProvider.setTextScale(scale);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    ).then((changed) {
      if (changed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: GlassTheme.primaryGreen,
          ),
        );
      }
    });
  }

  Future<void> _showDeleteAccountDialog() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account permanently deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showRateUsDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final theme = Theme.of(dialogCtx);
          final textTheme = theme.textTheme;
          final colorScheme = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;
          final brightness = isDark ? Brightness.dark : Brightness.light;
          final primaryText = AppTypography.primaryTextColor(brightness);
          final secondaryText = AppTypography.secondaryTextColor(brightness);
          final accentGreen = isDark
              ? GlassTheme.primaryGreenAccent
              : const Color(0xFF15803D);
          final starColor = isDark
              ? const Color(0xFFFBBF24)
              : const Color(0xFFB45309);
          return AlertDialog(
            backgroundColor: isDark
                ? GlassTheme.dynamicDialogDark
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark
                    ? GlassTheme.dynamicBorderDark
                    : GlassTheme.borderLight,
              ),
            ),
            title: Text(
              'Rate FoodGo Experience',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How would you rate your delivery experience?',
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: starColor,
                          size: 32,
                        ),
                        onPressed: () =>
                            setDialogState(() => rating = index + 1),
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
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: textTheme.labelLarge?.copyWith(color: secondaryText),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Thank you for rating FoodGo!',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: isDark
                          ? GlassTheme.dynamicCardDark
                          : const Color(0xFF15803D),
                    ),
                  );
                },
                child: Text(
                  'Submit Rating',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: context.tr('settings.title'),
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
            _SectionHeader(title: context.tr('settings.appearance')),
            GlassContainer(
              borderRadius: GlassTheme.borderRadius,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    iconColor: isDark ? Colors.indigo : Colors.amber,
                    title: context.tr('settings.themeMode'),
                    subtitle: isDark
                        ? context.tr('settings.darkMode')
                        : context.tr('settings.lightMode'),
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeTrackColor: GlassTheme.primaryGreen,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: themeProvider.paletteData.icon,
                    iconColor: themeProvider.paletteData.primary,
                    title: 'Theme & Festivals',
                    subtitle:
                        '${themeProvider.paletteData.nameEn} • ${themeProvider.paletteData.nameKh}',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showColorPaletteDialog(context),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              gradient:
                                  themeProvider.paletteData.headerGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.paletteData.primary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.push('/theme-center'),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.language,
                    iconColor: GlassTheme.primaryGreen,
                    title: context.tr('settings.language'),
                    subtitle: (() {
                      try {
                        return context
                            .watch<LocaleProvider>()
                            .language
                            .nativeName;
                      } catch (_) {
                        return 'English';
                      }
                    })(),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLanguageDialog,
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.text_fields,
                    iconColor: Colors.blueAccent,
                    title: context.tr('settings.textSize'),
                    subtitle: (() {
                      try {
                        final lp = context.watch<LocaleProvider>();
                        return lp.textScale.label(lp.isKhmer);
                      } catch (_) {
                        return 'Default';
                      }
                    })(),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showFontSizeDialog,
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.currency_exchange,
                    iconColor: Colors.amberAccent,
                    title: context.tr('settings.displayCurrency'),
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
                        leadingWidget: const FoodGoLogo(size: 22),
                        iconColor: GlassTheme.primaryGreen,
                        title: 'About FoodGo',
                        subtitle: 'Overview, capabilities & banking partners',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showAboutFoodGoDialog(context),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        iconColor: GlassTheme.primaryGreen,
                        title: 'App Version',
                        subtitle: '2.0.0 (Build 20) • Production Ready',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showAboutFoodGoDialog(context),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.cloud_done_outlined,
                        iconColor: Colors.blueAccent,
                        title: 'Backend API Host',
                        subtitle: _describeActiveApiHost(),
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
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: secondaryText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final secondaryText = AppTypography.secondaryTextColor(
      Theme.of(context).brightness,
    );
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 0,
      color: secondaryText.withValues(alpha: 0.18),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leadingWidget;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.icon,
    this.leadingWidget,
    this.iconColor = GlassTheme.primaryGreen,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : assert(
         icon != null || leadingWidget != null,
         'Either icon or leadingWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final resolvedIconColor = (!isDark && iconColor == GlassTheme.primaryGreen)
        ? const Color(0xFF15803D)
        : iconColor;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: resolvedIconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              leadingWidget ??
              Icon(icon ?? Icons.circle, color: resolvedIconColor, size: 20),
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(color: secondaryText),
              )
            : null,
        trailing: trailing != null
            ? DefaultTextStyle(
                style: TextStyle(color: secondaryText),
                child: IconTheme(
                  data: IconThemeData(color: secondaryText, size: 20),
                  child: trailing!,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _submit() async {
    if (_currentPw.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (_newPw.text.isEmpty || _newPw.text != _confirmPw.text) {
      _showError('Passwords do not match or are empty');
      return;
    }
    if (_newPw.text.length < 6) {
      _showError('New password must be at least 6 characters');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final api = ApiService();
      await api.post('auth/change-password/', {
        'current_password': _currentPw.text,
        'new_password': _newPw.text,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Failed to update password: ${ApiService.formatError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final secondaryText = AppTypography.secondaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ResponsiveBottomSheet(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Builder(
            builder: (ctx) {
              final textTheme = Theme.of(ctx).textTheme;
              final colorScheme = Theme.of(ctx).colorScheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Change Account Password',
                    style: textTheme.titleLarge?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currentPw,
                    obscureText: true,
                    style: textTheme.bodyLarge?.copyWith(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                      filled: true,
                      fillColor: fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPw,
                    obscureText: true,
                    style: textTheme.bodyLarge?.copyWith(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                      filled: true,
                      fillColor: fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPw,
                    obscureText: true,
                    style: textTheme.bodyLarge?.copyWith(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      labelStyle: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                      filled: true,
                      fillColor: fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save New Password',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      final api = ApiService();
      await api.delete('auth/delete-account/');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      final dangerColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.redAccent
          : const Color(0xFFB91C1C);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete account: ${ApiService.formatError(e)}',
          ),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final secondaryText = AppTypography.secondaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final dangerColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? GlassTheme.dynamicBorderDark : GlassTheme.borderLight,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: dangerColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Delete Account',
              style: textTheme.titleLarge?.copyWith(
                color: primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action is irreversible. All your order history, saved addresses, and profile data will be permanently deleted.',
            style: textTheme.bodySmall?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 16),
          Text(
            'Type "DELETE" to confirm:',
            style: textTheme.bodySmall?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            style: textTheme.bodyLarge?.copyWith(color: primaryText),
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(color: secondaryText),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: dangerColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: (_confirmController.text.trim() != 'DELETE' || _isDeleting)
              ? null
              : _deleteAccount,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Delete Permanently',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
