import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _wallet;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('wallets/my_wallet/');
      if (!mounted) return;
      setState(() {
        _wallet = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _topUp() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;
    
    // Simulate Stripe payment gateway loading
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      await _api.post('wallets/top_up/', {'amount': amountStr});
      _amountController.clear();
      _fetchWallet();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Top up successful via Stripe!'),
        backgroundColor: GlassTheme.primaryGreen,
      ));
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Wallet & Payments',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: GlassTheme.backgroundDark,
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: _isLoading && _wallet == null
              ? const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: GlassTheme.borderRadiusSmall,
                        child: Column(
                          children: [
                            const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('\$${_wallet?['balance'] ?? '0.00'}', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: 'Amount',
                                      hintStyle: TextStyle(color: GlassTheme.textMuted),
                                      prefixIcon: const Icon(Icons.attach_money, color: GlassTheme.primaryGreen),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GlassButton(
                                    text: 'Top Up',
                                    icon: Icons.add_card,
                                    onPressed: _isLoading ? () {} : _topUp,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Transaction History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _wallet == null || _wallet!['transactions'].isEmpty
                            ? Center(child: Text('No transactions yet', style: TextStyle(color: GlassTheme.textMuted)))
                            : ListView.builder(
                                itemCount: _wallet!['transactions'].length,
                                itemBuilder: (context, index) {
                                  final List transactions = _wallet!['transactions'];
                                  final tx = transactions[transactions.length - 1 - index]; // Reverse chronological
                                  final isDeposit = tx['transaction_type'] == 'deposit';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: (isDeposit ? GlassTheme.primaryGreen : Colors.redAccent).withValues(alpha: 0.2),
                                                child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: isDeposit ? GlassTheme.primaryGreen : Colors.redAccent),
                                              ),
                                              const SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(tx['description'] ?? 'Transaction', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                  Text(tx['transaction_type'].toString().toUpperCase(), style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${isDeposit ? '+' : '-'}\$${tx['amount']}',
                                            style: TextStyle(color: isDeposit ? GlassTheme.primaryGreen : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
