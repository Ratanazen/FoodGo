import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ghost }

/// Accessible, responsive Material 3 button adhering to the 48dp touch target standard.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
    this.width,
    this.padding,
  });

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveHeight = height ?? AppSpacing.minTouchTarget;

    Widget buttonContent = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(isDark)),
            ),
          )
        else ...[
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Kantumruy Pro',
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                color: _getTextColor(isDark),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailingIcon!,
          ],
        ],
      ],
    );

    final resolvedPadding =
        padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );

    final decoration = _getBoxDecoration(isDark);

    Widget buttonBody = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: effectiveHeight,
      width: width,
      padding: resolvedPadding,
      decoration: decoration,
      child: Center(child: buttonContent),
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: text,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
          minWidth: isExpanded ? double.infinity : AppSpacing.minTouchTarget,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: _isEnabled ? onPressed : null,
            child: buttonBody,
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration(bool isDark) {
    final borderRadius = BorderRadius.circular(AppSpacing.radiusMd);

    if (!_isEnabled) {
      return BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: borderRadius,
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withAlpha(70),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFE2E8F0),
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        );

      case AppButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.primaryGreen, width: 1.5),
        );

      case AppButtonVariant.danger:
        return BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.errorRed.withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        );
    }
  }

  Color _getTextColor(bool isDark) {
    if (!_isEnabled) {
      return isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    }

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return Colors.white;

      case AppButtonVariant.secondary:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

      case AppButtonVariant.outline:
        return AppColors.primaryGreen;

      case AppButtonVariant.ghost:
        return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }
  }
}
