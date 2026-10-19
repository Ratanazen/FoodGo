import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import 'widgets/auth_illustration.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP code sent! Please check your email inbox.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 10.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Illustration matching Reference Screen 3
                  const AuthIllustration(
                    type: AuthIllustrationType.forgotPassword,
                    size: 135,
                  ).animate().fade(duration: 400.ms).scale(),

                  const SizedBox(height: 20),

                  // Title: Forget Password
                  Text(
                    'Forget Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : GlassTheme.authTitleDark,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 150.ms),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Don\'t worry it happens. Please enter the address associated with your account.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? Colors.grey[400]
                          : GlassTheme.authSubtitle,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 200.ms),

                  const SizedBox(height: 28),

                  // Input: Email address
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: isDark
                            ? Colors.white54
                            : GlassTheme.authSubtitle,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : GlassTheme.authInputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : GlassTheme.authInputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: GlassTheme.authBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 250.ms),

                  const SizedBox(height: 24),

                  // Primary Button: Send OTP
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.authBlue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: GlassTheme.authBlue.withValues(alpha: 0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ).animate().fade(delay: 300.ms).scale(),

                  const SizedBox(height: 24),

                  // Bottom Link: You remember your password? Sign in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'You remember your password? ',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : GlassTheme.authSubtitle,
                          fontSize: 13,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: GlassTheme.authBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 350.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
