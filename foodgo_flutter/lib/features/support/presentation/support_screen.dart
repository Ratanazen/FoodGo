import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitted = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I track my delivery in real time?',
      'answer':
          'Once a driver accepts your order, you can view live delivery progress on our map, including driver vehicle details, current distance, and estimated arrival time. You can also track deliveries publicly using your Order ID at /track.',
    },
    {
      'question': 'What payment options are accepted across Cambodia?',
      'answer':
          'FoodGo supports Bakong KHQR (usable with ABA Mobile, ACLEDA mobile, Wing, Sathapana, and 30+ Cambodian financial institutions) as well as Cash on Delivery (COD).',
    },
    {
      'question': 'How does Driver SMS verification work?',
      'answer':
          'To ensure food safety and prevent fraud, all drivers must verify their Cambodian mobile number (+855 Smart, Cellcard, or Metfone) via a 6-digit SMS OTP before accepting delivery jobs.',
    },
    {
      'question': 'How does delivery handover verification work?',
      'answer':
          'Upon arriving at your delivery location, the driver will ask for your 6-digit delivery code or scan your delivery confirmation QR code to ensure accurate handover.',
    },
    {
      'question': 'Can I cancel an order after placing it?',
      'answer':
          'Orders can only be canceled while in "Pending" status before the restaurant begins preparation. Once food preparation has begun, cancellations must be handled through customer support.',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitInquiry() {
    if (_nameController.text.trim().isEmpty ||
        _contactController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all inquiry fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });

    _nameController.clear();
    _contactController.clear();
    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your inquiry has been received. Our team will contact you shortly.',
        ),
        backgroundColor: GlassTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : GlassTheme.textDark,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            AppIcons.back,
            color: isDark ? Colors.white : GlassTheme.textDark,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ResponsiveWebContainer(
          maxWidth: 1000,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FoodGo Customer Support Center',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : GlassTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assisting customers, drivers, and restaurant partners across Phnom Penh and provincial hubs.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : GlassTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Fast Contact Channels
                Text(
                  'Contact Channels',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : GlassTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactCard(
                        icon: AppIcons.phone,
                        title: 'Phone Hotline',
                        detail: '+855 23 999 888',
                        subtitle: 'Mon-Sun, 7:00 AM - 11:00 PM',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactCard(
                        icon: AppIcons.send,
                        title: 'Telegram Support',
                        detail: '@foodgo_kh_support',
                        subtitle: 'Instant messaging support',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactCard(
                        icon: AppIcons.email,
                        title: 'Email Inquiries',
                        detail: 'support@foodgo.kh',
                        subtitle: 'Replies within 2 hours',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactCard(
                        icon: AppIcons.locationOutline,
                        title: 'Head Office',
                        detail: 'BKK1, Phnom Penh',
                        subtitle: '#240 St 63, Boeung Keng Kang 1',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // FAQ Section
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : GlassTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ..._faqs.map(
                  (faq) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: ExpansionTile(
                        iconColor: GlassTheme.primaryGreen,
                        collapsedIconColor: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                        title: Text(
                          faq['question']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : GlassTheme.textDark,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Text(
                              faq['answer']!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Inquiry Form
                Text(
                  'Send an Inquiry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : GlassTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: isDark
                            ? GlassTheme.dropdownDark
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : GlassTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Inquiry Category',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : GlassTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'General',
                            child: Text('General Inquiry'),
                          ),
                          DropdownMenuItem(
                            value: 'Order',
                            child: Text('Order & Delivery Status'),
                          ),
                          DropdownMenuItem(
                            value: 'Payment',
                            child: Text('Payment & Bakong KHQR'),
                          ),
                          DropdownMenuItem(
                            value: 'Driver',
                            child: Text('Driver Partner Inquiry'),
                          ),
                          DropdownMenuItem(
                            value: 'Restaurant',
                            child: Text('Restaurant Partner Inquiry'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(
                          color: isDark ? Colors.white : GlassTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : GlassTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contactController,
                        style: TextStyle(
                          color: isDark ? Colors.white : GlassTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Phone (+855...) or Email',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : GlassTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        style: TextStyle(
                          color: isDark ? Colors.white : GlassTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'How can we help you?',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : GlassTheme.textMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitInquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Submit Inquiry',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_isSubmitted) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Ticket logged in system. An agent will respond to your contact info.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String detail,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: GlassTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : GlassTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GlassTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : GlassTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
