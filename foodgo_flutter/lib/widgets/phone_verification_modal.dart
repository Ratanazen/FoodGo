import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_typography.dart';
import '../core/theme/glass_theme.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'modern_otp_input.dart';
import 'responsive_layout.dart';

class PhoneVerificationModal {
  static Future<bool?> show(
    BuildContext context, {
    String? initialPhone,
    String purpose = 'customer_verification',
    VoidCallback? onVerified,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PhoneVerificationSheet(
        initialPhone: initialPhone,
        purpose: purpose,
        onVerified: onVerified,
      ),
    );
  }
}

class _PhoneVerificationSheet extends StatefulWidget {
  final String? initialPhone;
  final String purpose;
  final VoidCallback? onVerified;

  const _PhoneVerificationSheet({
    this.initialPhone,
    required this.purpose,
    this.onVerified,
  });

  @override
  State<_PhoneVerificationSheet> createState() =>
      _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<_PhoneVerificationSheet> {
  final ApiService _api = ApiService();
  late TextEditingController _phoneController;
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  String _maskedPhone = '';

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    String prefilled = widget.initialPhone ?? '';
    if (prefilled.startsWith('+855')) {
      prefilled = '0${prefilled.substring(4)}';
    }
    _phoneController = TextEditingController(text: prefilled);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
      } else {
        setState(() => _cooldownRemaining -= 1);
      }
    });
  }

  String _cleanPhoneInput(String input) {
    return input.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
  }

  String? _detectCarrier(String input) {
    String clean = _cleanPhoneInput(input);
    if (clean.startsWith('+855')) clean = '0${clean.substring(4)}';
    if (clean.length < 3) return null;
    final p3 = clean.substring(0, 3);
    const smart = [
      '010',
      '015',
      '016',
      '069',
      '070',
      '081',
      '086',
      '087',
      '093',
      '096',
      '098',
    ];
    const cellcard = [
      '011',
      '012',
      '014',
      '017',
      '061',
      '076',
      '077',
      '078',
      '079',
      '085',
      '089',
      '092',
    ];
    const metfone = [
      '023',
      '031',
      '060',
      '066',
      '067',
      '068',
      '071',
      '088',
      '090',
      '097',
    ];
    if (smart.contains(p3)) return 'Smart';
    if (cellcard.contains(p3)) return 'Cellcard';
    if (metfone.contains(p3)) return 'Metfone';
    if (p3 == '018') return 'Seatel';
    if (p3 == '038') return 'Cootel';
    return null;
  }

  Future<void> _sendOTP() async {
    final rawPhone = _cleanPhoneInput(_phoneController.text.trim());
    if (rawPhone.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter your Cambodian mobile number.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.post('auth/phone/send-otp/', {
        'phone': rawPhone,
        'purpose': widget.purpose,
      });

      if (!mounted) return;

      final data = res as Map<String, dynamic>;
      final cooldown = (data['cooldown_seconds'] as num?)?.toInt() ?? 60;
      final masked = data['phone_masked']?.toString() ?? rawPhone;

      setState(() {
        _isLoading = false;
        _isCodeSent = true;
        _maskedPhone = masked;
        _errorMessage = null;
      });

      _startCooldown(cooldown);
    } catch (e) {
      if (!mounted) return;
      String err =
          'Unable to send verification SMS. Please check your number and retry.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['error'] != null) {
          err = data['error'].toString();
        }
        final waitSec = (data['cooldown_seconds'] as num?)?.toInt();
        if (waitSec != null && waitSec > 0) {
          _startCooldown(waitSec);
        }
      }
      setState(() {
        _isLoading = false;
        _errorMessage = err;
      });
    }
  }

  Future<void> _verifyOTP() async {
    final rawPhone = _cleanPhoneInput(_phoneController.text.trim());
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      setState(
        () => _errorMessage = 'Please enter the 6-digit verification code.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _api.post('auth/phone/verify-otp/', {
        'phone': rawPhone,
        'otp': otp,
        'purpose': widget.purpose,
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _errorMessage = null;
      });

      // Refresh User profile in UserProvider
      try {
        await context.read<UserProvider>().fetchUser();
      } catch (_) {}

      widget.onVerified?.call();

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      String err = 'Invalid verification code. Please check and retry.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['error'] != null) {
          err = data['error'].toString();
        }
      }
      setState(() {
        _isLoading = false;
        _errorMessage = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final primaryText = AppTypography.primaryTextColor(theme.brightness);
    final secondaryText = AppTypography.secondaryTextColor(theme.brightness);
    final accentGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final surfaceFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final subtleBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);
    final buttonBg = isDark
        ? GlassTheme.primaryGreenDark
        : const Color(0xFF15803D);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ResponsiveBottomSheet(
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? GlassTheme.dialogDark
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone_android_rounded,
                        color: accentGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSuccess
                                ? 'Phone Number Verified'
                                : (_isCodeSent
                                      ? 'Enter SMS Code'
                                      : 'Verify Cambodian Phone'),
                            style: textTheme.titleLarge?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSuccess
                                ? 'Your mobile number is now verified.'
                                : (_isCodeSent
                                      ? 'Enter 6-digit OTP sent to $_maskedPhone'
                                      : 'Carrier SMS verification (Smart, Cellcard, Metfone)'),
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: secondaryText),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Error display
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Success View
                if (_isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentGreen.withValues(alpha: 0.16),
                            border: Border.all(color: accentGreen, width: 2),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: accentGreen,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Verification Complete',
                          style: textTheme.titleMedium?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Cambodian phone number is active and verified.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!_isCodeSent) ...[
                  // Step 1: Cambodian Phone Number Entry
                  Builder(
                    builder: (context) {
                      final detectedCarrier = _detectCarrier(
                        _phoneController.text,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: surfaceFill,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: detectedCarrier != null
                                    ? accentGreen.withValues(alpha: 0.6)
                                    : subtleBorder,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'KH +855',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: accentGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9\s\+\-]'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: '012 345 678',
                                      hintStyle: textTheme.bodyLarge?.copyWith(
                                        color: secondaryText.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (_) => _sendOTP(),
                                  ),
                                ),
                                if (detectedCarrier != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentGreen.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentGreen.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      detectedCarrier,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: accentGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Supported carriers: Smart, Cellcard, Metfone, Seatel, Cootel.',
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Send Verification Code',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // Step 2 Header summary: Phone target & Edit action
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: subtleBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 16,
                          color: accentGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _maskedPhone.isNotEmpty
                                ? _maskedPhone
                                : _phoneController.text,
                            style: textTheme.bodyMedium?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCodeSent = false;
                              _errorMessage = null;
                              _otpController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: accentGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: accentGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step 2: Modern 6-Digit Glass OTP Code Entry
                  ModernOtpInput(
                    controller: _otpController,
                    length: 6,
                    onCompleted: (_) => _verifyOTP(),
                  ),
                  const SizedBox(height: 14),

                  // Resend countdown row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_cooldownRemaining > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: secondaryText,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Resend in ${_cooldownRemaining}s',
                                style: textTheme.bodySmall?.copyWith(
                                  color: secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        TextButton.icon(
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 15,
                            color: accentGreen,
                          ),
                          label: Text(
                            'Resend Code',
                            style: textTheme.labelLarge?.copyWith(
                              color: accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: _isLoading ? null : _sendOTP,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Verify Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Verify Code',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
