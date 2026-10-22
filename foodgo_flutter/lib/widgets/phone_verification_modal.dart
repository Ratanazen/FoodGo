import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ResponsiveBottomSheet(
        child: Container(
          decoration: BoxDecoration(
            color: GlassTheme.dialogDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                      color: Colors.white24,
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: GlassTheme.primaryGreen,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSuccess
                                ? 'Your mobile number is now verified.'
                                : (_isCodeSent
                                      ? 'Enter 6-digit OTP sent to $_maskedPhone'
                                      : 'Carrier SMS verification (Smart, Cellcard, Metfone)'),
                            style: const TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
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
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
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
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            border: Border.all(
                              color: GlassTheme.primaryGreen,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: GlassTheme.primaryGreen,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Verification Complete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your Cambodian phone number is active and verified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GlassTheme.textMuted,
                            fontSize: 13,
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
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: detectedCarrier != null
                                    ? GlassTheme.primaryGreen.withValues(
                                        alpha: 0.5,
                                      )
                                    : Colors.white.withValues(alpha: 0.12),
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
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'KH +855',
                                        style: TextStyle(
                                          color: GlassTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9\s\+\-]'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '012 345 678',
                                      hintStyle: TextStyle(
                                        color: Colors.white30,
                                        fontSize: 15,
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
                                      color: GlassTheme.primaryGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: GlassTheme.primaryGreen
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      detectedCarrier,
                                      style: const TextStyle(
                                        color: GlassTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Supported carriers: Smart, Cellcard, Metfone, Seatel, Cootel.',
                            style: TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 12,
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
                        backgroundColor: GlassTheme.primaryGreen,
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
                          : const Text(
                              'Send Verification Code',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
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
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 16,
                          color: GlassTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _maskedPhone.isNotEmpty
                                ? _maskedPhone
                                : _phoneController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: GlassTheme.primaryGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: GlassTheme.primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: GlassTheme.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Resend in ${_cooldownRemaining}s',
                                style: const TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 15,
                            color: GlassTheme.primaryGreen,
                          ),
                          label: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: GlassTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                        backgroundColor: GlassTheme.primaryGreen,
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
                          : const Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
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
