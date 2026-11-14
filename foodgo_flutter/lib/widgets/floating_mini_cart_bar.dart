import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_icons.dart';
import '../providers/cart_provider.dart';

class FloatingMiniCartBar extends StatelessWidget {
  final double bottomOffset;

  const FloatingMiniCartBar({super.key, this.bottomOffset = 80.0});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.itemCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final bgColor = colorScheme.primary;
    final fgColor = colorScheme.onPrimary;

    return Positioned(
      bottom: bottomOffset,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child:
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/cart'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: bgColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: fgColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(AppIcons.cart, color: fgColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${cart.itemCount}',
                                style: textTheme.labelLarge?.copyWith(
                                  color: fgColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View your cart',
                                style: textTheme.labelLarge?.copyWith(
                                  color: fgColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Estimated total: \$${cart.totalAmount.toStringAsFixed(2)}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: fgColor.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Checkout',
                          style: textTheme.labelLarge?.copyWith(
                            color: fgColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(AppIcons.forward, color: fgColor, size: 13),
                      ],
                    ),
                  ),
                ),
              ).animate().slideY(
                begin: 0.6,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ),
    );
  }
}
