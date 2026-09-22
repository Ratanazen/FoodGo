import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../core/theme/glass_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        context.read<UserProvider>().fetchUser();
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login failed. Check your credentials.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: GlassTheme.borderRadiusSmall),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.fastfood,
                        size: 80,
                        color: GlassTheme.primaryGreen,
                      ).animate().fade(duration: 500.ms).scale(delay: 200.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to FoodGo',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 300.ms).slideY(),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: GlassTheme.textMuted),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: GlassTheme.primaryGreen,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: GlassTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ).animate().fade(delay: 400.ms).slideX(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: GlassTheme.textMuted),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: GlassTheme.primaryGreen,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: GlassTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: GlassTheme.primaryGreen),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ).animate().fade(delay: 500.ms).slideX(),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: GlassButton(
                          onPressed: _isLoading ? () {} : _login,
                          text: _isLoading ? 'Authenticating...' : 'Login',
                          icon: _isLoading ? Icons.hourglass_empty : Icons.login,
                        ),
                      ).animate().fade(delay: 600.ms).scale(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 56,
                        child: TextButton.icon(
                          onPressed: () => context.push('/phone-login'),
                          icon: const Icon(Icons.phone_iphone, color: GlassTheme.primaryGreen),
                          label: const Text('Login with Mobile Number', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            side: BorderSide(color: GlassTheme.primaryGreen.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: GlassTheme.borderRadiusSmall),
                          ),
                        ),
                      ).animate().fade(delay: 650.ms).scale(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: GlassTheme.textMuted),
                        ),
                      ).animate().fade(delay: 700.ms),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: TextStyle(color: GlassTheme.textMuted),
                          ),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 800.ms),
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
