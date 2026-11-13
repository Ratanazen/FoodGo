import 'package:flutter/material.dart';

import 'glass_widgets.dart';
import '../glass_container.dart';

class GlassCheckoutBar extends StatelessWidget {
  final String totalText;
  final String buttonText;
  final VoidCallback onPressed;

  const GlassCheckoutBar({
    super.key,
    required this.totalText,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTypography.secondaryTextColor(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalText,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppTypography.primaryTextColor(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GlassButton(text: buttonText, onPressed: onPressed),
        ],
      ),
    );
  }
}
