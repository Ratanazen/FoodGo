import 'package:flutter/material.dart';

export 'glass_widgets_extended.dart';
export 'glass_modals.dart';
export 'glass_states.dart';
export 'liquid_glass_background.dart';
export 'animated_pressable.dart';
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

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailingIcon;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
    this.margin,
    this.padding,
    this.boxShadow,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final baseColor = color ?? GlassTheme.primaryGreen.withValues(alpha: 0.85);
    final effectiveColor = isEnabled
        ? baseColor
        : baseColor.withValues(alpha: 0.4);

    final effectiveRadius = borderRadius ?? GlassTheme.borderRadiusSmall;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: text,
      child: AnimatedPressable(
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
                customBorder: border ??
                    Border.all(
                      color: Colors.white.withValues(alpha: isEnabled ? 0.28 : 0.12),
                      width: 1.2,
                    ),
                customShadow: boxShadow ??
                    [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
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
  }
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const GlassSearchBar({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: GlassTheme.borderRadiusSmall,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search, color: GlassTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search food...',
                hintStyle: TextStyle(color: GlassTheme.textMuted),
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
    return GlassContainer(
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: bottom != null ? 0 : 8,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leading ?? const SizedBox(width: 40),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Row(children: actions ?? [const SizedBox(width: 40)]),
            ],
          ),
          ?bottom,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + 20 + (bottom?.preferredSize.height ?? 0),
  );
}
