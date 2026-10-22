import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';

class LegalScreen extends StatefulWidget {
  final int initialTabIndex;

  const LegalScreen({super.key, this.initialTabIndex = 0});

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
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Legal & Compliance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          indicatorColor: GlassTheme.primaryGreen,
          labelColor: GlassTheme.primaryGreenAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveWebContainer(
          maxWidth: 900,
          child: TabBarView(
            controller: _tabController,
            children: [_buildTermsContent(), _buildPrivacyContent()],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FoodGo Terms of Service',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: October 2026 • Kingdom of Cambodia',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const Divider(height: 32, color: Colors.white24),
            _buildSection(
              title: '1. Introduction and Scope',
              body:
                  'Welcome to FoodGo. These Terms of Service govern your access to and use of the FoodGo platform, website, mobile application, and delivery ordering ecosystem within the Kingdom of Cambodia. By registering an account, placing an order, or acting as a delivery partner, you agree to comply with these terms.',
            ),
            _buildSection(
              title: '2. User Accounts and Phone Verification',
              body:
                  'To use FoodGo ordering or delivery services, you must provide a valid Cambodian phone number (+855 Smart, Cellcard, or Metfone). Each mobile number undergoes real-time SMS OTP verification. You are responsible for maintaining the confidentiality of your credentials and all activities occurring under your account.',
            ),
            _buildSection(
              title: '3. Ordering, Pricing, and Currency Exchange',
              body:
                  'Food items, restaurant menus, and delivery fees are displayed in both United States Dollars (USD) and Cambodian Riel (KHR) converted per official National Bank of Cambodia (NBC) market exchange rates. Prices include applicable local taxes. Minimum order fees and peak delivery surcharges may apply during extreme weather or high traffic conditions.',
            ),
            _buildSection(
              title: '4. Payments and Bakong KHQR',
              body:
                  'FoodGo supports Cash on Delivery (COD) and real-time cashless settlement via Bakong KHQR standards. Payments processed through ABA Pay, ACLEDA, and partner banks are authenticated instantaneously via digital signature verification. Orders paid via KHQR are held in escrow until the order is accepted or confirmed.',
            ),
            _buildSection(
              title: '5. Delivery Workflow and Handover Protocol',
              body:
                  'Delivery partners must maintain active Cambodian driver verification, valid vehicle registration, and mobile device GPS tracking. Upon delivery arrival, the handover is authenticated either through customer presentation of a unique 6-digit delivery PIN or scanning of the dynamic handover QR code.',
            ),
            _buildSection(
              title: '6. Cancellations and Refunds',
              body:
                  'Orders can be canceled free of charge before restaurant food preparation starts. Once preparation has commenced, food costs cannot be refunded. In cases of damaged, spilled, or incorrect food items, claims submitted within 2 hours of delivery will be investigated for immediate credit or refund.',
            ),
            _buildSection(
              title: '7. Governing Law and Dispute Resolution',
              body:
                  'These Terms are governed by the laws of the Kingdom of Cambodia, including the E-Commerce Law and Consumer Protection Law. Any disputes arising shall be subject to the exclusive jurisdiction of the competent courts in Phnom Penh, Cambodia.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FoodGo Privacy Policy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: October 2026 • Data Protection Standard',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const Divider(height: 32, color: Colors.white24),
            _buildSection(
              title: '1. Information We Collect',
              body:
                  'We collect necessary information to provide food delivery services: contact details (name, email, verified Cambodian phone number), delivery addresses with GPS coordinates, order history, and device telemetry required for reliable routing.',
            ),
            _buildSection(
              title: '2. SMS OTP and Cryptographic Security',
              body:
                  'Your phone number is normalized to E.164 standards (+855...). SMS verification codes are transmitted over TLS to licensed Cambodian telecommunication gateways. FoodGo hashes all verification tokens using salted HMAC-SHA256 algorithms and never stores plaintext OTPs in databases or logs.',
            ),
            _buildSection(
              title: '3. Real-Time Geolocation Tracking',
              body:
                  'When an order is in transit, driver and customer coordinates are transmitted securely over WebSockets strictly for live map ETA estimation and delivery completion verification. Location tracking terminates automatically upon order delivery confirmation.',
            ),
            _buildSection(
              title: '4. Payment Data Confidentiality',
              body:
                  'FoodGo does not store raw credit card numbers or bank PINs. All electronic payments are processed through National Bank of Cambodia Bakong KHQR rails and authorized banking gateways using cryptographic transaction signatures.',
            ),
            _buildSection(
              title: '5. Data Retention and Account Deletion',
              body:
                  'Users have the right to request deletion of their account and associated personal data at any time via Profile > Settings > Delete Account. Financial and tax records are retained in compliance with Cambodian statutory requirements.',
            ),
            _buildSection(
              title: '6. Contact Privacy Officer',
              body:
                  'For inquiries regarding data privacy or to exercise your rights, contact our Data Protection Officer at privacy@foodgo.kh or write to FoodGo Cambodia, #240 St 63, BKK1, Phnom Penh.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: GlassTheme.primaryGreenAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
