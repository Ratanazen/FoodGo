import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../shared/widgets/structured_summary_viewer.dart';
import '../../../widgets/glass/glass_widgets.dart';

class LegalScreen extends StatefulWidget {
  final int initialTab;
  const LegalScreen({super.key, int initialTab = 0, int? initialTabIndex})
    : initialTab = initialTabIndex ?? initialTab;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final fgColor = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Legal & Compliance',
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: fgColor),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: accentGreen,
            labelColor: accentGreen,
            unselectedLabelColor: secondaryText,
            labelStyle: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: textTheme.labelLarge,
            tabs: const [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildTermsTab(), _buildPrivacyTab()],
        ),
      ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: StructuredSummaryViewer(
        title: 'FoodGo Terms of Service',
        subtitle:
            'Effective Date: January 1, 2026 • Phnom Penh, Kingdom of Cambodia (គោលការណ៍ប្រើប្រាស់សេវាកម្ម)',
        badgeText: 'VERIFIED POLICY',
        keyPoints: const [
          'Marketplace connecting customers, partner restaurants, and independent couriers across Cambodia.',
          'Supports NBC Bakong KHQR (USD & KHR at 4,100 rate), Visa/Mastercard, FoodGo Wallet, and Cash on Delivery.',
          'Orders can be cancelled before kitchen preparation begins; prepaid cancellations are automatically refunded.',
          'Governed by the Law on Electronic Commerce of the Kingdom of Cambodia.',
        ],
        sections: const [
          SummarySection(
            title: '1. Platform Overview & Scope',
            icon: Icons.storefront_outlined,
            metadata: {
              'Jurisdiction': 'Kingdom of Cambodia',
              'Service Area':
                  'Phnom Penh, Siem Reap, Battambang, Sihanoukville',
              'Exchange Rate':
                  '1.00 USD = 4,100 KHR (អត្រាប្តូរប្រាក់ផ្លូវការ)',
            },
            body:
                'FoodGo operates an online food ordering, restaurant partner management, and real-time courier dispatch platform in the Kingdom of Cambodia. By accessing or placing orders through FoodGo, you agree to be bound by these Terms of Service.',
          ),
          SummarySection(
            title: '2. Account Registration & Phone Verification',
            icon: Icons.verified_user_outlined,
            body:
                'Users must provide accurate contact information, including a valid Cambodia mobile number (+855) or verified email address. You are responsible for safeguarding your account credentials and OTP verification codes.',
            bulletPoints: [
              'One primary account per customer mobile number (+855).',
              'Role-based access for Customer, Restaurant Partner, Driver Courier, and Platform Admin.',
              'Immediate suspension for fraudulent orders or unauthorized API usage.',
            ],
          ),
          SummarySection(
            title: '3. Orders, Pricing & Bakong KHQR Payments',
            icon: Icons.qr_code_scanner_rounded,
            body:
                'Menu prices are displayed in United States Dollars (USD) with automatic Khmer Riel (KHR) equivalents calculated at the standard platform rate of 1 USD = 4,100 KHR. Supported payment methods include Bakong KHQR (ABA PAY, ACLEDA Mobile, Wing, Sathapana, Canadia, and all NBC Bakong member banks), Credit/Debit Cards, FoodGo Wallet, and Cash on Delivery (COD).',
            bulletPoints: [
              'Dynamic KHQR codes include EMVCo Tag 99 creation/expiration timestamps for bank compliance.',
              'Orders cannot be cancelled without charge once the partner restaurant has begun preparing the food.',
              'Missing or damaged items reported within 2 hours qualify for a full FoodGo Wallet credit or bank refund.',
            ],
          ),
          SummarySection(
            title: '4. Delivery & Courier Hand-Off Verification',
            icon: Icons.delivery_dining_outlined,
            body:
                'Estimated delivery times are calculated dynamically based on kitchen preparation load, traffic conditions, and distance. Customers may verify hand-off using the encrypted Delivery Confirmation QR modal.',
          ),
          SummarySection(
            title: '5. Governing Law & Dispute Resolution',
            icon: Icons.gavel_rounded,
            body:
                'These Terms are governed by the laws of the Kingdom of Cambodia, including the Law on Electronic Commerce and the Law on Consumer Protection. Any disputes shall be resolved amicably through FoodGo Support (+855 23 999 888) or the competent courts of Phnom Penh.',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: StructuredSummaryViewer(
        title: 'FoodGo Privacy Policy',
        subtitle:
            'Effective Date: January 1, 2026 • NBC & E-Commerce Compliance (គោលការណ៍ឯកជនភាព)',
        badgeText: 'PRIVACY PROTECTED',
        keyPoints: const [
          'We never sell your personal data, phone number, or location history to third-party advertisers.',
          'Payment card numbers and Bakong KHQR credentials are never stored in plain text on FoodGo servers.',
          'GPS coordinates are used strictly for active delivery routing and restaurant distance calculation.',
          'You can request data export or permanent account deletion at any time from Settings.',
        ],
        sections: const [
          SummarySection(
            title: '1. Information We Collect',
            icon: Icons.folder_shared_outlined,
            metadata: {
              'Identity Data': 'Name, Username, +855 Phone, Email',
              'Delivery Data': 'Saved Street Address, GPS Lat/Lng',
              'Transaction Data': 'Order IDs, KHQR MD5 Hashes, Payment Status',
            },
            body:
                'We collect only the information required to process your food orders, verify Bakong KHQR settlements, and coordinate courier delivery to your doorstep.',
          ),
          SummarySection(
            title: '2. How We Use Your Information',
            icon: Icons.analytics_outlined,
            body:
                'Your data is used to transmit order tickets to the selected restaurant, share drop-off instructions with your assigned delivery driver, verify payment status via the National Bank of Cambodia (NBC) Bakong Open API, and send real-time order status notifications.',
            bulletPoints: [
              'Driver couriers can view your phone number and delivery coordinates only during an active delivery.',
              'Order history is retained so you can download TXT/receipt summaries and reorder favorite meals.',
            ],
          ),
          SummarySection(
            title: '3. Payment & Financial Security',
            icon: Icons.security_rounded,
            body:
                'All KHQR transactions are cryptographically signed with EMVCo CRC-16/CCITT-FALSE checksums and verified server-to-server using MD5 transaction tracking. JWT authentication tokens are stored in encrypted platform storage.',
          ),
          SummarySection(
            title: '4. Your Rights, Export & Account Deletion',
            icon: Icons.manage_accounts_outlined,
            body:
                'You may inspect, update, or permanently delete your account and associated addresses directly inside the FoodGo Settings screen or by contacting privacy@foodgo.kh.',
          ),
        ],
      ),
    );
  }
}
