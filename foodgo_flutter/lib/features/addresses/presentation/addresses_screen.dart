import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundLight,
      appBar: GlassAppBar(
        title: 'Addresses',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAddressCard('Home', '123 Glass Street, Transparency City, 10101', true),
          const SizedBox(height: 16),
          _buildAddressCard('Work', '456 Corporate Ave, Transparency City, 10102', false),
          const SizedBox(height: 32),
          GlassButton(
            text: 'Add New Address',
            icon: Icons.add,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String title, String subtitle, bool isDefault) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(title == 'Home' ? Icons.home : Icons.work, color: GlassTheme.primaryGreen, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Default', style: TextStyle(color: GlassTheme.primaryGreen, fontSize: 12)),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: GlassTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
