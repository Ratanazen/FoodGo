import 'package:flutter/material.dart';

export 'glass_widgets_extended.dart';
export 'glass_modals.dart';
export 'glass_states.dart';
export 'liquid_glass_background.dart';
export 'animated_pressable.dart';
export 'tilt_3d_card.dart';
export 'themed_skin_backdrop.dart';
export '../../core/theme/context_theme_extensions.dart';
export '../../core/theme/app_typography.dart';
export '../../core/localization/localization.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';
import 'animated_pressable.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? GlassTheme.borderRadius;
    final card = GlassContainer(
      borderRadius: effectiveRadius,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      customBorder: border,
      child: child,
    );
    if (onTap != null) {
      return AnimatedPressable(
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveRadius,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: card,
          ),
        ),
      );
    }
    return card;
  }
}

enum GlassButtonVariant { primary, accent, secondary, frosted, danger }

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailingIcon;
  final Color? color;
  final Color? textColor;
  final Gradient? gradient;
  final Border? border;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final bool isLoading;
  final double? width;
  final double? height;
  final bool isFullWidth;
  final GlassButtonVariant variant;
  final double? fontSize;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.color,
    this.textColor,
    this.gradient,
    this.border,
    this.borderRadius,
    this.margin,
    this.padding,
    this.boxShadow,
    this.isLoading = false,
    this.width,
    this.height,
    this.isFullWidth = false,
    this.variant = GlassButtonVariant.primary,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve color and styling by variant
    Color baseColor;
    Color defaultTextColor;
    Border? defaultBorder;
    List<BoxShadow>? defaultShadow;

    switch (variant) {
      case GlassButtonVariant.accent:
        baseColor = color ?? GlassTheme.limeAccent;
        defaultTextColor = textColor ?? const Color(0xFF17201B);
        defaultBorder =
            border ??
            Border.all(
              color: const Color(
                0xFFD7FB00,
              ).withValues(alpha: isEnabled ? 0.6 : 0.2),
              width: 1.2,
            );
        defaultShadow =
            boxShadow ??
            [
              BoxShadow(
                color: GlassTheme.limeAccent.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ];
        break;
      case GlassButtonVariant.secondary:
      case GlassButtonVariant.frosted:
        baseColor =
            color ??
            (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05));
        defaultTextColor =
            textColor ?? (isDark ? Colors.white : GlassTheme.textDark);
        defaultBorder =
            border ??
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.12),
              width: 1.2,
            );
        defaultShadow = boxShadow ?? [];
        break;
      case GlassButtonVariant.danger:
        baseColor = color ?? const Color(0xFFE53935);
        defaultTextColor = textColor ?? Colors.white;
        defaultBorder =
            border ??
            Border.all(
              color: Colors.white.withValues(alpha: isEnabled ? 0.3 : 0.12),
              width: 1.2,
            );
        defaultShadow =
            boxShadow ??
            [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ];
        break;
      case GlassButtonVariant.primary:
        baseColor = color ?? Theme.of(context).colorScheme.primary;
        defaultTextColor = textColor ?? Colors.white;
        defaultBorder =
            border ??
            Border.all(
              color: Colors.white.withValues(alpha: isEnabled ? 0.28 : 0.12),
              width: 1.2,
            );
        defaultShadow =
            boxShadow ??
            [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ];
        break;
    }

    final effectiveColor = isEnabled
        ? baseColor
        : baseColor.withValues(alpha: 0.4);
    final effectiveTextColor = isEnabled
        ? defaultTextColor
        : defaultTextColor.withValues(alpha: 0.5);

    final effectiveRadius = borderRadius ?? GlassTheme.borderRadiusSmall;
    final effectiveHeight = height ?? 52.0;

    Widget buttonContent = AnimatedPressable(
      onTap: isEnabled ? onPressed : null,
      pressedScale: 0.96,
      child: Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveRadius,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: effectiveRadius,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: GlassContainer(
              borderRadius: effectiveRadius,
              customColor: effectiveColor,
              customGradient: gradient,
              customBorder: defaultBorder,
              customShadow: defaultShadow,
              padding:
                  padding ??
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: effectiveHeight - (padding != null ? 0 : 28),
                ),
                child: Row(
                  mainAxisSize: isFullWidth || width != null
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            effectiveTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else if (icon != null) ...[
                      Icon(icon, color: effectiveTextColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isFullWidth || width != null) {
      buttonContent = SizedBox(
        width: width ?? double.infinity,
        child: buttonContent,
      );
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: text,
      child: buttonContent,
    );
  }
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const GlassSearchBar({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final secondaryColor = AppTypography.secondaryTextColor(brightness);
    return GlassContainer(
      borderRadius: GlassTheme.borderRadiusSmall,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search, color: secondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTypography.primaryTextColor(brightness),
              ),
              decoration: InputDecoration(
                hintText: 'Search food...',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: secondaryColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fgColor = AppTypography.primaryTextColor(brightness);
    return GlassContainer(
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.only(
        top: 4,
        bottom: bottom != null ? 0 : 4,
        left: 16,
        right: 16,
      ),
      child: SafeArea(
        bottom: false,
        child: IconTheme.merge(
          data: IconThemeData(color: fgColor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    leading ?? const SizedBox(width: 40),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: fgColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions ?? [const SizedBox(width: 40)],
                    ),
                  ],
                ),
              ),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + 28 + (bottom?.preferredSize.height ?? 0),
  );
}
