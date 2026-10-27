import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
// ignore: unused_import
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
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Admin Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of the Admin Console?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: GlassTheme.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: GlassTheme.limeAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: GlassTheme.limeAccent,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: GlassTheme.limeAccent,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Admin Console',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: GlassTheme.limeAccent,
            ),
            tooltip: 'Refresh Data',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
          unselectedLabelColor: GlassTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Payments'),
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Users'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Restaurants'),
            Tab(icon: Icon(Icons.security_outlined), text: 'Audit Logs'),
          ],
        ),
      ),
      body: ResponsiveWebContainer(
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
    );
  }

  // ─────────────────────────────────────────────
  // 1. OVERVIEW & ANALYTICS TAB
  // ─────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.analytics == null) {
          return const Center(
            child: CircularProgressIndicator(color: GlassTheme.limeAccent),
          );
        }

        final analytics = admin.analytics;
        final metrics = analytics?['metrics'] as Map<String, dynamic>? ?? {};
        final health =
            analytics?['system_health'] as Map<String, dynamic>? ?? {};
        final distribution =
            analytics?['order_status_distribution'] as Map<String, dynamic>? ??
            {};

        return RefreshIndicator(
          color: GlassTheme.limeAccent,
          backgroundColor: GlassTheme.heroDarkCard,
          onRefresh: () => admin.fetchAnalytics(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period Filter Selector
              _buildPeriodSelector(admin),
              const SizedBox(height: 16),

              // System Health Badge Card
              _buildSystemHealthCard(health),
              const SizedBox(height: 16),

              // Key Metrics 2x2 Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Revenue',
                      value: '\$${metrics['total_revenue_usd'] ?? '0.00'}',
                      subtitle: metrics['total_revenue_khr'] ?? '0 KHR',
                      icon: Icons.payments_outlined,
                      accentColor: GlassTheme.limeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Orders',
                      value: '${metrics['total_orders'] ?? 0}',
                      subtitle: '${metrics['completed_orders'] ?? 0} Completed',
                      icon: Icons.shopping_bag_outlined,
                      accentColor: Colors.lightBlueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Drivers',
                      value: '${metrics['active_drivers'] ?? 0}',
                      subtitle: '${metrics['total_drivers'] ?? 0} Registered',
                      icon: Icons.delivery_dining_outlined,
                      accentColor: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Customers',
                      value: '${metrics['active_customers'] ?? 0}',
                      subtitle: '${metrics['total_customers'] ?? 0} Registered',
                      icon: Icons.group_outlined,
                      accentColor: Colors.purpleAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Order Status Pipeline Card
              _buildStatusPipelineCard(distribution),
              const SizedBox(height: 20),

              // Recent Activity Feed
              _buildRecentOrdersSection(
                analytics?['recent_orders'] as List<dynamic>? ?? [],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(AdminProvider admin) {
    final periods = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'week', 'label': '7 Days'},
      {'key': 'month', 'label': '30 Days'},
      {'key': 'all', 'label': 'All Time'},
    ];

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
              selectedColor: GlassTheme.limeAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? GlassTheme.limeAccent : Colors.white12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemHealthCard(Map<String, dynamic> health) {
    final isHealthy = health['database'] == 'healthy';
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHealthy
                  ? Colors.greenAccent.withValues(alpha: 0.15)
                  : Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: isHealthy ? Colors.greenAccent : Colors.redAccent,
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
                    const Text(
                      'System & Core Health',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHealthy
                            ? Colors.greenAccent.withValues(alpha: 0.2)
                            : Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHealthy ? 'OPERATIONAL' : 'DEGRADED',
                        style: TextStyle(
                          color: isHealthy
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'PostgreSQL 15 Database: ${health['database'] ?? 'OK'} · ASGI Daphne: ${health['daphne_asgi'] ?? 'Running'}',
                  style: const TextStyle(
                    color: GlassTheme.textMuted,
                    fontSize: 12,
                  ),
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
  }) {
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
                title,
                style: const TextStyle(
                  color: GlassTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPipelineCard(Map<String, dynamic> distribution) {
    final statuses = [
      {'key': 'pending', 'label': 'Pending', 'color': Colors.amberAccent},
      {
        'key': 'preparing',
        'label': 'Preparing',
        'color': Colors.lightBlueAccent,
      },
      {
        'key': 'on_the_way',
        'label': 'In Transit',
        'color': Colors.purpleAccent,
      },
      {'key': 'delivered', 'label': 'Delivered', 'color': Colors.greenAccent},
      {'key': 'cancelled', 'label': 'Cancelled', 'color': Colors.redAccent},
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: statuses.map((s) {
              final count = distribution[s['key']] ?? 0;
              final color = s['color'] as Color;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s['label'] as String,
                      style: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(List<dynamic> recentOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Recent Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (recentOrders.isEmpty)
          const Text(
            'No recent orders logged.',
            style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
          )
        else
          ...recentOrders.map((o) {
            final statusStr = o['status'] ?? 'pending';
            Color badgeColor = Colors.amber;
            if (statusStr == 'delivered') badgeColor = Colors.green;
            if (statusStr == 'cancelled') badgeColor = Colors.red;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Customer: ${o['customer']}',
                          style: const TextStyle(
                            color: GlassTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        o['amount'] ?? '\$0.00',
                        style: const TextStyle(
                          color: GlassTheme.limeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
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

        return Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _orderSearchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search order ref, customer, phone...',
                      hintStyle: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: GlassTheme.limeAccent,
                        size: 20,
                      ),
                      suffixIcon: _orderSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: () {
                                _orderSearchCtrl.clear();
                                admin.fetchOrders(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: GlassTheme.limeAccent,
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: GlassTheme.limeAccent,
                      ),
                    )
                  : RefreshIndicator(
                      color: GlassTheme.limeAccent,
                      backgroundColor: GlassTheme.heroDarkCard,
                      onRefresh: () => admin.fetchOrders(),
                      child: orders.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching orders found',
                                style: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 14,
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
    final filters = [
      {'key': 'all', 'label': 'All'},
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
              selectedColor: GlassTheme.limeAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? GlassTheme.limeAccent : Colors.white12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, AdminProvider admin) {
    final statusStr = order['status'] ?? 'pending';
    final paymentStatus = order['payment_status'] ?? 'UNPAID';
    final driver = order['assigned_driver'] as Map<String, dynamic>?;
    final customer = order['customer_info'] as Map<String, dynamic>?;

    Color statusColor = Colors.amber;
    if (statusStr == 'delivered') statusColor = Colors.greenAccent;
    if (statusStr == 'cancelled') statusColor = Colors.redAccent;
    if (statusStr == 'on_the_way') statusColor = Colors.purpleAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['order_reference'] ?? 'Order #${order['id']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusStr.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Restaurant: ${order['restaurant_name'] ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (customer != null)
            Text(
              'Customer: ${customer['name']} (${customer['phone']})',
              style: const TextStyle(color: GlassTheme.textMuted, fontSize: 12),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Total: \$${order['total_amount']}',
                style: const TextStyle(
                  color: GlassTheme.limeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: paymentStatus == 'PAID'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PAYMENT: $paymentStatus',
                  style: TextStyle(
                    color: paymentStatus == 'PAID'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                driver != null
                    ? Icons.sports_motorsports_rounded
                    : Icons.person_search_rounded,
                size: 16,
                color: driver != null ? GlassTheme.limeAccent : Colors.white38,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  driver != null
                      ? 'Driver: ${driver['name']} (${driver['license_plate']})'
                      : 'No driver assigned',
                  style: TextStyle(
                    color: driver != null ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: driver != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (statusStr != 'delivered' && statusStr != 'cancelled') ...[
                TextButton(
                  onPressed: () => _showAssignDriverDialog(order['id'], admin),
                  style: TextButton.styleFrom(
                    foregroundColor: GlassTheme.limeAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'Assign Driver',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _showCancelOrderDialog(order['id'], admin),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignDriverDialog(int orderId, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: GlassTheme.heroDarkCard,
          title: const Text(
            'Assign Courier Driver',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select an available registered driver for this delivery dispatch:',
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.two_wheeler_rounded,
                  color: GlassTheme.limeAccent,
                ),
                title: const Text(
                  'Bob Rider (driver1)',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Plate: PP-1AB-2026 · Online',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  admin.assignDriver(orderId, 1);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.electric_scooter_rounded,
                  color: GlassTheme.limeAccent,
                ),
                title: const Text(
                  'Sophea Swift (driver2)',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Plate: PP-2CD-2026 · Online',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  admin.assignDriver(orderId, 2);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelOrderDialog(int orderId, AdminProvider admin) {
    final reasonCtrl = TextEditingController(
      text: 'Cancelled by administrator due to stock issue',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: GlassTheme.heroDarkCard,
          title: const Text(
            'Cancel Order Confirmation',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will transition the order to CANCELLED and log an administrative audit event.',
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Cancellation Reason',
                  labelStyle: const TextStyle(color: GlassTheme.textMuted),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Keep Order',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                admin.cancelOrder(orderId, reasonCtrl.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Cancel Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // 3. PAYMENTS & TRANSACTIONS MANAGEMENT TAB
  // ─────────────────────────────────────────────
  Widget _buildPaymentsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final payments = admin.payments;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _paymentSearchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by Order Ref, Txn ID, or Customer...',
                      hintStyle: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: GlassTheme.limeAccent,
                        size: 20,
                      ),
                      suffixIcon: _paymentSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white60,
                                size: 18,
                              ),
                              onPressed: () {
                                _paymentSearchCtrl.clear();
                                admin.fetchPayments(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: GlassTheme.limeAccent,
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: GlassTheme.limeAccent,
                      ),
                    )
                  : RefreshIndicator(
                      color: GlassTheme.limeAccent,
                      backgroundColor: GlassTheme.heroDarkCard,
                      onRefresh: () => admin.fetchPayments(),
                      child: payments.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching payment transactions found',
                                style: TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 14,
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
              selectedColor: GlassTheme.limeAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? GlassTheme.limeAccent
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, AdminProvider admin) {
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

    Color statusColor;
    switch (status) {
      case 'PAID':
        statusColor = Theme.of(context).colorScheme.primary;
        break;
      case 'PENDING':
        statusColor = Colors.orangeAccent;
        break;
      case 'EXPIRED':
      case 'FAILED':
        statusColor = Colors.redAccent;
        break;
      case 'REFUNDED':
        statusColor = Colors.purpleAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GlassTheme.heroDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: GlassTheme.limeAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment #${payment['id']} · $provider',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$orderRef · $customer',
                        style: const TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
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
                  const Text(
                    'Authoritative Amount',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: GlassTheme.limeAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Transaction Ref',
                    style: TextStyle(color: GlassTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txnId.length > 18 ? '${txnId.substring(0, 16)}...' : txnId,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
            style: const TextStyle(color: GlassTheme.textMuted, fontSize: 11),
          ),
          if (status == 'PAID') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purpleAccent,
                  side: const BorderSide(color: Colors.purpleAccent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.undo, size: 16),
                label: const Text(
                  'Issue Refund',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
    final reasonCtrl = TextEditingController(text: 'Customer requested refund');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.heroDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.undo, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text(
              'Authorize Refund',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refund ${payment['currency']} ${payment['amount']} for Payment #${payment['id']}?',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Reason for Refund',
                labelStyle: const TextStyle(color: GlassTheme.textMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ],
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
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await admin.refundPayment(
                payment['id'] as int,
                reason: reasonCtrl.text.trim(),
              );
              if (context.mounted) {
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
              }
            },
            child: const Text('Confirm Refund'),
          ),
        ],
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _userSearchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search username, email, phone...',
                      hintStyle: const TextStyle(
                        color: GlassTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: GlassTheme.limeAccent,
                        size: 20,
                      ),
                      suffixIcon: _userSearchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: () {
                                _userSearchCtrl.clear();
                                admin.fetchUsers(search: '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: GlassTheme.limeAccent,
                      ),
                    )
                  : RefreshIndicator(
                      color: GlassTheme.limeAccent,
                      backgroundColor: GlassTheme.heroDarkCard,
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
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: GlassTheme.limeAccent
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    (user['username'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: GlassTheme.limeAccent,
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
                                          Text(
                                            user['username'] ?? 'User',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: GlassTheme.limeAccent
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: const TextStyle(
                                                color: GlassTheme.limeAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${user['email'] ?? 'No email'} · ${user['phone'] ?? 'No phone'}',
                                        style: const TextStyle(
                                          color: GlassTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeThumbColor: GlassTheme.limeAccent,
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
              selectedColor: GlassTheme.limeAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white70,
                fontSize: 12,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.heroDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              'Deactivate Account',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate $username? They will immediately lose access to place or fulfill orders.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              admin.toggleUserStatus(user['id']);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 4. RESTAURANTS MANAGEMENT TAB
  // ─────────────────────────────────────────────
  Widget _buildRestaurantsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final restaurants = admin.restaurants;

        if (admin.isLoading && restaurants.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: GlassTheme.limeAccent),
          );
        }

        return RefreshIndicator(
          color: GlassTheme.limeAccent,
          backgroundColor: GlassTheme.heroDarkCard,
          onRefresh: () => admin.fetchRestaurants(),
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
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: GlassTheme.limeAccent,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Delivery: \$${r['delivery_fee']} · Rating: ${r['rating']} ',
                                style: const TextStyle(
                                  color: GlassTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                size: 13,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                          Text(
                            r['address'] ?? '',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeThumbColor: GlassTheme.limeAccent,
                      onChanged: (_) {
                        admin.toggleRestaurantStatus(r['id']);
                      },
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

  // ─────────────────────────────────────────────
  // 5. AUDIT LOGS & SECURITY TAB
  // ─────────────────────────────────────────────
  Widget _buildAuditLogsTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final logs = admin.auditLogs;

        if (admin.isLoading && logs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: GlassTheme.limeAccent),
          );
        }

        return RefreshIndicator(
          color: GlassTheme.limeAccent,
          backgroundColor: GlassTheme.heroDarkCard,
          onRefresh: () => admin.fetchAuditLogs(),
          child: logs.isEmpty
              ? const Center(
                  child: Text(
                    'No audit events logged yet',
                    style: TextStyle(color: GlassTheme.textMuted),
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
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: GlassTheme.limeAccent.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: GlassTheme.limeAccent,
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
                                    Text(
                                      action,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      timestamp.length > 16
                                          ? timestamp
                                                .substring(0, 16)
                                                .replaceAll('T', ' ')
                                          : timestamp,
                                      style: const TextStyle(
                                        color: GlassTheme.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Actor: $adminName · Target: ${log['target_type']} #${log['target_id']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                if (log['details'] != null &&
                                    log['details'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${log['details']}',
                                    style: const TextStyle(
                                      color: GlassTheme.textMuted,
                                      fontSize: 10,
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
