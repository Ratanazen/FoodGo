import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../core/theme/glass_theme.dart';
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

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.requestOTP(phone);
    setState(() {
      _isLoading = false;
      if (success) _otpSent = true;
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: GlassTheme.backgroundDark,
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80',
            ),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: GlassContainer(
                  padding: const EdgeInsets.all(32.0),
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
                                color: const Color(0xFF13231B),
                                border: Border.all(
                                  color: GlassTheme.primaryGreen.withValues(
                                    alpha: 0.55,
                                  ),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: GlassTheme.primaryGreen.withValues(
                                      alpha: 0.25,
                                    ),
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
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ).animate().fade().slideY(),
                      const SizedBox(height: 32),
                      if (!_otpSent) ...[
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Cambodian Phone Number',
                            hintText: '012 345 678 (or +855)',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontSize: 13,
                            ),
                            labelStyle: const TextStyle(
                              color: GlassTheme.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: GlassTheme.primaryGreen,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: GlassTheme.primaryGreen,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                          ),
                          keyboardType: TextInputType.phone,
                        ).animate().fade().slideX(),
                        const SizedBox(height: 8),
                        const Text(
                          'Supported: Smart, Cellcard, Metfone, Seatel, Cootel',
                          style: TextStyle(
                            color: GlassTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          child: GlassButton(
                            onPressed: _isLoading ? () {} : _sendOTP,
                            text: _isLoading
                                ? 'Sending SMS...'
                                : 'Send SMS OTP',
                            icon: Icons.send,
                          ),
                        ).animate().fade().scale(),
                      ] else ...[
                        // Masked phone target & Change button
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
                                  _phoneController.text,
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
                                    _otpSent = false;
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
                        ModernOtpInput(
                          controller: _otpController,
                          length: 6,
                          onCompleted: (_) => _verifyOTP(),
                        ).animate().fade().slideX(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _isLoading ? null : _sendOTP,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 15,
                                color: GlassTheme.primaryGreen,
                              ),
                              label: const Text(
                                'Resend SMS',
                                style: TextStyle(
                                  color: GlassTheme.primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: GlassButton(
                            onPressed: _isLoading ? () {} : _verifyOTP,
                            text: _isLoading
                                ? 'Verifying...'
                                : 'Verify & Login',
                            icon: Icons.check_circle,
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
