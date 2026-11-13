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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);

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
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeaderCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);
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
                        ? GlassTheme.primaryGreen
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
                      ? const Icon(
                          Icons.storefront_rounded,
                          size: 28,
                          color: GlassTheme.primaryGreen,
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
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: GlassTheme.primaryGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: secondaryText,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                Container(
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
                          ? GlassTheme.primaryGreen.withValues(alpha: 0.4)
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
                          color: isActive
                              ? GlassTheme.primaryGreen
                              : Colors.redAccent,
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
                      Text(
                        isActive ? 'ACCEPTING ORDERS' : 'STORE CLOSED',
                        style: TextStyle(
                          color: isActive
                              ? GlassTheme.primaryGreen
                              : Colors.redAccent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  isActive ? 'Live' : 'Paused',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
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
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.fastfood_rounded,
                  label: 'Menu Items',
                  value: '${_foodItems.length}',
                  color: GlassTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Orders',
                  value: '${_orders.length}',
                  color: const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.star_rounded,
                  label: 'Store Rating',
                  value: rating.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildOrdersEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);

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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.soup_kitchen_rounded,
                      size: 40,
                      color: GlassTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kitchen is Ready & Waiting',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New customer orders will appear here in real-time. Keep your portal active to prepare fresh orders promptly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                      height: 1.4,
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
                        color: GlassTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: GlassTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Listening for incoming tickets...',
                          style: TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;

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
                      style: TextStyle(color: GlassTheme.textMuted),
                    ),
                  )
                : ResponsiveWebContainer(
                    maxWidth: 1050,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Restaurant Header Card
                          _buildRestaurantHeaderCard(),
                          const SizedBox(height: 16),

                          // Modern Glass Pill Tab Selector
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
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
                                    color: GlassTheme.primaryGreen.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: isDark
                                  ? Colors.white70
                                  : const Color(0xFF374151),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5,
                              ),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_rounded,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 7),
                                      const Text('Orders'),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.22,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${_orders.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 7),
                                      const Text('Menu'),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.22,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${_foodItems.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                          const SizedBox(height: 16),

                          // Tab Views
                          Expanded(
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
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return _buildOrdersEmptyState();
    }
    return RefreshIndicator(
      color: GlassTheme.primaryGreen,
      onRefresh: _fetchDashboardData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;
          if (isWide) {
            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 260,
              ),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildRestaurantOrderCard(order);
              },
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildRestaurantOrderCard(order),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRestaurantOrderCard(dynamic order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);
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
              Row(
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
                  Text(
                    'Order #$orderId',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
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
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
              return Row(
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: GlassTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($khr)',
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),
                  const Spacer(),
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
                            ? GlassTheme.primaryGreen.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : (order['payment_status'] ?? 'UNPAID'),
                      style: TextStyle(
                        color: isPaid
                            ? GlassTheme.primaryGreen
                            : Colors.orangeAccent,
                        fontSize: 10.5,
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
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: secondaryText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['delivery_address_snapshot'].toString(),
                    style: TextStyle(color: secondaryText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  const Icon(
                    Icons.delivery_dining,
                    size: 18,
                    color: GlassTheme.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver: ${assignedDriver['name'] ?? 'Assigned'}',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${assignedDriver['vehicle_type'] ?? 'Motorbike'} • ${assignedDriver['license_plate'] ?? ''} • ${assignedDriver['phone'] ?? ''}',
                          style: TextStyle(color: secondaryText, fontSize: 11),
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
                  icon: const Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: GlassTheme.primaryGreen,
                  ),
                  label: const Text(
                    'View Bill',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Awaiting Driver',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueAccent,
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
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
        final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);
        final mutedText = isDark ? Colors.white54 : const Color(0xFF6B7280);
        final accentGreen = isDark
            ? GlassTheme.primaryGreen
            : GlassTheme.primaryGreenDark;
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
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                        style: TextStyle(
                          color: accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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
                      style: TextStyle(color: noteColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  'ITEMS ORDERED',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$$lineTotal',
                            style: TextStyle(
                              color: accentGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                      style: TextStyle(color: secondaryText),
                    ),
                    Text(
                      paymentStatus,
                      style: TextStyle(
                        color: paymentStatus == 'PAID'
                            ? accentGreen
                            : unpaidColor,
                        fontWeight: FontWeight.bold,
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
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$$total',
                      style: TextStyle(
                        color: accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                        label: const Text(
                          'Copy Ticket TXT',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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

  Widget _buildMenuTab() {
    return Column(
      children: [
        // Modern Glowing "+ Add New Food Item" Action Button
        Container(
          width: double.infinity,
          height: 50,
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add New Food Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 14),

        // List of items
        Expanded(
          child: RefreshIndicator(
            color: GlassTheme.primaryGreen,
            onRefresh: _fetchDashboardData,
            child: _foodItems.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          'No food items on menu yet. Add one above!',
                          style: TextStyle(color: GlassTheme.textMuted),
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
                                mainAxisExtent: 108,
                              ),
                          itemCount: _foodItems.length,
                          itemBuilder: (context, index) {
                            final item = _foodItems[index];
                            return _buildMenuItemCard(item);
                          },
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _foodItems.length,
                        itemBuilder: (context, index) {
                          final item = _foodItems[index];
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);
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
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: GlassTheme.primaryGreen,
                          size: 26,
                        ),
                      ),
                    )
                  : Container(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: GlassTheme.primaryGreen,
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
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
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
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '($khr)',
                      style: TextStyle(color: secondaryText, fontSize: 11),
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
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isAvail ? GlassTheme.primaryGreen : Colors.redAccent,
                    fontWeight: FontWeight.bold,
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
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: secondaryText),
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
                        style: TextStyle(color: primaryText),
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
                    style: TextStyle(
                      color: accentGreen,
                      fontSize: 12,
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
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 12,
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
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _imageController.text.trim() == url;
    final accentGreen = isDark
        ? GlassTheme.primaryGreen
        : GlassTheme.primaryGreenDark;
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
          style: TextStyle(
            color: isSelected
                ? accentGreen
                : (isDark ? Colors.white70 : const Color(0xFF374151)),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : GlassTheme.textInverseDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? GlassTheme.textMuted : const Color(0xFF4B5563),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? GlassTheme.primaryGreen : GlassTheme.primaryGreenDark,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF4B5563);

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
        style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please provide a rejection reason (prepaid orders are automatically refunded):',
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'e.g., Kitchen at full capacity',
              hintStyle: TextStyle(
                color: isDark ? GlassTheme.textMuted : const Color(0xFF6B7280),
              ),
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
            style: TextStyle(color: primaryText),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: secondaryText)),
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
          child: const Text(
            'Reject & Refund',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
