import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/my_qr_modal.dart';
import '../../../widgets/phone_verification_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your FoodGo account?',
          style: TextStyle(color: Colors.white70),
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
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResponsiveBottomSheet(
        child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GlassTheme.dialogDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payment_outlined,
                        color: GlassTheme.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'FoodGo supports secure banking rails and cash on delivery in Cambodia.',
                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
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
                      Icons.qr_code_2,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Bakong KHQR (National Bank of Cambodia)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Universal QR in USD & KHR across all member banks',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
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
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.cyanAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'ABA Mobile KHQR / PayWay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Direct scan-to-pay via ABA Mobile app',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
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
                      Icons.credit_card,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'ACLEDA Bank KHQR / x-Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Instant payment via ACLEDA Mobile banking',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
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
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Colors.amberAccent,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Cash on Delivery (COD)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Pay cash directly to driver upon order arrival',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
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
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: GlassTheme.primaryGreen,
                    ),
                  );
                }
                final String username = user?['username'] ?? 'Guest';
                final String email = user?['email'] ?? 'guest@example.com';
                final String phone = user?['phone'] ?? '';
                final bool isPhoneVerified = user?['is_phone_verified'] == true;
                final String? avatarUrl =
                    user?['avatar_url'] ?? user?['avatar'];

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
                                  border: Border.all(
                                    color: GlassTheme.limeAccent,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GlassTheme.limeAccent.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: avatarUrl,
                                        imageBuilder: (ctx, imageProvider) =>
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundImage: imageProvider,
                                            ),
                                        placeholder: (ctx, url) => CircleAvatar(
                                          radius: 40,
                                          backgroundColor: GlassTheme.limeAccent
                                              .withValues(alpha: 0.15),
                                          child:
                                              const CircularProgressIndicator(
                                                color: GlassTheme.limeAccent,
                                                strokeWidth: 2,
                                              ),
                                        ),
                                        errorWidget: (ctx, url, err) =>
                                            CircleAvatar(
                                              radius: 40,
                                              backgroundColor: GlassTheme
                                                  .limeAccent
                                                  .withValues(alpha: 0.15),
                                              child: Text(
                                                username.isNotEmpty
                                                    ? username[0].toUpperCase()
                                                    : 'G',
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  color: GlassTheme.limeAccent,
                                                ),
                                              ),
                                            ),
                                      )
                                    : CircleAvatar(
                                        radius: 40,
                                        backgroundColor: GlassTheme.limeAccent
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          username.isNotEmpty
                                              ? username[0].toUpperCase()
                                              : 'G',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: GlassTheme.limeAccent,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 14,
                                    color: GlassTheme.limeAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    phone.isNotEmpty ? phone : 'No phone linked',
                                    style: const TextStyle(
                                      color: Colors.white70,
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
                                        color: GlassTheme.primaryGreen.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: GlassTheme.primaryGreen.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
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
                                    InkWell(
                                      onTap: () => PhoneVerificationModal.show(
                                        context,
                                        initialPhone: phone,
                                        purpose: 'customer_verification',
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.amber.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
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
                              const SizedBox(height: 18),
                              // Quick Action Shortcuts: Addresses, Orders, KHQR
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => context.push('/addresses'),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              color: GlassTheme.limeAccent,
                                              size: 22,
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Addresses',
                                              style: TextStyle(
                                                color: Colors.white,
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
                                    child: InkWell(
                                      onTap: () => context.push('/orders'),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              color: Colors.amberAccent,
                                              size: 22,
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Orders',
                                              style: TextStyle(
                                                color: Colors.white,
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
                                    child: InkWell(
                                      onTap: () {
                                        final u = context
                                            .read<UserProvider>()
                                            .user;
                                        MyQrModal.show(context, user: u);
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                        ),
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.qr_code_2,
                                              color: Colors.redAccent,
                                              size: 22,
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'My KHQR',
                                              style: TextStyle(
                                                color: Colors.white,
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
                            Icons.store,
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
                            Icons.chevron_right,
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
                            Icons.delivery_dining,
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
                            Icons.chevron_right,
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
                            Icons.admin_panel_settings_rounded,
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
                            Icons.chevron_right,
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
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final currentUser = ctx.watch<UserProvider>().user;
                final bool isVerified = currentUser?['is_phone_verified'] == true;
                final String userPhone = currentUser?['phone'] ?? '';
                return Column(
                  children: [
                    _ProfileOption(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _ProfileOption(
                      icon: Icons.phone_android_outlined,
                      title: 'Phone Verification (SMS OTP)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              onTap: () => context.push('/orders'),
            ),
            _ProfileOption(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () => _showPaymentMethodsModal(context),
            ),
            _ProfileOption(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () => context.push('/addresses'),
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
            _ProfileOption(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => context.push('/notifications'),
            ),
            _ProfileOption(
              icon: Icons.favorite_outline,
              title: 'Favorites',
              onTap: () => context.push('/favorites'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Settings & Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ProfileOption(
              icon: Icons.settings_outlined,
              title: 'General Settings',
              onTap: () => context.push('/settings'),
            ),
            _ProfileOption(
              icon: Icons.language,
              title: 'Language',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => ResponsiveBottomSheet(
                    child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: GlassTheme.dialogDark,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
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
                        ListTile(
                          title: const Text(
                            'English (US)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.check,
                            color: GlassTheme.primaryGreen,
                          ),
                          onTap: () => Navigator.pop(ctx),
                        ),
                        ListTile(
                          title: const Text(
                            'ភាសាខ្មែរ (Khmer)',
                            style: TextStyle(color: Colors.white),
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
                          title: const Text(
                            'Français (French)',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Langue française sélectionnée'),
                                backgroundColor: GlassTheme.primaryGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
                  builder: (ctx) => ResponsiveBottomSheet(
                    child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: GlassTheme.dialogDark,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'FoodGo 24/7 Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get fast help with delivery, payments, or orders.',
                          style: TextStyle(
                            color: GlassTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.chat_bubble_outline,
                            color: GlassTheme.primaryGreen,
                          ),
                          title: const Text(
                            'Chat with Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Average reply time: 2 mins',
                            style: TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.phone_outlined,
                            color: Colors.amber,
                          ),
                          title: const Text(
                            'Hotline: +855 23 999 888',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Toll-free customer care',
                            style: TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
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
                  Text(
                    'FoodGo Enterprise Delivery v1.0.0',
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
                        Icons.favorite,
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
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.trailing,
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
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 14,
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
