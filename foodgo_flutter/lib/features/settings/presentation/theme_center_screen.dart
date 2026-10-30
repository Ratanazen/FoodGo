import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_styles.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/glass/animated_pressable.dart';
import '../../../widgets/glass/themed_skin_backdrop.dart';
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
  int _previewTab = 0; // 0: Home, 1: Details, 2: Cart, 3: Profile
  int _detailsQuantity = 2;

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

    final categories = [
      'All',
      ...PaletteData.allPalettes.map((p) => p.categoryEn).toSet(),
    ];

    final filteredPalettes = _activeCategoryFilter == 'All'
        ? PaletteData.allPalettes
        : PaletteData.allPalettes
              .where((p) => p.categoryEn == _activeCategoryFilter)
              .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            AppIcons.back,
            color: isDark ? Colors.white : Colors.black87,
            size: AppIconSizes.sm,
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
          if (MediaQuery.sizeOf(context).width >= 420)
            TextButton.icon(
              onPressed: _restoreDefaults,
              icon: const Icon(AppIcons.reset, size: AppIconSizes.xs),
              label: const Text('Reset All', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
              ),
            )
          else
            IconButton(
              onPressed: _restoreDefaults,
              icon: const Icon(AppIcons.reset, size: AppIconSizes.md),
              tooltip: 'Reset all themes',
            ),
          const SizedBox(width: 8),
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
                // ── 1. Live Preview Sandbox ──────────────────────────────────
                _buildLivePreviewCard(stagedData, isDark, hasUnsavedChanges),
                const SizedBox(height: 24),

                // ── 2. Appearance Mode (Light / Dark / System) ───────────────
                _buildSectionHeader(
                  'Appearance Mode',
                  'របៀបបង្ហាញពន្លឺ និងរាត្រី',
                ),
                const SizedBox(height: 12),
                _buildAppearanceModeSelector(themeProvider, isDark),
                const SizedBox(height: 24),

                // ── 3. Festive & Motion Preferences ─────────────────────────
                _buildSectionHeader(
                  'Experience Preferences',
                  'ជម្រើសពិធីបុណ្យ និងចលនា',
                ),
                const SizedBox(height: 12),
                _buildPreferencesCard(themeProvider, isDark, activeData),
                const SizedBox(height: 24),

                // ── 4. Theme Preset Gallery ─────────────────────────────────
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
                          labelStyle: TextStyle(
                            color: isSelected
                                ? stagedData.onPrimary
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
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
                _buildThemeGallery(filteredPalettes, themeProvider, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeGallery(
    List<PaletteData> palettes,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final cards = palettes.map((p) {
      final isStaged = _stagedPalette == p.id;
      final isCurrentlyApplied = themeProvider.currentPalette == p.id;
      return _buildThemeCard(
        palette: p,
        isStaged: isStaged,
        isApplied: isCurrentlyApplied,
        isDark: isDark,
        onTap: () => _stageTheme(p.id),
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
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

  Widget _buildAppearanceModeSelector(
    ThemeProvider themeProvider,
    bool isDark,
  ) {
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
                      size: AppIconSizes.sm,
                      color: isSelected
                          ? activePalette.onPrimary
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        m['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? activePalette.onPrimary
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
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

  Widget _buildPreferencesCard(
    ThemeProvider provider,
    bool isDark,
    PaletteData palette,
  ) {
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
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.snowfallEnabled,
              activeThumbColor: palette.primary,
              title: const Text(
                'Christmas Snowfall Animation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'ធ្លាក់ព្រិលបែបវេទមន្តសម្រាប់រដូវកាលណូអែល (Snowfall Effect)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onChanged: (val) => provider.setSnowfallEnabled(val),
            ),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            SwitchListTile(
              value: provider.skinBackdropEnabled,
              activeThumbColor: palette.primary,
              title: const Text(
                'Themed Skin Backdrops & Meshes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'បង្ហាញផ្ទៃខាងក្រោយ និងក្បាច់លម្អតាមប្រធានបទនីមួយៗ (Built-in Skin Backdrops)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              onChanged: (val) => provider.setSkinBackdropEnabled(val),
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
                      child: Icon(staged.icon, color: staged.primary, size: 24),
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
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: staged.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Skin Backdrop: ${staged.backdropNameEn}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: staged.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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

  Widget _buildScreenTab(
    int index,
    String label,
    IconData icon,
    PaletteData staged,
  ) {
    final isSelected = _previewTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _previewTab = index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
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
                color: isSelected ? staged.onPrimary : staged.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? staged.onPrimary : staged.primary,
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
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Mini Location & Notification Bar
          Row(
            children: [
              Icon(AppIcons.location, size: 14, color: staged.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Phnom Penh, Cambodia',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
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
                    style: TextStyle(fontSize: 10, color: mutedCol),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(AppIcons.filter, size: 13, color: staged.primary),
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
                        child: const Text(
                          '20% OFF DEALS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Summer Flavor Fest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Free delivery on orders \$15+',
                        style: TextStyle(color: Colors.white70, fontSize: 9.5),
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
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? staged.onPrimary
              : (isDark ? Colors.white70 : Colors.black87),
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
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);

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
              child: Icon(icon, color: staged.primary, size: 20),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ),
              Icon(AppIcons.star, size: 9, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 1),
              Text(
                rating,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: staged.primary,
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
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF6B7280);
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
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const Spacer(),
              Icon(AppIcons.favorite, size: 16, color: staged.accent),
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
                Icon(AppIcons.burger, size: 44, color: staged.primary),
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
                      style: TextStyle(
                        color: staged.onPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
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
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    Text(
                      'Angus beef patty, cheddar, brioche bun, house sauce',
                      style: TextStyle(fontSize: 9.5, color: mutedCol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: staged.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nutrition / Tags row
          Row(
            children: [
              _buildTagChip('★ 4.9 (320)', isDark: isDark, staged: staged),
              const SizedBox(width: 6),
              _buildTagChip('⏱️ 15-20 min', isDark: isDark, staged: staged),
              const SizedBox(width: 6),
              _buildTagChip('🔥 450 kcal', isDark: isDark, staged: staged),
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
                  style: TextStyle(
                    fontSize: 10.5,
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
                    child: Icon(
                      AppIcons.remove,
                      size: 13,
                      color: staged.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$_detailsQuantity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
                  style: TextStyle(
                    color: staged.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
    required bool isDark,
    required PaletteData staged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: staged.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCartMockup(PaletteData staged, bool isDark) {
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF6B7280);

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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const Spacer(),
              Text(
                'Phnom Penh Delivery',
                style: TextStyle(fontSize: 9.5, color: mutedCol),
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
                Icon(AppIcons.coupon, size: 13, color: staged.primary),
                const SizedBox(width: 6),
                Text(
                  'FOODGO20 Applied (-\$1.80)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: staged.primary,
                  ),
                ),
                const Spacer(),
                Icon(AppIcons.checkCircle, size: 13, color: Colors.green),
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
                      style: TextStyle(fontSize: 9.5, color: mutedCol),
                    ),
                    Text(
                      '\$9.00',
                      style: TextStyle(fontSize: 9.5, color: textCol),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Fee',
                      style: TextStyle(fontSize: 9.5, color: mutedCol),
                    ),
                    Text(
                      'FREE',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    Text(
                      '\$7.20',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: staged.primary,
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
                  style: TextStyle(
                    color: staged.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF6B7280);

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
            child: Icon(icon, size: 15, color: staged.primary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                Text(options, style: TextStyle(fontSize: 8.5, color: mutedCol)),
              ],
            ),
          ),
          Text('x$qty', style: TextStyle(fontSize: 9.5, color: mutedCol)),
          const SizedBox(width: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: staged.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            AppIcons.delete,
            size: 12,
            color: Colors.red.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMockup(PaletteData staged, bool isDark) {
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final mutedCol = isDark ? Colors.white60 : const Color(0xFF6B7280);

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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: staged.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ratanak Keo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Keo.Ratanak@gmail.com',
                        style: TextStyle(color: Colors.white70, fontSize: 9),
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
                      const Text(
                        'VIP GOLD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
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
                        style: TextStyle(fontSize: 8.5, color: mutedCol),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$48.50',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: staged.primary,
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
                        style: TextStyle(fontSize: 8.5, color: mutedCol),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 In Transit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: staged.accent,
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
    final cardBg = isDark ? staged.surfaceCardDark : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF1F2937);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: staged.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: staged.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textCol,
              ),
            ),
          ),
          Icon(
            AppIcons.chevronRight,
            size: 12,
            color: staged.primary.withValues(alpha: 0.6),
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
    return Semantics(
      button: true,
      selected: isApplied,
      label:
          '${palette.nameEn}. ${palette.descriptionEn}'
          '${isApplied
              ? '. Active theme.'
              : isStaged
              ? '. Previewing.'
              : ''}',
      child: ExcludeSemantics(
        child: AnimatedPressable(
          onTap: onTap,
          pressedScale: 0.98,
          child: Container(
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
                  child: Icon(
                    palette.icon,
                    color: palette.onPrimary,
                    size: AppIconSizes.md,
                  ),
                ),
                const SizedBox(width: 14),

                // Theme details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        palette.nameEn,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (palette.badgeText.isNotEmpty ||
                          palette.isSeasonallyActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (palette.badgeText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.primary.withValues(
                                      alpha: 0.16,
                                    ),
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
                              if (palette.isSeasonallyActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'IN SEASON',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: palette.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 9.5,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        palette.backdropNameEn,
                                        style: TextStyle(
                                          color: palette.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          Flexible(
                            child: Text(
                              palette.categoryEn,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.primary, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.checkCircle,
                          size: 14,
                          color: palette.primary,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                    AppIcons.chevronRight,
                    color: isDark ? Colors.white30 : Colors.black26,
                    size: AppIconSizes.md,
                  ),
              ],
            ),
          ),
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
