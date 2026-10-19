import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationItem {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  bool isRead;
  final String actionType; // 'promo', 'order', 'rate', 'explore'
  final String? payload;

  _NotificationItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.actionType,
    this.payload,
  });
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  late List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _defaultMockNotifications();
    _fetchNotifications();
  }

  List<_NotificationItem> _defaultMockNotifications() {
    return [
      _NotificationItem(
        id: '1',
        icon: Icons.delivery_dining,
        color: GlassTheme.primaryGreen,
        title: 'Order Delivered!',
        body:
            'Your order #1024 has been delivered. Tap to view your order details.',
        time: '2 min ago',
        isRead: false,
        actionType: 'order',
        payload: '#1024',
      ),
      _NotificationItem(
        id: '2',
        icon: Icons.local_offer,
        color: Colors.orange,
        title: '50% OFF Today Only!',
        body:
            'Use code FOODGO50 for 50% off your next order. Tap to copy code and use in cart.',
        time: '1 hr ago',
        isRead: false,
        actionType: 'promo',
        payload: 'FOODGO50',
      ),
      _NotificationItem(
        id: '3',
        icon: Icons.receipt_long,
        color: Colors.blue,
        title: 'Order Confirmed',
        body:
            'Your order from Burger Palace has been confirmed and is being prepared.',
        time: '3 hr ago',
        isRead: true,
        actionType: 'order',
        payload: '#1025',
      ),
      _NotificationItem(
        id: '4',
        icon: Icons.star,
        color: Colors.amber,
        title: 'Rate Your Experience',
        body:
            'How was your recent meal from Pizza World? Tap here to leave a rating.',
        time: 'Yesterday',
        isRead: true,
        actionType: 'rate',
        payload: 'Pizza World',
      ),
      _NotificationItem(
        id: '5',
        icon: Icons.storefront,
        color: Colors.purple,
        title: 'New Restaurant Near You',
        body:
            'Sushi Garden just opened in your area with free delivery! Tap to explore menu.',
        time: '2 days ago',
        isRead: true,
        actionType: 'explore',
        payload: 'Sushi Garden',
      ),
    ];
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('notifications/');
      final List<dynamic> list = res is List
          ? res
          : (res['results'] as List<dynamic>? ?? []);
      if (list.isNotEmpty && mounted) {
        setState(() {
          _notifications = list.map((item) {
            final type = item['notification_type']?.toString() ?? 'order';
            IconData icon = Icons.notifications;
            Color color = GlassTheme.primaryGreen;
            if (type == 'promo') {
              icon = Icons.local_offer;
              color = Colors.orange;
            } else if (type == 'order') {
              icon = Icons.delivery_dining;
              color = GlassTheme.primaryGreen;
            } else if (type == 'rate') {
              icon = Icons.star;
              color = Colors.amber;
            } else if (type == 'account') {
              icon = Icons.person;
              color = Colors.blue;
            }

            return _NotificationItem(
              id: item['id'].toString(),
              icon: icon,
              color: color,
              title: item['title'] ?? 'FoodGo Alert',
              body: item['message'] ?? '',
              time: _formatDate(item['created_at']),
              isRead: item['is_read'] == true,
              actionType: type,
              payload: item['order'] != null ? '#${item['order']}' : null,
            );
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Recent';
    try {
      final dt = DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Recent';
    }
  }

  void _markAllRead() async {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    try {
      await _api.post('notifications/mark-all-read/', {});
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.done_all, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('All notifications marked as read'),
          ],
        ),
        backgroundColor: GlassTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All Notifications?',
          style: TextStyle(color: Colors.white),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _notifications.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(_NotificationItem notif) {
    if (!notif.isRead) {
      setState(() => notif.isRead = true);
      try {
        _api.post('notifications/${notif.id}/read/', {});
      } catch (_) {}
    }

    switch (notif.actionType) {
      case 'promo':
        final code = notif.payload ?? 'FOODGO50';
        Clipboard.setData(ClipboardData(text: code));
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF161622),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
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
        );
        break;

      case 'order':
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF161622),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
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
                  notif.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
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
                      context.go('/orders');
                    },
                    child: const Text(
                      'View All Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      case 'rate':
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
              title: Text(
                'Rate ${notif.payload ?? 'Your Order'}',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How was your dining experience?',
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
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text('Thank you! $rating-star review submitted.'),
                          ],
                        ),
                        backgroundColor: GlassTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      case 'explore':
      default:
        context.go('/explore');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Notifications',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: GlassTheme.primaryGreen),
            )
          : _notifications.isEmpty
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
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You're completely caught up!",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            )
          : Column(
              children: [
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
                          Icon(
                            Icons.circle_notifications,
                            color: GlassTheme.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$unread unread notification${unread > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: GlassTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _markAllRead,
                            child: Text(
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: GlassTheme.primaryGreen,
                    backgroundColor: GlassTheme.dialogDark,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Dismissible(
                              key: Key(n.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: GlassTheme.borderRadiusSmall,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) {
                                setState(() {
                                  _notifications.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dismissed: "${n.title}"'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: GlassTheme.borderRadiusSmall,
                                  onTap: () => _handleNotificationTap(n),
                                  child: GlassContainer(
                                    borderRadius: GlassTheme.borderRadiusSmall,
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
                                            borderRadius: BorderRadius.circular(
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
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      n.title,
                                                      style: TextStyle(
                                                        fontWeight: n.isRead
                                                            ? FontWeight.w500
                                                            : FontWeight.w700,
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!n.isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: n.color,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                n.body,
                                                style: TextStyle(
                                                  color: GlassTheme.textMuted,
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(
                                                    n.time,
                                                    style: TextStyle(
                                                      color:
                                                          GlassTheme.textMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    'Tap to view',
                                                    style: TextStyle(
                                                      color: n.color.withValues(
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
                            )
                            .animate()
                            .fade(delay: (40 * index).ms)
                            .slideY(begin: 0.08);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
