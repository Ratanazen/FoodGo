import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/svg_icon.dart';

class SavedPhoneAccount {
  final String username;
  final String password;
  final String fullName;
  final String role; // 'admin', 'driver', 'customer', 'restaurant_owner'

  const SavedPhoneAccount({
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'fullName': fullName,
    'role': role,
  };

  factory SavedPhoneAccount.fromJson(Map<String, dynamic> json) => SavedPhoneAccount(
    username: json['username']?.toString() ?? '',
    password: json['password']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    role: json['role']?.toString() ?? 'customer',
  );
}

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
  bool _rememberMe = true;
  bool _saveAccountOnPhone = true;
  String? _loginErrorMessage;
  List<SavedPhoneAccount> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadSavedPhoneAccounts();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('saved_login_identifier');
    if (savedUser != null && savedUser.isNotEmpty && mounted) {
      setState(() {
        _usernameController.text = savedUser;
        _rememberMe = true;
      });
    }
  }

  Future<void> _loadSavedPhoneAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('foodgo_saved_phone_accounts');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          final list = decoded
              .map((e) => SavedPhoneAccount.fromJson(Map<String, dynamic>.from(e)))
              .where((a) => a.username.isNotEmpty)
              .toList();
          if (mounted) {
            setState(() {
              _savedAccounts = list;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved phone accounts: $e');
    }
  }

  Future<void> _saveAccountToPhoneOnLogin(
    String username,
    String password, {
    String? fullName,
    String? role,
  }) async {
    if (!_saveAccountOnPhone) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, SavedPhoneAccount>{};
      for (final a in _savedAccounts) {
        map[a.username.toLowerCase()] = a;
      }
      final existing = map[username.toLowerCase()];
      map[username.toLowerCase()] = SavedPhoneAccount(
        username: username,
        password: password,
        fullName: fullName != null && fullName.isNotEmpty
            ? fullName
            : existing?.fullName ?? username,
        role: role ?? existing?.role ?? 'customer',
      );
      final updatedList = map.values.toList();
      final jsonStr = jsonEncode(updatedList.map((a) => a.toJson()).toList());
      await prefs.setString('foodgo_saved_phone_accounts', jsonStr);
      if (mounted) {
        setState(() {
          _savedAccounts = updatedList;
        });
      }
    } catch (e) {
      debugPrint('Error saving account to phone: $e');
    }
  }

  Future<void> _persistRememberMe(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_login_identifier', identifier);
    } else {
      await prefs.remove('saved_login_identifier');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _loginErrorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final success = await authProvider.login(identifier, password);

    if (!mounted) return;

    if (success) {
      await _persistRememberMe(identifier);

      if (_saveAccountOnPhone) {
        final lastUser = authProvider.lastLoginUser;
        final fName = lastUser != null
            ? (lastUser['first_name'] != null && lastUser['last_name'] != null && '${lastUser['first_name']} ${lastUser['last_name']}'.trim().isNotEmpty
                ? '${lastUser['first_name']} ${lastUser['last_name']}'.trim()
                : lastUser['full_name'] ?? lastUser['name'] ?? identifier)
            : identifier;
        final r = lastUser?['role']?.toString().toLowerCase() ?? 'customer';
        await _saveAccountToPhoneOnLogin(identifier, password, fullName: fName.toString(), role: r);
      }

      if (!mounted) return;
      if (authProvider.lastLoginUser != null) {
        userProvider.setUser(authProvider.lastLoginUser!);
        userProvider.fetchUser();
      } else {
        await userProvider.fetchUser();
      }
      if (!mounted) return;

      final role = userProvider.role;
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
      setState(() {
        _isLoading = false;
        _loginErrorMessage =
            authProvider.lastAuthError ??
            'Login failed. Please check your credentials and try again.';
      });
    }
  }

  Widget _buildBrandHeroLogo(bool isDark) {
    return Column(
        children: [
          // 3D Multi-Layer Isometric Brand Badge
          Stack(
            alignment: Alignment.center,
            children: [
              // Ambient 3D Neon Back-Halo
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      GlassTheme.primaryGreen.withValues(
                        alpha: isDark ? 0.38 : 0.22,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Layer 2: 3D Outer Beveled Shadow Ring
              Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.40 : 0.85),
                          Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.50 : 0.16,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: GlassTheme.primaryGreen.withValues(
                            alpha: 0.38,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF13231B)
                            : const Color(0xFFE8F7EE),
                        border: Border.all(
                          color: GlassTheme.primaryGreen.withValues(
                            alpha: 0.55,
                          ),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const FoodGoLogo(size: 50),
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 2200.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : GlassTheme.authTitleDark,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              children: const [
                TextSpan(text: 'Food'),
                TextSpan(
                  text: 'Go',
                  style: TextStyle(color: GlassTheme.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Fast Delivery • Fresh Meals',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : GlassTheme.authSubtitle,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedSkinBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 32,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            // Ambient soft glowing orbs in the background
            Positioned(
              top: -50,
              right: -50,
              child:
                  Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              GlassTheme.primaryGreen.withValues(
                                alpha: isDark ? 0.16 : 0.08,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fade(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child:
                  Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              GlassTheme.primaryGreenAccent.withValues(
                                alpha: isDark ? 0.12 : 0.06,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fade(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
            ),

            // Main Form Content
            SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 6.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // FoodGo Brand Hero Logo Header with 3D Depth
                          _buildBrandHeroLogo(isDark)
                              .animate()
                              .fade(duration: 450.ms)
                              .scale(
                                begin: const Offset(0.88, 0.88),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutBack,
                              ),

                          const SizedBox(height: 14),

                          // Interactive 3D Perspective Glass Form Card
                          Tilt3DCard(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22.0,
                                vertical: 24.0,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(
                                        0xFF131D18,
                                      ).withValues(alpha: 0.84)
                                    : Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.16)
                                      : Colors.white.withValues(alpha: 0.90),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.55 : 0.14,
                                    ),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                    spreadRadius: -2,
                                  ),
                                  BoxShadow(
                                    color: GlassTheme.primaryGreen.withValues(
                                      alpha: isDark ? 0.22 : 0.15,
                                    ),
                                    blurRadius: 26,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Welcome Heading
                                    Text(
                                          context.tr('auth.welcomeBack'),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : GlassTheme.authTitleDark,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                        .animate()
                                        .fade(delay: 150.ms, duration: 400.ms)
                                        .slideY(
                                          begin: 0.15,
                                          end: 0,
                                          curve: Curves.easeOutCubic,
                                        ),

                                    const SizedBox(height: 4),

                                    // Supporting Subtitle
                                    Text(
                                          context.tr('auth.loginSubtitle'),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : GlassTheme.authSubtitle,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                        .animate()
                                        .fade(delay: 200.ms, duration: 400.ms)
                                        .slideY(
                                          begin: 0.15,
                                          end: 0,
                                          curve: Curves.easeOutCubic,
                                        ),

                                    const SizedBox(height: 14),

                                    // Error Notification Banner with shake animation
                                    if (_loginErrorMessage != null) ...[
                                      Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 2,
                                                  ),
                                                  child: Icon(
                                                    AppIcons.error,
                                                    color: Colors.redAccent,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _loginErrorMessage!,
                                                    style: const TextStyle(
                                                      color: Colors.redAccent,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .animate()
                                          .shake(
                                            duration: 450.ms,
                                            hz: 4,
                                            curve: Curves.easeInOut,
                                          )
                                          .fade(duration: 250.ms),
                                      const SizedBox(height: 16),
                                    ],

                                    // Input 1: Username or Email
                                    TextFormField(
                                      controller: _usernameController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: context.tr(
                                          'auth.usernameOrEmail',
                                        ),
                                        hintText:
                                            'e.g. customer1 or user@foodgo.com',
                                        labelStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : const Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                        prefixIcon: Icon(
                                          AppIcons.profile,
                                          color: isDark
                                              ? Colors.white54
                                              : GlassTheme.authSubtitle,
                                          size: 20,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF1E293B)
                                            : GlassTheme.authInputFill,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 15,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white12
                                                : GlassTheme.authInputBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: GlassTheme.primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your username or email';
                                        }
                                        return null;
                                      },
                                    ).animate().fade(delay: 250.ms),

                                    const SizedBox(height: 14),

                                    // Input 2: Password
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: context.tr('auth.password'),
                                        hintText: 'Enter your password',
                                        labelStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF64748B),
                                          fontSize: 13,
                                        ),
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : const Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                        prefixIcon: Icon(
                                          AppIcons.lock,
                                          color: isDark
                                              ? Colors.white54
                                              : GlassTheme.authSubtitle,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          icon: Icon(
                                            _obscurePassword
                                                ? AppIcons.passwordHidden
                                                : AppIcons.passwordVisible,
                                            color: isDark
                                                ? Colors.white54
                                                : GlassTheme.authSubtitle,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            );
                                          },
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF1E293B)
                                            : GlassTheme.authInputFill,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 15,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white12
                                                : GlassTheme.authInputBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: GlassTheme.primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ).animate().fade(delay: 300.ms),

                                    const SizedBox(height: 10),

                                    // Remember Me & Forgot Password Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _rememberMe = !_rememberMe;
                                                _saveAccountOnPhone = _rememberMe;
                                              });
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: Checkbox(
                                                    value: _rememberMe,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    activeColor:
                                                        GlassTheme.primaryGreen,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _rememberMe =
                                                            val ?? false;
                                                        _saveAccountOnPhone =
                                                            _rememberMe;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    context.tr(
                                                      'auth.rememberMe',
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.white70
                                                          : const Color(
                                                              0xFF475569,
                                                            ),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/forgot-password'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            context.tr('auth.forgotPassword'),
                                            style: TextStyle(
                                              color: GlassTheme.primaryGreen,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ).animate().fade(delay: 350.ms),

                                    const SizedBox(height: 18),

                                    // Primary 3D Tactile Button: Login
                                    SizedBox(
                                          height: 52,
                                          child: AnimatedPressable(
                                            pressedScale: 0.96,
                                            onTap: _isLoading ? null : _login,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFF2FD66F),
                                                    GlassTheme.primaryGreen,
                                                    Color(0xFF0F9B48),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.4),
                                                  width: 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF0B642F,
                                                    ).withValues(alpha: 0.8),
                                                    offset: const Offset(0, 4),
                                                    blurRadius: 0,
                                                  ),
                                                  BoxShadow(
                                                    color: GlassTheme
                                                        .primaryGreen
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : _login,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      Colors.transparent,
                                                  disabledForegroundColor:
                                                      Colors.white70,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.2,
                                                            ),
                                                      )
                                                    : Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            AppIcons.lock,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            context.tr(
                                                              'auth.login',
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  0.3,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fade(delay: 400.ms)
                                        .scale()
                                        .shimmer(
                                          delay: 500.ms,
                                          duration: 1200.ms,
                                          color: Colors.white24,
                                        ),

                                    const SizedBox(height: 22),

                                    // "Or Continue with" Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? Colors.white12
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            context.tr('auth.orContinueWith'),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : const Color(0xFF94A3B8),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: isDark
                                                ? Colors.white12
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                      ],
                                    ).animate().fade(delay: 450.ms),

                                    const SizedBox(height: 16),

                                    // Phone Login Alternative Button (Clean SMS OTP)
                                    SizedBox(
                                      height: 46,
                                      width: double.infinity,
                                      child: AnimatedPressable(
                                        pressedScale: 0.96,
                                        onTap: _isLoading
                                            ? null
                                            : () => context.push(
                                                '/phone-login',
                                              ),
                                        child: OutlinedButton.icon(
                                          onPressed: _isLoading
                                              ? null
                                              : () => context.push(
                                                  '/phone-login',
                                                ),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            side: BorderSide(
                                              color: isDark
                                                  ? Colors.white
                                                        .withValues(
                                                          alpha: 0.16,
                                                        )
                                                  : const Color(
                                                      0xFFCBD5E1,
                                                    ),
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                ),
                                          ),
                                          icon: const Icon(
                                            AppIcons.phone,
                                            size: 18,
                                            color:
                                                GlassTheme.primaryGreen,
                                          ),
                                          label: Text(
                                            context.tr('auth.phoneOtpLogin'),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF1E293B,
                                                    ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ).animate().fade(delay: 500.ms),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Bottom Link: Haven't any account? Sign up
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : GlassTheme.authSubtitle,
                                  fontSize: 13,
                                ),
                              ),
                              AnimatedPressable(
                                pressedScale: 0.94,
                                onTap: () => context.push('/register'),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    context.tr('auth.signUp'),
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
          ],
        ),
      ),
    );
  }
}
