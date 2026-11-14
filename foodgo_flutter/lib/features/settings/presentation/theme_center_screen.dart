import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
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
  int _selectedTopTab = 0; // 0: Themes, 1: Settings
  String _activeCategoryFilter = 'All';
  int _previewTab = 0; // 0: Home, 1: Details, 2: Cart, 3: Profile
  int _detailsQuantity = 2;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _stagedPalette = themeProvider.currentPalette;
  }

  Color _accessibleAccent(Color color, bool isDark) {
    final hsl = HSLColor.fromColor(color);
    if (!isDark && hsl.lightness > 0.38) {
      return hsl.withLightness(0.32).toColor();
    }
    if (isDark && hsl.lightness < 0.52) {
      return hsl.withLightness(0.62).toColor();
    }
    return color;
  }

  void _stageTheme(AppColorPalette palette) {
    setState(() {
      _stagedPalette = palette;
    });
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.setPalette(palette);
  }

  void _applyTheme() {
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.setPalette(_stagedPalette);
    final staged = PaletteData.fromId(_stagedPalette);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied "${staged.nameEn}" theme!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: staged.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: staged.primary,
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
        content: Text(
          'Restored default Modern FoodGo theme & system appearance mode.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF15803D),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentColor = _accessibleAccent(stagedData.primary, isDark);
    final hasUnsavedChanges = _stagedPalette != themeProvider.currentPalette;

    final categories = [
      'All',
      'Theme Styles',
      'Seasonal Themes',
      ...PaletteData.allPalettes
          .map((p) => p.categoryEn)
          .where((cat) => cat != 'Theme Styles' && cat != 'Seasonal Themes')
          .toSet(),
    ];

    final filteredPalettes = _activeCategoryFilter == 'All'
        ? PaletteData.allPalettes
        : PaletteData.allPalettes
              .where((p) => p.categoryEn == _activeCategoryFilter)
              .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Theme Center',
        leading: IconButton(
          icon: Icon(AppIcons.back, color: primaryText, size: AppIconSizes.sm),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 420)
            TextButton.icon(
              onPressed: _restoreDefaults,
              icon: const Icon(AppIcons.reset, size: AppIconSizes.xs),
              label: Text(
                'Reset All',
                style: textTheme.bodySmall?.copyWith(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: secondaryText),
            )
          else
            IconButton(
              onPressed: _restoreDefaults,
              icon: Icon(
                AppIcons.reset,
                size: AppIconSizes.md,
                color: secondaryText,
              ),
              tooltip: 'Reset all themes',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khmer Subtitle & Appearance Mode Pill
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: stagedData.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Appearance',
                          style: textTheme.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'មជ្ឈមណ្ឌលរចនាបថ និងរូបរាង',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: AppTheme.khmerPrimaryFont,
                          fontFamilyFallback: AppTheme.khmerFontFallbacks,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Top Pill Tab Bar (Themes | Settings) ───────────────────────
                _buildTopTabBar(isDark, stagedData),

                if (_selectedTopTab == 0) ...[
                  // ── 1. Current Theme Hero Banner ───────────────────────────
                  _buildCurrentThemeHero(
                    stagedData,
                    activeData,
                    isDark,
                    hasUnsavedChanges,
                  ),
                  const SizedBox(height: 20),

                  // ── 2. Appearance Mode Quick Selector ──────────────────────
                  _buildSectionHeader(
                    'Appearance Mode',
                    'របៀបបង្ហាញពន្លឺ និងរាត្រី',
                  ),
                  const SizedBox(height: 10),
                  _buildAppearanceModeSelector(themeProvider, isDark),
                  const SizedBox(height: 24),

                  // ── 3. Theme & Cultural Palettes Gallery ───────────────────
                  _buildSectionHeader(
                    'Theme & Cultural Palettes',
                    'កម្រងរចនាបថ និងពណ៌ប្រពៃណី',
                  ),
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
                            onSelected: (_) =>
                                setState(() => _activeCategoryFilter = cat),
                            selectedColor: stagedData.primary,
                            backgroundColor: isDark
                                ? activeData.surfaceCardDark
                                : Colors.grey.withValues(alpha: 0.12),
                            labelStyle: textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? stagedData.onPrimary
                                  : primaryText,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
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
                  const SizedBox(height: 18),

                  // Section A: Theme Styles
                  if (_activeCategoryFilter == 'All' ||
                      _activeCategoryFilter == 'Theme Styles') ...[
                    _buildSubSectionTitle(
                      'Theme Styles',
                      'Different looks, Same great experience. / រូបរាងប្លែកៗ បទពិសោធន៍ដ៏អស្ចារ្យដូចគ្នា',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildThemeGallery(
                      PaletteData.themeStyles,
                      themeProvider,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Section B: Seasonal Themes
                  if (_activeCategoryFilter == 'All' ||
                      _activeCategoryFilter == 'Seasonal Themes') ...[
                    _buildSubSectionTitle(
                      'Seasonal Themes',
                      'Festive atmospheres & cultural celebrations / បរិយាកាសពិធីបុណ្យ និងប្រពៃណីជាតិ',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildThemeGallery(
                      PaletteData.seasonalThemes,
                      themeProvider,
                      isDark,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Section C: Remaining Filtered Themes
                  if (_activeCategoryFilter != 'All' &&
                      _activeCategoryFilter != 'Theme Styles' &&
                      _activeCategoryFilter != 'Seasonal Themes') ...[
                    _buildThemeGallery(filteredPalettes, themeProvider, isDark),
                    const SizedBox(height: 24),
                  ],
                ] else ...[
                  // ── Settings Tab ───────────────────────────────────────────
                  // 1. Live Preview Sandbox
                  _buildLivePreviewCard(stagedData, isDark, hasUnsavedChanges),
                  const SizedBox(height: 24),

                  // 2. Festive & Motion Preferences
                  _buildSectionHeader(
                    'Experience Preferences',
                    'ជម្រើសពិធីបុណ្យ និងចលនា',
                  ),
                  const SizedBox(height: 12),
                  _buildPreferencesCard(themeProvider, isDark, activeData),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopTabBar(bool isDark, PaletteData staged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? staged.surfaceCardDark.withValues(alpha: 0.6)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTopTabItem(
              index: 0,
              icon: Icons.palette_outlined,
              label: 'Themes',
              labelKh: 'រចនាបថ',
              isSelected: _selectedTopTab == 0,
              staged: staged,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTopTabItem(
              index: 1,
              icon: Icons.tune_rounded,
              label: 'Settings',
              labelKh: 'ការកំណត់',
              isSelected: _selectedTopTab == 1,
              staged: staged,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabItem({
    required int index,
    required IconData icon,
    required String label,
    required String labelKh,
    required bool isSelected,
    required PaletteData staged,
    required bool isDark,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return InkWell(
      onTap: () => setState(() => _selectedTopTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? staged.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: staged.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? staged.onPrimary
                      : (isDark ? Colors.white70 : primaryText),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? staged.onPrimary
                        : (isDark ? Colors.white70 : primaryText),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($labelKh)',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: AppTheme.khmerPrimaryFont,
                    fontFamilyFallback: AppTheme.khmerFontFallbacks,
                    height: 1.5,
                    letterSpacing: 0,
                    color: isSelected
                        ? staged.onPrimary.withValues(alpha: 0.88)
                        : secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentThemeHero(
    PaletteData staged,
    PaletteData active,
    bool isDark,
    bool hasUnsavedChanges,
  ) {
    final isStagedApplied = staged.id == active.id;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? staged.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: staged.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: staged.primary.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Themed Preview Box with FoodGo Icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: staged.headerGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: staged.auraColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(staged.icon, color: staged.onPrimary, size: 26),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Tagline, & Active Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Active Style: ${staged.nameEn}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isStagedApplied
                                ? const Color(0xFF15803D)
                                : staged.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isStagedApplied
                                            ? const Color(0xFF15803D)
                                            : staged.primary)
                                        .withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isStagedApplied
                                    ? Icons.check_rounded
                                    : Icons.visibility_rounded,
                                size: 11,
                                color: isStagedApplied
                                    ? Colors.white
                                    : staged.onPrimary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isStagedApplied ? 'Active' : 'Preview',
                                style: textTheme.labelSmall?.copyWith(
                                  color: isStagedApplied
                                      ? Colors.white
                                      : staged.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      staged.descriptionEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildMiniColorDot(staged.primary),
                        const SizedBox(width: 5),
                        _buildMiniColorDot(staged.primaryAccent),
                        const SizedBox(width: 5),
                        _buildMiniColorDot(staged.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            staged.nameKh,
                            style: textTheme.labelSmall?.copyWith(
                              fontFamily: AppTheme.khmerPrimaryFont,
                              fontFamilyFallback: AppTheme.khmerFontFallbacks,
                              height: 1.5,
                              letterSpacing: 0,
                              color: secondaryText,
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

          // Apply Button if unsaved changes
          if (hasUnsavedChanges) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyTheme,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('Apply "${staged.nameEn}"'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: staged.primary,
                      foregroundColor: staged.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _resetStaged,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 14,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSectionTitle(String title, String subtitle, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: textTheme.labelSmall?.copyWith(
            fontFamily: AppTheme.khmerPrimaryFont,
            fontFamilyFallback: AppTheme.khmerFontFallbacks,
            height: 1.5,
            letterSpacing: 0,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniColorDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGallery(
    List<PaletteData> palettes,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 620
            ? 2
            : (constraints.maxWidth < 920 ? 3 : 4);
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: palettes.map((p) {
            final isStaged = _stagedPalette == p.id;
            final isCurrentlyApplied = themeProvider.currentPalette == p.id;
            return SizedBox(
              width: cardWidth,
              child: _buildThemeCard(
                palette: p,
                isStaged: isStaged,
                isApplied: isCurrentlyApplied,
                isDark: isDark,
                onTap: () => _stageTheme(p.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitleKh) {
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitleKh,
          style: textTheme.bodySmall?.copyWith(
            fontFamily: AppTheme.khmerPrimaryFont,
            fontFamilyFallback: AppTheme.khmerFontFallbacks,
            height: 1.5,
            letterSpacing: 0,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceModeSelector(
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final modes = [
      {
        'mode': ThemeMode.system,
        'label': 'System',
        'icon': AppIcons.systemMode,
      },
      {'mode': ThemeMode.light, 'label': 'Light', 'icon': AppIcons.lightMode},
      {'mode': ThemeMode.dark, 'label': 'Dark', 'icon': AppIcons.darkMode},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181F2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activePalette.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        m['icon'] as IconData,
                        size: AppIconSizes.sm,
                        color: isSelected
                            ? activePalette.onPrimary
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m['label'] as String,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? activePalette.onPrimary
                              : (isDark ? Colors.white70 : primaryText),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferencesCard(
    ThemeProvider provider,
    bool isDark,
    PaletteData palette,
  ) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final titleStyle = textTheme.bodyMedium?.copyWith(
      color: primaryText,
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = textTheme.labelSmall?.copyWith(
      fontFamily: AppTheme.khmerPrimaryFont,
      fontFamilyFallback: AppTheme.khmerFontFallbacks,
      height: 1.5,
      letterSpacing: 0,
      color: secondaryText,
    );

    return Material(
      color: isDark ? palette.surfaceCardDark : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: provider.seasonalDecorationsEnabled,
              activeThumbColor: palette.primary,
              title: Text('Festive Decorations & Greetings', style: titleStyle),
              subtitle: Text(
                'បង្ហាញបដា និងពាក្យជូនពរពិធីបុណ្យជាតិនៅលើទំព័រដើម',
                style: subtitleStyle,
              ),
              onChanged: (val) => provider.setSeasonalDecorationsEnabled(val),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.reducedMotion,
              activeThumbColor: palette.primary,
              title: Text('Reduced Motion Transitions', style: titleStyle),
              subtitle: Text(
                'កាត់បន្ថយចលនា សម្រាប់ដំណើរការរលូនលើទូរស័ព្ទកម្រិតទាប',
                style: subtitleStyle,
              ),
              onChanged: (val) => provider.setReducedMotion(val),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.snowfallEnabled,
              activeThumbColor: palette.primary,
              title: Text('Christmas Snowfall Animation', style: titleStyle),
              subtitle: Text(
                'ធ្លាក់ព្រិលបែបវេទមន្តសម្រាប់រដូវកាលណូអែល (Snowfall Effect)',
                style: subtitleStyle,
              ),
              onChanged: (val) => provider.setSnowfallEnabled(val),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.skinBackdropEnabled,
              activeThumbColor: palette.primary,
              title: Text('Themed Skin Backdrops & Meshes', style: titleStyle),
              subtitle: Text(
                'បង្ហាញផ្ទៃខាងក្រោយ និងក្បាច់លម្អតាមប្រធានបទនីមួយៗ (Built-in Skin Backdrops)',
                style: subtitleStyle,
              ),
              onChanged: (val) => provider.setSkinBackdropEnabled(val),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.skinAnimationEnabled,
              activeThumbColor: palette.primary,
              title: Text('Animated Theme Skins & Meshes', style: titleStyle),
              subtitle: Text(
                'ចលនារលក ពន្លឺ និងក្បាច់លម្អរស់រវើកនៅលើផ្ទៃខាងក្រោយ (Dynamic Harmonic Motion)',
                style: subtitleStyle,
              ),
              onChanged: (val) => provider.setSkinAnimationEnabled(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard(
    PaletteData staged,
    bool isDark,
    bool hasUnsavedChanges,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final accentColor = _accessibleAccent(staged.primary, isDark);
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                      ),
                      Text(
                        ThemeStyles.getFestivalSubtitleKh(staged),
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    staged.badgeText.isNotEmpty
                        ? staged.badgeText
                        : 'LIVE PREVIEW',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4-Screen Mockup Tab Selector matching reference mockup (Home, Details, Cart, Profile)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                _buildScreenTab(0, 'Home', AppIcons.home, staged),
                const SizedBox(width: 6),
                _buildScreenTab(1, 'Details', AppIcons.burger, staged),
                const SizedBox(width: 6),
                _buildScreenTab(2, 'Cart', AppIcons.cart, staged),
                const SizedBox(width: 6),
                _buildScreenTab(3, 'Profile', AppIcons.profile, staged),
              ],
            ),
          ),

          // Sleek Mini Phone Mockup Frame
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 330,
            decoration: BoxDecoration(
              color: isDark ? staged.backgroundDark : staged.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: staged.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ThemedSkinBackdrop(
              customPalette: staged,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey<String>('$_previewTab-${staged.id.name}'),
                  child: _previewTab == 0
                      ? _buildHomeMockup(staged, isDark)
                      : _previewTab == 1
                      ? _buildDetailsMockup(staged, isDark)
                      : _previewTab == 2
                      ? _buildCartMockup(staged, isDark)
                      : _buildProfileMockup(staged, isDark),
                ),
              ),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: staged.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: staged.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(staged.icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Previewing: ${staged.nameEn}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Skin Backdrop: ${staged.backdropNameEn}',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staged.descriptionEn,
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
                          child: Text(
                            'Revert',
                            style: textTheme.labelLarge?.copyWith(
                              color: primaryText,
                            ),
                          ),
                        ),
                      ),
                    if (hasUnsavedChanges) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: hasUnsavedChanges ? _applyTheme : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: staged.primary,
                          foregroundColor: staged.onPrimary,
                          disabledBackgroundColor: staged.primary.withValues(
                            alpha: 0.4,
                          ),
                          disabledForegroundColor: staged.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          hasUnsavedChanges ? 'Apply Theme' : 'Theme Applied',
                          style: textTheme.labelLarge?.copyWith(
                            color: staged.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildScreenTab(
    int index,
    String label,
    IconData icon,
    PaletteData staged,
  ) {
    final isSelected = _previewTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _accessibleAccent(staged.primary, isDark);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _previewTab = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? staged.primary
                : staged.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? staged.primary
                  : staged.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? staged.onPrimary : accentColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? staged.onPrimary : accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeMockup(PaletteData staged, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = AppTypography.primaryTextColor(brightness);
    final mutedCol = AppTypography.secondaryTextColor(brightness);
    final accentColor = _accessibleAccent(staged.primary, isDark);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Mini Location & Notification Bar
          Row(
            children: [
              Icon(AppIcons.location, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Phnom Penh, Cambodia',
                        maxLines: 2,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(AppIcons.chevronDown, size: 12, color: mutedCol),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Stack(
                children: [
                  Icon(AppIcons.notifications, size: 18, color: textCol),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: staged.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini Search Bar
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: staged.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.search, size: 13, color: mutedCol),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Search burgers, pizza, drinks...',
                    style: textTheme.bodySmall?.copyWith(color: mutedCol),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(AppIcons.filter, size: 13, color: accentColor),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mini Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMiniPill('All', isSelected: true, staged: staged),
                const SizedBox(width: 6),
                _buildMiniPill(
                  'Burgers',
                  isSelected: false,
                  staged: staged,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildMiniPill(
                  'Pizza',
                  isSelected: false,
                  staged: staged,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildMiniPill(
                  'Drinks',
                  isSelected: false,
                  staged: staged,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mini Promo Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: staged.headerGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: staged.primary.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '20% OFF DEALS',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Summer Flavor Fest',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Free delivery on orders \$15+',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  staged.icon,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mini Dishes Grid (2 cards)
          Row(
            children: [
              Expanded(
                child: _buildMiniDishCard(
                  title: 'Cheeseburger',
                  price: '\$6.50',
                  rating: '4.9',
                  icon: AppIcons.burger,
                  staged: staged,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniDishCard(
                  title: 'Supreme Pizza',
                  price: '\$8.20',
                  rating: '4.8',
                  icon: AppIcons.pizza,
                  staged: staged,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(
    String label, {
    required bool isSelected,
    required PaletteData staged,
    bool isDark = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? staged.primary
            : (isDark ? staged.surfaceCardDark : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? staged.primary
              : staged.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? staged.onPrimary
              : AppTypography.primaryTextColor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
        ),
      ),
    );
  }

  Widget _buildMiniDishCard({
    required String title,
    required String price,
    required String rating,
    required IconData icon,
    required PaletteData staged,
    required bool isDark,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final accentColor = _accessibleAccent(staged.primary, isDark);
    final starColor = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: staged.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: staged.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(AppIcons.star, size: 11, color: starColor),
              const SizedBox(width: 2),
              Text(
                rating,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: starColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: staged.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.add, size: 10, color: staged.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsMockup(PaletteData staged, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = AppTypography.primaryTextColor(brightness);
    final mutedCol = AppTypography.secondaryTextColor(brightness);
    final accentColor = _accessibleAccent(staged.primary, isDark);
    final totalPrice = 6.50 * _detailsQuantity;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini App Bar
          Row(
            children: [
              Icon(AppIcons.back, size: 16, color: textCol),
              const SizedBox(width: 8),
              Text(
                'Food Details',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                ),
              ),
              const Spacer(),
              Icon(
                AppIcons.favorite,
                size: 16,
                color: _accessibleAccent(staged.accent, isDark),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hero Dish Banner
          Container(
            height: 76,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  staged.primary.withValues(alpha: 0.22),
                  staged.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: staged.primary.withValues(alpha: 0.2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(AppIcons.burger, size: 44, color: accentColor),
                Positioned(
                  top: 6,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: staged.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BESTSELLER',
                      style: textTheme.labelSmall?.copyWith(
                        color: staged.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title & Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cheeseburger Deluxe',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    Text(
                      'Angus beef patty, cheddar, brioche bun, house sauce',
                      style: textTheme.labelSmall?.copyWith(color: mutedCol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nutrition / Tags row
          Row(
            children: [
              _buildTagChip(
                '4.9 (320)',
                icon: Icons.star_rounded,
                isDark: isDark,
                staged: staged,
              ),
              const SizedBox(width: 6),
              _buildTagChip(
                '15-20 min',
                icon: Icons.schedule_rounded,
                isDark: isDark,
                staged: staged,
              ),
              const SizedBox(width: 6),
              _buildTagChip(
                '450 kcal',
                icon: Icons.local_fire_department_rounded,
                isDark: isDark,
                staged: staged,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive Quantity Stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: staged.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Text(
                  'Quantity Stepper:',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textCol,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    if (_detailsQuantity > 1) {
                      setState(() => _detailsQuantity--);
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: staged.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(AppIcons.remove, size: 13, color: accentColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$_detailsQuantity',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textCol,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _detailsQuantity++);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: staged.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      AppIcons.add,
                      size: 13,
                      color: staged.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mini Add to Cart Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: staged.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.cart, size: 13, color: staged.onPrimary),
                const SizedBox(width: 6),
                Text(
                  'Add to Cart • \$${totalPrice.toStringAsFixed(2)}',
                  style: textTheme.labelLarge?.copyWith(
                    color: staged.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(
    String label, {
    IconData? icon,
    required bool isDark,
    required PaletteData staged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final textColor = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final accentColor = _accessibleAccent(staged.primary, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: staged.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: accentColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartMockup(PaletteData staged, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = AppTypography.primaryTextColor(brightness);
    final mutedCol = AppTypography.secondaryTextColor(brightness);
    final accentColor = _accessibleAccent(staged.primary, isDark);
    final freeGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Cart (2 items)',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: textCol,
                ),
              ),
              const Spacer(),
              Text(
                'Phnom Penh Delivery',
                style: textTheme.labelSmall?.copyWith(color: mutedCol),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cart Item 1
          _buildMiniCartItem(
            name: 'Cheeseburger Deluxe',
            options: 'Large • Extra Cheese',
            price: '\$6.50',
            qty: '1',
            icon: AppIcons.burger,
            staged: staged,
            isDark: isDark,
          ),
          const SizedBox(height: 6),

          // Cart Item 2
          _buildMiniCartItem(
            name: 'Iced Green Tea Splash',
            options: '50% Sugar • Normal Ice',
            price: '\$2.50',
            qty: '1',
            icon: AppIcons.drink,
            staged: staged,
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // Promo Code Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: staged.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: staged.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.coupon, size: 13, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'FOODGO20 Applied (-\$1.80)',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                Icon(AppIcons.checkCircle, size: 13, color: freeGreen),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mini Price Breakdown
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: staged.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: textTheme.labelSmall?.copyWith(color: mutedCol),
                    ),
                    Text(
                      '\$9.00',
                      style: textTheme.labelSmall?.copyWith(color: textCol),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Fee',
                      style: textTheme.labelSmall?.copyWith(color: mutedCol),
                    ),
                    Text(
                      'FREE',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: freeGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    Text(
                      '\$7.20',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Checkout CTA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: staged.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Checkout',
                  style: textTheme.labelLarge?.copyWith(
                    color: staged.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(AppIcons.forward, size: 12, color: staged.onPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCartItem({
    required String name,
    required String options,
    required String price,
    required String qty,
    required IconData icon,
    required PaletteData staged,
    required bool isDark,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = AppTypography.primaryTextColor(brightness);
    final mutedCol = AppTypography.secondaryTextColor(brightness);
    final accentColor = _accessibleAccent(staged.primary, isDark);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: staged.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: staged.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: accentColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textCol,
                  ),
                ),
                Text(
                  options,
                  style: textTheme.labelSmall?.copyWith(color: mutedCol),
                ),
              ],
            ),
          ),
          Text('x$qty', style: textTheme.labelSmall?.copyWith(color: mutedCol)),
          const SizedBox(width: 6),
          Text(
            price,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            AppIcons.delete,
            size: 12,
            color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMockup(PaletteData staged, bool isDark) {
    final textTheme = Theme.of(context).textTheme;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final mutedCol = AppTypography.secondaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final accentColor = _accessibleAccent(staged.primary, isDark);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile User Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: staged.headerGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'RK',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _accessibleAccent(staged.primary, false),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ratanak Keo',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Keo.Ratanak@gmail.com',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.star, size: 10, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        'VIP GOLD',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mini Stats Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: staged.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'FoodGo Balance',
                        style: textTheme.labelSmall?.copyWith(color: mutedCol),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$48.50',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: mutedCol.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Active Orders',
                        style: textTheme.labelSmall?.copyWith(color: mutedCol),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 In Transit',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _accessibleAccent(staged.accent, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Menu rows
          _buildMiniProfileRow('My Orders', AppIcons.orders, staged, isDark),
          const SizedBox(height: 5),
          _buildMiniProfileRow(
            'Payment Methods',
            AppIcons.payment,
            staged,
            isDark,
          ),
          const SizedBox(height: 5),
          _buildMiniProfileRow(
            'Theme: ${staged.nameEn}',
            AppIcons.theme,
            staged,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProfileRow(
    String title,
    IconData icon,
    PaletteData staged,
    bool isDark,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = AppTypography.primaryTextColor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final accentColor = _accessibleAccent(staged.primary, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: staged.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textCol,
              ),
            ),
          ),
          Icon(
            AppIcons.chevronRight,
            size: 12,
            color: accentColor.withValues(alpha: 0.7),
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
    final textTheme = Theme.of(context).textTheme;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final accentColor = _accessibleAccent(palette.primary, isDark);
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final borderColor = isApplied
        ? palette.primary
        : (isStaged
              ? palette.primaryAccent
              : (isDark ? Colors.white12 : Colors.black12));
    final cardBg = isDark ? palette.surfaceCardDark : Colors.white;

    return Semantics(
      button: true,
      selected: isApplied,
      label:
          '${palette.nameEn}. ${palette.descriptionEn}${isApplied
              ? '. Active theme.'
              : isStaged
              ? '. Previewing.'
              : ''}',
      child: ExcludeSemantics(
        child: AnimatedPressable(
          onTap: onTap,
          pressedScale: 0.97,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: (isApplied || isStaged) ? 2.2 : 1.0,
              ),
              boxShadow: (isApplied || isStaged)
                  ? [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Visual Theme Skin Preview Canvas ───────────────────
                Container(
                  height: 105,
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: palette.headerGradient),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Atmospheric background art
                      CustomPaint(
                        painter: _ThemeCardPreviewPainter(palette: palette),
                      ),

                      // Center Floating Icon Badge
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.auraColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            palette.icon,
                            color: palette.onPrimary,
                            size: 22,
                          ),
                        ),
                      ),

                      // Top-Left Category / Style Badge
                      if (palette.badgeText.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              palette.badgeText,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),

                      // Top-Right Active / In-Season Pill
                      Positioned(
                        top: 8,
                        right: 8,
                        child: isApplied
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF15803D,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Active',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (palette.isSeasonallyActive
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB45309),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'In Season',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),

                // ── 2. Theme Typography & Info ───────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        palette.nameEn,
                        maxLines: 2,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        palette.nameKh,
                        maxLines: 2,
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: AppTheme.khmerPrimaryFont,
                          fontFamilyFallback: AppTheme.khmerFontFallbacks,
                          height: 1.5,
                          letterSpacing: 0,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        palette.descriptionEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Swatches & Selection Indicator
                      Row(
                        children: [
                          _buildMiniColorDot(palette.primary),
                          const SizedBox(width: 5),
                          _buildMiniColorDot(palette.primaryAccent),
                          const SizedBox(width: 5),
                          _buildMiniColorDot(palette.secondary),
                          const Spacer(),
                          if (isApplied)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: accentColor,
                            )
                          else if (isStaged)
                            Text(
                              'Staged',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            )
                          else
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black26,
                                  width: 1.5,
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
          ),
        ),
      ),
    );
  }
}

class _ThemeCardPreviewPainter extends CustomPainter {
  final PaletteData palette;
  const _ThemeCardPreviewPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Draw decorative ambient circles and highlights
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, 20), 40, paint1);

    final paint2 = Paint()
      ..color = palette.auraColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 35, paint2);

    // Subtle diagonal decorative lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width * 0.6, 0),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height),
      Offset(size.width, size.height * 0.3),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThemeCardPreviewPainter oldDelegate) =>
      oldDelegate.palette.id != palette.id;
}
