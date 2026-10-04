import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/svg_icon.dart';
import '../../../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _wallet;
  final TextEditingController _amountController = TextEditingController(text: '10.00');
  final List<double> _quickAmounts = [5.00, 10.00, 20.00, 50.00, 100.00];

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

  Future<void> _instantTopUp(double amount) async {
    if (amount <= 0) return;
    setState(() => _isProcessing = true);
    try {
      final updated = await _api.post('wallets/top_up/', {'amount': amount.toStringAsFixed(2)});
      if (!mounted) return;
      setState(() {
        _wallet = updated;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added \$${amount.toStringAsFixed(2)} to account!'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to top up: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showKHQRTopUpDialog(double amount) async {
    if (amount <= 0) return;
    setState(() => _isProcessing = true);
    try {
      final res = await _api.post('wallets/khqr_topup/', {'amount': amount.toStringAsFixed(2)});
      if (!mounted) return;
      setState(() => _isProcessing = false);

      final String qrPayload = res['qr_payload'] ?? '';
      final String merchantRef = res['merchant_reference'] ?? '';
      final String effectivePayload = qrPayload.isNotEmpty ? qrPayload : 'FOODGO-KHQR-TOPUP';
      bool showRawPayload = false;

      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: GlassTheme.dialogDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GlassTheme.bakongRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SvgAssetIcon(assetName: 'khqr_logo', size: 24),
                ),
                const SizedBox(width: 12),
                const Text('KHQR Top-Up', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scan with ABA Mobile, Bakong, or any Cambodian App',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // KHQR Top Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      color: GlassTheme.khqrBannerRed,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Center(
                      child: Text(
                        'KHQR · SCAN TO PAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // QR Image Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Center(
                      child: QrImageView(
                        data: effectivePayload,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '\$${amount.toStringAsFixed(2)} USD',
                    style: const TextStyle(color: GlassTheme.primaryGreen, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Ref: $merchantRef', style: TextStyle(color: GlassTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 14),

                  // Copy Payload Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16, color: GlassTheme.primaryGreen),
                    label: const Text('Copy KHQR Payload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: effectivePayload));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('KHQR payload copied to clipboard!'),
                          backgroundColor: GlassTheme.primaryGreen,
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Toggle "Show All QR Payload Details"
                  InkWell(
                    onTap: () => setDialogState(() => showRawPayload = !showRawPayload),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showRawPayload ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: GlassTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            showRawPayload ? 'Hide QR Payload' : 'Show All QR Payload Details',
                            style: TextStyle(color: GlassTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Raw QR Payload Box (Toggled)
                  if (showRawPayload) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('KHQR Payload:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('${effectivePayload.length} chars', style: TextStyle(color: GlassTheme.textMuted, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            effectivePayload,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: GlassTheme.primaryGreenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      text: 'Simulate Successful Payment',
                      icon: Icons.check_circle_outline,
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        await _instantTopUp(amount);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate KHQR: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet?['balance'] ?? '0.00';
    final List transactions = _wallet?['transactions'] ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Account Balance & Wallet',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        color: GlassTheme.backgroundDark,
        child: SafeArea(
          child: _isLoading && _wallet == null
              ? const Center(child: CircularProgressIndicator(color: GlassTheme.primaryGreen))
              : RefreshIndicator(
                  onRefresh: _fetchWallet,
                  color: GlassTheme.primaryGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Balance Card
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        customColor: GlassTheme.primaryGreen.withValues(alpha: 0.12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, color: GlassTheme.primaryGreen, size: 20),
                                const SizedBox(width: 8),
                                const Text('Total Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '\$$balance',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('USD Currency · Live Balance', style: TextStyle(color: GlassTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Top Up Section
                      const Text('Add Money to Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),

                      // Preset chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickAmounts.map((amt) {
                          final isSelected = _amountController.text == amt.toStringAsFixed(2);
                          return InkWell(
                            onTap: () => setState(() => _amountController.text = amt.toStringAsFixed(2)),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? GlassTheme.primaryGreen.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? GlassTheme.primaryGreen : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                '+\$${amt.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? GlassTheme.primaryGreen : Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Custom Amount TextField
                      TextField(
                        controller: _amountController,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Custom Amount',
                          labelStyle: TextStyle(color: GlassTheme.textMuted),
                          prefixIcon: const Icon(Icons.attach_money, color: GlassTheme.primaryGreen),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          // KHQR Pay Button (big)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GlassTheme.abaBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.qr_code_2, size: 22),
                                label: const Text('KHQR Top Up', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _isProcessing
                                    ? null
                                    : () {
                                        final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
                                        if (amt > 0) _showKHQRTopUpDialog(amt);
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Instant Add Money Button
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: GlassButton(
                                text: 'Add Money',
                                icon: Icons.add_card,
                                onPressed: _isProcessing
                                    ? () {}
                                    : () {
                                        final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
                                        if (amt > 0) _instantTopUp(amt);
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Transactions Header
                      const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),

                      if (transactions.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: GlassTheme.textMuted),
                                const SizedBox(height: 8),
                                Text('No transactions yet', style: TextStyle(color: GlassTheme.textMuted)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...transactions.reversed.map((tx) {
                          final isDeposit = tx['transaction_type'] == 'deposit';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (isDeposit ? GlassTheme.primaryGreen : Colors.orangeAccent)
                                        .withValues(alpha: 0.2),
                                    child: Icon(
                                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isDeposit ? GlassTheme.primaryGreen : Colors.orangeAccent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx['description'] ?? (isDeposit ? 'Deposit' : 'Payment'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        Text(
                                          tx['transaction_type'].toString().toUpperCase(),
                                          style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isDeposit ? '+' : '-'}\$${tx['amount']}',
                                    style: TextStyle(
                                      color: isDeposit ? GlassTheme.primaryGreen : Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
