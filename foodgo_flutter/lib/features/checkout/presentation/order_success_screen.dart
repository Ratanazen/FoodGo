import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/lottie_assets.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Object? orderId;
  final String? orderReference;

  const OrderSuccessScreen({super.key, this.orderId, this.orderReference});

  String _buildOrderSummaryTxt(String displayId) {
    final now = DateTime.now().toLocal();
    final ts =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return [
      '========================================',
      'FOODGO ORDER CONFIRMATION SUMMARY',
      '========================================',
      'Order Reference : $displayId',
      'Status          : CONFIRMED & SENT TO KITCHEN',
      'Placed At       : $ts',
      'Estimated ETA   : 25 - 30 minutes',
      'Support Hotline : +855 23 999 888',
      '========================================',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryTextColor = isDark
        ? Colors.white70
        : const Color(0xFF4B5563);

    final rawOrderId = orderId?.toString().trim() ?? '';
    final effectiveOrderId = rawOrderId.isNotEmpty ? rawOrderId : '1001';
    final displayId = (orderReference != null && orderReference!.isNotEmpty)
        ? orderReference!
        : '#$effectiveOrderId';

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Success Checkmark
                    MotionEntrance(
                      staggerIndex: 0,
                      offsetY: AppMotion.standardDistance,
                      duration: AppMotion.extended,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GlassTheme.primaryGreen.withValues(
                                alpha: 0.12,
                              ),
                              border: Border.all(
                                color: GlassTheme.primaryGreen.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.5,
                              ),
                            ),
                          ),
                          LottieAsset.success(size: 130),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    MotionEntrance(
                      staggerIndex: 1,
                      child: Text(
                        'Order Placed!',
                        style: AppTypography.headlineLarge(
                          color: primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    MotionEntrance(
                      staggerIndex: 2,
                      child: Text(
                        'Your order $displayId has been sent to the restaurant.\nGet ready for some delicious food!',
                        style: AppTypography.bodyLarge(
                          color: secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Structured Order Confirmation Summary Card
                    MotionEntrance(
                      staggerIndex: 3,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        borderRadius: GlassTheme.borderRadiusMedium,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ORDER SUMMARY',
                                  style: AppTypography.labelSmall(
                                    color: GlassTheme.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    final txt = _buildOrderSummaryTxt(
                                      displayId,
                                    );
                                    Clipboard.setData(ClipboardData(text: txt));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Order confirmation summary TXT copied!',
                                        ),
                                        backgroundColor:
                                            GlassTheme.primaryGreenDark,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.copy_rounded,
                                          size: 14,
                                          color: GlassTheme.primaryGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy Summary TXT',
                                          style: AppTypography.labelSmall(
                                            color: GlassTheme.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildSummaryRow(
                              label: 'Order Reference',
                              value: displayId,
                              primaryTextColor: primaryTextColor,
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              label: 'Kitchen Status',
                              value: 'Confirmed & Preparing',
                              primaryTextColor: GlassTheme.primaryGreen,
                            ),
                            const SizedBox(height: 6),
                            _buildSummaryRow(
                              label: 'Estimated Delivery',
                              value: '25 - 30 mins',
                              primaryTextColor: primaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Action Buttons
                    MotionEntrance(
                      staggerIndex: 4,
                      child: GlassButton(
                        text: 'Track Order Live',
                        icon: AppIcons.delivery,
                        onPressed: () {
                          context.go('/map/$effectiveOrderId');
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    MotionEntrance(
                      staggerIndex: 5,
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            context.go('/home');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: primaryTextColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                AppIcons.home,
                                size: 18,
                                color: GlassTheme.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Back to Home',
                                style: AppTypography.labelLarge(
                                  color: GlassTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color primaryTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall(color: GlassTheme.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall(
              color: primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
