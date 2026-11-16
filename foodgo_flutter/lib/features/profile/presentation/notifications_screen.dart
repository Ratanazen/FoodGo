import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'All'; // 'All', 'Orders', 'Promos'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _clearAll(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
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
            'Clear All Notifications?',
            style: textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : GlassTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove all notifications?',
            style: textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
            GlassButton(
              text: 'Clear All',
              variant: GlassButtonVariant.danger,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: () {
                Navigator.pop(ctx);
                provider.clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _handleNotificationTap(NotificationModel notif) {
    final provider = context.read<NotificationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!notif.isRead) {
      provider.markAsRead(notif.id);
    }

    final type = notif.notificationType.toLowerCase();

    if (type == 'promo') {
      final code = notif.data['code']?.toString() ?? 'FOODGO50';
      Clipboard.setData(ClipboardData(text: code));
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ResponsiveBottomSheet(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.orange,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Promo Code Copied!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : GlassTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voucher "$code" has been copied to your clipboard. Apply it during checkout to save big!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        color: isDark
                            ? Theme.of(context).colorScheme.primary
                            : GlassTheme.dynamicPrimaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          code,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: isDark
                                    ? Theme.of(context).colorScheme.primary
                                    : GlassTheme.dynamicPrimaryDark,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy_rounded,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: 'Explore Menu',
                        variant: GlassButtonVariant.secondary,
                        height: 50,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/explore');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        text: 'Apply in Cart',
                        variant: GlassButtonVariant.primary,
                        height: 50,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/cart');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else if (type == 'order') {
      final orderId = notif.orderId;
      final restName =
          notif.data['restaurant_name']?.toString() ?? 'FoodGo Restaurant';
      final statusStr = notif.data['status']?.toString() ?? 'Active';

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ResponsiveBottomSheet(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delivery_dining,
                    color: isDark
                        ? Theme.of(context).colorScheme.primary
                        : GlassTheme.dynamicPrimaryDark,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  notif.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : GlassTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notif.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restName,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : GlassTheme.textDark,
                                fontWeight: FontWeight.w600,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusStr.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isDark
                                    ? Theme.of(context).colorScheme.primary
                                    : GlassTheme.dynamicPrimaryDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (notif.deliveryAddress != null ||
                    notif.locationName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: isDark
                              ? GlassTheme.primaryGreenAccent
                              : const Color(0xFF15803D),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notif.deliveryAddress ?? notif.locationName!,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : GlassTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: 'All Orders',
                        variant: GlassButtonVariant.secondary,
                        height: 50,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/orders');
                        },
                      ),
                    ),
                    if (orderId != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          text: 'Track Order',
                          variant: GlassButtonVariant.primary,
                          height: 50,
                          isFullWidth: true,
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/map/$orderId');
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else if (type == 'rate') {
      showDialog<int>(
        context: context,
        builder: (_) => const _RateExperienceDialog(),
      ).then((rating) {
        if (!mounted || rating == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text('Thank you! $rating-star review submitted.'),
              ],
            ),
            backgroundColor: GlassTheme.dynamicPrimaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } else {
      context.go('/explore');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, child) {
        final allItems = notifProvider.notifications;
        final unread = notifProvider.unreadCount;

        List<NotificationModel> displayedItems;
        if (_activeFilter == 'Orders') {
          displayedItems = notifProvider.orderNotifications;
        } else if (_activeFilter == 'Promos') {
          displayedItems = notifProvider.promoNotifications;
        } else {
          displayedItems = allItems;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GlassAppBar(
            title: 'Notifications',
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : GlassTheme.textDark,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (allItems.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    color: isDark ? Colors.white : GlassTheme.textDark,
                  ),
                  tooltip: 'Clear All',
                  onPressed: () => _clearAll(context),
                ),
            ],
          ),
          body: ResponsiveWebContainer(
            maxWidth: 800,
            child: notifProvider.isLoading && allItems.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Builder(
                    builder: (bodyCtx) {
                      final theme = Theme.of(bodyCtx);
                      final textTheme = theme.textTheme;
                      final brightness = theme.brightness;
                      final primaryText = AppTypography.primaryTextColor(
                        brightness,
                      );
                      final secondaryText = AppTypography.secondaryTextColor(
                        brightness,
                      );
                      final greenAccent = isDark
                          ? GlassTheme.primaryGreenAccent
                          : const Color(0xFF15803D);
                      final smaltAccent = isDark
                          ? theme.colorScheme.primary
                          : GlassTheme.dynamicPrimaryDark;

                      return Column(
                        children: [
                          // Segmented Filter Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip(
                                    label: 'All',
                                    count: allItems.length,
                                    isSelected: _activeFilter == 'All',
                                    onTap: () =>
                                        setState(() => _activeFilter = 'All'),
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: 'Orders',
                                    count:
                                        notifProvider.orderNotifications.length,
                                    isSelected: _activeFilter == 'Orders',
                                    onTap: () => setState(
                                      () => _activeFilter = 'Orders',
                                    ),
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: 'Promos',
                                    count:
                                        notifProvider.promoNotifications.length,
                                    isSelected: _activeFilter == 'Promos',
                                    onTap: () => setState(
                                      () => _activeFilter = 'Promos',
                                    ),
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Unread banner
                          if (unread > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                borderRadius: GlassTheme.borderRadiusSmall,
                                customColor: smaltAccent.withValues(
                                  alpha: isDark ? 0.12 : 0.08,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle_notifications,
                                      color: smaltAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '$unread unread notification${unread > 1 ? 's' : ''}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: smaltAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        notifProvider.markAllAsRead();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.done_all,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'All notifications marked as read',
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                GlassTheme.dynamicPrimaryDark,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Mark all read',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: smaltAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Notifications list or empty state
                          Expanded(
                            child: displayedItems.isEmpty
                                ? Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.notifications_off_outlined,
                                            size: 72,
                                            color: secondaryText,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _activeFilter == 'All'
                                                ? 'No notifications yet'
                                                : 'No ${_activeFilter.toLowerCase()} notifications',
                                            textAlign: TextAlign.center,
                                            style: textTheme.titleLarge
                                                ?.copyWith(
                                                  color: primaryText,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "You're completely caught up!",
                                            textAlign: TextAlign.center,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: secondaryText,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () =>
                                        notifProvider.fetchNotifications(),
                                    color: smaltAccent,
                                    backgroundColor: isDark
                                        ? GlassTheme.dynamicDialogDark
                                        : Colors.white,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: displayedItems.length,
                                      itemBuilder: (context, index) {
                                        final n = displayedItems[index];
                                        final badgeColor = isDark
                                            ? n.color
                                            : HSLColor.fromColor(
                                                n.color,
                                              ).withLightness(0.32).toColor();
                                        return Dismissible(
                                          key: Key('notif_${n.id}'),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 20,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFB91C1C,
                                              ).withValues(alpha: 0.9),
                                              borderRadius:
                                                  GlassTheme.borderRadiusSmall,
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onDismissed: (_) {
                                            notifProvider.dismiss(n.id);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Dismissed: "${n.title}"',
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: AnimatedPressable(
                                              onTap: () =>
                                                  _handleNotificationTap(n),
                                              pressedScale: 0.98,
                                              child: GlassContainer(
                                                borderRadius: GlassTheme
                                                    .borderRadiusSmall,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                customColor: n.isRead
                                                    ? (isDark
                                                          ? null
                                                          : Colors.white)
                                                    : (isDark
                                                          ? n.color.withValues(
                                                              alpha: 0.08,
                                                            )
                                                          : Colors.white),
                                                customBorder: Border.all(
                                                  color: isDark
                                                      ? (n.isRead
                                                            ? Colors.white12
                                                            : n.color
                                                                  .withValues(
                                                                    alpha: 0.25,
                                                                  ))
                                                      : const Color(0xFFE2E8F0),
                                                  width: 1.2,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        color: n.color
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        n.icon,
                                                        color: badgeColor,
                                                        size: 22,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  n.title,
                                                                  style: textTheme.bodyMedium?.copyWith(
                                                                    fontWeight:
                                                                        n.isRead
                                                                        ? FontWeight
                                                                              .w500
                                                                        : FontWeight
                                                                              .w700,
                                                                    color:
                                                                        primaryText,
                                                                  ),
                                                                ),
                                                              ),
                                                              if (!n.isRead)
                                                                Container(
                                                                  width: 8,
                                                                  height: 8,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        badgeColor,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            n.message,
                                                            style: textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color:
                                                                      secondaryText,
                                                                  height: 1.4,
                                                                ),
                                                          ),
                                                          if (n.locationName !=
                                                                  null ||
                                                              n.deliveryAddress !=
                                                                  null) ...[
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .location_on_outlined,
                                                                  size: 13,
                                                                  color:
                                                                      greenAccent,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    n.deliveryAddress ??
                                                                        n.locationName!,
                                                                    maxLines: 2,
                                                                    style: textTheme
                                                                        .labelSmall
                                                                        ?.copyWith(
                                                                          color:
                                                                              greenAccent,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  n.timeAgo,
                                                                  style: textTheme
                                                                      .labelSmall
                                                                      ?.copyWith(
                                                                        color:
                                                                            secondaryText,
                                                                      ),
                                                                ),
                                                              ),
                                                              Text(
                                                                'Tap to view',
                                                                style: textTheme
                                                                    .labelSmall
                                                                    ?.copyWith(
                                                                      color:
                                                                          badgeColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
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
                                        ).animate().fade(delay: (30 * index).ms).slideY(begin: 0.06);
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedBg = colorScheme.primary;
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final selectedBorder = colorScheme.primary;
    final unselectedBorder = isDark
        ? GlassTheme.dynamicBorderDark
        : const Color(0xFFE2E8F0);
    final selectedTextColor = colorScheme.onPrimary;
    final unselectedTextColor = AppTypography.secondaryTextColor(
      theme.brightness,
    );

    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Builder(
          builder: (chipCtx) {
            final chipTextTheme = Theme.of(chipCtx).textTheme;
            final secondaryText = AppTypography.secondaryTextColor(
              isDark ? Brightness.dark : Brightness.light,
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: chipTextTheme.bodySmall?.copyWith(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFEEF2F6)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: chipTextTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.white : secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RateExperienceDialog extends StatefulWidget {
  const _RateExperienceDialog();

  @override
  State<_RateExperienceDialog> createState() => _RateExperienceDialogState();
}

class _RateExperienceDialogState extends State<_RateExperienceDialog> {
  final _feedbackController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final starColor = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFB45309);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? GlassTheme.dynamicBorderDark : GlassTheme.borderLight,
        ),
      ),
      title: Text(
        'Rate Your Experience',
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
              'How was your recent meal?',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: secondaryText),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: starColor,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: _feedbackController,
              maxLines: 2,
              hintText: 'Share your feedback (optional)...',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(color: secondaryText),
          ),
        ),
        GlassButton(
          text: 'Submit',
          variant: GlassButtonVariant.primary,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onPressed: () => Navigator.pop(context, _rating),
        ),
      ],
    );
  }
}
