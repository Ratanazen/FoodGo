import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/lottie_assets.dart';
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
          backgroundColor: GlassTheme.primaryGreen,
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
            ? GlassTheme.primaryGreen.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree
              ? GlassTheme.primaryGreen.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.check_circle : Icons.delivery_dining,
                color: isFree ? GlassTheme.primaryGreen : Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? 'You unlocked FREE delivery! 🎉'
                      : 'Add \$${remaining.toStringAsFixed(2)} more for FREE delivery',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFree ? GlassTheme.primaryGreen : Colors.white,
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
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFree ? GlassTheme.primaryGreen : Colors.amberAccent,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartProvider cart, CartItem item, int index) {
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
        child: GlassCard(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: GlassTheme.borderRadiusSmall,
                  image: item.image != null && item.image!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(item.image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.image == null || item.image!.isEmpty
                    ? const Icon(
                        Icons.fastfood,
                        size: 36,
                        color: GlassTheme.primaryGreen,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: GlassTheme.limeAccentBright,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        cart.decrementItem(item.id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
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
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: GlassTheme.limeAccent,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.white38,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Remove item',
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
    final hasDiscount = cart.discountAmount > 0;
    final promoCode = cart.appliedPromoCode;

    return GlassContainer(
      borderRadius: isDesktop
          ? BorderRadius.circular(24)
          : const BorderRadius.vertical(top: Radius.circular(32)),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        bottom: !isDesktop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop) ...[
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],

            // ── Voucher / Promo Code Input Section ─────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (promoCode != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: GlassTheme.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Code "$promoCode" Applied',
                              style: const TextStyle(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => cart.removePromoCode(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.white60,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          color: GlassTheme.primaryGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter Voucher or Promo Code',
                              hintStyle: TextStyle(
                                color: GlassTheme.textMuted,
                                fontSize: 12,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _applyVoucher(cart),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _applyVoucher(cart),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: GlassTheme.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: GlassTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                const Text('Subtotal', style: TextStyle(fontSize: 15)),
                Text(
                  '\$${cart.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee', style: TextStyle(fontSize: 15)),
                Text(
                  cart.deliveryFee <= 0
                      ? 'FREE'
                      : '\$${cart.deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cart.deliveryFee <= 0
                        ? GlassTheme.primaryGreen
                        : null,
                  ),
                ),
              ],
            ),
            if (hasDiscount) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount ($promoCode)',
                    style: const TextStyle(
                      fontSize: 15,
                      color: GlassTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    '-\$${cart.discountAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: GlassTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(height: 1, color: GlassTheme.borderLight),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${cart.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: GlassTheme.limeAccentBright,
                      ),
                    ),
                    Text(
                      '≈ ${KhmerCurrency.formatKhr(cart.grandTotal)} KHR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassTheme.limeAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/checkout');
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.black, size: 20),
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
    return InkWell(
      onTap: () {
        _voucherController.text = code;
        _applyVoucher(cart);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Navigator.of(context).canPop()
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  )
                : null,
            centerTitle: true,
            title: const Text(
              'Your Cart',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            actions: [
              if (cart.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.white70,
                      ),
                      tooltip: 'Clear Cart',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: GlassTheme.dialogDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: const Text('Clear Cart?'),
                            content: const Text(
                              'Are you sure you want to remove all items from your cart?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white60),
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
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          body: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LottieAsset.emptyBox(size: 150),
                      const SizedBox(height: 16),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover delicious food and add items to your cart',
                        style: TextStyle(color: GlassTheme.textMuted),
                      ),
                      const SizedBox(height: 32),
                      GlassButton(
                        text: 'Explore Food',
                        icon: Icons.explore,
                        onPressed: () => context.go('/explore'),
                      ),
                    ],
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
