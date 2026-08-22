import 'package:flutter/material.dart';
import '../../../../widgets/glass/glass_widgets.dart';
import '../../../../widgets/glass_container.dart';
import '../../../../widgets/glass/glass_widgets_extended.dart';
import '../../../../core/theme/glass_theme.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Edit Profile',
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 50, color: GlassTheme.primaryGreen),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(20),
                      customColor: GlassTheme.primaryGreen,
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const GlassTextField(hintText: 'Full Name', prefixIcon: Icons.person),
            const SizedBox(height: 16),
            const GlassTextField(hintText: 'Email Address', prefixIcon: Icons.email),
            const SizedBox(height: 16),
            const GlassTextField(hintText: 'Phone Number', prefixIcon: Icons.phone),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                text: 'Save Changes',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
