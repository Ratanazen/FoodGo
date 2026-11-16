import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_theme.dart';
import 'animated_pressable.dart';

class GlassTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final Widget? prefix;
  final IconData? suffixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final String? errorText;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;

  const GlassTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.maxLines = 1,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.errorText,
    this.borderRadius,
    this.fillColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppRadius.medium);
    final effectiveFill =
        fillColor ??
        (isDark
            ? GlassTheme.dynamicDialogDark.withValues(alpha: 0.86)
            : Colors.white);
    final textColor = AppTypography.primaryTextColor(brightness);
    final hintColor = AppTypography.secondaryTextColor(brightness);
    final borderColor = errorText != null
        ? const Color(0xFFE53935)
        : (isDark ? GlassTheme.dynamicBorderDark : const Color(0xFFE2E8F0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: effectiveRadius,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            maxLines: maxLines,
            focusNode: focusNode,
            autofocus: autofocus,
            readOnly: readOnly,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: hintColor),
              prefixIcon:
                  prefix ??
                  (prefixIcon != null
                      ? Icon(prefixIcon, color: hintColor, size: 20)
                      : null),
              suffixIcon:
                  suffix ??
                  (suffixIcon != null
                      ? Icon(suffixIcon, color: hintColor, size: 20)
                      : null),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE53935),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class GlassChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final int? count;
  final IconData? icon;

  const GlassChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final selectedBg = colorScheme.primary;
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final selectedBorder = colorScheme.primary;
    final unselectedBorder = isDark
        ? GlassTheme.dynamicBorderDark
        : const Color(0xFFE2E8F0);
    final selectedTextColor = colorScheme.onPrimary;
    final unselectedTextColor = AppTypography.secondaryTextColor(brightness);

    return AnimatedPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? selectedTextColor : unselectedTextColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedTextColor.withValues(alpha: 0.22)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : const Color(0xFFEEF2F6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
