import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/glass_theme.dart';

class ModernOtpInput extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autoFocus;

  const ModernOtpInput({
    super.key,
    this.length = 6,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.autoFocus = true,
  });

  @override
  State<ModernOtpInput> createState() => _ModernOtpInputState();
}

class _ModernOtpInputState extends State<ModernOtpInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_handleControllerChange);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    setState(() {});
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.controller.text;
    final isFocused = _focusNode.hasFocus;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Hidden textfield for native keyboard, accessibility, and clipboard paste
        Opacity(
          opacity: 0.0,
          child: SizedBox(
            height: 56,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              autofillHints: const [AutofillHints.oneTimeCode],
              enableSuggestions: false,
              autocorrect: false,
            ),
          ),
        ),

        // 6 Glass PIN Boxes
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final isFilled = index < currentText.length;
              final isCurrent = index == currentText.length && isFocused;
              final digit = isFilled ? currentText[index] : '';

              Color boxColor = Colors.white.withValues(alpha: 0.04);
              Color borderColor = Colors.white.withValues(alpha: 0.12);
              List<BoxShadow> shadows = [];

              if (isCurrent) {
                borderColor = GlassTheme.primaryGreen;
                boxColor = GlassTheme.primaryGreen.withValues(alpha: 0.10);
                shadows = [
                  BoxShadow(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ];
              } else if (isFilled) {
                borderColor = GlassTheme.primaryGreen.withValues(alpha: 0.65);
                boxColor = GlassTheme.primaryGreen.withValues(alpha: 0.08);
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: widget.length > 5 ? 3 : 5),
                  height: 58,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: isCurrent ? 2.0 : 1.2,
                    ),
                    boxShadow: shadows,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: TextStyle(
                      color: isFilled ? Colors.white : Colors.white38,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
