import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/responsive_layout.dart';
import 'widgets/auth_illustration.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool get _isPhone {
    final text = _identifierController.text.trim();
    return !text.contains('@') &&
        text.replaceAll(RegExp(r'[^0-9]'), '').length >= 4;
  }

  Future<void> _sendOTP() async {
    final identifier = _identifierController.text.trim();
    final cleanDigits = identifier.replaceAll(RegExp(r'[^0-9]'), '');
    final isEmail = identifier.contains('@') && identifier.contains('.');
    final isPhone = cleanDigits.length >= 7;

    if (!isEmail && !isPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address or phone number'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _api.post('forgot-password/', {
        'identifier': identifier,
        'email': identifier,
        'phone': identifier,
      });
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = isPhone
          ? 'OTP verification code sent! Please check your SMS messages.'
          : 'Password reset link sent! Please check your email inbox.';
      if (res is Map && res['message'] != null) {
        message = res['message'].toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = 'Failed to send reset code. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          if (data['error'] != null) {
            errorMsg = data['error'].toString();
          } else if (data['detail'] != null) {
            errorMsg = data['detail'].toString();
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        child: ResponsiveWebContainer(
          maxWidth: 460,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.12),
                        border: Border.all(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: AuthIllustration(
                          type: AuthIllustrationType.forgotPassword,
                          size: 72,
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 400.ms).scale(),

                  const SizedBox(height: 24),

                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : GlassTheme.authTitleDark,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 150.ms),

                  const SizedBox(height: 10),

                  Text(
                    'Enter your registered email address or phone number and we will send you a verification code to recover your account.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey[400]
                          : GlassTheme.authSubtitle,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fade(delay: 200.ms),

                  const SizedBox(height: 32),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                          : GlassTheme.authInputFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : GlassTheme.authInputBorder,
                      ),
                    ),
                    child: TextField(
                      controller: _identifierController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _sendOTP(),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email address or phone number',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          _isPhone
                              ? Icons.phone_iphone_rounded
                              : Icons.alternate_email_rounded,
                          color: GlassTheme.primaryGreen,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 250.ms),

                  const SizedBox(height: 26),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlassTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: GlassTheme.primaryGreen.withValues(
                          alpha: 0.4,
                        ),
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
                              'Send Reset Code / Link',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ).animate().fade(delay: 300.ms).scale(),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password? ',
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
                            color: GlassTheme.primaryGreen,
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
