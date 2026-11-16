import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/glass_container.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../widgets/phone_verification_modal.dart';
import '../../../widgets/svg_icon.dart';
import '../../../widgets/about_foodgo_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final brightness = Theme.of(dialogCtx).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(dialogCtx).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final dangerColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
        final isKhmer = Localizations.localeOf(dialogCtx).languageCode == 'km';
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
          title: Text(
            context.tr('settings.logoutConfirmTitle'),
            style: textTheme.titleLarge?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
              height: isKhmer ? 1.5 : null,
              letterSpacing: isKhmer ? 0 : null,
            ),
          ),
          content: Text(
            context.tr('settings.logoutConfirmMessage'),
            style: textTheme.bodyMedium?.copyWith(
              color: secondaryText,
              height: isKhmer ? 1.5 : null,
              letterSpacing: isKhmer ? 0 : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                context.tr('common.cancel'),
                style: textTheme.labelLarge?.copyWith(
                  color: secondaryText,
                  height: isKhmer ? 1.5 : null,
                  letterSpacing: isKhmer ? 0 : null,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final userProvider = context.read<UserProvider>();
                final router = GoRouter.of(context);
                final messenger = ScaffoldMessenger.maybeOf(context);
                Navigator.pop(dialogCtx);
                await authProvider.logout();
                messenger?.clearSnackBars();
                userProvider.clearUser();
                router.go('/login');
              },
              child: Text(
                context.tr('auth.logout'),
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: isKhmer ? 1.5 : null,
                  letterSpacing: isKhmer ? 0 : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(ctx).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final accentGreen = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
        final paymentMethods = [
          (
            icon: AppIcons.qrCode,
            color: isDark ? Colors.redAccent : const Color(0xFFB91C1C),
            title: 'Bakong KHQR (National Bank of Cambodia)',
            subtitle: 'Universal QR in USD & KHR across all member banks',
          ),
          (
            icon: AppIcons.bankTransfer,
            color: isDark ? Colors.cyanAccent : const Color(0xFF0E7490),
            title: 'ABA Mobile KHQR / PayWay',
            subtitle: 'Direct scan-to-pay via ABA Mobile app',
          ),
          (
            icon: AppIcons.creditCard,
            color: isDark ? Colors.lightBlueAccent : const Color(0xFF1D4ED8),
            title: 'ACLEDA Bank KHQR / x-Pay',
            subtitle: 'Instant payment via ACLEDA Mobile banking',
          ),
          (
            icon: AppIcons.payment,
            color: isDark ? Colors.amberAccent : const Color(0xFFB45309),
            title: 'Cash on Delivery (COD)',
            subtitle: 'Pay cash directly to driver upon order arrival',
          ),
        ];

        return ResponsiveBottomSheet(
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            AppIcons.payment,
                            color: accentGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Payment Methods',
                            style: textTheme.titleLarge?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FoodGo supports secure banking rails and cash on delivery in Cambodia.',
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...paymentMethods.map(
                      (method) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: method.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              method.icon,
                              color: method.color,
                              size: 21,
                            ),
                          ),
                          title: Text(
                            method.title,
                            style: textTheme.bodyMedium?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            method.subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/orders');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryText,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.18),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'View Orders & Receipts',
                              textAlign: TextAlign.center,
                              style: textTheme.labelLarge?.copyWith(
                                color: primaryText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                ctx,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                ctx,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: textTheme.labelLarge?.copyWith(
                                color: Theme.of(ctx).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final accentAmber = isDark ? Colors.amber : const Color(0xFFB45309);
    final dangerRed = isDark ? Colors.redAccent : const Color(0xFFB91C1C);

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
                  return Center(
                    child: CircularProgressIndicator(color: accentGreen),
                  );
                }
                final String displayName = userProvider.displayName;
                final String email = userProvider.email.isNotEmpty
                    ? userProvider.email
                    : (user?['username'] != null
                          ? '${user!['username']}@foodgo.app'
                          : 'guest@example.com');
                final String username = user?['username']?.toString() ?? '';
                final String phone = userProvider.phone;
                final bool isPhoneVerified = user?['is_phone_verified'] == true;
                final String? avatarUrl = userProvider.avatarUrl;
                final String initials = userProvider.initials;

                return Column(
                  children: [
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? GlassTheme.dynamicSurfaceCardDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? GlassTheme.dynamicBorderDark
                                  : const Color(0xFFE5E7EB),
                              width: 1.0,
                            ),
                            boxShadow: [
                              GlassTheme.dynamicSoftShadow(isDark: isDark),
                            ],
                          ),
                          child: Column(
                            children: [
                              AnimatedPressable(
                                pressedScale: 0.93,
                                onTap: () => context.push('/edit-profile'),
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: GlassTheme.primaryGreen,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: GlassTheme.primaryGreen
                                                .withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child:
                                          avatarUrl != null &&
                                              avatarUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: avatarUrl,
                                              imageBuilder:
                                                  (ctx, imageProvider) =>
                                                      CircleAvatar(
                                                        radius: 40,
                                                        backgroundImage:
                                                            imageProvider,
                                                      ),
                                              placeholder: (ctx, url) =>
                                                  const CircleAvatar(
                                                    radius: 40,
                                                    backgroundColor: GlassTheme
                                                        .lightGreenSurface,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: GlassTheme
                                                              .primaryGreen,
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                              errorWidget: (ctx, url, err) =>
                                                  CircleAvatar(
                                                    radius: 40,
                                                    backgroundColor: GlassTheme
                                                        .lightGreenSurface,
                                                    child: Text(
                                                      initials,
                                                      style: textTheme
                                                          .displayLarge
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: const Color(
                                                              0xFF15803D,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                            )
                                          : CircleAvatar(
                                              radius: 40,
                                              backgroundColor:
                                                  GlassTheme.lightGreenSurface,
                                              child: Text(
                                                initials,
                                                style: textTheme.displayLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF15803D,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF15803D),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          AppIcons.edit,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                displayName,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                  height: 1.4,
                                  letterSpacing: 0,
                                ),
                              ),
                              if (username.isNotEmpty &&
                                  username != displayName &&
                                  !username.startsWith('adb_user_')) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '@$username',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: textTheme.bodySmall?.copyWith(
                                  color: secondaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.phone,
                                    size: 14,
                                    color: accentGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone.isNotEmpty
                                        ? phone
                                        : 'No phone linked',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: primaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isPhoneVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: GlassTheme.primaryGreen
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: GlassTheme.primaryGreen
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            AppIcons.successFilled,
                                            size: 10,
                                            color: accentGreen,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Verified',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  color: accentGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    AnimatedPressable(
                                      pressedScale: 0.92,
                                      onTap: () => PhoneVerificationModal.show(
                                        context,
                                        initialPhone: phone,
                                        purpose: 'customer_verification',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.withValues(
                                              alpha: 0.5,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              AppIcons.warning,
                                              size: 10,
                                              color: accentAmber,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Verify SMS',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: accentAmber,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        context.push('/edit-profile'),
                                    icon: Icon(
                                      AppIcons.edit,
                                      size: 14,
                                      color: accentGreen,
                                    ),
                                    label: Text(
                                      context.tr(
                                        'profile.editProfile',
                                        fallback: 'Edit Profile',
                                      ),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: primaryText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: GlassTheme.primaryGreen
                                            .withValues(alpha: 0.5),
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      backgroundColor: GlassTheme.primaryGreen
                                          .withValues(alpha: 0.08),
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      LocaleProvider? localeProvider;
                                      try {
                                        localeProvider = context
                                            .watch<LocaleProvider>();
                                      } catch (_) {
                                        localeProvider = null;
                                      }
                                      final isKhmer =
                                          localeProvider?.isKhmer ?? false;
                                      return InkWell(
                                        onTap: () {
                                          try {
                                            context
                                                .read<LocaleProvider>()
                                                .toggleLanguage();
                                          } catch (_) {}
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: GlassTheme.primaryGreen
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: GlassTheme.primaryGreen
                                                  .withValues(alpha: 0.4),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                AppIcons.language,
                                                size: 14,
                                                color: accentGreen,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isKhmer
                                                    ? 'ភាសាខ្មែរ'
                                                    : 'English',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: primaryText,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: isKhmer
                                                          ? 1.5
                                                          : null,
                                                      letterSpacing: isKhmer
                                                          ? 0
                                                          : null,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Quick Action Shortcuts: Addresses, Orders
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedPressable(
                                      pressedScale: 0.94,
                                      onTap: () => context.push('/addresses'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : const Color(0xFFE5E7EB),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              AppIcons.locationOutline,
                                              color: accentGreen,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Addresses',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: primaryText,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AnimatedPressable(
                                      pressedScale: 0.94,
                                      onTap: () => context.push('/orders'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : const Color(0xFFE5E7EB),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              AppIcons.orders,
                                              color: accentGreen,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Orders',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: primaryText,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.08, end: 0),
                    if (user?['role'] == 'restaurant_owner' ||
                        user?['role'] == 'admin') ...[
                      const SizedBox(height: 16),
                      GlassContainer(
                        padding: const EdgeInsets.all(4),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        child: ListTile(
                          leading: Icon(
                            AppIcons.restaurants,
                            color: accentGreen,
                          ),
                          title: Text(
                            'Restaurant Dashboard',
                            style: textTheme.titleMedium?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Icon(
                            AppIcons.chevronRight,
                            color: secondaryText,
                          ),
                          onTap: () => context.push('/restaurant-dashboard'),
                        ),
                      ),
                    ],
                    if (user?['role'] == 'driver' ||
                        user?['role'] == 'admin') ...[
                      const SizedBox(height: 16),
                      GlassContainer(
                        padding: const EdgeInsets.all(4),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        child: ListTile(
                          leading: Icon(AppIcons.delivery, color: accentGreen),
                          title: Text(
                            'Driver Dashboard',
                            style: textTheme.titleMedium?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Icon(
                            AppIcons.chevronRight,
                            color: secondaryText,
                          ),
                          onTap: () => context.push('/driver-dashboard'),
                        ),
                      ),
                    ],
                    if (user?['role'] == 'admin' ||
                        user?['is_staff'] == true) ...[
                      const SizedBox(height: 16),
                      GlassContainer(
                        padding: const EdgeInsets.all(4),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        child: ListTile(
                          leading: Icon(AppIcons.admin, color: accentGreen),
                          title: Text(
                            'Admin Console',
                            style: textTheme.titleMedium?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Platform analytics, orders, users & audit logs',
                            style: textTheme.labelSmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                          trailing: Icon(
                            AppIcons.chevronRight,
                            color: secondaryText,
                          ),
                          onTap: () => context.push('/admin-dashboard'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Account',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final currentUser = ctx.watch<UserProvider>().user;
                final bool isVerified =
                    currentUser?['is_phone_verified'] == true;
                final String userPhone = currentUser?['phone'] ?? '';
                return Column(
                  children: [
                    _ProfileOption(
                      icon: AppIcons.profile,
                      title: 'Edit Profile',
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _ProfileOption(
                      icon: AppIcons.users,
                      title: 'Account Role',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.primaryGreen.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          (currentUser?['role'] ?? 'customer')
                              .toString()
                              .toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        final role = (currentUser?['role'] ?? 'customer')
                            .toString()
                            .toLowerCase();
                        if (role == 'driver') {
                          context.go('/driver-dashboard');
                        } else if (role == 'restaurant_owner') {
                          context.go('/restaurant-dashboard');
                        } else if (role == 'admin') {
                          context.go('/admin-dashboard');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Customer account active. Sign out to register a Driver account, or keep browsing & ordering meals.',
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    _ProfileOption(
                      icon: AppIcons.phone,
                      title: 'Phone Verification (SMS OTP)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? GlassTheme.primaryGreen.withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Unverified',
                          style: textTheme.labelSmall?.copyWith(
                            color: isVerified ? accentGreen : accentAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        PhoneVerificationModal.show(
                          context,
                          initialPhone: userPhone,
                          purpose: 'customer_verification',
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            _ProfileOption(
              icon: AppIcons.orders,
              title: 'My Orders',
              onTap: () => context.push('/orders'),
            ),
            _ProfileOption(
              icon: AppIcons.payment,
              title: 'Payment Methods',
              onTap: () => _showPaymentMethodsModal(context),
            ),
            _ProfileOption(
              icon: AppIcons.locationOutline,
              title: 'Saved Addresses',
              onTap: () => context.push('/addresses'),
            ),
            _ProfileOption(
              icon: AppIcons.notifications,
              title: 'Notifications',
              onTap: () => context.push('/notifications'),
            ),
            _ProfileOption(
              icon: AppIcons.saved,
              title: 'Favorites',
              onTap: () => context.push('/favorites'),
            ),
            const SizedBox(height: 24),
            Text(
              'Settings & Preferences',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 12),
            _ProfileOption(
              icon: AppIcons.settings,
              title: 'General Settings',
              onTap: () => context.push('/settings'),
            ),
            _ProfileOption(
              icon: AppIcons.theme,
              title: 'Theme & Khmer Festivals',
              onTap: () => context.push('/theme-center'),
            ),
            _ProfileOption(
              icon: AppIcons.language,
              title: 'Language',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) {
                    final sheetDark =
                        Theme.of(ctx).brightness == Brightness.dark;
                    final sheetTextTheme = Theme.of(ctx).textTheme;
                    final sheetPrimaryText = AppTypography.primaryTextColor(
                      sheetDark ? Brightness.dark : Brightness.light,
                    );
                    final sheetAccentGreen = sheetDark
                        ? GlassTheme.primaryGreenAccent
                        : const Color(0xFF15803D);
                    return ResponsiveBottomSheet(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: sheetDark
                              ? GlassTheme.dynamicDialogDark
                              : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          border: Border.all(
                            color: sheetDark
                                ? GlassTheme.dynamicBorderDark
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Select Language / ជ្រើសរើសភាសា',
                              style: sheetTextTheme.titleLarge?.copyWith(
                                color: sheetPrimaryText,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text(
                                'English (US)',
                                style: sheetTextTheme.bodyLarge?.copyWith(
                                  color: sheetPrimaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Icon(
                                AppIcons.check,
                                color: sheetAccentGreen,
                              ),
                              onTap: () => Navigator.pop(ctx),
                            ),
                            ListTile(
                              title: Text(
                                'ភាសាខ្មែរ (Khmer)',
                                style: sheetTextTheme.bodyLarge?.copyWith(
                                  color: sheetPrimaryText,
                                  height: 1.5,
                                  letterSpacing: 0,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ភាសាខ្មែរ ត្រូវបានជ្រើសរើស'),
                                    backgroundColor: GlassTheme.primaryGreen,
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              title: Text(
                                'Français (French)',
                                style: sheetTextTheme.bodyLarge?.copyWith(
                                  color: sheetPrimaryText,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Langue française sélectionnée',
                                    ),
                                    backgroundColor: GlassTheme.primaryGreen,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            _ProfileOption(
              icon: AppIcons.help,
              title: 'Help & Support',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) {
                    final sheetDark =
                        Theme.of(ctx).brightness == Brightness.dark;
                    final sheetTextTheme = Theme.of(ctx).textTheme;
                    final sheetPrimaryText = AppTypography.primaryTextColor(
                      sheetDark ? Brightness.dark : Brightness.light,
                    );
                    final sheetSecondaryText = AppTypography.secondaryTextColor(
                      sheetDark ? Brightness.dark : Brightness.light,
                    );
                    final sheetAccentGreen = sheetDark
                        ? GlassTheme.primaryGreenAccent
                        : const Color(0xFF15803D);
                    return ResponsiveBottomSheet(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: sheetDark
                              ? GlassTheme.dynamicDialogDark
                              : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          border: Border.all(
                            color: sheetDark
                                ? GlassTheme.dynamicBorderDark
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'FoodGo 24/7 Support',
                              style: sheetTextTheme.titleLarge?.copyWith(
                                color: sheetPrimaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Get fast help with delivery, payments, or orders.',
                              style: sheetTextTheme.bodySmall?.copyWith(
                                color: sheetSecondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: Icon(
                                AppIcons.support,
                                color: sheetAccentGreen,
                              ),
                              title: Text(
                                'Chat with Support',
                                style: sheetTextTheme.titleMedium?.copyWith(
                                  color: sheetPrimaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Average reply time: 2 mins',
                                style: sheetTextTheme.bodySmall?.copyWith(
                                  color: sheetSecondaryText,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx),
                            ),
                            ListTile(
                              leading: Icon(
                                AppIcons.phone,
                                color: sheetDark
                                    ? Colors.amber
                                    : const Color(0xFFB45309),
                              ),
                              title: Text(
                                'Hotline: +855 23 999 888',
                                style: sheetTextTheme.titleMedium?.copyWith(
                                  color: sheetPrimaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Toll-free customer care',
                                style: sheetTextTheme.bodySmall?.copyWith(
                                  color: sheetSecondaryText,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            _ProfileOption(
              leadingWidget: const FoodGoLogo(size: 22),
              title: 'About FoodGo',
              onTap: () => showAboutFoodGoDialog(context),
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isAuthenticated) {
                  return _ProfileOption(
                    icon: AppIcons.logout,
                    title: 'Logout',
                    textColor: dangerRed,
                    iconColor: dangerRed,
                    onTap: () => _showLogoutDialog(context),
                  );
                } else {
                  return _ProfileOption(
                    icon: AppIcons.login,
                    title: 'Login / Sign Up',
                    textColor: accentGreen,
                    iconColor: accentGreen,
                    onTap: () => context.push('/login'),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => showAboutFoodGoDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GlassTheme.lightGreenSurface,
                        border: Border.all(
                          color: GlassTheme.primaryGreen.withValues(
                            alpha: 0.35,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const FoodGoLogo(size: 32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FoodGo Enterprise Delivery v2.0.0',
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with ',
                        style: textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                      Icon(AppIcons.favorite, color: dangerRed, size: 12),
                      Text(
                        ' in Phnom Penh, Cambodia',
                        style: textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
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
  final IconData? icon;
  final Widget? leadingWidget;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const _ProfileOption({
    this.icon,
    this.leadingWidget,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.trailing,
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
    final dangerRed = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
    final effectiveColor = iconColor ?? GlassTheme.primaryGreen;
    final bool isDestructive =
        effectiveColor == Colors.red ||
        effectiveColor == Colors.redAccent ||
        effectiveColor == const Color(0xFFB91C1C) ||
        effectiveColor == const Color(0xFFEF4444) ||
        textColor == Colors.red ||
        textColor == Colors.redAccent ||
        textColor == const Color(0xFFB91C1C);

    return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: AnimatedPressable(
            pressedScale: 0.97,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDestructive
                    ? (isDark
                          ? const Color(0xFF2D1214)
                          : const Color(0xFFFEF2F2))
                    : (isDark
                          ? GlassTheme.dynamicSurfaceCardDark
                          : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDestructive
                      ? const Color(0xFFFCA5A5)
                      : (isDark
                            ? GlassTheme.dynamicBorderDark
                            : const Color(0xFFE5E7EB)),
                  width: 1.0,
                ),
                boxShadow: [GlassTheme.dynamicSoftShadow(isDark: isDark)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDestructive
                          ? const Color(0xFFFEE2E2)
                          : Theme.of(context).colorScheme.primary.withValues(
                              alpha: isDark ? 0.2 : 0.12,
                            ),
                    ),
                    child:
                        leadingWidget ??
                        Icon(
                          icon ?? AppIcons.info,
                          color: isDestructive
                              ? dangerRed
                              : Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor ?? primaryText,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  Icon(AppIcons.chevronRight, color: secondaryText, size: 20),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
