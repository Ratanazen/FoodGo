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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Notifications?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to remove all notifications?',
          style: TextStyle(color: Colors.white70),
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
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notif) {
    final provider = context.read<NotificationProvider>();
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
            decoration: const BoxDecoration(
              color: Color(0xFF161622),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voucher "$code" has been copied to your clipboard. Apply it during checkout to save big!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/explore');
                      },
                      child: const Text(
                        'Explore Menu',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: GlassTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/cart');
                      },
                      child: const Text(
                        'Apply in Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
            decoration: const BoxDecoration(
              color: Color(0xFF161622),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: GlassTheme.primaryGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notif.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notif.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      restName,
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusStr.toUpperCase(),
                        style: const TextStyle(
                          color: GlassTheme.primaryGreen,
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
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/orders');
                      },
                      child: const Text(
                        'All Orders',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (orderId != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: GlassTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/map/$orderId');
                        },
                        child: const Text(
                          'Track Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Rate Your Experience',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How was your recent meal?',
                  style: TextStyle(color: Colors.white70),
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
                TextField(
                  controller: feedbackController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your feedback (optional)...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
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
                  foregroundColor: Colors.white,
                ),
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
                      backgroundColor: GlassTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Submit'),
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
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (allItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
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
                      color: GlassTheme.primaryGreen,
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
                            onTap: () => setState(() => _activeFilter = 'All'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Orders',
                            count: notifProvider.orderNotifications.length,
                            isSelected: _activeFilter == 'Orders',
                            onTap: () =>
                                setState(() => _activeFilter = 'Orders'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Promos',
                            count: notifProvider.promoNotifications.length,
                            isSelected: _activeFilter == 'Promos',
                            onTap: () =>
                                setState(() => _activeFilter = 'Promos'),
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
                          customColor: GlassTheme.primaryGreen.withValues(
                            alpha: 0.1,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle_notifications,
                                color: GlassTheme.primaryGreen,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$unread unread notification${unread > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: GlassTheme.primaryGreen,
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
                                      backgroundColor: GlassTheme.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Mark all read',
                                  style: TextStyle(
                                    color: GlassTheme.primaryGreen,
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
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activeFilter == 'All'
                                        ? 'No notifications yet'
                                        : 'No ${_activeFilter.toLowerCase()} notifications',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "You're completely caught up!",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  notifProvider.fetchNotifications(),
                              color: GlassTheme.primaryGreen,
                              backgroundColor: GlassTheme.dialogDark,
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
                                      padding: const EdgeInsets.only(right: 20),
                                      margin: const EdgeInsets.only(bottom: 12),
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
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: InkWell(
                                        borderRadius:
                                            GlassTheme.borderRadiusSmall,
                                        onTap: () => _handleNotificationTap(n),
                                        child: GlassContainer(
                                          borderRadius:
                                              GlassTheme.borderRadiusSmall,
                                          padding: const EdgeInsets.all(16),
                                          customColor: n.isRead
                                              ? null
                                              : n.color.withValues(alpha: 0.08),
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
                                                      BorderRadius.circular(12),
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
                                                      CrossAxisAlignment.start,
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
                                                              color:
                                                                  Colors.white,
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
                                                      style: const TextStyle(
                                                        color: GlassTheme
                                                            .textMuted,
                                                        fontSize: 13,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          n.timeAgo,
                                                          style: const TextStyle(
                                                            color: GlassTheme
                                                                .textMuted,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Text(
                                                          'Tap to view',
                                                          style: TextStyle(
                                                            color: n.color
                                                                .withValues(
                                                                  alpha: 0.8,
                                                                ),
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? GlassTheme.primaryGreen
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? GlassTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
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
