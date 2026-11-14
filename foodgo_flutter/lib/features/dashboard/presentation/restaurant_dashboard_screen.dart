import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/glass_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _restaurant;
  List<dynamic> _orders = [];
  List<dynamic> _foodItems = [];
  List<dynamic> _categories = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final resData = await _api.get('restaurants/my_restaurant/');
      final ordData = await _api.get('orders/');

      List<dynamic> items = [];
      List<dynamic> cats = [];
      if (resData != null && resData['food_categories'] != null) {
        cats = List<dynamic>.from(resData['food_categories']);
        for (var cat in cats) {
          final catItems = List<dynamic>.from(cat['items'] ?? []);
          for (var it in catItems) {
            it['category_name'] = cat['name'];
            it['category_id'] = cat['id'];
            items.add(it);
          }
        }
      }

      if (!mounted) return;
      List<dynamic> rawOrders = [];
      if (ordData is List) {
        rawOrders = ordData;
      } else if (ordData is Map && ordData['results'] is List) {
        rawOrders = ordData['results'] as List;
      }

      setState(() {
        _restaurant = resData;
        _orders = rawOrders.reversed.toList();
        _categories = cats;
        _foodItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restaurantAcceptOrder(String orderId) async {
    try {
      await _api.post('orders/$orderId/restaurant-accept/', {});
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted.'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept order.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restaurantRejectOrder(String orderId) async {
    final reasonText = await showDialog<String>(
      context: context,
      builder: (_) => const _RestaurantRejectOrderDialog(),
    );

    if (reasonText == null || !mounted) return;

    try {
      final reason = reasonText.isEmpty
          ? 'Kitchen unable to fulfill order'
          : reasonText;
      await _api.post('orders/$orderId/restaurant-reject/', {'reason': reason});
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected and refunded if prepaid.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.formatError(e, fallback: 'Failed to reject order.'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startPreparing(String orderId) async {
    try {
      await _api.post('orders/$orderId/start-preparing/', {});
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order preparation started.'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start preparing order.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _readyForPickup(String orderId) async {
    try {
      await _api.post('orders/$orderId/ready-for-pickup/', {});
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order ready for pickup. Driver notified.'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark order ready.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleItemAvailability(int itemId, bool currentVal) async {
    try {
      await _api.patch('food-items/$itemId/', {'is_available': !currentVal});
      _fetchDashboardData();
    } catch (e) {
      debugPrint('Failed to toggle availability: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update item availability.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleStoreActive(bool currentStatus) async {
    if (_restaurant == null) return;
    final resId = _restaurant!['id'];
    try {
      await _api.patch('restaurants/$resId/', {'is_active': !currentStatus});
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? 'Store is now OPEN & accepting orders.'
                : 'Store is now CLOSED.',
          ),
          backgroundColor: !currentStatus
              ? GlassTheme.primaryGreen
              : Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update store status: ${ApiService.formatError(e)}',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
      case 'preparing':
        return const Color(0xFF06B6D4);
      case 'ready_for_pickup':
      case 'ready':
        return const Color(0xFF8B5CF6);
      case 'driver_assigned':
      case 'driver_accepted':
      case 'picked_up':
      case 'on_the_way':
      case 'out_for_delivery':
      case 'driver_arrived':
        return const Color(0xFF3B82F6);
      case 'delivered':
      case 'completed':
        return GlassTheme.primaryGreen;
      case 'cancelled':
      case 'rejected':
      case 'failed_delivery':
        return Colors.redAccent;
      default:
        return GlassTheme.primaryGreen;
    }
  }

  Future<void> _showAddFoodItemDialog() async {
    if (_restaurant == null) return;
    final addedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodItemBottomSheet(
        restaurantId: _restaurant!['id'] as int,
        categories: _categories,
        api: _api,
      ),
    );
    if (addedName != null && addedName.isNotEmpty) {
      _fetchDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added "$addedName" to your menu!'),
          backgroundColor: GlassTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Restaurant Log Out',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out of the Restaurant Portal?',
          style: TextStyle(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              context.read<UserProvider>().clearUser();
              context.go('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeaderCard() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final name = _restaurant!['name'] ?? 'Restaurant';
    final address = _restaurant!['address'] ?? 'Phnom Penh';
    final rating = _restaurant!['rating']?.toString() ?? '4.85';
    final banner = _restaurant!['banner'];
    final bool isActive = _restaurant!['is_active'] ?? true;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? accentGreen
                        : (isDark ? Colors.white24 : Colors.black26),
                    width: 2,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: GlassTheme.primaryGreen.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: banner != null
                      ? CachedNetworkImageProvider(banner)
                      : null,
                  child: banner == null
                      ? Icon(
                          Icons.storefront_rounded,
                          size: 28,
                          color: accentGreen,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: textTheme.titleLarge?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Live Status & Open/Closed Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? GlassTheme.primaryGreen.withValues(alpha: 0.16)
                          : Colors.redAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? accentGreen.withValues(alpha: 0.45)
                            : Colors.redAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? accentGreen : Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: isActive
                                    ? GlassTheme.primaryGreen
                                    : Colors.redAccent,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isActive ? 'ACCEPTING ORDERS' : 'STORE CLOSED',
                            style: textTheme.labelSmall?.copyWith(
                              color: isActive
                                  ? accentGreen
                                  : (isDark
                                        ? Colors.redAccent
                                        : const Color(0xFFB91C1C)),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Live' : 'Paused',
                  style: textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isActive,
                    activeThumbColor: Colors.white,
                    activeTrackColor: GlassTheme.primaryGreen,
                    inactiveThumbColor: isDark
                        ? Colors.white60
                        : Colors.black54,
                    inactiveTrackColor: isDark
                        ? Colors.white12
                        : Colors.black12,
                    onChanged: (_) => _toggleStoreActive(isActive),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Metrics Summary Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricPill(
                    icon: Icons.fastfood_rounded,
                    label: 'Menu Items',
                    value: '${_foodItems.length}',
                    color: accentGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    icon: Icons.receipt_long_rounded,
                    label: 'Total Orders',
                    value: '${_orders.length}',
                    color: isDark
                        ? const Color(0xFF06B6D4)
                        : const Color(0xFF0E7490),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    icon: Icons.star_rounded,
                    label: 'Store Rating',
                    value: rating.toString(),
                    color: isDark
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildOrdersEmptyState() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);

    return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          GlassTheme.primaryGreen.withValues(alpha: 0.25),
                          GlassTheme.primaryGreen.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.soup_kitchen_rounded,
                      size: 40,
                      color: accentGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kitchen is Ready & Waiting',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New customer orders will appear here in real-time. Keep your portal active to prepare fresh orders promptly.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: GlassTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Listening for incoming tickets...',
                            style: textTheme.labelMedium?.copyWith(
                              color: accentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Tickets'),
                    onPressed: _fetchDashboardData,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: 'Restaurant Portal',
          leading: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            ),
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: primaryText,
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.10),
                ),
              ),
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.refresh_rounded, size: 20, color: primaryText),
                tooltip: 'Refresh',
                onPressed: _fetchDashboardData,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(
                left: 4,
                right: 4,
                top: 2,
                bottom: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.25),
                ),
              ),
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: 'Log Out',
                onPressed: () => _confirmLogout(context),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: GlassTheme.primaryGreen,
                    ),
                  )
                : _restaurant == null
                ? Center(
                    child: Text(
                      'You do not own a restaurant.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  )
                : ResponsiveWebContainer(
                    maxWidth: 1050,
                    child: NestedScrollView(
                      headerSliverBuilder: (context, _) => [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Restaurant Header Card
                                _buildRestaurantHeaderCard(),
                                const SizedBox(height: 16),

                                // Modern Glass Pill Tab Selector
                                Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 50,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                      width: 1.2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: TabBar(
                                    controller: _tabController,
                                    dividerColor: Colors.transparent,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          GlassTheme.primaryGreen,
                                          Color(0xFF059669),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(21),
                                      boxShadow: [
                                        BoxShadow(
                                          color: GlassTheme.primaryGreen
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: primaryText,
                                    labelStyle: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    unselectedLabelStyle: textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                    tabs: [
                                      Tab(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.receipt_long_rounded,
                                              size: 17,
                                            ),
                                            const SizedBox(width: 7),
                                            const Text('Orders'),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.22,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${_orders.length}',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Tab(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.restaurant_menu_rounded,
                                              size: 17,
                                            ),
                                            const SizedBox(width: 7),
                                            const Text('Menu'),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.22,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${_foodItems.length}',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(
                                  delay: 100.ms,
                                  duration: 400.ms,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                      body: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Orders
                            _buildOrdersTab(),

                            // Tab 2: Menu Items
                            _buildMenuTab(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _orderSearchQuery = '';

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return _buildOrdersEmptyState();
    }
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    final query = _orderSearchQuery.trim().toLowerCase();
    final filteredOrders = query.isEmpty
        ? _orders
        : _orders.where((o) {
            if (o is! Map) return false;
            final idStr = o['id']?.toString().toLowerCase() ?? '';
            final status = o['status']?.toString().toLowerCase() ?? '';
            final cust = o['customer_info'] is Map
                ? (o['customer_info']['name']?.toString().toLowerCase() ?? '')
                : '';
            return idStr.contains(query) ||
                status.contains(query) ||
                cust.contains(query);
          }).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _orderSearchQuery = val),
            style: textTheme.bodyMedium?.copyWith(color: primaryText),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintText: 'Find order by #ID, customer, or status...',
              hintStyle: textTheme.bodySmall?.copyWith(color: secondaryText),
              prefixIcon: Icon(Icons.search, color: accentGreen, size: 18),
              border: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: GlassTheme.primaryGreen,
            onRefresh: _fetchDashboardData,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 650;
                if (isWide) {
                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 280,
                        ),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildRestaurantOrderCard(order);
                    },
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildRestaurantOrderCard(order),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantOrderCard(dynamic order) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final status = order['status']?.toString() ?? 'pending';
    final orderId = order['id'].toString();
    final assignedDriver = order['assigned_driver'];
    final statusColor = _getOrderStatusColor(status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        size: 16,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Order #$orderId',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final double amount =
                  double.tryParse(order['total_amount']?.toString() ?? '0') ??
                  0.0;
              final khr = KhmerCurrency.formatKhr(amount);
              final isPaid =
                  (order['payment_status'] ?? '').toString().toUpperCase() ==
                  'PAID';
              final unpaidColor = isDark
                  ? Colors.orangeAccent
                  : const Color(0xFFC2410C);
              return Row(
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: accentGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '($khr)',
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? GlassTheme.primaryGreen.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPaid
                            ? accentGreen.withValues(alpha: 0.35)
                            : Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : (order['payment_status'] ?? 'UNPAID'),
                      style: textTheme.labelSmall?.copyWith(
                        color: isPaid ? accentGreen : unpaidColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (order['delivery_address_snapshot'] != null &&
              order['delivery_address_snapshot'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['delivery_address_snapshot'].toString(),
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
          if (assignedDriver != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, size: 18, color: accentGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver: ${assignedDriver['name'] ?? 'Assigned'}',
                          style: textTheme.labelMedium?.copyWith(
                            color: primaryText,
                          ),
                        ),
                        Text(
                          '${assignedDriver['vehicle_type'] ?? 'Motorbike'} • ${assignedDriver['license_plate'] ?? ''} • ${assignedDriver['phone'] ?? ''}',
                          style: textTheme.labelSmall?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryText,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(Icons.receipt_long, size: 16, color: accentGreen),
                  label: Text(
                    'View Bill',
                    style: textTheme.labelMedium?.copyWith(
                      color: primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _showRestaurantOrderBill(order),
                ),
              ),
              if (status == 'pending') ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => _restaurantRejectOrder(orderId),
                  child: Text(
                    'Reject',
                    style: textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? Colors.redAccent
                          : const Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    text: 'Accept',
                    icon: Icons.check,
                    onPressed: () => _restaurantAcceptOrder(orderId),
                  ),
                ),
              ] else if (status == 'confirmed' ||
                  status == 'driver_assigned' ||
                  status == 'driver_accepted') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    text: 'Start Prep',
                    icon: Icons.soup_kitchen,
                    onPressed: () => _startPreparing(orderId),
                  ),
                ),
              ] else if (status == 'preparing') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    text: 'Ready for Pickup',
                    icon: Icons.check_circle_outline,
                    onPressed: () => _readyForPickup(orderId),
                  ),
                ),
              ] else if (status == 'ready_for_pickup') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        size: 14,
                        color: isDark
                            ? Colors.blueAccent
                            : const Color(0xFF1D4ED8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Awaiting Driver',
                        style: textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? Colors.blueAccent
                              : const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  void _showRestaurantOrderBill(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final status = order['status']?.toString() ?? 'pending';
    final paymentStatus = order['payment_status']?.toString() ?? 'UNPAID';
    final total = order['total_amount']?.toString() ?? '0.00';
    final instructions = order['special_instructions']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final brightness = Theme.of(ctx).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(ctx).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final accentGreen = isDark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF15803D);
        final noteColor = isDark ? Colors.amber : const Color(0xFF92400E);
        final unpaidColor = isDark
            ? Colors.orangeAccent
            : const Color(0xFFC2410C);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? GlassTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Order Bill #FG-${order['id']}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: accentGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (instructions.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Note: $instructions',
                      style: textTheme.bodySmall?.copyWith(color: noteColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  'ITEMS ORDERED',
                  style: textTheme.labelSmall?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, sepIdx) => Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      height: 12,
                    ),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      final name =
                          it['food_name'] ?? 'Item #${it['food_item']}';
                      final qty = it['quantity'] ?? 1;
                      final price = it['price'] ?? '0.00';
                      final lineTotal =
                          ((double.tryParse(price.toString()) ?? 0.0) *
                                  (int.tryParse(qty.toString()) ?? 1))
                              .toStringAsFixed(2);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$qty x $name',
                              style: textTheme.bodyMedium?.copyWith(
                                color: primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$$lineTotal',
                            style: textTheme.labelLarge?.copyWith(
                              color: accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.12),
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Status:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                    Text(
                      paymentStatus,
                      style: textTheme.labelLarge?.copyWith(
                        color: paymentStatus == 'PAID'
                            ? accentGreen
                            : unpaidColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Bill:',
                      style: textTheme.titleMedium?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$$total',
                      style: textTheme.headlineSmall?.copyWith(
                        color: accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryText,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: accentGreen,
                        ),
                        label: Text(
                          'Copy Ticket TXT',
                          style: textTheme.labelMedium?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          final buffer = StringBuffer()
                            ..writeln(
                              '========================================',
                            )
                            ..writeln(
                              'FOODGO KITCHEN ORDER TICKET #FG-${order['id']}',
                            )
                            ..writeln(
                              '========================================',
                            )
                            ..writeln(
                              'Status         : ${status.toUpperCase()}',
                            )
                            ..writeln('Payment Status : $paymentStatus');
                          if (instructions.isNotEmpty) {
                            buffer.writeln('Special Note   : $instructions');
                          }
                          buffer.writeln(
                            '----------------------------------------',
                          );
                          buffer.writeln('ITEMS:');
                          for (final it in items) {
                            final name =
                                it['food_name'] ?? 'Item #${it['food_item']}';
                            final qty = it['quantity'] ?? 1;
                            final price = it['price'] ?? '0.00';
                            final lineTotal =
                                ((double.tryParse(price.toString()) ?? 0.0) *
                                        (int.tryParse(qty.toString()) ?? 1))
                                    .toStringAsFixed(2);
                            buffer.writeln(' - ${qty}x $name : \$$lineTotal');
                          }
                          buffer
                            ..writeln(
                              '----------------------------------------',
                            )
                            ..writeln('TOTAL BILL     : \$$total')
                            ..writeln(
                              '========================================',
                            );
                          Clipboard.setData(
                            ClipboardData(text: buffer.toString()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Kitchen Ticket TXT copied to clipboard!',
                              ),
                              backgroundColor: GlassTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        text: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _menuSearchQuery = '';
  int? _selectedMenuCatId;

  Widget _buildMenuTab() {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? GlassTheme.primaryGreenAccent
        : const Color(0xFF15803D);

    final query = _menuSearchQuery.trim().toLowerCase();
    final filteredMenu = _foodItems.where((item) {
      if (_selectedMenuCatId != null &&
          item['category_id'] != _selectedMenuCatId) {
        return false;
      }
      if (query.isEmpty) return true;
      final name = item['name']?.toString().toLowerCase() ?? '';
      final cat = item['category_name']?.toString().toLowerCase() ?? '';
      return name.contains(query) || cat.contains(query);
    }).toList();

    return Column(
      children: [
        // Modern Glowing "+ Add New Food Item" Action Button
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: GlassTheme.primaryGreen.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showAddFoodItemDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Food Item',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        if (_foodItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _menuSearchQuery = val),
              style: textTheme.bodyMedium?.copyWith(color: primaryText),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: 'Find menu item by name or category...',
                hintStyle: textTheme.bodySmall?.copyWith(color: secondaryText),
                prefixIcon: Icon(Icons.search, color: accentGreen, size: 18),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('All (${_foodItems.length})'),
                      selected: _selectedMenuCatId == null,
                      onSelected: (_) =>
                          setState(() => _selectedMenuCatId = null),
                    ),
                  ),
                  ..._categories.map((cat) {
                    final catId = cat['id'] as int?;
                    final catName = cat['name']?.toString() ?? 'Category';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(catName),
                        selected: _selectedMenuCatId == catId,
                        onSelected: (_) =>
                            setState(() => _selectedMenuCatId = catId),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),

        // List of items
        Expanded(
          child: RefreshIndicator(
            color: GlassTheme.primaryGreen,
            onRefresh: _fetchDashboardData,
            child: filteredMenu.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Text(
                          _foodItems.isEmpty
                              ? 'No food items on menu yet. Add one above!'
                              : 'No matching menu items found.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 650;
                      if (isWide) {
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 120,
                              ),
                          itemCount: filteredMenu.length,
                          itemBuilder: (context, index) {
                            final item = filteredMenu[index];
                            return _buildMenuItemCard(item);
                          },
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredMenu.length,
                        itemBuilder: (context, index) {
                          final item = filteredMenu[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: _buildMenuItemCard(item),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(dynamic item) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final bool isAvail = item['is_available'] ?? true;
    final double price =
        double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final khr = KhmerCurrency.formatKhr(price);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          // Squircle Thumbnail
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child:
                  item['image'] != null && item['image'].toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item['image'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlassTheme.primaryGreen,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: accentGreen,
                          size: 26,
                        ),
                      ),
                    )
                  : Container(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      child: Icon(
                        Icons.fastfood_rounded,
                        color: accentGreen,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['name'] ?? '',
                  style: textTheme.titleSmall?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['category_name'] ?? 'General',
                          style: textTheme.labelSmall?.copyWith(
                            color: secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '($khr)',
                      style: textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // In Stock / Sold Out toggle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.scale(
                scale: 0.78,
                child: Switch(
                  value: isAvail,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: Colors.white,
                  activeTrackColor: GlassTheme.primaryGreen,
                  inactiveThumbColor: isDark ? Colors.white60 : Colors.black54,
                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                  onChanged: (_) =>
                      _toggleItemAvailability(item['id'], isAvail),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAvail
                      ? GlassTheme.primaryGreen.withValues(alpha: 0.15)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAvail ? 'IN STOCK' : 'SOLD OUT',
                  style: textTheme.labelSmall?.copyWith(
                    color: isAvail
                        ? accentGreen
                        : (isDark ? Colors.redAccent : const Color(0xFFB91C1C)),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Dedicated StatefulWidget for the Add Food Item bottom sheet so that all
/// [TextEditingController] instances are disposed strictly in [State.dispose]
/// AFTER the modal route exit animation and keyboard dismissal complete.
class AddFoodItemBottomSheet extends StatefulWidget {
  final int restaurantId;
  final List<dynamic> categories;
  final ApiService api;

  const AddFoodItemBottomSheet({
    super.key,
    required this.restaurantId,
    required this.categories,
    required this.api,
  });

  @override
  State<AddFoodItemBottomSheet> createState() => _AddFoodItemBottomSheetState();
}

class _AddFoodItemBottomSheetState extends State<AddFoodItemBottomSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();
  final _descController = TextEditingController();
  final _ingController = TextEditingController();
  final _newCatController = TextEditingController();

  int? _selectedCatId;
  bool _isCreatingNewCat = false;
  bool _isSaving = false;
  String? _modalError;

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.categories.isNotEmpty
        ? widget.categories.first['id'] as int?
        : null;
    _isCreatingNewCat = widget.categories.isEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descController.dispose();
    _ingController.dispose();
    _newCatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final parsedPrice = double.tryParse(priceStr);
    if (name.isEmpty ||
        priceStr.isEmpty ||
        parsedPrice == null ||
        parsedPrice <= 0) {
      setState(() {
        _modalError =
            'Please enter a valid food item name and a price greater than \$0.00.';
      });
      return;
    }

    final normalizedImageUrl = ApiService.normalizeOptionalUrl(
      _imageController.text,
    );

    setState(() {
      _isSaving = true;
      _modalError = null;
    });

    try {
      int? catId = _selectedCatId;
      if (_isCreatingNewCat && _newCatController.text.trim().isNotEmpty) {
        final catRes = await widget.api.post('food-categories/', {
          'restaurant': widget.restaurantId,
          'name': _newCatController.text.trim(),
        });
        catId = catRes['id'] as int?;
      }

      if (catId == null) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _modalError = 'Please select or create a category.';
        });
        return;
      }

      await widget.api.post('food-items/', {
        'category': catId,
        'name': name,
        'price': parsedPrice.toStringAsFixed(2),
        'image_url': normalizedImageUrl,
        'description': _descController.text.trim(),
        'ingredients': _ingController.text.trim(),
        'is_available': true,
      });

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _modalError = ApiService.formatError(
          e,
          fallback:
              'Could not add menu item. Please check your inputs and try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);
    final accentGreen = isDark
        ? GlassTheme.primaryGreen
        : GlassTheme.primaryGreenDark;
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? GlassTheme.surfaceCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Food Item',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildInput(
                controller: _nameController,
                label: 'Food Item Name',
                icon: Icons.fastfood,
              ),
              const SizedBox(height: 14),

              if (!_isCreatingNewCat && widget.categories.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedCatId,
                  dropdownColor: isDark
                      ? GlassTheme.dropdownDark
                      : Colors.white,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: secondaryText),
                    prefixIcon: Icon(Icons.category, color: accentGreen),
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: widget.categories.map<DropdownMenuItem<int>>((cat) {
                    return DropdownMenuItem<int>(
                      value: cat['id'] as int?,
                      child: Text(
                        cat['name']?.toString() ?? 'Category',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: primaryText),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCatId = val),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: Icon(Icons.add, size: 16, color: accentGreen),
                  label: Text(
                    'Create New Category',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => setState(() => _isCreatingNewCat = true),
                ),
              ] else ...[
                _buildInput(
                  controller: _newCatController,
                  label: 'New Category Name (e.g. Burgers, Drinks)',
                  icon: Icons.create_new_folder,
                ),
                if (widget.categories.isNotEmpty)
                  TextButton(
                    child: Text(
                      'Choose from existing categories',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => setState(() => _isCreatingNewCat = false),
                  ),
              ],
              const SizedBox(height: 14),

              _buildInput(
                controller: _priceController,
                label: 'Price (USD, e.g. 7.50)',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 14),

              _buildInput(
                controller: _imageController,
                label: 'Image URL (Optional — paste link or leave blank)',
                icon: Icons.image_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildImagePresetChip(label: 'No Photo', url: ''),
                  _buildImagePresetChip(
                    label: 'Burger Photo',
                    url:
                        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop&q=80',
                  ),
                  _buildImagePresetChip(
                    label: 'Khmer Dish',
                    url:
                        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&auto=format&fit=crop&q=80',
                  ),
                  _buildImagePresetChip(
                    label: 'Drink / Cafe',
                    url:
                        'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=600&auto=format&fit=crop&q=80',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildInput(
                controller: _descController,
                label: 'Description',
                icon: Icons.notes,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _buildInput(
                controller: _ingController,
                label: 'Ingredients (comma separated)',
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 24),

              if (_modalError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _modalError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? Colors.redAccent
                                    : const Color(0xFFB91C1C),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              SizedBox(
                height: 52,
                child: GlassButton(
                  text: _isSaving ? 'Adding Item...' : 'Save & Add to Menu',
                  icon: _isSaving ? Icons.hourglass_top : Icons.check,
                  onPressed: _isSaving ? () {} : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePresetChip({required String label, required String url}) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final isSelected = _imageController.text.trim() == url;
    final accentGreen = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    return InkWell(
      onTap: () => setState(() => _imageController.text = url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? GlassTheme.primaryGreen.withValues(alpha: 0.2)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentGreen
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected
                ? accentGreen
                : AppTypography.secondaryTextColor(brightness),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTypography.primaryTextColor(brightness),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTypography.secondaryTextColor(brightness),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RestaurantRejectOrderDialog extends StatefulWidget {
  const _RestaurantRejectOrderDialog();

  @override
  State<_RestaurantRejectOrderDialog> createState() =>
      _RestaurantRejectOrderDialogState();
}

class _RestaurantRejectOrderDialogState
    extends State<_RestaurantRejectOrderDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      title: Text(
        'Reject Order',
        style: textTheme.titleLarge?.copyWith(
          color: primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please provide a rejection reason (prepaid orders are automatically refunded):',
            style: textTheme.bodySmall?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'e.g., Kitchen at full capacity',
              hintStyle: textTheme.bodySmall?.copyWith(color: secondaryText),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                ),
              ),
            ),
            style: textTheme.bodyMedium?.copyWith(color: primaryText),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(color: secondaryText),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            minimumSize: const Size(130, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () =>
              Navigator.pop(context, _reasonController.text.trim()),
          child: Text(
            'Reject & Refund',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
