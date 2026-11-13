import 'package:flutter/material.dart';

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
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: GlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: child,
          ),
        ),
      ),
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
      builder: (context) => Dialog(
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTypography.primaryTextColor(
                      Theme.of(context).brightness,
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTypography.secondaryTextColor(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          cancelText,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppTypography.secondaryTextColor(
                                  Theme.of(context).brightness,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GlassButton(
                        text: confirmText,
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
      ),
    );
  }
}
