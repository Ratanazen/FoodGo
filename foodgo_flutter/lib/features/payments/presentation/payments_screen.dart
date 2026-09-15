import 'package:flutter/material.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: GlassAppBar(
        title: 'Payment Methods',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPaymentCard('Visa •••• 4242', Icons.credit_card, true),
          const SizedBox(height: 16),
          _buildPaymentCard('PayPal', Icons.account_balance_wallet, false),
          const SizedBox(height: 16),
          _buildPaymentCard('Apple Pay', Icons.phone_iphone, false),
          const SizedBox(height: 32),
          GlassButton(
            text: 'Add Payment Method',
            icon: Icons.add,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(String title, IconData icon, bool isDefault) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: GlassTheme.primaryGreen, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          if (isDefault)
            const Icon(Icons.check_circle, color: GlassTheme.primaryGreen)
          else
            Icon(Icons.radio_button_unchecked, color: GlassTheme.textMuted),
        ],
      ),
    );
  }
}
