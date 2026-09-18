import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../core/theme/glass_theme.dart';
import 'package:go_router/go_router.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(32),
                borderRadius: BorderRadius.circular(100),
                customColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                child: const Icon(Icons.check, size: 80, color: GlassTheme.primaryGreen),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              const Text('Order Confirmed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)).animate().fade(delay: 400.ms).slideY(),
              const SizedBox(height: 16),
              Text(
                'Your order #12345\nhas been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 16),
              ).animate().fade(delay: 500.ms).slideY(),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: GlassTheme.borderRadiusSmall,
                child: const Column(
                  children: [
                    Text('Estimated delivery', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 8),
                    Text('25–35 minutes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen)),
                  ],
                ),
              ).animate().fade(delay: 600.ms).scale(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: 'Track Order',
                  onPressed: () => context.go('/map/1'),
                ),
              ).animate().fade(delay: 700.ms),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Back to Home', style: TextStyle(color: GlassTheme.textMuted, fontSize: 16)),
              ).animate().fade(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
