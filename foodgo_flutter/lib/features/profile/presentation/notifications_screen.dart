import 'package:flutter/material.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Notifications',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 4,
        itemBuilder: (context, index) {
          final isUnread = index < 2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(20),
                    customColor: isUnread 
                      ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      index % 2 == 0 ? Icons.local_shipping : Icons.local_offer,
                      color: isUnread ? GlassTheme.primaryGreen : GlassTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              index % 2 == 0 ? 'Order Arriving Soon!' : 'Promo Code: 30% OFF',
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: GlassTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          index % 2 == 0 
                            ? 'Your order #102$index is 5 minutes away.' 
                            : 'Use code GLASS30 for 30% off your next order.',
                          style: TextStyle(color: GlassTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Text('2 hours ago', style: TextStyle(fontSize: 12, color: GlassTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: (100 * index).ms).slideY(),
          );
        },
      ),
    );
  }
}
