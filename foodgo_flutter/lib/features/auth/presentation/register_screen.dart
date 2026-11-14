import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'customer';
  bool _usernameManuallyEdited = false;
  String? _registerErrorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_onFullNameChanged);
  }

  void _onFullNameChanged() {
    if (!_usernameManuallyEdited) {
      final name = _fullNameController.text.trim();
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      _usernameController.text = slug;
    }
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFullNameChanged);
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _registerErrorMessage = null;
    });

    final rawName = _fullNameController.text.trim();
    final parts = rawName.split(' ').where((s) => s.isNotEmpty).toList();
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final username = _usernameController.text.trim().toLowerCase();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: username,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: firstName,
      lastName: lastName,
      role: _selectedRole,
    );

    if (!mounted) return;

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
      setState(() {
        _isLoading = false;
        _registerErrorMessage =
            authProvider.lastAuthError ??
            'Registration failed. Username or email may already be taken.';
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.38),
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.55),
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
        Builder(
          builder: (context) {
            final brightness = Theme.of(context).brightness;
            final textTheme = Theme.of(context).textTheme;
            final primaryText = AppTypography.primaryTextColor(brightness);
            final secondaryText = AppTypography.secondaryTextColor(brightness);
            final accentGreen = isDark
                ? GlassTheme.primaryGreenAccent
                : const Color(0xFF15803D);
            return Column(
              children: [
                RichText(
                  text: TextSpan(
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primaryText,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.08,
                          ),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    children: [
                      const TextSpan(text: 'Food'),
                      TextSpan(
                        text: 'Go',
                        style: TextStyle(color: accentGreen),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Join FoodGo • Fresh Meals Delivered',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleSelector(bool isDark) {
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: textTheme.labelSmall?.copyWith(
            color: secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                title: 'Customer',
                icon: Icons.person_rounded,
                role: 'customer',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRoleCard(
                title: 'Driver',
                icon: Icons.delivery_dining_rounded,
                role: 'driver',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    required String role,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == role;
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    return AnimatedPressable(
      pressedScale: 0.96,
      onTap: () {
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2FD66F), GlassTheme.primaryGreen],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF1E293B) : GlassTheme.authInputFill),
          border: Border.all(
            color: isSelected
                ? GlassTheme.primaryGreen
                : (isDark ? Colors.white12 : GlassTheme.authInputBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return ThemedSkinBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: '',
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTypography.primaryTextColor(brightness),
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
                                vertical: 22.0,
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
                              child: Builder(
                                builder: (context) {
                                  final brightness = Theme.of(
                                    context,
                                  ).brightness;
                                  final textTheme = Theme.of(context).textTheme;
                                  final primaryText =
                                      AppTypography.primaryTextColor(
                                        brightness,
                                      );
                                  final secondaryText =
                                      AppTypography.secondaryTextColor(
                                        brightness,
                                      );
                                  final accentGreen = isDark
                                      ? GlassTheme.primaryGreenAccent
                                      : const Color(0xFF15803D);
                                  final dangerRed = isDark
                                      ? Colors.redAccent
                                      : const Color(0xFFB91C1C);
                                  final isKhmer =
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'km';

                                  InputDecoration buildFieldDecoration({
                                    required String labelText,
                                    required String hintText,
                                    required IconData prefixIcon,
                                    String? helperText,
                                    Widget? suffixIcon,
                                  }) {
                                    return InputDecoration(
                                      labelText: labelText,
                                      hintText: hintText,
                                      helperText: helperText,
                                      helperStyle: textTheme.labelSmall
                                          ?.copyWith(color: secondaryText),
                                      labelStyle: textTheme.bodyMedium
                                          ?.copyWith(
                                            color: secondaryText,
                                            height: isKhmer ? 1.5 : null,
                                            letterSpacing: isKhmer ? 0 : null,
                                          ),
                                      hintStyle: textTheme.bodyMedium?.copyWith(
                                        color: secondaryText,
                                      ),
                                      prefixIcon: Icon(
                                        prefixIcon,
                                        color: secondaryText,
                                        size: 20,
                                      ),
                                      suffixIcon: suffixIcon,
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : GlassTheme.authInputFill,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
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
                                        borderSide: BorderSide(
                                          color: dangerRed,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: dangerRed,
                                          width: 1.5,
                                        ),
                                      ),
                                    );
                                  }

                                  return Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Screen Heading
                                        Text(
                                              context.tr('auth.createAccount'),
                                              style: textTheme.headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: primaryText,
                                                    height: isKhmer
                                                        ? 1.5
                                                        : null,
                                                    letterSpacing: isKhmer
                                                        ? 0
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                            )
                                            .animate()
                                            .fade(
                                              delay: 150.ms,
                                              duration: 400.ms,
                                            )
                                            .slideY(
                                              begin: 0.15,
                                              end: 0,
                                              curve: Curves.easeOutCubic,
                                            ),

                                        const SizedBox(height: 4),

                                        // Supporting Subtitle
                                        Text(
                                              context.tr(
                                                'auth.registerSubtitle',
                                              ),
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: secondaryText,
                                                    height: isKhmer
                                                        ? 1.5
                                                        : null,
                                                    letterSpacing: isKhmer
                                                        ? 0
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                            )
                                            .animate()
                                            .fade(
                                              delay: 200.ms,
                                              duration: 400.ms,
                                            )
                                            .slideY(
                                              begin: 0.15,
                                              end: 0,
                                              curve: Curves.easeOutCubic,
                                            ),

                                        const SizedBox(height: 14),

                                        // Error Notification Banner with shake animation
                                        if (_registerErrorMessage != null) ...[
                                          Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: dangerRed.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: dangerRed.withValues(
                                                      alpha: 0.35,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Icon(
                                                        AppIcons.error,
                                                        color: dangerRed,
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        _registerErrorMessage!,
                                                        style: textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: dangerRed,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                          const SizedBox(height: 14),
                                        ],

                                        // Input 1: Full name
                                        TextFormField(
                                          controller: _fullNameController,
                                          textInputAction: TextInputAction.next,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: primaryText,
                                          ),
                                          decoration: buildFieldDecoration(
                                            labelText: context.tr(
                                              'auth.fullName',
                                            ),
                                            hintText: 'e.g. David Kim',
                                            prefixIcon: AppIcons.profile,
                                          ),
                                          validator: (val) =>
                                              val == null || val.trim().isEmpty
                                              ? 'Please enter your full name'
                                              : null,
                                        ).animate().fade(delay: 200.ms),

                                        const SizedBox(height: 12),

                                        // Input 2: Username
                                        TextFormField(
                                          controller: _usernameController,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (_) {
                                            _usernameManuallyEdited = true;
                                          },
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: primaryText,
                                          ),
                                          decoration: buildFieldDecoration(
                                            labelText: context.tr(
                                              'auth.username',
                                            ),
                                            hintText: 'e.g. david_kim',
                                            helperText:
                                                'Letters, numbers, underscores (min 3)',
                                            prefixIcon:
                                                Icons.alternate_email_rounded,
                                          ),
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Please enter a username';
                                            }
                                            if (val.trim().length < 3) {
                                              return 'Username must be at least 3 characters';
                                            }
                                            if (!RegExp(
                                              r'^[a-zA-Z0-9_]+$',
                                            ).hasMatch(val.trim())) {
                                              return 'Only letters, numbers, and underscores allowed';
                                            }
                                            return null;
                                          },
                                        ).animate().fade(delay: 240.ms),

                                        const SizedBox(height: 12),

                                        // Input 3: Email address
                                        TextFormField(
                                          controller: _emailController,
                                          textInputAction: TextInputAction.next,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: primaryText,
                                          ),
                                          decoration: buildFieldDecoration(
                                            labelText: context.tr('auth.email'),
                                            hintText: 'e.g. david@foodgo.com',
                                            prefixIcon: AppIcons.mail,
                                          ),
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!val.contains('@') ||
                                                !val.contains('.')) {
                                              return 'Please enter a valid email address';
                                            }
                                            return null;
                                          },
                                        ).animate().fade(delay: 280.ms),

                                        const SizedBox(height: 12),

                                        // Input 4: Password
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _register(),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: primaryText,
                                          ),
                                          decoration: buildFieldDecoration(
                                            labelText: context.tr(
                                              'auth.password',
                                            ),
                                            hintText:
                                                'Enter at least 6 characters',
                                            prefixIcon: AppIcons.lock,
                                            suffixIcon: IconButton(
                                              tooltip: _obscurePassword
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              icon: Icon(
                                                _obscurePassword
                                                    ? AppIcons.passwordHidden
                                                    : AppIcons.passwordVisible,
                                                color: secondaryText,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                            ),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ).animate().fade(delay: 320.ms),

                                        const SizedBox(height: 14),

                                        // Role selector (Customer / Driver)
                                        _buildRoleSelector(
                                          isDark,
                                        ).animate().fade(delay: 360.ms),

                                        const SizedBox(height: 14),

                                        // Terms & Conditions Disclaimer
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0,
                                          ),
                                          child: RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: secondaryText,
                                                  ),
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      'By signing up you agree to our ',
                                                ),
                                                TextSpan(
                                                  text: 'Terms & Conditions',
                                                  style: TextStyle(
                                                    color: accentGreen,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: TextStyle(
                                                    color: accentGreen,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ).animate().fade(delay: 400.ms),

                                        const SizedBox(height: 18),

                                        // Primary 3D Tactile Extruded Button: Create Account
                                        SizedBox(
                                              height: 52,
                                              child: AnimatedPressable(
                                                pressedScale: 0.96,
                                                onTap: _isLoading
                                                    ? null
                                                    : _register,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                    gradient:
                                                        const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color(0xFF2FD66F),
                                                            GlassTheme
                                                                .primaryGreen,
                                                            Color(0xFF0F9B48),
                                                          ],
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      width: 1.2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color:
                                                            const Color(
                                                              0xFF0B642F,
                                                            ).withValues(
                                                              alpha: 0.8,
                                                            ),
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                        blurRadius: 0,
                                                      ),
                                                      BoxShadow(
                                                        color: GlassTheme
                                                            .primaryGreen
                                                            .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                        blurRadius: 18,
                                                        offset: const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: _isLoading
                                                        ? null
                                                        : _register,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      foregroundColor:
                                                          Colors.white,
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
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      2.2,
                                                                ),
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .person_add_rounded,
                                                                size: 18,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Flexible(
                                                                child: Text(
                                                                  context.tr(
                                                                    'auth.createAccount',
                                                                  ),
                                                                  style: textTheme.bodyLarge?.copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    height:
                                                                        isKhmer
                                                                        ? 1.5
                                                                        : null,
                                                                    letterSpacing:
                                                                        isKhmer
                                                                        ? 0
                                                                        : null,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .animate()
                                            .fade(delay: 440.ms)
                                            .scale()
                                            .shimmer(
                                              delay: 550.ms,
                                              duration: 1200.ms,
                                              color: Colors.white24,
                                            ),

                                        const SizedBox(height: 20),

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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              child: Text(
                                                context.tr(
                                                  'auth.orContinueWith',
                                                ),
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: secondaryText,
                                                      height: isKhmer
                                                          ? 1.5
                                                          : null,
                                                      letterSpacing: isKhmer
                                                          ? 0
                                                          : null,
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
                                        ).animate().fade(delay: 480.ms),

                                        const SizedBox(height: 14),

                                        // Phone OTP Alternative Button (matches LoginScreen)
                                        SizedBox(
                                          height: 46,
                                          width: double.infinity,
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
                                                    ? Colors.white.withValues(
                                                        alpha: 0.16,
                                                      )
                                                    : const Color(0xFFCBD5E1),
                                                width: 1.2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                  ),
                                            ),
                                            icon: Icon(
                                              AppIcons.phone,
                                              size: 18,
                                              color: accentGreen,
                                            ),
                                            label: Text(
                                              context.tr('auth.phoneOtpLogin'),
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: primaryText,
                                                    fontWeight: FontWeight.w600,
                                                    height: isKhmer
                                                        ? 1.5
                                                        : null,
                                                    letterSpacing: isKhmer
                                                        ? 0
                                                        : null,
                                                  ),
                                            ),
                                          ),
                                        ).animate().fade(delay: 520.ms),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Bottom Link: Already have an account? Sign in
                          Builder(
                            builder: (context) {
                              final brightness = Theme.of(context).brightness;
                              final textTheme = Theme.of(context).textTheme;
                              final secondaryText =
                                  AppTypography.secondaryTextColor(brightness);
                              final accentGreen = isDark
                                  ? GlassTheme.primaryGreenAccent
                                  : const Color(0xFF15803D);
                              final isKhmer =
                                  Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'km';
                              return Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${context.tr('auth.alreadyHaveAccount')} ',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: secondaryText,
                                      height: isKhmer ? 1.5 : null,
                                      letterSpacing: isKhmer ? 0 : null,
                                    ),
                                  ),
                                  AnimatedPressable(
                                    pressedScale: 0.94,
                                    onTap: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/login');
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        context.tr('auth.login'),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: accentGreen,
                                          fontWeight: FontWeight.bold,
                                          height: isKhmer ? 1.5 : null,
                                          letterSpacing: isKhmer ? 0 : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fade(delay: 560.ms);
                            },
                          ),

                          const SizedBox(height: 24),
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
