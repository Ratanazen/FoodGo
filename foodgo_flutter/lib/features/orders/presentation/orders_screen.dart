import 'package:flutter/material.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/theme/glass_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'My Orders',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: 4,
              itemBuilder: (context, index) {
                final isCompleted = index > 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #102$index',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              borderRadius: GlassTheme.borderRadiusSmall,
                              customColor: isCompleted 
                                ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                              child: Text(
                                isCompleted ? 'Completed' : 'In Progress',
                                style: TextStyle(
                                  color: isCompleted ? GlassTheme.primaryGreen : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: GlassTheme.borderRadiusSmall,
                              ),
                              child: const Icon(Icons.restaurant, color: GlassTheme.textMuted),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delicious Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('3 items • \$41.96', style: TextStyle(color: GlassTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('Today, 12:30 PM', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isCompleted) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: GlassButton(
                              text: 'Reorder',
                              onPressed: () {},
                              color: Colors.transparent,
                            ),
                          )
                        ]
                      ],
                    ),
                  ).animate().fade(delay: (100 * index).ms).slideY(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}