import 'package:flutter/material.dart';
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
      setState(() {
        _restaurant = resData;
        _orders = (ordData as List).reversed.toList();
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
    final reasonController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: const Text(
          'Reject Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a rejection reason (prepaid orders are automatically refunded):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g., Kitchen at full capacity',
                hintStyle: TextStyle(color: GlassTheme.textMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reject & Refund',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      try {
        final reason = reasonController.text.trim().isEmpty
            ? 'Kitchen unable to fulfill order'
            : reasonController.text.trim();
        await _api.post('orders/$orderId/restaurant-reject/', {
          'reason': reason,
        });
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
          const SnackBar(
            content: Text('Failed to reject order.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    }
  }

  void _showAddFoodItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final descController = TextEditingController();
    final ingController = TextEditingController();
    final newCatController = TextEditingController();

    int? selectedCatId = _categories.isNotEmpty
        ? _categories.first['id']
        : null;
    bool isCreatingNewCat = _categories.isEmpty;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: GlassTheme.surfaceCardDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                                color: GlassTheme.primaryGreen.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Add Food Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name input
                    _buildInput(
                      controller: nameController,
                      label: 'Food Item Name',
                      icon: Icons.fastfood,
                    ),
                    const SizedBox(height: 14),

                    // Category selection
                    if (!isCreatingNewCat && _categories.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedCatId,
                        dropdownColor: GlassTheme.dropdownDark,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(color: GlassTheme.textMuted),
                          prefixIcon: const Icon(
                            Icons.category,
                            color: GlassTheme.primaryGreen,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _categories.map<DropdownMenuItem<int>>((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'],
                            child: Text(
                              cat['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedCatId = val),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: GlassTheme.primaryGreen,
                        ),
                        label: const Text(
                          '+ Create New Category',
                          style: TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () =>
                            setModalState(() => isCreatingNewCat = true),
                      ),
                    ] else ...[
                      _buildInput(
                        controller: newCatController,
                        label: 'New Category Name (e.g. Burgers, Drinks)',
                        icon: Icons.create_new_folder,
                      ),
                      if (_categories.isNotEmpty)
                        TextButton(
                          child: const Text(
                            'Choose from existing categories',
                            style: TextStyle(
                              color: GlassTheme.primaryGreen,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () =>
                              setModalState(() => isCreatingNewCat = false),
                        ),
                    ],
                    const SizedBox(height: 14),

                    // Price input
                    _buildInput(
                      controller: priceController,
                      label: 'Price (USD, e.g. 7.50)',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Image URL input
                    _buildInput(
                      controller: imageController,
                      label: 'Image URL (Unsplash or web photo)',
                      icon: Icons.image_outlined,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),

                    // Description & Ingredients
                    _buildInput(
                      controller: descController,
                      label: 'Description',
                      icon: Icons.notes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    _buildInput(
                      controller: ingController,
                      label: 'Ingredients (comma separated)',
                      icon: Icons.eco_outlined,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: GlassButton(
                        text: isSaving
                            ? 'Adding Item...'
                            : 'Save & Add to Menu',
                        icon: isSaving ? Icons.hourglass_top : Icons.check,
                        onPressed: isSaving
                            ? () {}
                            : () async {
                                final name = nameController.text.trim();
                                final priceStr = priceController.text.trim();
                                if (name.isEmpty || priceStr.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter food name and price',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  int? catId = selectedCatId;
                                  // Create category if new
                                  if (isCreatingNewCat &&
                                      newCatController.text.trim().isNotEmpty) {
                                    final catRes = await _api
                                        .post('food-categories/', {
                                          'restaurant': _restaurant!['id'],
                                          'name': newCatController.text.trim(),
                                        });
                                    catId = catRes['id'];
                                  }

                                  if (catId == null) {
                                    setModalState(() => isSaving = false);
                                    return;
                                  }

                                  await _api.post('food-items/', {
                                    'category': catId,
                                    'name': name,
                                    'price': priceStr,
                                    'image_url': imageController.text.trim(),
                                    'description': descController.text.trim(),
                                    'ingredients': ingController.text.trim(),
                                    'is_available': true,
                                  });

                                  if (!sheetCtx.mounted) return;
                                  Navigator.of(sheetCtx).pop();
                                  _fetchDashboardData();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Successfully added "$name" to your menu!',
                                      ),
                                      backgroundColor: GlassTheme.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add item: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: GlassTheme.textMuted),
        prefixIcon: Icon(icon, color: GlassTheme.primaryGreen),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: GlassTheme.dialogDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Restaurant Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of the Restaurant Portal?',
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
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Restaurant Portal',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: GlassTheme.backgroundDark),
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
                        GlassContainer(
                              padding: const EdgeInsets.all(20),
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: GlassTheme.primaryGreen
                                        .withValues(alpha: 0.2),
                                    backgroundImage:
                                        _restaurant!['banner'] != null
                                        ? CachedNetworkImageProvider(
                                            _restaurant!['banner'],
                                          )
                                        : null,
                                    child: _restaurant!['banner'] == null
                                        ? const Icon(
                                            Icons.store,
                                            size: 28,
                                            color: GlassTheme.primaryGreen,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _restaurant!['name'] ?? 'Restaurant',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_foodItems.length} items on menu · ${_orders.length} orders',
                                          style: TextStyle(
                                            color: GlassTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 16),

                        // Tab Selector (Live Orders vs Menu Items)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: GlassTheme.primaryGreen.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: GlassTheme.primaryGreen,
                              ),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: GlassTheme.textMuted,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.receipt_long, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Orders (${_orders.length})'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.restaurant_menu, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Menu (${_foodItems.length})'),
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
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return Center(
        child: Text(
          'No orders yet',
          style: TextStyle(color: GlassTheme.textMuted),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 650;
        if (isWide) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 175,
            ),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              return _buildRestaurantOrderCard(order);
            },
          );
        }
        return ListView.builder(
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
    );
  }

  Widget _buildRestaurantOrderCard(dynamic order) {
    final status = order['status']?.toString() ?? 'pending';
    final orderId = order['id'].toString();
    final assignedDriver = order['assigned_driver'];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: GlassTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final double amount =
                  double.tryParse(order['total_amount']?.toString() ?? '0') ??
                  0.0;
              final khr = KhmerCurrency.formatKhr(amount);
              return Text(
                'Total: \$${order['total_amount']} ($khr) • Status: ${order['payment_status'] ?? 'UNPAID'}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              );
            },
          ),
          if (order['delivery_address_snapshot'] != null &&
              order['delivery_address_snapshot'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.white54,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order['delivery_address_snapshot'].toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${assignedDriver['vehicle_type'] ?? 'Motorbike'} • ${assignedDriver['license_plate'] ?? ''} • ${assignedDriver['phone'] ?? ''}',
                          style: TextStyle(
                            color: GlassTheme.textMuted,
                            fontSize: 11,
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
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
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
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: GlassTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Bill #FG-${order['id']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
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
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'ITEMS ORDERED',
                style: TextStyle(
                  color: Colors.white54,
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
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 12,
                  ),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final name = it['food_name'] ?? 'Item #${it['food_item']}';
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '\$$lineTotal',
                          style: const TextStyle(
                            color: GlassTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Status:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    paymentStatus,
                    style: TextStyle(
                      color: paymentStatus == 'PAID'
                          ? GlassTheme.primaryGreen
                          : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bill:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '\$$total',
                    style: const TextStyle(
                      color: GlassTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassButton(text: 'Close', onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        // Big "+ Add New Food Item" button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add New Food Item',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _showAddFoodItemDialog,
          ),
        ),
        const SizedBox(height: 14),

        // List of items
        Expanded(
          child: _foodItems.isEmpty
              ? Center(
                  child: Text(
                    'No food items on menu yet. Add one above!',
                    style: TextStyle(color: GlassTheme.textMuted),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 650;
                    if (isWide) {
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 96,
                            ),
                        itemCount: _foodItems.length,
                        itemBuilder: (context, index) {
                          final item = _foodItems[index];
                          return _buildMenuItemCard(item);
                        },
                      );
                    }
                    return ListView.builder(
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
      ],
    );
  }

  Widget _buildMenuItemCard(dynamic item) {
    final bool isAvail = item['is_available'] ?? true;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.white.withValues(alpha: 0.05),
              child:
                  item['image'] != null && item['image'].toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item['image'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GlassTheme.primaryGreen,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.fastfood, color: GlassTheme.primaryGreen),
                    )
                  : Icon(Icons.fastfood, color: GlassTheme.primaryGreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['category_name'] ?? '',
                        style: TextStyle(
                          color: GlassTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${item['price']}',
                      style: const TextStyle(
                        color: GlassTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // In Stock switch
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch(
                value: isAvail,
                activeThumbColor: GlassTheme.primaryGreen,
                activeTrackColor: GlassTheme.primaryGreen.withValues(
                  alpha: 0.5,
                ),
                onChanged: (_) => _toggleItemAvailability(item['id'], isAvail),
              ),
              Text(
                isAvail ? 'In Stock' : 'Sold Out',
                style: TextStyle(
                  fontSize: 10,
                  color: isAvail ? GlassTheme.primaryGreen : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}
