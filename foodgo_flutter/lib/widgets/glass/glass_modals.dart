import 'package:flutter/material.dart';

import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';
import 'glass_widgets.dart';

class GlassModals {
  static Future<T?> showGlassBottomSheet<T>(
    BuildContext context,
    Widget child,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: GlassContainer(
              customColor: isDark
                  ? GlassTheme.dynamicDialogDark.withValues(alpha: 0.96)
                  : const Color(0xFCFFFFFF),
              customBorder: Border.all(
                color: isDark
                    ? GlassTheme.dynamicBorderDark
                    : GlassTheme.borderLight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 12,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.28)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<T?> showGlassDialog<T>(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassContainer(
              customColor: isDark ? GlassTheme.dynamicDialogDark : Colors.white,
              customBorder: Border.all(
                color: isDark
                    ? GlassTheme.dynamicBorderDark
                    : GlassTheme.borderLight,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTypography.primaryTextColor(brightness),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTypography.secondaryTextColor(brightness),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isDark
                                    ? GlassTheme.dynamicBorderDark
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            cancelText,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppTypography.secondaryTextColor(
                                    brightness,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          text: confirmText,
                          height: 48,
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirm();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
