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
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Notifications?',
          style: TextStyle(
            color: isDark ? Colors.white : GlassTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all notifications?',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
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
      ),
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
              color: isDark ? GlassTheme.dialogDark : Colors.white,
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
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 14,
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
                      const Icon(
                        Icons.discount_outlined,
                        color: GlassTheme.royalSmalt,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        code,
                        style: TextStyle(
                          color: isDark
                              ? GlassTheme.limeAccentBright
                              : GlassTheme.royalSmalt,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 1.2,
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
              color: isDark ? GlassTheme.dialogDark : Colors.white,
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
                    color: GlassTheme.royalSmalt.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: GlassTheme.royalSmalt,
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
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 14,
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
                      Text(
                        restName,
                        style: TextStyle(
                          color: isDark ? Colors.white : GlassTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GlassTheme.royalSmalt.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusStr.toUpperCase(),
                          style: const TextStyle(
                            color: GlassTheme.royalSmalt,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
      int rating = 5;
      final feedbackController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Rate Your Experience',
              style: TextStyle(
                color: isDark ? Colors.white : GlassTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How was your recent meal?',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
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
                      onPressed: () {
                        setDialogState(() => rating = index + 1);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: feedbackController,
                  maxLines: 2,
                  hintText: 'Share your feedback (optional)...',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
              GlassButton(
                text: 'Submit',
                variant: GlassButtonVariant.primary,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Text('Thank you! $rating-star review submitted.'),
                        ],
                      ),
                      backgroundColor: GlassTheme.royalSmalt,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: GlassTheme.royalSmalt,
                    ),
                  )
                : Column(
                    children: [
                      // Segmented Filter Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                              count: notifProvider.orderNotifications.length,
                              isSelected: _activeFilter == 'Orders',
                              onTap: () =>
                                  setState(() => _activeFilter = 'Orders'),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Promos',
                              count: notifProvider.promoNotifications.length,
                              isSelected: _activeFilter == 'Promos',
                              onTap: () =>
                                  setState(() => _activeFilter = 'Promos'),
                              isDark: isDark,
                            ),
                          ],
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
                            customColor: GlassTheme.royalSmalt.withValues(
                              alpha: isDark ? 0.12 : 0.08,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle_notifications,
                                  color: GlassTheme.royalSmalt,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$unread unread notification${unread > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: GlassTheme.royalSmalt,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    notifProvider.markAllAsRead();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.done_all,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'All notifications marked as read',
                                            ),
                                          ],
                                        ),
                                        backgroundColor: GlassTheme.royalSmalt,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Mark all read',
                                    style: TextStyle(
                                      color: GlassTheme.royalSmalt,
                                      fontSize: 13,
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 72,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _activeFilter == 'All'
                                          ? 'No notifications yet'
                                          : 'No ${_activeFilter.toLowerCase()} notifications',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : GlassTheme.textDark,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "You're completely caught up!",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () =>
                                    notifProvider.fetchNotifications(),
                                color: GlassTheme.royalSmalt,
                                backgroundColor: isDark
                                    ? GlassTheme.dialogDark
                                    : Colors.white,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: displayedItems.length,
                                  itemBuilder: (context, index) {
                                    final n = displayedItems[index];
                                    return Dismissible(
                                      key: Key('notif_${n.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 20,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.8,
                                          ),
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
                                            behavior: SnackBarBehavior.floating,
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
                                            borderRadius:
                                                GlassTheme.borderRadiusSmall,
                                            padding: const EdgeInsets.all(16),
                                            customColor: n.isRead
                                                ? (isDark ? null : Colors.white)
                                                : (isDark
                                                      ? n.color.withValues(
                                                          alpha: 0.08,
                                                        )
                                                      : Colors.white),
                                            customBorder: Border.all(
                                              color: isDark
                                                  ? (n.isRead
                                                        ? Colors.white12
                                                        : n.color.withValues(
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
                                                    color: n.color.withValues(
                                                      alpha: 0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    n.icon,
                                                    color: n.color,
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
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    n.isRead
                                                                    ? FontWeight
                                                                          .w500
                                                                    : FontWeight
                                                                          .w700,
                                                                fontSize: 14,
                                                                color: isDark
                                                                    ? Colors
                                                                          .white
                                                                    : GlassTheme
                                                                          .textDark,
                                                              ),
                                                            ),
                                                          ),
                                                          if (!n.isRead)
                                                            Container(
                                                              width: 8,
                                                              height: 8,
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color:
                                                                        n.color,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        n.message,
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? Colors.white70
                                                              : const Color(
                                                                  0xFF64748B,
                                                                ),
                                                          fontSize: 13,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            n.timeAgo,
                                                            style: TextStyle(
                                                              color: isDark
                                                                  ? Colors
                                                                        .white38
                                                                  : const Color(
                                                                      0xFF94A3B8,
                                                                    ),
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            'Tap to view',
                                                            style: TextStyle(
                                                              color: n.color,
                                                              fontSize: 11,
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
    final selectedBg = GlassTheme.royalSmalt;
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final selectedBorder = GlassTheme.royalSmalt;
    final unselectedBorder = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFE2E8F0);
    final selectedTextColor = Colors.white;
    final unselectedTextColor = isDark
        ? Colors.white70
        : const Color(0xFF475569);

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
                    color: GlassTheme.royalSmalt.withValues(alpha: 0.28),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
