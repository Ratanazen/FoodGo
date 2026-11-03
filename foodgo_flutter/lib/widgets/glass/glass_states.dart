import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';
import '../vector_illustrations.dart';
import 'glass_widgets.dart';

class GlassSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GlassSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.small,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(borderRadius),
          customColor: Colors.grey.withValues(alpha: 0.1),
          child: const SizedBox(),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 800.ms);
  }
}

class AppErrorView extends StatelessWidget {
  final String? title;
  final String? message;
  final String? retryText;
  final VoidCallback onRetry;

  const AppErrorView({
    super.key,
    this.title,
    this.message,
    this.retryText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? context.tr('errors.serverError');
    final effectiveMessage = message ?? context.tr('errors.networkError');
    final effectiveRetry = retryText ?? context.tr('common.retry');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const VectorIllustration(
              type: VectorIllustrationType.networkOffline,
              size: 140,
            ),
            const SizedBox(height: 20),
            Text(
              effectiveTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              effectiveMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: GlassTheme.textMuted),
            ),
            const SizedBox(height: 24),
            GlassButton(text: effectiveRetry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VectorIllustrationType? illustrationType;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.illustrationType,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustrationType != null)
              VectorIllustration(type: illustrationType!, size: 150)
            else
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(100),
                child: Icon(
                  icon ?? Icons.inbox_outlined,
                  size: 64,
                  color: GlassTheme.dynamicPrimaryColor,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: GlassTheme.textMuted),
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 24),
              GlassButton(text: buttonText!, onPressed: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}
