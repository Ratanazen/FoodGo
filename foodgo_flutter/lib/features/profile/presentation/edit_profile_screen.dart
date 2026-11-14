import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/responsive_layout.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarUrlController;

  String? _pickedImagePath;
  String? _selectedAvatarUrl;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  // Preset avatar choices
  static const List<Map<String, String>> _presetAvatars = [
    {
      'title': 'Gourmet Chef',
      'url':
          'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&w=256&q=80',
    },
    {
      'title': 'Burger Lover',
      'url':
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=256&q=80',
    },
    {
      'title': 'Food Explorer',
      'url':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=256&q=80',
    },
    {
      'title': 'Speedy Rider',
      'url':
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=256&q=80',
    },
    {
      'title': 'Coffee Artisan',
      'url':
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=256&q=80',
    },
    {
      'title': 'Sweet Tooth',
      'url':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _firstNameController = TextEditingController(
      text: user?['first_name'] ?? '',
    );
    _lastNameController = TextEditingController(text: user?['last_name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');

    _selectedAvatarUrl = user?['avatar_url'] ?? user?['avatar'];
    _avatarUrlController = TextEditingController(
      text: _selectedAvatarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImagePath = image.path;
          _selectedAvatarUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access ${source == ImageSource.camera ? "camera" : "gallery"}: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (sheetInnerCtx) {
                  final theme = Theme.of(sheetInnerCtx);
                  final textTheme = theme.textTheme;
                  final brightness = theme.brightness;
                  final isDark = brightness == Brightness.dark;
                  final primaryText = AppTypography.primaryTextColor(
                    brightness,
                  );
                  final secondaryText = AppTypography.secondaryTextColor(
                    brightness,
                  );
                  final greenAccent = isDark
                      ? GlassTheme.primaryGreenAccent
                      : const Color(0xFF15803D);
                  final blueAccent = isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF1D4ED8);
                  final amberAccent = isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFB45309);
                  final purpleAccent = isDark
                      ? const Color(0xFFC084FC)
                      : const Color(0xFF7E22CE);
                  final redAccent = isDark
                      ? const Color(0xFFF87171)
                      : const Color(0xFFB91C1C);

                  Widget buildOption({
                    required IconData icon,
                    required Color accentColor,
                    required String title,
                    String? subtitle,
                    Color? titleColor,
                    required VoidCallback onTap,
                  }) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accentColor),
                      ),
                      title: Text(
                        title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: titleColor ?? primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: subtitle == null
                          ? null
                          : Text(
                              subtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                      onTap: onTap,
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Change Profile Photo',
                        style: textTheme.titleLarge?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      buildOption(
                        icon: AppIcons.camera,
                        accentColor: greenAccent,
                        title: 'Take Photo with Camera',
                        subtitle: 'Capture a new profile picture',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      const SizedBox(height: 8),
                      buildOption(
                        icon: AppIcons.gallery,
                        accentColor: blueAccent,
                        title: 'Choose from Gallery',
                        subtitle: 'Select an image from device library',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      const SizedBox(height: 8),
                      buildOption(
                        icon: AppIcons.profile,
                        accentColor: amberAccent,
                        title: 'Pick FoodGo Avatar Preset',
                        subtitle: 'Choose from curated food enthusiast icons',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showPresetAvatarDialog();
                        },
                      ),
                      const SizedBox(height: 8),
                      buildOption(
                        icon: AppIcons.link,
                        accentColor: purpleAccent,
                        title: 'Enter Image URL',
                        subtitle: 'Paste direct link from web (Unsplash, etc.)',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showUrlInputDialog();
                        },
                      ),
                      if (_selectedAvatarUrl != null ||
                          _pickedImagePath != null) ...[
                        const SizedBox(height: 8),
                        buildOption(
                          icon: AppIcons.delete,
                          accentColor: redAccent,
                          title: 'Remove Photo',
                          titleColor: redAccent,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _pickedImagePath = null;
                              _selectedAvatarUrl = null;
                              _avatarUrlController.clear();
                            });
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPresetAvatarDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final textTheme = theme.textTheme;
        final brightness = theme.brightness;
        final isDark = brightness == Brightness.dark;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final activeBorder = isDark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Choose Avatar',
                          style: textTheme.titleLarge?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          AppIcons.close,
                          color: secondaryText,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: _presetAvatars.length,
                    itemBuilder: (context, index) {
                      final item = _presetAvatars[index];
                      final isSelected = _selectedAvatarUrl == item['url'];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedAvatarUrl = item['url'];
                            _pickedImagePath = null;
                            _avatarUrlController.text = item['url']!;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeBorder.withValues(
                                    alpha: isDark ? 0.2 : 0.12,
                                  )
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? activeBorder
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.black.withValues(alpha: 0.08)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(item['url']!),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['title']!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: isDark ? Colors.white70 : primaryText,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUrlInputDialog() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _UrlInputDialog(initialUrl: _selectedAvatarUrl ?? ''),
    );
    if (!mounted || text == null || text.isEmpty) return;
    setState(() {
      _selectedAvatarUrl = text;
      _pickedImagePath = null;
      _avatarUrlController.text = text;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final userProvider = context.read<UserProvider>();

    final success = await userProvider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: _selectedAvatarUrl,
      avatarFilePath: _pickedImagePath,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userProvider.lastError ??
                'Failed to update profile. Please check your inputs.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAvatarWidget(String username) {
    if (_pickedImagePath != null && !kIsWeb) {
      return CircleAvatar(
        radius: 54,
        backgroundColor: Colors.black26,
        backgroundImage: FileImage(File(_pickedImagePath!)),
      );
    }

    if (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _selectedAvatarUrl!,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: 54, backgroundImage: imageProvider),
        placeholder: (context, url) => CircleAvatar(
          radius: 54,
          backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
          child: const CircularProgressIndicator(
            color: GlassTheme.primaryGreen,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (errCtx, url, error) {
          final errTheme = Theme.of(errCtx);
          final accentGreen = errTheme.brightness == Brightness.dark
              ? GlassTheme.primaryGreenAccent
              : const Color(0xFF15803D);
          return CircleAvatar(
            radius: 54,
            backgroundColor: accentGreen.withValues(alpha: 0.16),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: errTheme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentGreen,
              ),
            ),
          );
        },
      );
    }

    return Builder(
      builder: (avatarCtx) {
        final avatarTheme = Theme.of(avatarCtx);
        final accentGreen = avatarTheme.brightness == Brightness.dark
            ? GlassTheme.primaryGreenAccent
            : const Color(0xFF15803D);
        return CircleAvatar(
          radius: 54,
          backgroundColor: accentGreen.withValues(alpha: 0.16),
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : 'U',
            style: avatarTheme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentGreen,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final username = user?['username'] ?? 'User';
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Edit Profile',
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveWebContainer(
        maxWidth: 680,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Stack with Camera Trigger
                Center(
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentGreen,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentGreen.withValues(alpha: 0.28),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _buildAvatarWidget(username),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GlassContainer(
                                padding: const EdgeInsets.all(8),
                                borderRadius: BorderRadius.circular(20),
                                customColor: colorScheme.primary,
                                child: Icon(
                                  AppIcons.camera,
                                  color: colorScheme.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: Icon(AppIcons.edit, size: 14, color: accentGreen),
                    label: Text(
                      'Change Profile Photo',
                      style: textTheme.labelLarge?.copyWith(
                        color: accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 50.ms, duration: 350.ms),
                Center(
                  child: Text(
                    '@$username',
                    style: textTheme.bodyMedium?.copyWith(color: secondaryText),
                  ),
                ),
                const SizedBox(height: 28),

                // First Name Field
                _buildField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: AppIcons.profile,
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 16),

                // Last Name Field
                _buildField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: AppIcons.badge,
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 16),

                // Email Field
                _buildField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: AppIcons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val != null &&
                            val.isNotEmpty &&
                            !val.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 16),

                // Phone Field with Country Prefix Helper
                _buildField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: AppIcons.phone,
                      keyboardType: TextInputType.phone,
                      helperText: 'e.g. +855 12 345 678 or 012 345 678',
                      validator: (val) {
                        if (val != null && val.isNotEmpty && val.length < 6) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                      height: 52,
                      child: GlassButton(
                        text: _isSaving ? 'Saving Changes...' : 'Save Profile',
                        icon: _isSaving ? AppIcons.loading : AppIcons.success,
                        onPressed: _isSaving ? () {} : _handleSave,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accent = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: textTheme.bodyLarge?.copyWith(color: primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(color: secondaryText),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: textTheme.labelSmall?.copyWith(color: secondaryText),
        prefixIcon: Icon(icon, color: accent),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent),
        ),
      ),
    );
  }
}

class _UrlInputDialog extends StatefulWidget {
  final String initialUrl;

  const _UrlInputDialog({required this.initialUrl});

  @override
  State<_UrlInputDialog> createState() => _UrlInputDialogState();
}

class _UrlInputDialogState extends State<_UrlInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accent = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste Image Link',
                style: textTheme.titleLarge?.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste a direct URL to an image file (JPG, PNG, WebP).',
                style: textTheme.bodySmall?.copyWith(color: secondaryText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                style: textTheme.bodyMedium?.copyWith(color: primaryText),
                decoration: InputDecoration(
                  hintText: 'https://images.unsplash.com/...',
                  hintStyle: textTheme.bodySmall?.copyWith(
                    color: secondaryText.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(AppIcons.link, color: accent),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: textTheme.labelLarge?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text.trim()),
                    child: Text(
                      'Set Photo',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
