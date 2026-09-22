import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../core/theme/glass_theme.dart';

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
    final success = await context.read<AuthProvider>().requestOTP(phone);
    setState(() {
      _isLoading = false;
      if (success) _otpSent = true;
    });

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mock OTP sent! (Use 1234)'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _verifyOTP() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().verifyOTP(phone, otp);
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid or expired OTP.'),
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
            image: NetworkImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.phone_iphone, size: 80, color: GlassTheme.primaryGreen)
                        .animate().fade(duration: 500.ms).scale(delay: 200.ms),
                    const SizedBox(height: 16),
                    Text(
                      _otpSent ? 'Enter OTP' : 'Enter Mobile Number',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ).animate().fade().slideY(),
                    const SizedBox(height: 32),
                    if (!_otpSent) ...[
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: GlassTheme.textMuted),
                          prefixIcon: const Icon(Icons.phone, color: GlassTheme.primaryGreen),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: GlassTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        keyboardType: TextInputType.phone,
                      ).animate().fade().slideX(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: GlassButton(
                          onPressed: _isLoading ? () {} : _sendOTP,
                          text: _isLoading ? 'Sending...' : 'Send OTP',
                          icon: Icons.send,
                        ),
                      ).animate().fade().scale(),
                    ] else ...[
                      TextFormField(
                        controller: _otpController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: '4-Digit OTP',
                          labelStyle: TextStyle(color: GlassTheme.textMuted),
                          prefixIcon: const Icon(Icons.password, color: GlassTheme.primaryGreen),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: GlassTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ).animate().fade().slideX(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: GlassButton(
                          onPressed: _isLoading ? () {} : _verifyOTP,
                          text: _isLoading ? 'Verifying...' : 'Login',
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
    );
  }
}
