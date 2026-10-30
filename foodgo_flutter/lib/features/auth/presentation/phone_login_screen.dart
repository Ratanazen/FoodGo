import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/svg_icon.dart';
import '../../../widgets/modern_otp_input.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (mounted) setState(() {});
    });
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

  Color _carrierColor(String carrier) {
    switch (carrier) {
      case 'Smart':
        return const Color(0xFF00A651);
      case 'Cellcard':
        return const Color(0xFFFF6600);
      case 'Metfone':
        return const Color(0xFFE50012);
      case 'Seatel':
        return const Color(0xFF0072CE);
      default:
        return const Color(0xFF26A69A);
    }
  }

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _cooldownRemaining > 0) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.requestOTP(phone);
    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
        _startCooldown(60);
      }
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code dispatched via SMS.'),
            backgroundColor: GlassTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.lastAuthError ??
                  'Failed to send SMS code. Please check your phone number.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _verifyOTP() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOTP(phone, otp);
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        final userProvider = context.read<UserProvider>();
        await userProvider.fetchUser();
        if (!mounted) return;
        final role = userProvider.user?['role']?.toString().toLowerCase();
        if (role == 'admin') {
          context.go('/admin-dashboard');
        } else if (role == 'driver') {
          context.go('/driver-dashboard');
        } else if (role == 'restaurant_owner') {
          context.go('/restaurant-dashboard');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.lastAuthError ?? 'Invalid or expired verification code.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider?>();
    final palette = themeProvider?.paletteData;

    final primaryColor = palette?.primary ?? GlassTheme.primaryGreen;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2620);
    final textMuted = isDark ? GlassTheme.textMuted : const Color(0xFF718096);
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

    final detectedCarrier = _detectCarrier(_phoneController.text);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.back, color: textColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Tilt3DCard(
                borderRadius: BorderRadius.circular(28),
                child: GlassContainer(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? (palette?.surfaceCardDark ??
                                          GlassTheme.midnightSmalt)
                                    : Colors.white,
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.55),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 22,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const FoodGoLogo(size: 60),
                            ),
                          )
                          .animate()
                          .fade(duration: 400.ms)
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 16),
                      Text(
                        _otpSent ? 'Enter OTP' : 'Enter Mobile Number',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                        textAlign: TextAlign.center,
                      ).animate().fade().slideY(),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent
                            ? 'Enter the 6-digit verification code sent to your phone'
                            : 'Sign in quickly using your Cambodian mobile number',
                        style: TextStyle(color: textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      if (!_otpSent) ...[
                        // Phone input with country flag prefix & carrier badge
                        TextFormField(
                          controller: _phoneController,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Cambodian Phone Number',
                            hintText: '012 345 678 (or +855)',
                            hintStyle: TextStyle(
                              color: textMuted.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            labelStyle: TextStyle(color: textMuted),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '🇰🇭',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+855',
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    AppIcons.phone,
                                    color: primaryColor,
                                    size: AppIconSizes.sm,
                                  ),
                                ],
                              ),
                            ),
                            suffixIcon: detectedCarrier != null
                                ? Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _carrierColor(
                                        detectedCarrier,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _carrierColor(detectedCarrier),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          AppIcons.checkCircle,
                                          size: 11,
                                          color: _carrierColor(detectedCarrier),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          detectedCarrier,
                                          style: TextStyle(
                                            color: _carrierColor(
                                              detectedCarrier,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: inputBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: inputBg,
                          ),
                          keyboardType: TextInputType.phone,
                        ).animate().fade().slideX(),
                        const SizedBox(height: 10),
                        // Carrier quick hint chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Supported:',
                              style: TextStyle(
                                color: GlassTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            for (final c in [
                              'Smart',
                              'Cellcard',
                              'Metfone',
                              'Seatel',
                              'Cootel',
                            ])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: detectedCarrier == c
                                      ? _carrierColor(c).withValues(alpha: 0.2)
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              )),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: detectedCarrier == c
                                        ? _carrierColor(c)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: detectedCarrier == c
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: detectedCarrier == c
                                        ? _carrierColor(c)
                                        : textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: GlassButton(
                            onPressed: _isLoading ? () {} : _sendOTP,
                            text: _isLoading
                                ? 'Sending SMS...'
                                : 'Send SMS OTP',
                            icon: AppIcons.send,
                          ),
                        ).animate().fade().scale(),
                      ] else ...[
                        // Masked phone target & Change button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: inputBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.mail,
                                size: AppIconSizes.sm,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Code sent to:',
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      _phoneController.text,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedPressable(
                                pressedScale: 0.92,
                                onTap: () {
                                  setState(() {
                                    _otpSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppIcons.edit,
                                        size: AppIconSizes.xs,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Change',
                                        style: TextStyle(
                                          color: primaryColor,
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
                        const SizedBox(height: 20),
                        ModernOtpInput(
                          controller: _otpController,
                          length: 6,
                          onCompleted: (_) => _verifyOTP(),
                        ).animate().fade().slideX(),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedPressable(
                              pressedScale: 0.94,
                              onTap: (_isLoading || _cooldownRemaining > 0)
                                  ? null
                                  : _sendOTP,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.refresh,
                                      size: AppIconSizes.xs,
                                      color: _cooldownRemaining > 0
                                          ? textMuted
                                          : primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _cooldownRemaining > 0
                                          ? 'Resend SMS in ${_cooldownRemaining}s'
                                          : 'Resend SMS',
                                      style: TextStyle(
                                        color: _cooldownRemaining > 0
                                            ? textMuted
                                            : primaryColor,
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
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 54,
                          child: GlassButton(
                            onPressed: _isLoading ? () {} : _verifyOTP,
                            text: _isLoading
                                ? 'Verifying...'
                                : 'Verify & Login',
                            icon: AppIcons.checkCircle,
                          ),
                        ).animate().fade().scale(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
