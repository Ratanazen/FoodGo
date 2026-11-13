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
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        final primaryText = AppTypography.primaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        final secondaryText = AppTypography.secondaryTextColor(
          isDark ? Brightness.dark : Brightness.light,
        );
        return AlertDialog(
          backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.tr('settings.logoutConfirmTitle'),
            style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          ),
          content: Text(
            context.tr('settings.logoutConfirmMessage'),
            style: TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                context.tr('common.cancel'),
                style: TextStyle(color: secondaryText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
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
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<AuthProvider>().logout();
                context.read<UserProvider>().clearUser();
                context.go('/login');
              },
              child: Text(
                context.tr('auth.logout'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? GlassTheme.dialogDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
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
                        Text(
                          'Payment Methods',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FoodGo supports secure banking rails and cash on delivery in Cambodia.',
                      style: TextStyle(color: secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          AppIcons.qrCode,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Bakong KHQR (National Bank of Cambodia)',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Universal QR in USD & KHR across all member banks',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          AppIcons.bankTransfer,
                          color: isDark
                              ? Colors.cyanAccent
                              : const Color(0xFF0E7490),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'ABA Mobile KHQR / PayWay',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Direct scan-to-pay via ABA Mobile app',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          AppIcons.creditCard,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'ACLEDA Bank KHQR / x-Pay',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Instant payment via ACLEDA Mobile banking',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          AppIcons.payment,
                          color: isDark
                              ? Colors.amberAccent
                              : const Color(0xFFB45309),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Cash on Delivery (COD)',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Pay cash directly to driver upon order arrival',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                            child: const Text('View Orders & Receipts'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Close'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: GlassTheme.primaryGreen,
                    ),
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
                                ? GlassTheme.surfaceCardDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFE5E7EB),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.25 : 0.04,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
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
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: GlassTheme
                                                            .primaryGreen,
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
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      GlassTheme.primaryGreen,
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
                                          color: GlassTheme.primaryGreen,
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
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              if (username.isNotEmpty &&
                                  username != displayName &&
                                  !username.startsWith('adb_user_')) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '@$username',
                                  style: const TextStyle(
                                    color: GlassTheme.primaryGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    AppIcons.phone,
                                    size: 14,
                                    color: GlassTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone.isNotEmpty
                                        ? phone
                                        : 'No phone linked',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF374151),
                                      fontSize: 13,
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
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            AppIcons.successFilled,
                                            size: 10,
                                            color: GlassTheme.primaryGreen,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              color: GlassTheme.primaryGreen,
                                              fontSize: 10,
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
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              AppIcons.warning,
                                              size: 10,
                                              color: Colors.amber,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Verify SMS',
                                              style: TextStyle(
                                                color: Colors.amber,
                                                fontSize: 10,
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
                                    icon: const Icon(
                                      AppIcons.edit,
                                      size: 14,
                                      color: GlassTheme.primaryGreen,
                                    ),
                                    label: Text(
                                      context.tr(
                                        'profile.editProfile',
                                        fallback: 'Edit Profile',
                                      ),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                          child: Text(
                                            isKhmer
                                                ? '🇰🇭 ភាសាខ្មែរ'
                                                : '🇬🇧 English',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : GlassTheme.textDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Quick Action Shortcuts: Addresses, Orders, KHQR
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
                                            const Icon(
                                              AppIcons.locationOutline,
                                              color: GlassTheme.primaryGreen,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Addresses',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                                fontSize: 12,
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
                                            const Icon(
                                              AppIcons.orders,
                                              color: GlassTheme.primaryGreen,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Orders',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                                fontSize: 12,
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
                          leading: const Icon(
                            AppIcons.restaurants,
                            color: GlassTheme.primaryGreen,
                          ),
                          title: const Text(
                            'Restaurant Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            AppIcons.chevronRight,
                            color: Colors.white54,
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
                          leading: const Icon(
                            AppIcons.delivery,
                            color: GlassTheme.primaryGreen,
                          ),
                          title: const Text(
                            'Driver Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            AppIcons.chevronRight,
                            color: Colors.white54,
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
                          leading: const Icon(
                            AppIcons.admin,
                            color: GlassTheme.limeAccent,
                          ),
                          title: const Text(
                            'Admin Console',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Platform analytics, orders, users & audit logs',
                            style: TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(
                            AppIcons.chevronRight,
                            color: Colors.white54,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
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
                          style: const TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 10,
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
                                'Customer account active. Driver and merchant roles are provisioned by Admin in the backend.',
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
                          style: TextStyle(
                            color: isVerified
                                ? GlassTheme.primaryGreen
                                : Colors.amber,
                            fontSize: 11,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
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
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    final primaryText = AppTypography.primaryTextColor(
                      isDark ? Brightness.dark : Brightness.light,
                    );
                    final accentGreen = isDark
                        ? GlassTheme.primaryGreen
                        : GlassTheme.primaryGreenDark;
                    return ResponsiveBottomSheet(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? GlassTheme.dialogDark : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Select Language / ជ្រើសរើសភាសា',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text(
                                'English (US)',
                                style: TextStyle(
                                  color: primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Icon(
                                AppIcons.check,
                                color: accentGreen,
                              ),
                              onTap: () => Navigator.pop(ctx),
                            ),
                            ListTile(
                              title: Text(
                                'ភាសាខ្មែរ (Khmer)',
                                style: TextStyle(color: primaryText),
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
                                style: TextStyle(color: primaryText),
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
                          color: isDark ? GlassTheme.dialogDark : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'FoodGo 24/7 Support',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Get fast help with delivery, payments, or orders.',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: Icon(
                                AppIcons.support,
                                color: accentGreen,
                              ),
                              title: Text(
                                'Chat with Support',
                                style: TextStyle(
                                  color: primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Average reply time: 2 mins',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx),
                            ),
                            ListTile(
                              leading: Icon(
                                AppIcons.phone,
                                color: isDark
                                    ? Colors.amber
                                    : const Color(0xFFB45309),
                              ),
                              title: Text(
                                'Hotline: +855 23 999 888',
                                style: TextStyle(
                                  color: primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Toll-free customer care',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 12,
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
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () => _showLogoutDialog(context),
                  );
                } else {
                  return _ProfileOption(
                    icon: AppIcons.login,
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
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Made with ',
                        style: TextStyle(
                          color: GlassTheme.textMuted.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const Icon(
                        AppIcons.favorite,
                        color: Colors.redAccent,
                        size: 12,
                      ),
                      Text(
                        ' in Phnom Penh, Cambodia',
                        style: TextStyle(
                          color: GlassTheme.textMuted.withValues(alpha: 0.6),
                          fontSize: 11,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = iconColor ?? GlassTheme.primaryGreen;
    final bool isDestructive =
        effectiveColor == Colors.red ||
        textColor == Colors.red ||
        effectiveColor == const Color(0xFFEF4444);

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
                    : (isDark ? GlassTheme.surfaceCardDark : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDestructive
                      ? const Color(0xFFFCA5A5)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE5E7EB)),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                              ? const Color(0xFFEF4444)
                              : Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color:
                            textColor ??
                            (isDark ? Colors.white : const Color(0xFF111827)),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    AppIcons.chevronRight,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
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
