import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/glass/animated_pressable.dart';
import '../../../widgets/svg_icon.dart';

/// Dedicated Theme Center for switching appearance modes, selecting cultural
/// & festive themes, viewing live interactive previews, and toggling seasonal animations.
class ThemeCenterScreen extends StatefulWidget {
  const ThemeCenterScreen({super.key});

  @override
  State<ThemeCenterScreen> createState() => _ThemeCenterScreenState();
}

class _ThemeCenterScreenState extends State<ThemeCenterScreen> {
  late AppColorPalette _stagedPalette;
  String _activeCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _stagedPalette = themeProvider.currentPalette;
  }

  void _stageTheme(AppColorPalette palette) {
    setState(() {
      _stagedPalette = palette;
    });
  }

  void _applyTheme() {
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.setPalette(_stagedPalette);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied "${PaletteData.fromId(_stagedPalette).nameEn}" theme!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: PaletteData.fromId(_stagedPalette).primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetStaged() {
    final themeProvider = context.read<ThemeProvider>();
    setState(() {
      _stagedPalette = themeProvider.currentPalette;
    });
  }

  void _restoreDefaults() {
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.resetToDefaults();
    setState(() {
      _stagedPalette = AppColorPalette.modernFoodGo;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Restored default Modern FoodGo theme & system appearance mode.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final stagedData = PaletteData.fromId(_stagedPalette);
    final activeData = themeProvider.paletteData;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnsavedChanges = _stagedPalette != themeProvider.currentPalette;

    final categories = ['All', 'Khmer & Festive', 'Signature Brand', 'Accessibility & Special'];

    final filteredPalettes = _activeCategoryFilter == 'All'
        ? PaletteData.allPalettes
        : PaletteData.allPalettes
            .where((p) => p.categoryEn == _activeCategoryFilter)
            .toList();

    return Scaffold(
      backgroundColor: isDark ? activeData.backgroundDark : activeData.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Center',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'មជ្ឈមណ្ឌលរចនាបថ និងរូបរាង',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _restoreDefaults,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset All', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Live Preview Sandbox ──────────────────────────────────
            _buildLivePreviewCard(stagedData, isDark, hasUnsavedChanges),
            const SizedBox(height: 24),

            // ── 2. Appearance Mode (Light / Dark / System) ───────────────
            _buildSectionHeader('Appearance Mode', 'របៀបបង្ហាញពន្លឺ និងរាត្រី'),
            const SizedBox(height: 12),
            _buildAppearanceModeSelector(themeProvider, isDark),
            const SizedBox(height: 24),

            // ── 3. Festive & Motion Preferences ─────────────────────────
            _buildSectionHeader('Experience Preferences', 'ជម្រើសពិធីបុណ្យ និងចលនា'),
            const SizedBox(height: 12),
            _buildPreferencesCard(themeProvider, isDark, activeData),
            const SizedBox(height: 24),

            // ── 4. Theme Preset Gallery ─────────────────────────────────
            _buildSectionHeader('Theme & Cultural Palettes', 'កម្រងរចនាបថ និងពណ៌ប្រពៃណី'),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _activeCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _activeCategoryFilter = cat),
                      selectedColor: stagedData.primary,
                      backgroundColor: isDark
                          ? activeData.surfaceCardDark
                          : Colors.grey.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Theme Cards Grid / List
            ...filteredPalettes.map((p) {
              final isStaged = _stagedPalette == p.id;
              final isCurrentlyApplied = themeProvider.currentPalette == p.id;
              return _buildThemeCard(
                palette: p,
                isStaged: isStaged,
                isApplied: isCurrentlyApplied,
                isDark: isDark,
                onTap: () => _stageTheme(p.id),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitleKh) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitleKh,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceModeSelector(ThemeProvider themeProvider, bool isDark) {
    final modes = [
      {'mode': ThemeMode.system, 'label': 'System', 'icon': Icons.brightness_auto_rounded},
      {'mode': ThemeMode.light, 'label': 'Light', 'icon': Icons.light_mode_rounded},
      {'mode': ThemeMode.dark, 'label': 'Dark', 'icon': Icons.dark_mode_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181F2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: modes.map((m) {
          final mode = m['mode'] as ThemeMode;
          final isSelected = themeProvider.themeMode == mode;
          final activePalette = themeProvider.paletteData;

          return Expanded(
            child: InkWell(
              onTap: () => themeProvider.setThemeMode(mode),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activePalette.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      m['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferencesCard(ThemeProvider provider, bool isDark, PaletteData palette) {
    return Material(
      color: isDark ? palette.surfaceCardDark : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: provider.seasonalDecorationsEnabled,
              activeThumbColor: palette.primary,
              title: const Text(
                'Festive Decorations & Greetings',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'បង្ហាញបដា និងពាក្យជូនពរពិធីបុណ្យជាតិនៅលើទំព័រដើម',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onChanged: (val) => provider.setSeasonalDecorationsEnabled(val),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.reducedMotion,
              activeThumbColor: palette.primary,
              title: const Text(
                'Reduced Motion Transitions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'កាត់បន្ថយចលនា សម្រាប់ដំណើរការរលូនលើទូរស័ព្ទកម្រិតទាប',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onChanged: (val) => provider.setReducedMotion(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(PaletteData staged, bool isDark, bool hasUnsavedChanges) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? staged.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: staged.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: staged.primary.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mini Header preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: staged.headerGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const FoodGoAppIcon(size: 28, borderRadius: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ThemeStyles.getFestivalGreeting(staged),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ThemeStyles.getFestivalSubtitleKh(staged),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    staged.badgeText.isNotEmpty ? staged.badgeText : 'LIVE PREVIEW',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive sample components in preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: staged.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: staged.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(staged.icon, color: staged.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Previewing: ${staged.nameEn}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staged.descriptionEn,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Controls Row
                Row(
                  children: [
                    if (hasUnsavedChanges)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetStaged,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Revert'),
                        ),
                      ),
                    if (hasUnsavedChanges) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: hasUnsavedChanges ? _applyTheme : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: staged.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: staged.primary.withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          hasUnsavedChanges ? 'Apply Theme' : 'Theme Applied',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required PaletteData palette,
    required bool isStaged,
    required bool isApplied,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? palette.surfaceCardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isStaged
                ? palette.primary
                : (isDark ? Colors.white10 : Colors.black12),
            width: isStaged ? 2.0 : 1.0,
          ),
          boxShadow: isStaged
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Theme Icon with Header gradient background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: palette.headerGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(palette.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),

            // Theme details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          palette.nameEn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (palette.badgeText.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            palette.badgeText,
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    palette.nameKh,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Palette Swatch Dots
                  Row(
                    children: [
                      _buildSwatchDot(palette.primary),
                      _buildSwatchDot(palette.primaryDark),
                      _buildSwatchDot(palette.primaryAccent),
                      _buildSwatchDot(palette.secondary),
                      const SizedBox(width: 8),
                      Text(
                        palette.categoryEn,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Selection indicator
            if (isApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.primary, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: palette.primary),
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
              )
            else if (isStaged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber, width: 1.2),
                ),
                child: const Text(
                  'PREVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.black26,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatchDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}
