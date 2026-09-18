import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _NotifData(
        icon: Icons.delivery_dining,
        color: GlassTheme.primaryGreen,
        title: 'Order Delivered!',
        body: 'Your order #1024 has been delivered. Enjoy your meal!',
        time: '2 min ago',
        isRead: false,
      ),
      _NotifData(
        icon: Icons.local_offer,
        color: Colors.orange,
        title: '50% OFF Today Only!',
        body: 'Use code FOODGO50 for 50% off your next order.',
        time: '1 hr ago',
        isRead: false,
      ),
      _NotifData(
        icon: Icons.receipt_long,
        color: Colors.blue,
        title: 'Order Confirmed',
        body: 'Your order from Burger Palace has been confirmed.',
        time: '3 hr ago',
        isRead: true,
      ),
      _NotifData(
        icon: Icons.star,
        color: Colors.amber,
        title: 'Rate Your Experience',
        body: 'How was your order from Pizza World? Tap to rate.',
        time: 'Yesterday',
        isRead: true,
      ),
      _NotifData(
        icon: Icons.local_activity,
        color: Colors.purple,
        title: 'New Restaurant Near You',
        body: 'Sushi Garden just opened in your area. Check it out!',
        time: '2 days ago',
        isRead: true,
      ),
    ];

    final unread = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Notifications',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: GlassTheme.borderRadiusSmall,
                customColor: GlassTheme.primaryGreen.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.circle_notifications, color: GlassTheme.primaryGreen),
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
                      onPressed: () {},
                      child: Text(
                        'Mark all read',
                        style: TextStyle(color: GlassTheme.primaryGreen, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    borderRadius: GlassTheme.borderRadiusSmall,
                    padding: const EdgeInsets.all(16),
                    customColor: n.isRead ? null : n.color.withValues(alpha: 0.05),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: n.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(n.icon, color: n.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                        fontSize: 14,
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
                              Text(
                                n.time,
                                style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(delay: (60 * index).ms).slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const _NotifData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}
