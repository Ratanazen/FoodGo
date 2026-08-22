import 'package:flutter/material.dart';
import '../../core/theme/glass_theme.dart';
import '../glass_container.dart';

class GlassTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;

  const GlassTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: GlassTheme.textMuted),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: GlassTheme.textMuted) : null,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: GlassTheme.textMuted) : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const GlassChip({super.key, required this.label, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        customColor: isSelected ? GlassTheme.primaryGreen.withValues(alpha: 0.2) : null,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? GlassTheme.primaryGreen : GlassTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
