import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/svg_icon.dart';
import '../../../services/api_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../payment/models/payment_model.dart';

class WalletScreen extends StatefulWidget {
  final Map<String, dynamic>? initialWallet;
  final bool? initialLoading;

  const WalletScreen({super.key, this.initialWallet, this.initialLoading});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _wallet;
  final TextEditingController _amountController = TextEditingController(
    text: '10.00',
  );
  final List<double> _quickAmounts = [5.00, 10.00, 20.00, 50.00, 100.00];
  String _txFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialWallet != null || widget.initialLoading != null) {
      _wallet = widget.initialWallet;
      _isLoading = widget.initialLoading ?? false;
    } else {
      _fetchWallet();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoading = true);
    try {
      final hasToken = await SecureStorage().hasAccessToken();
      if (!hasToken) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
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
      final updated = await _api.post('wallets/top_up/', {
        'amount': amount.toStringAsFixed(2),
      });
      if (!mounted) return;
      setState(() {
        _wallet = updated;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully added \$${amount.toStringAsFixed(2)} to account!',
          ),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to top up: ${ApiService.formatError(e)}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showKHQRTopUpDialog(double amount) async {
    if (amount <= 0) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);
    try {
      final res = await _api.post('wallets/khqr_topup/', {
        'amount': amount.toStringAsFixed(2),
      });
      if (!mounted) return;
      setState(() => _isProcessing = false);

      final String qrPayload = (res['qr_payload'] ?? '').toString().trim();
      final String merchantRef = (res['merchant_reference'] ?? '').toString();
      final String md5Hash = (res['md5'] ?? '').toString();
      if (qrPayload.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment server did not return a valid KHQR payload.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final String effectivePayload =
          PaymentModel.ensureDynamicKhqrExpiration(qrPayload) ?? qrPayload;
      bool showRawPayload = false;
      bool isVerifyingTopUp = false;

      final brightness = Theme.of(context).brightness;
      final isDark = brightness == Brightness.dark;
      final textTheme = Theme.of(context).textTheme;
      final primaryText = AppTypography.primaryTextColor(brightness);
      final secondaryText = AppTypography.secondaryTextColor(brightness);
      final accentGreen = isDark
          ? GlassTheme.primaryGreenAccent
          : const Color(0xFF15803D);

      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GlassTheme.bakongRed.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SvgAssetIcon(assetName: 'khqr_logo', size: 24),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'KHQR Top-Up',
                    style: textTheme.titleLarge?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scan with ABA Mobile, Bakong, or any Cambodian App',
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // KHQR Top Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      color: GlassTheme.khqrBannerRed,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'KHQR · SCAN TO PAY',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
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
                    style: textTheme.displayLarge?.copyWith(
                      color: accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '≈ ${KhmerCurrency.formatKhr(amount)} KHR',
                    style: textTheme.bodySmall?.copyWith(
                      color: primaryText.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: $merchantRef',
                    style: textTheme.labelSmall?.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: 14),

                  // Copy Payload Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: accentGreen,
                    ),
                    label: Text(
                      'Copy KHQR Payload',
                      style: textTheme.bodySmall?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                    onTap: () =>
                        setDialogState(() => showRawPayload = !showRawPayload),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showRawPayload
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            showRawPayload
                                ? 'Hide QR Payload'
                                : 'Show All QR Payload Details',
                            style: textTheme.labelSmall?.copyWith(
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
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
                        color: isDark
                            ? Colors.black54
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'KHQR Payload:',
                                style: textTheme.labelSmall?.copyWith(
                                  color: secondaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${effectivePayload.length} chars',
                                style: textTheme.labelSmall?.copyWith(
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            effectivePayload,
                            style: textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: accentGreen,
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
                      text: isVerifyingTopUp
                          ? 'Verifying KHQR Payment...'
                          : 'I Have Paid · Verify Top-Up',
                      icon: Icons.verified_outlined,
                      isLoading: isVerifyingTopUp,
                      onPressed: isVerifyingTopUp
                          ? null
                          : () async {
                              setDialogState(() => isVerifyingTopUp = true);
                              try {
                                final verifyRes = await _api
                                    .post('wallets/verify_topup/', {
                                      'merchant_reference': merchantRef,
                                      'md5': md5Hash,
                                      'qr_payload': effectivePayload,
                                      'amount': amount.toStringAsFixed(2),
                                      'currency': 'USD',
                                    });
                                if (!mounted) return;
                                final statusStr = (verifyRes['status'] ?? '')
                                    .toString()
                                    .toUpperCase();
                                if (statusStr == 'CREDITED') {
                                  if (dialogCtx.mounted) {
                                    Navigator.of(dialogCtx).pop();
                                  }
                                  await _fetchWallet();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'KHQR Top-Up of \$${amount.toStringAsFixed(2)} verified and credited!',
                                      ),
                                      backgroundColor: GlassTheme.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  setDialogState(
                                    () => isVerifyingTopUp = false,
                                  );
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        verifyRes['message']?.toString() ??
                                            'Payment not yet confirmed by bank. Please complete the scan first.',
                                      ),
                                      backgroundColor: Colors.orangeAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (err) {
                                if (dialogCtx.mounted) {
                                  setDialogState(
                                    () => isVerifyingTopUp = false,
                                  );
                                }
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Verification error: ${ApiService.formatError(err)}',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('Close', style: TextStyle(color: secondaryText)),
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
            content: Text(
              'Failed to generate KHQR: ${ApiService.formatError(e)}',
            ),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    final accentAmber = isDark ? Colors.orangeAccent : const Color(0xFFB45309);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Account Balance & Wallet',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: _isLoading && _wallet == null
              ? Center(child: CircularProgressIndicator(color: accentGreen))
              : RefreshIndicator(
                  onRefresh: _fetchWallet,
                  color: accentGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Balance Card
                      GlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: BorderRadius.circular(24),
                            customColor: GlassTheme.primaryGreen.withValues(
                              alpha: 0.12,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: accentGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Available Balance',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '\$$balance',
                                  style: textTheme.displayLarge?.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '≈ ${KhmerCurrency.formatKhr(double.tryParse(balance.toString()) ?? 0.0)} KHR',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: accentGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Live Dual Balance · អត្រា ៤,១០០ ៛/USD',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: secondaryText,
                                    height: 1.5,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.08, end: 0)
                          .scale(
                            begin: const Offset(0.96, 0.96),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 24),

                      // Quick Top Up Section
                      Text(
                        'Add Money to Account',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Preset chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickAmounts.map((amt) {
                          final isSelected =
                              _amountController.text == amt.toStringAsFixed(2);
                          return InkWell(
                            onTap: () => setState(
                              () => _amountController.text = amt
                                  .toStringAsFixed(2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? GlassTheme.primaryGreen.withValues(
                                        alpha: isDark ? 0.3 : 0.16,
                                      )
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            )),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? accentGreen
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.12,
                                              )),
                                ),
                              ),
                              child: Text(
                                '+\$${amt.toStringAsFixed(0)} (${KhmerCurrency.formatKhr(amt)})',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? accentGreen : primaryText,
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
                        style: textTheme.titleLarge?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Custom Amount',
                          labelStyle: textTheme.bodyMedium?.copyWith(
                            color: secondaryText,
                          ),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: accentGreen,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.12),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: accentGreen,
                              width: 1.5,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.qr_code_2, size: 22),
                                label: Text(
                                  'KHQR Top Up',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _isProcessing
                                    ? null
                                    : () {
                                        final amt =
                                            double.tryParse(
                                              _amountController.text.trim(),
                                            ) ??
                                            0.0;
                                        if (amt > 0) {
                                          _showKHQRTopUpDialog(amt);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid amount greater than \$0.00.',
                                              ),
                                              backgroundColor: Color(
                                                0xFFB45309,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
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
                                isLoading: _isProcessing,
                                onPressed: _isProcessing
                                    ? () {}
                                    : () {
                                        final amt =
                                            double.tryParse(
                                              _amountController.text.trim(),
                                            ) ??
                                            0.0;
                                        if (amt > 0) {
                                          _instantTopUp(amt);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid amount greater than \$0.00.',
                                              ),
                                              backgroundColor: Color(
                                                0xFFB45309,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Transactions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction History',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            '${transactions.length} total',
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTxFilterChip(
                              'All',
                              'all',
                              transactions.length,
                            ),
                            const SizedBox(width: 8),
                            _buildTxFilterChip(
                              '+ Top-Ups',
                              'deposit',
                              transactions
                                  .where(
                                    (t) => t['transaction_type'] == 'deposit',
                                  )
                                  .length,
                            ),
                            const SizedBox(width: 8),
                            _buildTxFilterChip(
                              '- Payments',
                              'payment',
                              transactions
                                  .where(
                                    (t) => t['transaction_type'] != 'deposit',
                                  )
                                  .length,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      () {
                        final filteredTxs = transactions.where((tx) {
                          if (_txFilter == 'deposit') {
                            return tx['transaction_type'] == 'deposit';
                          }
                          if (_txFilter == 'payment') {
                            return tx['transaction_type'] != 'deposit';
                          }
                          return true;
                        }).toList();

                        if (filteredTxs.isEmpty) {
                          return GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: secondaryText,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _txFilter == 'all'
                                        ? 'No transactions yet'
                                        : 'No ${_txFilter == 'deposit' ? 'top-up' : 'payment'} transactions found',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: filteredTxs.reversed.map((tx) {
                            final isDeposit =
                                tx['transaction_type'] == 'deposit';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          (isDeposit
                                                  ? GlassTheme.primaryGreen
                                                  : Colors.orangeAccent)
                                              .withValues(alpha: 0.2),
                                      child: Icon(
                                        isDeposit
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isDeposit
                                            ? accentGreen
                                            : accentAmber,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx['description'] ??
                                                (isDeposit
                                                    ? 'Deposit (បញ្ចូលប្រាក់)'
                                                    : 'Payment (ទូទាត់ប្រាក់)'),
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryText,
                                                  height: 1.5,
                                                  letterSpacing: 0,
                                                ),
                                          ),
                                          Text(
                                            '${tx['transaction_type'].toString().toUpperCase()} • ${KhmerCurrency.formatKhr(double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0)}',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  color: secondaryText,
                                                  height: 1.5,
                                                  letterSpacing: 0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${isDeposit ? '+' : '-'}\$${tx['amount']}',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: isDeposit
                                            ? accentGreen
                                            : accentAmber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
                          }).toList(),
                        );
                      }(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTxFilterChip(String label, String value, int count) {
    final isSelected = _txFilter == value;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);
    return InkWell(
      onTap: () => setState(() => _txFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? GlassTheme.primaryGreen.withValues(alpha: isDark ? 0.25 : 0.16)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentGreen
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? accentGreen : secondaryText,
          ),
        ),
      ),
    );
  }
}
