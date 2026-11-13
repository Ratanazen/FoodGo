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
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  color: isDark ? Colors.white : GlassTheme.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GlassTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    AppIcons.camera,
                    color: GlassTheme.primaryGreen,
                  ),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: TextStyle(
                    color: isDark ? Colors.white : GlassTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Capture a new profile picture',
                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GlassTheme.googleBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    AppIcons.gallery,
                    color: GlassTheme.googleBlue,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: isDark ? Colors.white : GlassTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Select an image from device library',
                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(AppIcons.profile, color: Colors.amber),
                ),
                title: Text(
                  'Pick FoodGo Avatar Preset',
                  style: TextStyle(
                    color: isDark ? Colors.white : GlassTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Choose from curated food enthusiast icons',
                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showPresetAvatarDialog();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(AppIcons.link, color: Colors.purpleAccent),
                ),
                title: Text(
                  'Enter Image URL',
                  style: TextStyle(
                    color: isDark ? Colors.white : GlassTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Paste direct link from web (Unsplash, etc.)',
                  style: TextStyle(color: GlassTheme.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showUrlInputDialog();
                },
              ),
              if (_selectedAvatarUrl != null || _pickedImagePath != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(AppIcons.delete, color: Colors.redAccent),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
          ),
        );
      },
    );
  }

  void _showPresetAvatarDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Avatar',
                      style: TextStyle(
                        color: isDark ? Colors.white : GlassTheme.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        AppIcons.close,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
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
                              ? GlassTheme.primaryGreen.withValues(
                                  alpha: isDark ? 0.2 : 0.12,
                                )
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? GlassTheme.primaryGreen
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
                              radius: 28,
                              backgroundImage: NetworkImage(item['url']!),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['title']!,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        errorWidget: (context, url, error) => CircleAvatar(
          radius: 54,
          backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: GlassTheme.primaryGreen,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 54,
      backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: GlassTheme.primaryGreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final username = user?['username'] ?? 'User';

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
                                  color: GlassTheme.primaryGreen,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: GlassTheme.primaryGreen.withValues(
                                      alpha: 0.3,
                                    ),
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
                                customColor: GlassTheme.primaryGreen,
                                child: const Icon(
                                  AppIcons.camera,
                                  color: Colors.black87,
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
                    icon: const Icon(
                      AppIcons.edit,
                      size: 14,
                      color: GlassTheme.primaryGreen,
                    ),
                    label: const Text(
                      'Change Profile Photo',
                      style: TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 50.ms, duration: 350.ms),
                Center(
                  child: Text(
                    '@$username',
                    style: const TextStyle(
                      color: GlassTheme.textMuted,
                      fontSize: 14,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : GlassTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? GlassTheme.textMuted : const Color(0xFF64748B),
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          fontSize: 11,
        ),
        prefixIcon: Icon(icon, color: GlassTheme.primaryGreen),
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
          borderSide: BorderSide(color: GlassTheme.primaryGreen),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste Image Link',
              style: TextStyle(
                color: isDark ? Colors.white : GlassTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a direct URL to an image file (JPG, PNG, WebP).',
              style: TextStyle(
                color: isDark ? GlassTheme.textMuted : const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: TextStyle(
                color: isDark ? Colors.white : GlassTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'https://images.unsplash.com/...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  AppIcons.link,
                  color: isDark
                      ? GlassTheme.primaryGreen
                      : GlassTheme.primaryGreenDark,
                ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  child: const Text(
                    'Set Photo',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
