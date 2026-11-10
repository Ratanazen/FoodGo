import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
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
  String? _selectedSavedUsername;
  List<SavedPhoneAccount> _savedAccounts = [];

  static const List<SavedPhoneAccount> _presetAccounts = [
    SavedPhoneAccount(
      username: 'admin',
      password: 'admin123',
      fullName: 'FoodGo Admin',
      role: 'admin',
    ),
    SavedPhoneAccount(
      username: 'driver1',
      password: 'driver123',
      fullName: 'Bob Rider (Driver)',
      role: 'driver',
    ),
    SavedPhoneAccount(
      username: 'driver2',
      password: 'driver123',
      fullName: 'Sophea Swift (Driver)',
      role: 'driver',
    ),
    SavedPhoneAccount(
      username: 'customer1',
      password: 'customer123',
      fullName: 'Alice Smith (Customer)',
      role: 'customer',
    ),
    SavedPhoneAccount(
      username: 'Ratana',
      password: 'ratana123',
      fullName: 'Ratana Zen (Customer)',
      role: 'customer',
    ),
    SavedPhoneAccount(
      username: 'owner',
      password: 'owner123',
      fullName: 'Restaurant Owner',
      role: 'restaurant_owner',
    ),
  ];

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

  Future<void> _autoAddAllAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final merged = <String, SavedPhoneAccount>{};
      for (final a in _presetAccounts) {
        merged[a.username.toLowerCase()] = a;
      }
      for (final a in _savedAccounts) {
        if (!merged.containsKey(a.username.toLowerCase())) {
          merged[a.username.toLowerCase()] = a;
        }
      }
      final updatedList = merged.values.toList();
      final jsonStr = jsonEncode(updatedList.map((a) => a.toJson()).toList());
      await prefs.setString('foodgo_saved_phone_accounts', jsonStr);

      if (mounted) {
        setState(() {
          _savedAccounts = updatedList;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚡ All 6 accounts saved on phone (Admin, Delivery, Customer, Owner)! Tap any card to auto-fill.',
            ),
            backgroundColor: GlassTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-adding accounts: $e');
    }
  }

  Future<void> _removeSavedAccount(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedList = _savedAccounts
          .where((a) => a.username.toLowerCase() != username.toLowerCase())
          .toList();
      final jsonStr = jsonEncode(updatedList.map((a) => a.toJson()).toList());
      await prefs.setString('foodgo_saved_phone_accounts', jsonStr);
      if (mounted) {
        setState(() {
          _savedAccounts = updatedList;
          if (_selectedSavedUsername?.toLowerCase() == username.toLowerCase()) {
            _selectedSavedUsername = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error removing saved account: $e');
    }
  }

  void _selectSavedAccount(SavedPhoneAccount acc) {
    setState(() {
      _selectedSavedUsername = acc.username;
      _usernameController.text = acc.username;
      _passwordController.text = acc.password;
      _rememberMe = true;
    });
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

  void _showServerDialog() {
    final controller = TextEditingController(text: AppConfig.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2620),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(AppIcons.dns, color: GlassTheme.primaryGreen, size: 20),
            SizedBox(width: 8),
            Text(
              'API Server URL',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select or paste your backend server URL:',
              style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Base URL',
                labelStyle: const TextStyle(color: GlassTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Presets:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text(
                    'Vercel (Production Live)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      controller.text = 'https://food-go-app.vercel.app/api/',
                ),
                ActionChip(
                  label: const Text(
                    'Localhost (Port 8000)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      controller.text = 'http://127.0.0.1:8000/api/',
                ),
                ActionChip(
                  label: const Text(
                    'Android Emulator (10.0.2.2)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      controller.text = 'http://10.0.2.2:8000/api/',
                ),
                ActionChip(
                  label: const Text(
                    'Cloudflare Edge (Fallback)',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () => controller.text =
                      'https://foodgo.rtnaeam611.workers.dev/api/',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryGreen,
            ),
            onPressed: () async {
              final newUrl = controller.text;
              await AppConfig.setCustomApiUrl(newUrl);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Server URL updated successfully!'),
                  backgroundColor: GlassTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeroLogo(bool isDark) {
    return GestureDetector(
      onLongPress: _showServerDialog,
      child: Column(
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
      ),
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

                                    const SizedBox(height: 20),

                                    // ── Saved Accounts on Phone Section ──
                                    _buildSavedAccountsSection(isDark),
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

  Widget _buildSavedAccountsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      context.tr('auth.savedAccounts'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_savedAccounts.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_savedAccounts.length}',
                        style: const TextStyle(
                          color: GlassTheme.primaryGreen,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _autoAddAllAccounts,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      context.tr('auth.autoAddAll'),
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_savedAccounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.save_outlined,
                  size: 24,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 6),
                Text(
                  'No accounts saved on this phone yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _autoAddAllAccounts,
                  icon: const Icon(
                    Icons.bolt,
                    size: 16,
                    color: Colors.amberAccent,
                  ),
                  label: const Text(
                    '⚡ Auto Add All Accounts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: GlassTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _savedAccounts.map((acc) {
              final isSelected =
                  _selectedSavedUsername?.toLowerCase() ==
                  acc.username.toLowerCase();
              return _buildSavedAccountCard(acc, isSelected, isDark);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSavedAccountCard(
    SavedPhoneAccount acc,
    bool isSelected,
    bool isDark,
  ) {
    Color roleColor;
    IconData roleIcon;
    String roleLabel;

    switch (acc.role.toLowerCase()) {
      case 'admin':
        roleColor = const Color(0xFFF59E0B);
        roleIcon = Icons.admin_panel_settings_rounded;
        roleLabel = 'Admin';
        break;
      case 'driver':
        roleColor = const Color(0xFF0EA5E9);
        roleIcon = Icons.two_wheeler_rounded;
        roleLabel = 'Delivery';
        break;
      case 'restaurant_owner':
        roleColor = const Color(0xFFA855F7);
        roleIcon = Icons.storefront_rounded;
        roleLabel = 'Owner';
        break;
      default:
        roleColor = GlassTheme.primaryGreen;
        roleIcon = Icons.person_rounded;
        roleLabel = 'Customer';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? roleColor.withValues(alpha: isDark ? 0.18 : 0.08)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? roleColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectSavedAccount(acc),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Role Icon Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(roleIcon, size: 18, color: roleColor),
                ),
                const SizedBox(width: 10),

                // Name & Username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              acc.fullName.isNotEmpty
                                  ? acc.fullName
                                  : acc.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${acc.username}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions: Quick Select or Delete
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  color: isSelected
                      ? roleColor
                      : (isDark ? Colors.white38 : Colors.black38),
                  tooltip: 'Fill credentials',
                  onPressed: () => _selectSavedAccount(acc),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: isDark ? Colors.white30 : Colors.black26,
                  tooltip: 'Remove from phone',
                  onPressed: () => _removeSavedAccount(acc.username),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
