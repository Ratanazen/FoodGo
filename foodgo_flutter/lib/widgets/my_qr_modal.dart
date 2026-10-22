import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/glass_theme.dart';
import '../core/utils/khmer_currency.dart';
import 'glass/glass_widgets.dart';
import 'glass_container.dart';
import 'svg_icon.dart';
import 'responsive_layout.dart';

class MyQrModal {
  static void show(
    BuildContext context, {
    required Map<String, dynamic>? user,
    double initialAmount = 0.0,
    Future<void> Function(double amount)? onReceivePayment,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MyQrSheet(
        user: user,
        initialAmount: initialAmount,
        onReceivePayment: onReceivePayment,
      ),
    );
  }
}

class _MyQrSheet extends StatefulWidget {
  final Map<String, dynamic>? user;
  final double initialAmount;
  final Future<void> Function(double amount)? onReceivePayment;

  const _MyQrSheet({
    required this.user,
    required this.initialAmount,
    this.onReceivePayment,
  });

  @override
  State<_MyQrSheet> createState() => _MyQrSheetState();
}

class _MyQrSheetState extends State<_MyQrSheet> {
  late double _amount;
  late TextEditingController _amountController;
  bool _isKhr = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
    _amountController = TextEditingController(
      text: _amount > 0 ? _amount.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _userName {
    final first = widget.user?['first_name'] ?? '';
    final last = widget.user?['last_name'] ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    return widget.user?['username'] ?? 'FoodGo Member';
  }

  String get _bakongId {
    final uname = widget.user?['username'] ?? 'customer';
    return '${uname.toLowerCase()}@bkrt';
  }

  static String calculateCrc16(String input) {
    int crc = 0xFFFF;
    final bytes = input.codeUnits;
    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  String get _qrPayload {
    final amtStr = _amount > 0 ? _amount.toStringAsFixed(2) : '0.00';
    final currCode = _isKhr ? '116' : '840';
    final raw =
        '00020101021229370016bakong@bkrt0109$_bakongId'
        '5303$currCode'
        '${_amount > 0 ? "540${amtStr.length.toString().padLeft(2, '0')}$amtStr" : ""}'
        '5802KH5911${_userName.replaceAll(" ", "_")}'
        '6010Phnom_Penh6304';
    final checksum = calculateCrc16(raw);
    return '$raw$checksum';
  }

  void _onAmountChanged(String val) {
    setState(() {
      _amount = double.tryParse(val.trim()) ?? 0.0;
    });
  }

  void _setPreset(double amt) {
    setState(() {
      _amount = amt;
      _amountController.text = amt > 0 ? amt.toStringAsFixed(0) : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ResponsiveBottomSheet(
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GlassTheme.bakongRed.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SvgAssetIcon(
                          assetName: 'khqr_logo',
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My KHQR (Pay Me)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'កូដ QR ទទួលប្រាក់ • $_bakongId',
                            style: const TextStyle(
                              color: GlassTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User Info Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: GlassTheme.bakongRed.withValues(
                        alpha: 0.25,
                      ),
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Bakong ID: $_bakongId',
                            style: const TextStyle(
                              color: GlassTheme.primaryGreenAccent,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _bakongId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bakong Account ID copied!'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: GlassTheme.primaryGreen,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.copy,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount Setup Bar & Preset Chips
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: _onAmountChanged,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Receive Amount (Optional)',
                        labelStyle: const TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          size: 18,
                          color: GlassTheme.primaryGreen,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _isKhr = !_isKhr),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isKhr ? '៛ KHR' : '\$ USD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Preset Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PresetChip(
                      label: 'Open',
                      isSelected: _amount == 0,
                      onTap: () => _setPreset(0),
                    ),
                    const SizedBox(width: 6),
                    _PresetChip(
                      label: '+\$5 (៛20.5k)',
                      isSelected: _amount == 5,
                      onTap: () => _setPreset(5),
                    ),
                    const SizedBox(width: 6),
                    _PresetChip(
                      label: '+\$10 (៛41k)',
                      isSelected: _amount == 10,
                      onTap: () => _setPreset(10),
                    ),
                    const SizedBox(width: 6),
                    _PresetChip(
                      label: '+\$20 (៛82k)',
                      isSelected: _amount == 20,
                      onTap: () => _setPreset(20),
                    ),
                    const SizedBox(width: 6),
                    _PresetChip(
                      label: '+\$50 (៛205k)',
                      isSelected: _amount == 50,
                      onTap: () => _setPreset(50),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // NBC KHQR Stand Container
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: GlassTheme.bakongRed.withValues(alpha: 0.3),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Red NBC Stand Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: GlassTheme.khqrBannerRed,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'KHQR · ទទួលប្រាក់ (PAY ME)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Supported Banking Badges
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Bakong',
                            style: TextStyle(
                              color: GlassTheme.bakongRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(' • ', style: TextStyle(color: Colors.black26)),
                          Text(
                            'ABA Mobile',
                            style: TextStyle(
                              color: GlassTheme.abaBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          Text(' • ', style: TextStyle(color: Colors.black26)),
                          Text(
                            'ACLEDA',
                            style: TextStyle(
                              color: GlassTheme.acledaNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // QR Image
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: _qrPayload,
                        version: QrVersions.auto,
                        size: 190.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),

                    // Dual Amount Footer on Stand
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Text(
                            _amount > 0
                                ? '\$${_amount.toStringAsFixed(2)} • ${KhmerCurrency.formatKhr(_amount)}'
                                : 'Any Amount (ស្រេចចិត្ត)',
                            style: const TextStyle(
                              color: GlassTheme.textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'FoodGo KHQR Pay Me · $_userName',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text(
                        'Copy KHQR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _qrPayload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('KHQR Payload copied to clipboard!'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: GlassTheme.primaryGreen,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassButton(
                      text: _isProcessing ? 'Processing...' : 'Simulate Pay Me',
                      icon: Icons.check_circle_outline,
                      onPressed: _isProcessing
                          ? () {}
                          : () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final amtToCredit = _amount > 0 ? _amount : 10.0;
                              setState(() => _isProcessing = true);
                              if (widget.onReceivePayment != null) {
                                await widget.onReceivePayment!(amtToCredit);
                              }
                              if (!mounted) return;
                              setState(() => _isProcessing = false);
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '+\$${amtToCredit.toStringAsFixed(2)} (${KhmerCurrency.formatKhr(amtToCredit)}) received successfully!',
                                  ),
                                  backgroundColor: GlassTheme.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? GlassTheme.bakongRed.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? GlassTheme.bakongRed
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.redAccent : Colors.white70,
          ),
        ),
      ),
    );
  }
}
