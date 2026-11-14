import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/khmer_currency.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass/glass_widgets.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/responsive_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _orderSearchCtrl = TextEditingController();
  final TextEditingController _paymentSearchCtrl = TextEditingController();
  final TextEditingController _userSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  void _loadAllData() {
    final admin = context.read<AdminProvider>();
    admin.fetchAnalytics();
    admin.fetchOrders();
    admin.fetchPayments();
    admin.fetchUsers();
    admin.fetchRestaurants();
    admin.fetchAuditLogs();
    admin.fetchDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderSearchCtrl.dispose();
    _paymentSearchCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  void _confirmLogout(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.dialogDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        title: Text(
          'Admin Log Out',
          style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out of the Admin Console?',
          style: TextStyle(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: secondaryText)),
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: 'Admin Console',
          leading: IconButton(
            icon: Icon(
              AppIcons.back,
              size: 18,
              color: isDark
                  ? GlassTheme.dynamicPrimaryColor
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: Icon(
                AppIcons.refresh,
                color: isDark
                    ? GlassTheme.dynamicPrimaryColor
                    : Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Refresh Data',
              onPressed: _loadAllData,
            ),
            IconButton(
              icon: const Icon(AppIcons.logout, color: Colors.redAccent),
              tooltip: 'Log Out',
              onPressed: () => _confirmLogout(context),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(12),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: secondaryText,
            tabs: const [
              Tab(icon: Icon(AppIcons.admin), text: 'Overview'),
              Tab(icon: Icon(AppIcons.orders), text: 'Orders'),
              Tab(icon: Icon(AppIcons.payment), text: 'Payments'),
              Tab(icon: Icon(AppIcons.users), text: 'Users'),
              Tab(icon: Icon(AppIcons.restaurants), text: 'Restaurants'),
              Tab(icon: Icon(AppIcons.security), text: 'Audit Logs'),
            ],
          ),
        ),
        body: SafeArea(
          child: ResponsiveWebContainer(
            maxWidth: 1200,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrdersTab(),
                _buildPaymentsTab(),
                _buildUsersTab(),
                _buildRestaurantsTab(),
                _buildAuditLogsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 1. OVERVIEW & ANALYTICS TAB
  // ─────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.analytics == null) {
          return Center(
            child: CircularProgressIndicator(
              color: GlassTheme.dynamicPrimaryColor,
            ),
          );
        }

        final analytics = admin.analytics;
        final metrics = analytics?['metrics'] as Map<String, dynamic>? ?? {};
        final health =
            analytics?['system_health'] as Map<String, dynamic>? ?? {};
        final distribution =
            analytics?['order_status_distribution'] as Map<String, dynamic>? ??
            {};

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final blueAccent = isDark
            ? Colors.lightBlueAccent
            : const Color(0xFF0369A1);
        final amberAccent = isDark
            ? Colors.amberAccent
            : const Color(0xFFB45309);
        final purpleAccent = isDark
            ? Colors.purpleAccent
            : const Color(0xFF7E22CE);

        return RefreshIndicator(
          color: GlassTheme.dynamicPrimaryColor,
          backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
          onRefresh: () => admin.fetchAnalytics(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period Filter Selector
              _buildPeriodSelector(admin).motionEntrance(staggerIndex: 0),
              const SizedBox(height: 16),

              // System Health Badge Card
              _buildSystemHealthCard(health).motionEntrance(staggerIndex: 1),
              const SizedBox(height: 16),

              // Key Metrics 2x2 Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Revenue',
                      value: '\$${metrics['total_revenue_usd'] ?? '0.00'}',
                      subtitle: metrics['total_revenue_khr'] ?? '0 KHR',
                      icon: AppIcons.payment,
                      accentColor: GlassTheme.dynamicPrimaryColor,
                      onTap: () => _tabController.animateTo(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Orders',
                      value: '${metrics['total_orders'] ?? 0}',
                      subtitle: '${metrics['completed_orders'] ?? 0} Completed',
                      icon: AppIcons.cart,
                      accentColor: blueAccent,
                      onTap: () => _tabController.animateTo(1),
                    ),
                  ),
                ],
              ).motionEntrance(staggerIndex: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Drivers',
                      value: '${metrics['active_drivers'] ?? 0}',
                      subtitle: '${metrics['total_drivers'] ?? 0} Registered',
                      icon: AppIcons.delivery,
                      accentColor: amberAccent,
                      onTap: () {
                        _tabController.animateTo(3);
                        admin.fetchUsers(role: 'driver');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Customers',
                      value: '${metrics['active_customers'] ?? 0}',
                      subtitle: '${metrics['total_customers'] ?? 0} Registered',
                      icon: AppIcons.users,
                      accentColor: purpleAccent,
                      onTap: () {
                        _tabController.animateTo(3);
                        admin.fetchUsers(role: 'customer');
                      },
                    ),
                  ),
                ],
              ).motionEntrance(staggerIndex: 3),
              const SizedBox(height: 20),

              // Order Status Pipeline Card
              _buildStatusPipelineCard(
                distribution,
              ).motionEntrance(staggerIndex: 4),
              const SizedBox(height: 20),

              // Live Delivery Operations & Courier Fleet
              _buildDeliveryFleetCard(
                metrics,
                distribution,
              ).motionEntrance(staggerIndex: 5),
              const SizedBox(height: 20),

              // Recent Activity Feed
              _buildRecentOrdersSection(
                analytics?['recent_orders'] as List<dynamic>? ?? [],
              ).motionEntrance(staggerIndex: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(AdminProvider admin) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final periods = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'week', 'label': '7 Days'},
      {'key': 'month', 'label': '30 Days'},
      {'key': 'all', 'label': 'All Time'},
    ];

    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((p) {
          final isSelected = admin.selectedPeriod == p['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['label']!),
              selected: isSelected,
              onSelected: (_) => admin.fetchAnalytics(period: p['key']),
              selectedColor: GlassTheme.dynamicPrimaryColor,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.85),
              labelStyle: textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : primaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? GlassTheme.dynamicPrimaryColor
                    : (isDark
                          ? Colors.white12
                          : secondaryText.withValues(alpha: 0.25)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemHealthCard(Map<String, dynamic> health) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final isHealthy = health['database'] == 'healthy';
    final statusColor = isHealthy
        ? (isDark ? Colors.greenAccent : const Color(0xFF15803D))
        : (isDark ? Colors.redAccent : const Color(0xFFB91C1C));
    final dbEngine = health['database_engine']?.toString() ?? 'Database';

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: statusColor,
              size: 22,
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
                        'System & Core Health',
                        style: textTheme.bodyLarge?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHealthy ? 'OPERATIONAL' : 'DEGRADED',
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dbEngine: ${health['database'] ?? 'OK'} · ASGI Daphne: ${health['daphne_asgi'] ?? 'Running'}',
                  style: textTheme.bodySmall?.copyWith(color: secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final card = GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(color: secondaryText),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: GlassTheme.borderRadiusMedium,
      child: card,
    );
  }

  Widget _buildStatusPipelineCard(Map<String, dynamic> distribution) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final statuses = [
      {
        'key': 'pending',
        'label': 'Pending',
        'color': isDark ? Colors.amberAccent : const Color(0xFFB45309),
      },
      {
        'key': 'preparing',
        'label': 'Preparing',
        'color': isDark ? Colors.lightBlueAccent : const Color(0xFF0369A1),
      },
      {
        'key': 'on_the_way',
        'label': 'In Transit',
        'color': isDark ? Colors.purpleAccent : const Color(0xFF7E22CE),
      },
      {
        'key': 'delivered',
        'label': 'Delivered',
        'color': isDark ? Colors.greenAccent : const Color(0xFF15803D),
      },
      {
        'key': 'cancelled',
        'label': 'Cancelled',
        'color': isDark ? Colors.redAccent : const Color(0xFFB91C1C),
      },
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Status Breakdown',
                style: textTheme.bodyLarge?.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Tap status to filter',
                style: textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: statuses.map((s) {
              final count = distribution[s['key']] ?? 0;
              final color = s['color'] as Color;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    _tabController.animateTo(1);
                    context.read<AdminProvider>().fetchOrders(
                      status: s['key'] as String,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: textTheme.titleLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s['label'] as String,
                          style: textTheme.labelSmall?.copyWith(
                            color: secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryFleetCard(
    Map<String, dynamic> metrics,
    Map<String, dynamic> distribution,
  ) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final tileBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    final tileBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : GlassTheme.borderLight;
    final greenColor = isDark ? Colors.greenAccent : const Color(0xFF15803D);
    final amberColor = isDark ? Colors.amberAccent : const Color(0xFFB45309);
    final purpleColor = isDark ? Colors.purpleAccent : const Color(0xFF7E22CE);
    final outlinedAccent = isDark
        ? GlassTheme.dynamicPrimaryColor
        : HSLColor.fromColor(
            GlassTheme.dynamicPrimaryColor,
          ).withLightness(0.32).toColor();

    final activeDrivers = metrics['active_drivers'] ?? 0;
    final totalDrivers = metrics['total_drivers'] ?? 0;
    final inTransit = distribution['on_the_way'] ?? 0;
    final pending = distribution['pending'] ?? 0;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: amberColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delivery_dining_rounded,
                  color: amberColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Delivery & Courier Fleet',
                      style: textTheme.bodyLarge?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time dispatch overview & courier readiness',
                      style: textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (activeDrivers as num) > 0
                      ? greenColor.withValues(alpha: 0.15)
                      : amberColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activeDrivers > 0 ? greenColor : amberColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$activeDrivers Online',
                      style: textTheme.labelSmall?.copyWith(
                        color: activeDrivers > 0 ? greenColor : amberColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tileBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COURIERS',
                        style: textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeDrivers / $totalDrivers',
                        style: textTheme.titleMedium?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to ride',
                        style: textTheme.labelSmall?.copyWith(
                          color: greenColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tileBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ON ROAD',
                        style: textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$inTransit',
                        style: textTheme.titleMedium?.copyWith(
                          color: purpleColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'In transit',
                        style: textTheme.labelSmall?.copyWith(
                          color: purpleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (pending as num) > 0
                        ? amberColor.withValues(alpha: 0.08)
                        : tileBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pending > 0
                          ? amberColor.withValues(alpha: 0.3)
                          : tileBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISPATCH',
                        style: textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pending',
                        style: textTheme.titleMedium?.copyWith(
                          color: pending > 0 ? amberColor : primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pending > 0 ? 'Needs courier' : 'All dispatched',
                        style: textTheme.labelSmall?.copyWith(
                          color: pending > 0 ? amberColor : secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: outlinedAccent,
                    side: BorderSide(
                      color: outlinedAccent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: Text(
                    'Manage Couriers',
                    style: textTheme.bodySmall?.copyWith(
                      color: outlinedAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    _tabController.animateTo(3);
                    context.read<AdminProvider>().fetchUsers(role: 'driver');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.dynamicPrimaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: Text(
                    'Dispatch Orders',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: () {
                    _tabController.animateTo(1);
                    context.read<AdminProvider>().fetchOrders(
                      status: 'unassigned',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(List<dynamic> recentOrders) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final amountAccent = isDark
        ? GlassTheme.dynamicPrimaryColor
        : HSLColor.fromColor(
            GlassTheme.dynamicPrimaryColor,
          ).withLightness(0.32).toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Recent Orders',
          style: textTheme.bodyLarge?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (recentOrders.isEmpty)
          Text(
            'No recent orders logged.',
            style: textTheme.bodyMedium?.copyWith(color: secondaryText),
          )
        else
          ...recentOrders.map((o) {
            final statusStr = o['status'] ?? 'pending';
            Color badgeColor = isDark ? Colors.amber : const Color(0xFFB45309);
            if (statusStr == 'delivered') {
              badgeColor = isDark ? Colors.green : const Color(0xFF15803D);
            }
            if (statusStr == 'cancelled') {
              badgeColor = isDark ? Colors.red : const Color(0xFFB91C1C);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : GlassTheme.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_outlined,
                      color: badgeColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${o['reference']} · ${o['restaurant']}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Customer: ${o['customer']}',
                          style: textTheme.labelSmall?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        o['amount'] ?? '\$0.00',
                        style: textTheme.labelLarge?.copyWith(
                          color: amountAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusStr.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 2. ORDERS MANAGEMENT TAB
  // ─────────────────────────────────────────────
  Widget _buildOrdersTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final orders = admin.orders;

        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);

        return Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _orderSearchCtrl,
                    style: textTheme.bodyMedium?.copyWith(color: primaryText),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search order ref, customer, phone...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: GlassTheme.dynamicPrimaryColor,
                        size: 20,
                      ),
                      suffixIcon: _orderSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: secondaryText,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() => _orderSearchCtrl.clear());
                                admin.fetchOrders(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: GlassTheme.dynamicPrimaryColor,
                        ),
                      ),
                    ),
                    onSubmitted: (val) => admin.fetchOrders(search: val),
                  ),
                  const SizedBox(height: 12),
                  _buildOrderStatusFilters(admin),
                ],
              ),
            ),

            // Order List
            Expanded(
              child: admin.isLoading && orders.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: GlassTheme.dynamicPrimaryColor,
                      ),
                    )
                  : RefreshIndicator(
                      color: GlassTheme.dynamicPrimaryColor,
                      backgroundColor: isDark
                          ? GlassTheme.heroDarkCard
                          : Colors.white,
                      onRefresh: () => admin.fetchOrders(),
                      child: orders.isEmpty
                          ? Center(
                              child: Text(
                                'No matching orders found',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: secondaryText,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: orders.length,
                              itemBuilder: (context, idx) {
                                final order =
                                    orders[idx] as Map<String, dynamic>;
                                return _buildOrderCard(order, admin);
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderStatusFilters(AdminProvider admin) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final selectedOnPrimary =
        GlassTheme.dynamicPrimaryColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'unassigned', 'label': 'Needs Driver'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'preparing', 'label': 'Preparing'},
      {'key': 'on_the_way', 'label': 'On Way'},
      {'key': 'delivered', 'label': 'Delivered'},
      {'key': 'cancelled', 'label': 'Cancelled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = admin.orderStatusFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => admin.fetchOrders(status: f['key']),
              selectedColor: GlassTheme.dynamicPrimaryColor,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.88),
              labelStyle: textTheme.bodySmall?.copyWith(
                color: isSelected ? selectedOnPrimary : secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? GlassTheme.dynamicPrimaryColor
                    : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, AdminProvider admin) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentColor = isDark
        ? GlassTheme.dynamicPrimaryColor
        : HSLColor.fromColor(
            GlassTheme.dynamicPrimaryColor,
          ).withLightness(0.32).toColor();
    final blueActionColor = isDark
        ? Colors.blueAccent
        : const Color(0xFF1D4ED8);
    final redActionColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);

    final statusStr = order['status'] ?? 'pending';
    final paymentStatus = order['payment_status'] ?? 'UNPAID';
    final driver = order['assigned_driver'] as Map<String, dynamic>?;
    final customer = order['customer_info'] as Map<String, dynamic>?;
    final address =
        order['delivery_address_snapshot'] ??
        (order['address'] is Map ? order['address']['street'] : null) ??
        'Phnom Penh';
    final deliveryFee =
        order['delivery_fee_charged'] ?? order['delivery_fee'] ?? '2.00';
    final totalVal =
        double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;

    Color statusColor = isDark ? Colors.amber : const Color(0xFFB45309);
    if (statusStr == 'delivered') {
      statusColor = isDark ? Colors.greenAccent : const Color(0xFF15803D);
    }
    if (statusStr == 'cancelled') statusColor = redActionColor;
    if (statusStr == 'on_the_way') {
      statusColor = isDark ? Colors.purpleAccent : const Color(0xFF7E22CE);
    }
    if (statusStr == 'preparing') {
      statusColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0369A1);
    }

    final amberTextColor = isDark ? Colors.amber : const Color(0xFFB45309);
    final greenTextColor = isDark
        ? Colors.greenAccent
        : const Color(0xFF15803D);
    final orangeTextColor = isDark
        ? Colors.orangeAccent
        : const Color(0xFFC2410C);
    final isPaid = paymentStatus == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              driver == null &&
                  statusStr != 'delivered' &&
                  statusStr != 'cancelled'
              ? Colors.amber.withValues(alpha: isDark ? 0.3 : 0.5)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order['order_reference'] ?? 'Order #${order['id']}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusStr.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: secondaryText, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Restaurant: ${order['restaurant_name'] ?? 'N/A'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (customer != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, color: secondaryText, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Customer: ${customer['name']} (${customer['phone'] ?? ''})',
                    style: textTheme.bodySmall?.copyWith(color: secondaryText),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: redActionColor, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Deliver to: $address',
                  style: textTheme.bodySmall?.copyWith(color: secondaryText),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    'Total: \$${order['total_amount']}',
                    style: textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '≈ ${KhmerCurrency.formatKhr(totalVal)}',
                    style: textTheme.labelSmall?.copyWith(color: secondaryText),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withValues(alpha: 0.16)
                      : Colors.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'PAYMENT: PAID' : 'PAYMENT: DUE',
                  style: textTheme.labelSmall?.copyWith(
                    color: isPaid ? greenTextColor : orangeTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Courier Section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: driver != null
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03))
                  : Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: driver != null
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFE2E8F0))
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  driver != null
                      ? Icons.two_wheeler_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: driver != null ? greenTextColor : amberTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver != null
                            ? 'Courier: ${driver['name']} (${driver['license_plate'] ?? 'Plate PP'})'
                            : 'No courier assigned yet',
                        style: textTheme.bodySmall?.copyWith(
                          color: driver != null ? primaryText : amberTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Delivery Fee: \$$deliveryFee · ${driver != null ? (driver['phone'] ?? 'Active') : 'Waiting for dispatch'}',
                        style: textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (statusStr != 'delivered' && statusStr != 'cancelled') ...[
                  ElevatedButton(
                    onPressed: () =>
                        _showAssignDriverDialog(order['id'], admin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: driver != null
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06))
                          : GlassTheme.dynamicPrimaryColor,
                      foregroundColor: driver != null
                          ? primaryText
                          : (GlassTheme.dynamicPrimaryColor.computeLuminance() >
                                    0.45
                                ? Colors.black
                                : Colors.white),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      driver != null ? 'Reassign' : 'Assign Driver',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (statusStr != 'delivered' && statusStr != 'cancelled') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blueActionColor,
                    side: BorderSide(color: blueActionColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 13),
                  label: Text(
                    'Live Route',
                    style: textTheme.labelSmall?.copyWith(
                      color: blueActionColor,
                    ),
                  ),
                  onPressed: () =>
                      context.push('/map/${order['id']}?isDriver=false'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showCancelOrderDialog(order['id'], admin),
                  style: TextButton.styleFrom(
                    foregroundColor: redActionColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Cancel',
                    style: textTheme.labelSmall?.copyWith(
                      color: redActionColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignDriverDialog(int orderId, AdminProvider admin) {
    final drivers = <Map<String, dynamic>>[];

    // 1. From admin.drivers
    for (final d in admin.drivers) {
      if (d is Map<String, dynamic>) {
        final u = d['user'] is Map ? d['user'] : {};
        drivers.add({
          'id': d['id'],
          'name': u['full_name'] ?? u['username'] ?? 'Courier #${d['id']}',
          'username': u['username'] ?? '',
          'vehicle': d['vehicle_type'] ?? 'Motorcycle',
          'plate': d['license_plate'] ?? 'PP-2026',
          'is_online': d['is_online'] == true,
          'phone': u['phone'] ?? d['phone'] ?? '+855 23 999 888',
        });
      }
    }

    // 2. From admin.users
    if (drivers.isEmpty) {
      for (final u in admin.users) {
        if (u is Map<String, dynamic> && u['role'] == 'driver') {
          final info = u['driver_info'] as Map<String, dynamic>?;
          final driverId = info?['driver_id'] ?? u['id'];
          drivers.add({
            'id': driverId,
            'name':
                u['first_name'] != null && u['first_name'].toString().isNotEmpty
                ? '${u['first_name']} ${u['last_name'] ?? ''}'.trim()
                : u['username'] ?? 'Courier',
            'username': u['username'] ?? '',
            'vehicle': info?['vehicle_type'] ?? 'Motorcycle',
            'plate': info?['license_plate'] ?? 'PP-2026',
            'is_online': info?['is_online'] == true,
            'phone': u['phone'] ?? '+855 23 999 888',
          });
        }
      }
    }

    // 3. Fallback registered couriers if none populated yet
    if (drivers.isEmpty) {
      drivers.addAll([
        {
          'id': 1,
          'name': 'Bob Rider',
          'username': 'driver1',
          'vehicle': 'Honda Click 125i',
          'plate': 'PP-1AB-2026',
          'is_online': true,
          'phone': '+855 77 333 444',
        },
        {
          'id': 2,
          'name': 'Sophea Swift',
          'username': 'driver2',
          'vehicle': 'Yamaha Scoopy',
          'plate': 'PP-2CD-2026',
          'is_online': true,
          'phone': '+855 12 888 999',
        },
      ]);
    }

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final greenBadgeColor = isDark
        ? Colors.greenAccent
        : const Color(0xFF15803D);
    final accentColor = isDark
        ? GlassTheme.dynamicPrimaryColor
        : HSLColor.fromColor(
            GlassTheme.dynamicPrimaryColor,
          ).withLightness(0.32).toColor();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.two_wheeler_rounded, color: accentColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Assign Courier Driver',
                  style: textTheme.titleMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select an available registered courier to dispatch this delivery:',
                  style: textTheme.bodyMedium?.copyWith(color: secondaryText),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: drivers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final d = drivers[i];
                      final isOnline = d['is_online'] == true;
                      return Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOnline
                                ? greenBadgeColor.withValues(alpha: 0.35)
                                : (isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isOnline
                                ? greenBadgeColor.withValues(alpha: 0.15)
                                : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.06)),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: isOnline ? greenBadgeColor : secondaryText,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  d['name'],
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? greenBadgeColor.withValues(alpha: 0.18)
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.06,
                                              )),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOnline ? 'ONLINE' : 'OFFLINE',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: isOnline
                                        ? greenBadgeColor
                                        : secondaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${d['vehicle']} · ${d['plate']} · ${d['phone']}',
                            style: textTheme.labelSmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                          trailing: Icon(
                            Icons.check_circle_outline_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.of(ctx).pop();
                            final ok = await admin.assignDriver(
                              orderId,
                              d['id'] as int,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Courier ${d['name']} assigned to Order #$orderId.'
                                      : (admin.errorMessage ??
                                            'Failed to assign courier.'),
                                ),
                                backgroundColor: ok
                                    ? const Color(0xFF15803D)
                                    : Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(color: secondaryText),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancelOrderDialog(int orderId, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) => _AdminCancelOrderDialog(orderId: orderId, admin: admin),
    );
  }

  // ─────────────────────────────────────────────
  // 3. PAYMENTS & TRANSACTIONS MANAGEMENT TAB
  // ─────────────────────────────────────────────
  Widget _buildPaymentsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final payments = admin.payments;

        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _paymentSearchCtrl,
                    style: textTheme.bodyMedium?.copyWith(color: primaryText),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by Order Ref, Txn ID, or Customer...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: GlassTheme.dynamicPrimaryColor,
                        size: 20,
                      ),
                      suffixIcon: _paymentSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: secondaryText,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() => _paymentSearchCtrl.clear());
                                admin.fetchPayments(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: GlassTheme.dynamicPrimaryColor,
                        ),
                      ),
                    ),
                    onSubmitted: (val) => admin.fetchPayments(search: val),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentStatusFilters(admin),
                ],
              ),
            ),

            // Payments List
            Expanded(
              child: admin.isLoading && payments.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: GlassTheme.dynamicPrimaryColor,
                      ),
                    )
                  : RefreshIndicator(
                      color: GlassTheme.dynamicPrimaryColor,
                      backgroundColor: isDark
                          ? GlassTheme.heroDarkCard
                          : Colors.white,
                      onRefresh: () => admin.fetchPayments(),
                      child: payments.isEmpty
                          ? Center(
                              child: Text(
                                'No matching payment transactions found',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: secondaryText,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: payments.length,
                              itemBuilder: (context, idx) {
                                final payment =
                                    payments[idx] as Map<String, dynamic>;
                                return _buildPaymentCard(payment, admin);
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentStatusFilters(AdminProvider admin) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final selectedOnPrimary =
        GlassTheme.dynamicPrimaryColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'PAID', 'label': 'Paid'},
      {'key': 'PENDING', 'label': 'Pending'},
      {'key': 'EXPIRED', 'label': 'Expired'},
      {'key': 'FAILED', 'label': 'Failed'},
      {'key': 'CANCELLED', 'label': 'Cancelled'},
      {'key': 'REFUNDED', 'label': 'Refunded'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = admin.paymentStatusFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => admin.fetchPayments(status: f['key']),
              selectedColor: GlassTheme.dynamicPrimaryColor,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.88),
              labelStyle: textTheme.bodySmall?.copyWith(
                color: isSelected ? selectedOnPrimary : secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? GlassTheme.dynamicPrimaryColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFCBD5E1)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, AdminProvider admin) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final accentColor = isDark
        ? GlassTheme.dynamicPrimaryColor
        : HSLColor.fromColor(
            GlassTheme.dynamicPrimaryColor,
          ).withLightness(0.32).toColor();

    final status = (payment['status'] as String? ?? 'PENDING').toUpperCase();
    final provider = (payment['provider'] as String? ?? 'KHQR').toUpperCase();
    final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
    final currency = payment['currency']?.toString() ?? 'USD';
    final txnId = payment['transaction_id']?.toString() ?? 'Pending';
    final merchantRef = payment['merchant_reference']?.toString() ?? 'N/A';
    final orderRef =
        payment['order_reference']?.toString() ?? 'Order #${payment['order']}';
    final customer = payment['customer_username']?.toString() ?? 'Customer';
    final createdAt = payment['created_at']?.toString() ?? '';

    final purpleColor = isDark ? Colors.purpleAccent : const Color(0xFF7E22CE);
    final dangerColor = isDark ? Colors.redAccent : const Color(0xFFB91C1C);
    Color statusColor;
    switch (status) {
      case 'PAID':
        statusColor = isDark ? Colors.greenAccent : const Color(0xFF15803D);
        break;
      case 'PENDING':
        statusColor = isDark ? Colors.orangeAccent : const Color(0xFFC2410C);
        break;
      case 'EXPIRED':
      case 'FAILED':
        statusColor = dangerColor;
        break;
      case 'REFUNDED':
        statusColor = purpleColor;
        break;
      default:
        statusColor = secondaryText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? GlassTheme.heroDarkCard
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.payment, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment #${payment['id']} · $provider',
                            style: textTheme.bodyLarge?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$orderRef · $customer',
                            style: textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authoritative Amount',
                    style: textTheme.labelSmall?.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${amount.toStringAsFixed(2)}',
                    style: textTheme.titleLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Transaction Ref',
                    style: textTheme.labelSmall?.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txnId.length > 18 ? '${txnId.substring(0, 16)}...' : txnId,
                    style: textTheme.bodySmall?.copyWith(
                      color: primaryText,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ref: $merchantRef · ${createdAt.length > 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt}',
            style: textTheme.labelSmall?.copyWith(color: secondaryText),
          ),
          if (status == 'PAID') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: purpleColor,
                  side: BorderSide(color: purpleColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.undo, size: 16),
                label: Text(
                  'Issue Refund',
                  style: textTheme.bodySmall?.copyWith(
                    color: purpleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _showRefundDialog(context, payment, admin),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRefundDialog(
    BuildContext context,
    Map<String, dynamic> payment,
    AdminProvider admin,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AdminRefundDialog(
        payment: payment,
        admin: admin,
        onCompleted: (bool success) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Refund for Payment #${payment['id']} processed successfully.'
                    : 'Failed to process refund: ${admin.errorMessage}',
              ),
              backgroundColor: success
                  ? Theme.of(context).colorScheme.primary
                  : Colors.redAccent,
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 4. USERS MANAGEMENT TAB
  // ─────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final users = admin.users;

        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final accentColor = isDark
            ? GlassTheme.dynamicPrimaryColor
            : HSLColor.fromColor(
                GlassTheme.dynamicPrimaryColor,
              ).withLightness(0.32).toColor();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _userSearchCtrl,
                    style: textTheme.bodyMedium?.copyWith(color: primaryText),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search username, email, phone...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: GlassTheme.dynamicPrimaryColor,
                        size: 20,
                      ),
                      suffixIcon: _userSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: secondaryText,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() => _userSearchCtrl.clear());
                                admin.fetchUsers(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: GlassTheme.dynamicPrimaryColor,
                        ),
                      ),
                    ),
                    onSubmitted: (val) => admin.fetchUsers(search: val),
                  ),
                  const SizedBox(height: 12),
                  _buildUserRoleFilters(admin),
                ],
              ),
            ),
            Expanded(
              child: admin.isLoading && users.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: GlassTheme.dynamicPrimaryColor,
                      ),
                    )
                  : RefreshIndicator(
                      color: GlassTheme.dynamicPrimaryColor,
                      backgroundColor: isDark
                          ? GlassTheme.heroDarkCard
                          : Colors.white,
                      onRefresh: () => admin.fetchUsers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        itemBuilder: (context, idx) {
                          final user = users[idx] as Map<String, dynamic>;
                          final isActive = user['is_active'] == true;
                          final role = user['role'] ?? 'customer';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: GlassTheme
                                      .dynamicPrimaryColor
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    (user['username'] ?? 'U')[0].toUpperCase(),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user['username'] ?? 'User',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: primaryText,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: GlassTheme
                                                  .dynamicPrimaryColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: accentColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${user['email'] ?? 'No email'} · ${user['phone'] ?? 'No phone'}',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeThumbColor:
                                      GlassTheme.dynamicPrimaryColor,
                                  onChanged: (_) {
                                    if (isActive) {
                                      _confirmToggleUser(context, user, admin);
                                    } else {
                                      admin.toggleUserStatus(user['id']);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserRoleFilters(AdminProvider admin) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final selectedOnPrimary =
        GlassTheme.dynamicPrimaryColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    final roles = [
      {'key': 'all', 'label': 'All Roles'},
      {'key': 'customer', 'label': 'Customers'},
      {'key': 'driver', 'label': 'Drivers'},
      {'key': 'restaurant_owner', 'label': 'Owners'},
      {'key': 'admin', 'label': 'Admins'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((r) {
          final isSelected = admin.userRoleFilter == r['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(r['label']!),
              selected: isSelected,
              onSelected: (_) => admin.fetchUsers(role: r['key']),
              selectedColor: GlassTheme.dynamicPrimaryColor,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.88),
              labelStyle: textTheme.bodySmall?.copyWith(
                color: isSelected ? selectedOnPrimary : secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? GlassTheme.dynamicPrimaryColor
                    : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmToggleUser(
    BuildContext context,
    Map<String, dynamic> user,
    AdminProvider admin,
  ) {
    final username = user['username'] ?? 'this user';
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(
              'Deactivate Account',
              style: textTheme.titleMedium?.copyWith(
                color: primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate $username? They will immediately lose access to place or fulfill orders.',
          style: textTheme.bodyMedium?.copyWith(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(color: secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              admin.toggleUserStatus(user['id']);
            },
            child: Text(
              'Deactivate',
              style: textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _restaurantSearchQuery = '';

  // ─────────────────────────────────────────────
  // 4. RESTAURANTS MANAGEMENT TAB
  // ─────────────────────────────────────────────
  Widget _buildRestaurantsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final rawRestaurants = admin.restaurants;
        final query = _restaurantSearchQuery.trim().toLowerCase();
        final restaurants = query.isEmpty
            ? rawRestaurants
            : rawRestaurants.where((item) {
                if (item is! Map) return false;
                final name = item['name']?.toString().toLowerCase() ?? '';
                final addr = item['address']?.toString().toLowerCase() ?? '';
                return name.contains(query) || addr.contains(query);
              }).toList();
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final accentColor = isDark
            ? GlassTheme.dynamicPrimaryColor
            : HSLColor.fromColor(
                GlassTheme.dynamicPrimaryColor,
              ).withLightness(0.32).toColor();

        if (admin.isLoading && rawRestaurants.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: GlassTheme.dynamicPrimaryColor,
            ),
          );
        }

        return RefreshIndicator(
          color: GlassTheme.dynamicPrimaryColor,
          backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
          onRefresh: () => admin.fetchRestaurants(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _restaurantSearchQuery = val),
                    style: textTheme.bodyMedium?.copyWith(color: primaryText),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: 'Find restaurant by name or address...',
                      hintStyle: textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: accentColor,
                        size: 18,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, idx) {
                    final r = restaurants[idx] as Map<String, dynamic>;
                    final isActive = r['is_active'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['name'] ?? 'Restaurant',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Delivery: \$${r['delivery_fee']} · Rating: ${r['rating']} ',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: secondaryText,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.star,
                                      size: 13,
                                      color: isDark
                                          ? Colors.amber
                                          : const Color(0xFFD97706),
                                    ),
                                  ],
                                ),
                                Text(
                                  r['address'] ?? '',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: secondaryText,
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeThumbColor: GlassTheme.dynamicPrimaryColor,
                            onChanged: (_) {
                              admin.toggleRestaurantStatus(r['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // 5. AUDIT LOGS & SECURITY TAB
  // ─────────────────────────────────────────────
  Widget _buildAuditLogsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final logs = admin.auditLogs;
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final textTheme = Theme.of(context).textTheme;
        final primaryText = AppTypography.primaryTextColor(brightness);
        final secondaryText = AppTypography.secondaryTextColor(brightness);
        final accentColor = isDark
            ? GlassTheme.dynamicPrimaryColor
            : HSLColor.fromColor(
                GlassTheme.dynamicPrimaryColor,
              ).withLightness(0.32).toColor();

        if (admin.isLoading && logs.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: GlassTheme.dynamicPrimaryColor,
            ),
          );
        }

        return RefreshIndicator(
          color: GlassTheme.dynamicPrimaryColor,
          backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
          onRefresh: () => admin.fetchAuditLogs(),
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    'No audit events logged yet',
                    style: textTheme.bodyMedium?.copyWith(color: secondaryText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, idx) {
                    final log = logs[idx] as Map<String, dynamic>;
                    final action = log['action'] ?? 'ACTION';
                    final adminName = log['admin_username'] ?? 'System';
                    final timestamp = log['timestamp'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: GlassTheme.dynamicPrimaryColor.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: accentColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        action,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: primaryText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timestamp.length > 16
                                          ? timestamp
                                                .substring(0, 16)
                                                .replaceAll('T', ' ')
                                          : timestamp,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Actor: $adminName · Target: ${log['target_type']} #${log['target_id']}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: secondaryText,
                                  ),
                                ),
                                if (log['details'] != null &&
                                    log['details'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${log['details']}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: secondaryText,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _AdminCancelOrderDialog extends StatefulWidget {
  final int orderId;
  final AdminProvider admin;

  const _AdminCancelOrderDialog({required this.orderId, required this.admin});

  @override
  State<_AdminCancelOrderDialog> createState() =>
      _AdminCancelOrderDialogState();
}

class _AdminCancelOrderDialogState extends State<_AdminCancelOrderDialog> {
  final TextEditingController _reasonCtrl = TextEditingController(
    text: 'Cancelled by administrator due to stock issue',
  );

  @override
  void dispose() {
    _reasonCtrl.dispose();
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
      backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      title: Text(
        'Cancel Order Confirmation',
        style: textTheme.titleMedium?.copyWith(
          color: primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This will transition the order to CANCELLED and log an administrative audit event.',
            style: textTheme.bodyMedium?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            style: textTheme.bodyMedium?.copyWith(color: primaryText),
            decoration: InputDecoration(
              labelText: 'Cancellation Reason',
              labelStyle: textTheme.bodyMedium?.copyWith(color: secondaryText),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Keep Order',
            style: textTheme.labelLarge?.copyWith(color: secondaryText),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _reasonCtrl.text;
            Navigator.of(context).pop();
            widget.admin.cancelOrder(widget.orderId, reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? Colors.redAccent
                : const Color(0xFFB91C1C),
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Cancel Order',
            style: textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AdminRefundDialog extends StatefulWidget {
  final Map<String, dynamic> payment;
  final AdminProvider admin;
  final ValueChanged<bool> onCompleted;

  const _AdminRefundDialog({
    required this.payment,
    required this.admin,
    required this.onCompleted,
  });

  @override
  State<_AdminRefundDialog> createState() => _AdminRefundDialogState();
}

class _AdminRefundDialogState extends State<_AdminRefundDialog> {
  final TextEditingController _reasonCtrl = TextEditingController(
    text: 'Customer requested refund',
  );

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryText = AppTypography.primaryTextColor(brightness);
    final secondaryText = AppTypography.secondaryTextColor(brightness);
    final purpleColor = isDark ? Colors.purpleAccent : const Color(0xFF7E22CE);

    return AlertDialog(
      backgroundColor: isDark ? GlassTheme.heroDarkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.undo, color: purpleColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Authorize Refund',
              style: textTheme.titleLarge?.copyWith(
                color: primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund ${widget.payment['currency']} ${widget.payment['amount']} for Payment #${widget.payment['id']}?',
            style: textTheme.bodyMedium?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            style: textTheme.bodyMedium?.copyWith(color: primaryText),
            decoration: InputDecoration(
              labelText: 'Reason for Refund',
              labelStyle: textTheme.bodyMedium?.copyWith(color: secondaryText),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ),
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
            backgroundColor: purpleColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            final reason = _reasonCtrl.text.trim();
            Navigator.pop(context);
            final success = await widget.admin.refundPayment(
              widget.payment['id'] as int,
              reason: reason,
            );
            widget.onCompleted(success);
          },
          child: Text(
            'Confirm Refund',
            style: textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
