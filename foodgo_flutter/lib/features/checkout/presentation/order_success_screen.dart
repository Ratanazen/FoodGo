import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/svg_icon.dart';
import '../../../../widgets/lottie_assets.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../providers/cart_provider.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int? orderId;

  const OrderSuccessScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final effectiveOrderId =
        orderId ?? context.read<CartProvider>().lastOrderId;
    final String displayOrderNum = effectiveOrderId != null
        ? '#$effectiveOrderId'
        : '#1001';

    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(100),
          customColor: GlassTheme.primaryGreen.withValues(alpha: 0.15),
          child: LottieAsset.success(size: 100),
        ),
        const SizedBox(height: 32),
        const Text(
          'Order Confirmed!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'ការកម្ម៉ង់ទទួលបានជោគជ័យ!',
          style: TextStyle(
            fontSize: 16,
            color: GlassTheme.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your order $displayOrderNum\nhas been placed and sent to restaurant.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GlassTheme.textMuted, fontSize: 15),
        ),
        const SizedBox(height: 28),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: GlassTheme.borderRadiusSmall,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SvgAssetIcon(assetName: 'delivery_bike', size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated delivery · Phnom Penh',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '25–35 minutes (២៥–៣៥ នាទី)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: GlassTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            text: 'Track Order',
            icon: AppIcons.route,
            onPressed: () {
              if (effectiveOrderId != null) {
                context.go('/map/$effectiveOrderId');
              } else {
                context.go('/map');
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedPressable(
          pressedScale: 0.94,
          onTap: () => context.go('/home'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.home,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to Home',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: reduceMotion
                ? content
                : content
                      .animate()
                      .fadeIn(duration: AppMotion.page, curve: AppMotion.enter)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: AppMotion.page,
                        curve: AppMotion.enter,
                      ),
          ),
        ),
      ),
    );
  }
}
