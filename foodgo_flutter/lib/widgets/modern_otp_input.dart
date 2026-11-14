import 'dart:async';
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

class _ModernOtpInputState extends State<ModernOtpInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _cursorAnimController;
  Timer? _clipboardCheckTimer;
  bool _canPaste = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _cursorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    widget.controller.addListener(_handleControllerChange);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }

    _checkClipboard();
  }

  @override
  void dispose() {
    _cursorAnimController.dispose();
    _clipboardCheckTimer?.cancel();
    widget.controller.removeListener(_handleControllerChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty &&
          RegExp(r'^\d{' + widget.length.toString() + r'}$').hasMatch(text)) {
        if (mounted) setState(() => _canPaste = true);
      }
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        final code = digits.substring(
          0,
          digits.length > widget.length ? widget.length : digits.length,
        );
        widget.controller.text = code;
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  void _handleControllerChange() {
    setState(() {});
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      HapticFeedback.mediumImpact();
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.controller.text;
    final isFocused = _focusNode.hasFocus;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Hidden textfield for native keyboard and accessibility
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
              onTap: () {
                HapticFeedback.selectionClick();
                _focusNode.requestFocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (index) {
                  final isFilled = index < currentText.length;
                  final isCurrent = index == currentText.length && isFocused;
                  final digit = isFilled ? currentText[index] : '';

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  Color boxColor = isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04);
                  Color borderColor = isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12);
                  List<BoxShadow> shadows = [];

                  if (isCurrent) {
                    borderColor = GlassTheme.primaryGreen;
                    boxColor = GlassTheme.primaryGreen.withValues(alpha: 0.12);
                    shadows = [
                      BoxShadow(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ];
                  } else if (isFilled) {
                    borderColor = GlassTheme.primaryGreen.withValues(
                      alpha: 0.65,
                    );
                    boxColor = GlassTheme.primaryGreen.withValues(alpha: 0.08);
                  }

                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.symmetric(
                        horizontal: widget.length > 5 ? 3 : 5,
                      ),
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
                      child: isCurrent && digit.isEmpty
                          ? FadeTransition(
                              opacity: _cursorAnimController,
                              child: Container(
                                width: 2,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: GlassTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            )
                          : Text(
                              digit,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: isFilled
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF1F2937))
                                        : (isDark
                                              ? Colors.white38
                                              : const Color(0xFF9CA3AF)),
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
        ),

        // Quick clipboard paste button
        if (_canPaste && currentText.length < widget.length) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pasteFromClipboard,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.content_paste_rounded,
                    size: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF15803D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paste Code from Clipboard',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
