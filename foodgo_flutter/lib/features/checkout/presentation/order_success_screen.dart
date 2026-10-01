import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/svg_icon.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../providers/cart_provider.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int? orderId;

  const OrderSuccessScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final effectiveOrderId = orderId ?? context.read<CartProvider>().lastOrderId;
    final String displayOrderNum = effectiveOrderId != null ? '#$effectiveOrderId' : '#1001';

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
                child: const Icon(Icons.check_circle_rounded, size: 80, color: GlassTheme.primaryGreen),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              const Text('Order Confirmed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)).animate().fade(delay: 400.ms).slideY(),
              const SizedBox(height: 16),
              Text(
                'Your order $displayOrderNum\nhas been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 16),
              ).animate().fade(delay: 500.ms).slideY(),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: GlassTheme.borderRadiusSmall,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SvgAssetIcon(assetName: 'delivery_bike', size: 20),
                        SizedBox(width: 8),
                        Text('Estimated delivery', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('25–35 minutes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlassTheme.primaryGreen)),
                  ],
                ),
              ).animate().fade(delay: 600.ms).scale(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  text: 'Track Order',
                  icon: Icons.navigation_rounded,
                  onPressed: () {
                    if (effectiveOrderId != null) {
                      context.go('/map/$effectiveOrderId');
                    } else {
                      context.go('/map');
                    }
                  },
                ),
              ).animate().fade(delay: 700.ms),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined, size: 18, color: Colors.white70),
                label: const Text('Back to Home', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ).animate().fade(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
