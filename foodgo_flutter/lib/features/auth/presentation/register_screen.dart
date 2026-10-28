import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/google_auth_service.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/svg_icon.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final String _selectedRole = 'customer';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawName = _fullNameController.text.trim();
    final parts = rawName.split(' ').where((s) => s.isNotEmpty).toList();
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    // Sanitize username by replacing spaces with underscores and filtering special characters
    String cleanUsername = rawName
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    if (cleanUsername.isEmpty || cleanUsername.length < 3) {
      final emailPrefix = _emailController.text
          .split('@')
          .first
          .trim()
          .toLowerCase();
      cleanUsername = emailPrefix.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: cleanUsername,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: firstName,
      lastName: lastName,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() => _isLoading = false);
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
              authProvider.lastAuthError ??
                  'Registration failed. Username or email may already be taken.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loginWithGoogle() async {
    final googleResult = await GoogleAuthService.signIn(context);
    if (googleResult == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle(
      idToken: googleResult.idToken,
      email: googleResult.email,
      displayName: googleResult.displayName,
      avatarUrl: googleResult.photoUrl,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

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
        const SnackBar(
          content: Text('Google Sign-Up failed. Please try again.'),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 20.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // FoodGo Brand Logo Emblem
                    Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF13231B)
                                  : const Color(0xFFE8F7EE),
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

                    const SizedBox(height: 18),

                    // Title: Sign Up
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : GlassTheme.authTitleDark,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 150.ms),

                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'Give proper information for continue',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? Colors.grey[400]
                            : GlassTheme.authSubtitle,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 200.ms),

                    const SizedBox(height: 24),

                    // Input 1: Full name
                    TextFormField(
                      controller: _fullNameController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Full name',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
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
                            color: GlassTheme.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter your full name'
                          : null,
                    ).animate().fade(delay: 250.ms),

                    const SizedBox(height: 14),

                    // Input 2: Email address
                    TextFormField(
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
                            color: GlassTheme.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter an email address';
                        }
                        if (!val.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ).animate().fade(delay: 300.ms),

                    const SizedBox(height: 14),

                    // Input 3: Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: isDark
                              ? Colors.white54
                              : GlassTheme.authSubtitle,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: isDark
                                ? Colors.white54
                                : GlassTheme.authSubtitle,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
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
                            color: GlassTheme.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ).animate().fade(delay: 350.ms),

                    const SizedBox(height: 14),

                    const SizedBox(height: 16),

                    // Terms & Conditions Disclaimer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey[400]
                                : GlassTheme.authSubtitle,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(
                              text: 'By signing up you are agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 400.ms),

                    const SizedBox(height: 20),

                    // Primary Button: Create Account
                    SizedBox(
                      height: 50,
                      child: AnimatedPressable(
                        pressedScale: 0.96,
                        onTap: _isLoading ? null : _register,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ).animate().fade(delay: 450.ms).scale(),

                    const SizedBox(height: 16),

                    // Google Sign Up Option
                    SizedBox(
                      height: 44,
                      child: AnimatedPressable(
                        pressedScale: 0.95,
                        onTap: _isLoading ? null : _loginWithGoogle,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const GoogleLogo(size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Sign up with Google',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 500.ms),

                    const SizedBox(height: 20),

                    // Bottom Link: Already have an Account? Sign in
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an Account? ',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : GlassTheme.authSubtitle,
                            fontSize: 13,
                          ),
                        ),
                        AnimatedPressable(
                          pressedScale: 0.94,
                          onTap: () => context.go('/login'),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 550.ms),
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
