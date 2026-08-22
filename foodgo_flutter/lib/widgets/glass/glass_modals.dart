import 'package:flutter/material.dart';
import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';
import 'glass_widgets.dart';

class GlassModals {
  static Future<T?> showGlassBottomSheet<T>(BuildContext context, Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: child,
      ),
    );
  }

  static Future<T?> showGlassDialog<T>(BuildContext context, {required String title, required String message, required VoidCallback onConfirm, String confirmText = 'Confirm', String cancelText = 'Cancel'}) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: GlassTheme.textMuted)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(cancelText, style: TextStyle(color: GlassTheme.textMuted)),
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
    );
  }
}
