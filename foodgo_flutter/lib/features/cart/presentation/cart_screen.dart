import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/vector_illustrations.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _voucherController = TextEditingController();

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _applyVoucher(CartProvider cart) {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    final success = cart.applyPromoCode(code);
    if (!mounted) return;

    if (success) {
      _voucherController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher "$code" applied successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid promo code. Try FOODGO30, FOODGOFREE, or FOODGO20.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFreeDeliveryBar(CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const threshold = 20.0;
    final isFree = cart.deliveryFee <= 0 || cart.totalAmount >= threshold;
    final remaining = (threshold - cart.totalAmount).clamp(0.0, threshold);
    final progress = isFree
        ? 1.0
        : (cart.totalAmount / threshold).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFree
            ? Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.3)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? AppIcons.successFilled : AppIcons.delivery,
                color: isFree
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? Colors.amberAccent : Colors.amber.shade800),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? 'You unlocked FREE delivery!'
                      : 'Add \$${remaining.toStringAsFixed(2)} more for FREE delivery',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isFree
                            ? Theme.of(context).colorScheme.primary
                            : AppTypography.primaryTextColor(
                                isDark ? Brightness.dark : Brightness.light,
                              ),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFree
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? Colors.amberAccent : Colors.amber.shade700),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartProvider cart, CartItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Dismissible(
        key: ValueKey('cart_item_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.85),
            borderRadius: GlassTheme.borderRadiusMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(AppIcons.delete, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          final removedItem = item;
          final qty = item.quantity;
          cart.removeItem(item.id);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${removedItem.name} removed from cart'),
              backgroundColor: GlassTheme.dialogDark,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'UNDO',
                textColor: GlassTheme.primaryGreen,
                onPressed: () {
                  for (int i = 0; i < qty; i++) {
                    cart.addItem(
                      removedItem.id,
                      removedItem.name,
                      removedItem.price,
                      removedItem.image,
                      restaurantId: removedItem.restaurantId,
                      restaurantName: removedItem.restaurantName,
                    );
                  }
                },
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular food thumbnail
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: item.image != null && item.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.image!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: GlassTheme.lightGreenSurface,
                            child: const Icon(
                              AppIcons.healthy,
                              color: GlassTheme.primaryGreen,
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          color: GlassTheme.lightGreenSurface,
                          child: const Icon(
                            AppIcons.healthy,
                            color: GlassTheme.primaryGreen,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTypography.primaryTextColor(
                              isDark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isDark
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF15803D),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          KhmerCurrency.formatKhr(item.price),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTypography.secondaryTextColor(
                                  isDark ? Brightness.dark : Brightness.light,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stepper: Red circular (-) and Green circular (+)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedPressable(
                    pressedScale: 0.86,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cart.decrementItem(item.id);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF4444),
                      ),
                      child: const Icon(
                        AppIcons.remove,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTypography.primaryTextColor(
                              isDark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                    ),
                  ),
                  AnimatedPressable(
                    pressedScale: 0.86,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cart.addItem(
                        item.id,
                        item.name,
                        item.price,
                        item.image,
                        restaurantId: item.restaurantId,
                        restaurantName: item.restaurantName,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: GlassTheme.primaryGreen,
                      ),
                      child: const Icon(
                        AppIcons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              AnimatedPressable(
                pressedScale: 0.88,
                onTap: () {
                  HapticFeedback.lightImpact();
                  final removedItem = item;
                  final qty = item.quantity;
                  cart.removeItem(item.id);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${removedItem.name} removed from cart'),
                      backgroundColor: GlassTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: Colors.white,
                        onPressed: () {
                          for (int i = 0; i < qty; i++) {
                            cart.addItem(
                              removedItem.id,
                              removedItem.name,
                              removedItem.price,
                              removedItem.image,
                              restaurantId: removedItem.restaurantId,
                              restaurantName: removedItem.restaurantName,
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF3F4F6),
                  ),
                  child: Icon(
                    AppIcons.delete,
                    size: 17,
                    color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(delay: (100 * index).ms).slideX(),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    CartProvider cart, {
    bool isDesktop = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDiscount = cart.discountAmount > 0;
    final promoCode = cart.appliedPromoCode;

    return GlassContainer(
      borderRadius: isDesktop
          ? BorderRadius.circular(24)
          : const BorderRadius.vertical(top: Radius.circular(32)),
      customColor: isDark ? null : Colors.white,
      customShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ],
      customBorder: isDesktop
          ? Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
            )
          : Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        bottom: !isDesktop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop) ...[
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTypography.primaryTextColor(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Voucher / Promo Code Input Section ─────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (promoCode != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.successFilled,
                                color: isDark
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFF15803D),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Code "$promoCode" Applied',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFF15803D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => cart.removePromoCode(),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              AppIcons.close,
                              color: AppTypography.secondaryTextColor(
                                isDark ? Brightness.dark : Brightness.light,
                              ),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          AppIcons.coupon,
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF15803D),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            textCapitalization: TextCapitalization.characters,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTypography.primaryTextColor(
                                    isDark
                                        ? Brightness.dark
                                        : Brightness.light,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              hintText: 'Enter Voucher or Promo Code',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTypography.secondaryTextColor(
                                      isDark
                                          ? Brightness.dark
                                          : Brightness.light,
                                    ),
                                  ),
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _applyVoucher(cart),
                          ),
                        ),
                        AnimatedPressable(
                          pressedScale: 0.92,
                          onTap: () => _applyVoucher(cart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'Apply',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFF15803D),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick apply chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPromoChip(
                            'FOODGO30 (30% OFF)',
                            'FOODGO30',
                            cart,
                          ),
                          const SizedBox(width: 6),
                          _buildPromoChip(
                            'FOODGOFREE (Free Delivery)',
                            'FOODGOFREE',
                            cart,
                          ),
                          const SizedBox(width: 6),
                          _buildPromoChip(
                            'FOODGO20 (20% OFF)',
                            'FOODGO20',
                            cart,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTypography.secondaryTextColor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                ),
                Text(
                  '\$${cart.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTypography.primaryTextColor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Fee',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTypography.secondaryTextColor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                ),
                Text(
                  cart.deliveryFee <= 0
                      ? 'FREE'
                      : '\$${cart.deliveryFee.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cart.deliveryFee <= 0
                            ? (isDark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF15803D))
                            : AppTypography.primaryTextColor(
                                isDark ? Brightness.dark : Brightness.light,
                              ),
                      ),
                ),
              ],
            ),
            if (hasDiscount) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Discount ($promoCode)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF15803D),
                          ),
                    ),
                  ),
                  Text(
                    '-\$${cart.discountAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF15803D),
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTypography.primaryTextColor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${cart.grandTotal.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF15803D),
                          ),
                    ),
                    Text(
                      '≈ ${KhmerCurrency.formatKhr(cart.grandTotal)} KHR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTypography.secondaryTextColor(
                              isDark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            AnimatedPressable(
              pressedScale: 0.96,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/checkout');
              },
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('cart.checkout'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(AppIcons.forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoChip(String label, String code, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPressable(
      pressedScale: 0.93,
      onTap: () {
        _voucherController.text = code;
        _applyVoucher(cart);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTypography.secondaryTextColor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GlassAppBar(
            title: context.tr('cart.title'),
            leading: Navigator.of(context).canPop()
                ? Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: AnimatedPressable(
                      pressedScale: 0.9,
                      onTap: () => context.pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.black.withValues(alpha: 0.1),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            AppIcons.back,
                            size: 16,
                            color: AppTypography.primaryTextColor(brightness),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            actions: [
              if (cart.items.isNotEmpty) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14532D).withValues(alpha: 0.45)
                          : GlassTheme.lightGreenSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cart.itemCount} ${cart.itemCount == 1 ? "Product" : "Products"}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF15803D),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: AnimatedPressable(
                    pressedScale: 0.9,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark
                              ? GlassTheme.dialogDark
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(
                            'Clear Cart?',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppTypography.primaryTextColor(
                                    brightness,
                                  ),
                                ),
                          ),
                          content: Text(
                            'Are you sure you want to remove all items from your cart?',
                            style: Theme.of(ctx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTypography.secondaryTextColor(
                                    brightness,
                                  ),
                                ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppTypography.secondaryTextColor(
                                        brightness,
                                      ),
                                    ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              onPressed: () {
                                cart.clear();
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                'Clear',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          AppIcons.delete,
                          size: 18,
                          color: AppTypography.secondaryTextColor(brightness),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          body: cart.items.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const VectorIllustration(
                          type: VectorIllustrationType.emptyCart,
                          size: 160,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('cart.emptyTitle'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTypography.primaryTextColor(
                                  brightness,
                                ),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('cart.emptySubtitle'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTypography.secondaryTextColor(
                                  brightness,
                                ),
                              ),
                        ),
                        const SizedBox(height: 32),
                        GlassButton(
                          text: context.tr('cart.startOrdering'),
                          icon: AppIcons.foodCategory,
                          onPressed: () => context.go('/explore'),
                        ),
                      ],
                    ),
                  ),
                )
              : ResponsiveWebContainer(
                  maxWidth: 1050,
                  child: ResponsiveBreakpoints.isWide(context)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ListView(
                                  children: [
                                    _buildFreeDeliveryBar(cart),
                                    ...cart.items.values
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => _buildCartItemCard(
                                            cart,
                                            entry.value,
                                            entry.key,
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child:
                                    _buildSummaryCard(
                                          context,
                                          cart,
                                          isDesktop: true,
                                        )
                                        .animate()
                                        .fade(delay: 200.ms)
                                        .slideX(begin: 0.1),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: _buildFreeDeliveryBar(cart),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                itemCount: cart.items.length,
                                itemBuilder: (context, index) =>
                                    _buildCartItemCard(
                                      cart,
                                      cart.items.values.toList()[index],
                                      index,
                                    ),
                              ),
                            ),
                            _buildSummaryCard(
                              context,
                              cart,
                              isDesktop: false,
                            ).animate().fade(delay: 200.ms).slideY(begin: 1.0),
                          ],
                        ),
                ),
        );
      },
    );
  }
}
