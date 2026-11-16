import 'package:flutter/material.dart';
import '../../core/errors/failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';

/// User-friendly error display widget supporting typed [Failure] instances and retry actions.
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.title,
    required this.message,
    this.retryText = 'Retry',
    this.onRetry,
  });

  /// Factory constructor that configures appropriate icons and messages from a typed [Failure].
  factory ErrorState.fromFailure(
    Failure failure, {
    Key? key,
    String? retryText,
    VoidCallback? onRetry,
  }) {
    IconData icon;
    String title;

    switch (failure) {
      case NetworkFailure():
        icon = Icons.wifi_off_rounded;
        title = 'No Connection';
      case UnauthorizedFailure():
        icon = Icons.lock_outline_rounded;
        title = 'Session Expired';
      case NotFoundFailure():
        icon = Icons.search_off_rounded;
        title = 'Not Found';
      case ServerFailure():
        icon = Icons.cloud_off_rounded;
        title = 'Server Error';
      case ValidationFailure():
        icon = Icons.warning_amber_rounded;
        title = 'Invalid Input';
      case CacheFailure():
        icon = Icons.storage_rounded;
        title = 'Storage Error';
      case UnknownFailure():
        icon = Icons.error_outline_rounded;
        title = 'Unexpected Error';
    }

    return ErrorState(
      key: key,
      icon: icon,
      title: title,
      message: failure.message,
      retryText: retryText ?? 'Try Again',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.errorRed.withAlpha(50)),
              ),
              child: Icon(icon, size: 40.0, color: AppColors.errorRed),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: retryText ?? 'Retry',
                onPressed: onRetry,
                isExpanded: false,
                variant: AppButtonVariant.primary,
                leadingIcon: const Icon(
                  Icons.refresh_rounded,
                  size: 18.0,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
