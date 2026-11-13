import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../shared/widgets/structured_summary_viewer.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();
  final _faqSearchController = TextEditingController();
  String _selectedCategory = 'Order Issue';
  String _faqSearchQuery = '';
  bool _isSubmitting = false;
  Map<String, String>? _lastSubmittedTicket;

  static const _categories = [
    'Order Issue',
    'Bakong KHQR / Payment',
    'Delivery Driver Feedback',
    'Restaurant Partner Inquiry',
    'Account & Security',
  ];

  static const _faqs = [
    {
      'q': 'How do I pay with Bakong KHQR (ABA, ACLEDA, Wing)?',
      'a':
          'Select Bakong KHQR at checkout to generate a dynamic EMVCo QR code with Tag 99 expiration metadata. Scan the QR code using ABA Mobile, ACLEDA Mobile, Wing Bank, or any Bakong-supported banking app in Cambodia, or tap "I Have Paid — Verify Now" once completed.',
    },
    {
      'q': 'What is the USD to KHR exchange rate on FoodGo?',
      'a':
          'FoodGo uses the standard marketplace exchange rate of 1.00 USD = 4,100 KHR (អត្រា ៤,១០០ រៀល) across all menu items, delivery fees, and KHQR payment receipts.',
    },
    {
      'q': 'Can I cancel my order after placing it?',
      'a':
          'Yes! You can cancel any order while its status is "Pending" or "Confirmed" before the restaurant begins preparing your food. Go to Orders → Cancel Order.',
    },
    {
      'q': 'How do I become a FoodGo Restaurant Partner or Driver?',
      'a':
          'Open Settings → Switch Active Role, or register a new account and select Restaurant Owner or Delivery Driver to access the dedicated portals.',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _contactController.dispose();
    _faqSearchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredFaqs {
    final q = _faqSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs.where((faq) {
      return (faq['q'] ?? '').toLowerCase().contains(q) ||
          (faq['a'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _copyContactValue(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $value'),
        backgroundColor: GlassTheme.primaryGreenDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitInquiry() async {
    final subject = StructuredSummaryViewer.sanitizePlainText(
      _subjectController.text,
    );
    final message = StructuredSummaryViewer.sanitizePlainText(
      _messageController.text,
    );
    final contact = StructuredSummaryViewer.sanitizePlainText(
      _contactController.text,
    );

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both a subject and a detailed message for your inquiry.',
          ),
          backgroundColor: GlassTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final now = DateTime.now();
    final ticketRef =
        'SUP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

    setState(() {
      _isSubmitting = false;
      _lastSubmittedTicket = {
        'ticketRef': ticketRef,
        'category': _selectedCategory,
        'subject': subject,
        'contact': contact.isEmpty ? 'Account Default (+855)' : contact,
        'message': message,
        'timestamp':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      };
      _subjectController.clear();
      _messageController.clear();
      _contactController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Support Ticket #$ticketRef created! Summary & TXT receipt generated below.',
        ),
        backgroundColor: GlassTheme.primaryGreenDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : GlassTheme.textInverseDark;
    final filteredFaqs = _filteredFaqs;

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Help & Support',
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryTextColor,
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(18),
                    borderRadius: GlassTheme.borderRadiusLarge,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: GlassTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FoodGo Customer Support Center',
                                style: AppTypography.titleSmall(
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '24/7 Phnom Penh Concierge • Bakong KHQR & Delivery Assistance',
                                style: AppTypography.bodySmall(
                                  color: GlassTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Contact Channels',
                    style: AppTypography.titleMedium(color: primaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  // Contact Channels (Tap to Copy)
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          isDark: isDark,
                          icon: Icons.headset_mic_rounded,
                          title: 'Phone Hotline',
                          subtitle: '+855 23 999 888',
                          onTap: () => _copyContactValue(
                            'Support Hotline',
                            '+855 23 999 888',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactCard(
                          isDark: isDark,
                          icon: Icons.telegram_rounded,
                          title: 'Telegram Support',
                          subtitle: '@foodgo_kh_support',
                          onTap: () => _copyContactValue(
                            'Telegram Handle',
                            '@foodgo_kh_support',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactCard(
                          isDark: isDark,
                          icon: Icons.email_outlined,
                          title: 'Email Desk',
                          subtitle: 'support@foodgo.kh',
                          onTap: () => _copyContactValue(
                            'Support Email',
                            'support@foodgo.kh',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // FAQ Section Header + Search Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frequently Asked Questions',
                        style: AppTypography.titleMedium(
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        '${filteredFaqs.length} of ${_faqs.length} topics',
                        style: AppTypography.caption(
                          color: GlassTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _faqSearchController,
                    onChanged: (v) => setState(() => _faqSearchQuery = v),
                    style: AppTypography.bodyMedium(color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText:
                          'Search FAQs (e.g., Bakong KHQR, KHR rate, cancel)...',
                      hintStyle: AppTypography.bodySmall(
                        color: GlassTheme.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: GlassTheme.primaryGreen,
                      ),
                      suffixIcon: _faqSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _faqSearchController.clear();
                                setState(() => _faqSearchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (filteredFaqs.isEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: GlassTheme.borderRadiusMedium,
                      child: Text(
                        'No FAQ topics matched "$_faqSearchQuery". Try another keyword or submit a support ticket below.',
                        style: AppTypography.bodySmall(
                          color: GlassTheme.textMuted,
                        ),
                      ),
                    )
                  else
                    ...filteredFaqs.map(
                      (faq) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassContainer(
                          borderRadius: GlassTheme.borderRadiusMedium,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              iconColor: GlassTheme.primaryGreen,
                              collapsedIconColor: GlassTheme.textMuted,
                              title: Text(
                                faq['q']!,
                                style: AppTypography.titleSmall(
                                  color: primaryTextColor,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SelectableText(
                                    faq['a']!,
                                    style: AppTypography.bodySmall(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF4B5563),
                                    ).copyWith(height: 1.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Contact Form
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: GlassTheme.borderRadiusLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send an Inquiry',
                          style: AppTypography.titleMedium(
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Need help with an order or Bakong KHQR payment? Send us a message and receive an instant copyable ticket summary.',
                          style: AppTypography.bodySmall(
                            color: GlassTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          dropdownColor: isDark
                              ? GlassTheme.surfaceDark
                              : Colors.white,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedCategory = v);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText:
                                'Callback Phone (+855) or Email (Optional)',
                            prefixIcon: Icon(Icons.contact_phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject (e.g., Order #1024 KHQR check)',
                            prefixIcon: Icon(Icons.subject_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Detailed Message',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: GlassButton(
                            text: _isSubmitting
                                ? 'Submitting Inquiry...'
                                : 'Submit Inquiry',
                            icon: Icons.send_rounded,
                            isLoading: _isSubmitting,
                            onPressed: _submitInquiry,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Generated Support Ticket Summary & TXT Viewer
                  if (_lastSubmittedTicket != null) ...[
                    const SizedBox(height: 24),
                    StructuredSummaryViewer(
                      title:
                          'Support Ticket Summary (${_lastSubmittedTicket!['ticketRef']})',
                      subtitle:
                          'Submitted at ${_lastSubmittedTicket!['timestamp']} • Status: RECEIVED',
                      badgeText: 'TICKET LOGGED',
                      enableSearch: false,
                      keyPoints: [
                        'Ticket Reference ${_lastSubmittedTicket!['ticketRef']} has been queued for Phnom Penh Support Concierge review.',
                        'Average response time is under 15 minutes via phone or Telegram.',
                      ],
                      sections: [
                        SummarySection(
                          title: 'Inquiry Metadata & Message Content',
                          icon: Icons.confirmation_number_outlined,
                          metadata: {
                            'Ticket Reference':
                                _lastSubmittedTicket!['ticketRef']!,
                            'Category': _lastSubmittedTicket!['category']!,
                            'Contact': _lastSubmittedTicket!['contact']!,
                            'Submitted At': _lastSubmittedTicket!['timestamp']!,
                            'Subject': _lastSubmittedTicket!['subject']!,
                          },
                          body: _lastSubmittedTicket!['message'],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primaryTextColor = isDark ? Colors.white : GlassTheme.textInverseDark;
    return InkWell(
      onTap: onTap,
      borderRadius: GlassTheme.borderRadiusMedium,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: GlassTheme.borderRadiusMedium,
        child: Column(
          children: [
            Icon(icon, color: GlassTheme.primaryGreen, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.labelMedium(
                color: primaryTextColor,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.caption(color: GlassTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to copy',
              style: AppTypography.labelSmall(
                color: GlassTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
