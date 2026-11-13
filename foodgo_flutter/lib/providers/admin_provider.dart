import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _activeRequests = 0;
  String? _errorMessage;

  Map<String, dynamic>? _analytics;
  String _selectedPeriod = 'all';

  List<dynamic> _orders = [];
  String _orderStatusFilter = 'all';
  String _orderSearchQuery = '';

  List<dynamic> _users = [];
  String _userRoleFilter = 'all';
  String _userSearchQuery = '';

  List<dynamic> _restaurants = [];
  List<dynamic> _auditLogs = [];
  List<dynamic> _payments = [];
  String _paymentStatusFilter = 'all';
  String _paymentSearchQuery = '';

  List<dynamic> _drivers = [];
  String _driverFilter = 'all';
  String _driverSearchQuery = '';

  bool get isLoading => _activeRequests > 0;
  String? get errorMessage => _errorMessage;

  Future<void> _trackRequest(
    Future<void> Function() action, {
    bool clearError = true,
  }) async {
    _activeRequests++;
    if (clearError) _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } finally {
      _activeRequests = (_activeRequests - 1).clamp(0, 999);
      notifyListeners();
    }
  }

  Map<String, dynamic>? get analytics => _analytics;
  String get selectedPeriod => _selectedPeriod;

  List<dynamic> get orders => _orders;
  String get orderStatusFilter => _orderStatusFilter;
  String get orderSearchQuery => _orderSearchQuery;

  List<dynamic> get users => _users;
  String get userRoleFilter => _userRoleFilter;
  String get userSearchQuery => _userSearchQuery;

  List<dynamic> get restaurants => _restaurants;
  List<dynamic> get auditLogs => _auditLogs;

  List<dynamic> get payments => _payments;
  String get paymentStatusFilter => _paymentStatusFilter;
  String get paymentSearchQuery => _paymentSearchQuery;

  List<dynamic> get drivers => _drivers;
  String get driverFilter => _driverFilter;
  String get driverSearchQuery => _driverSearchQuery;

  Future<void> fetchAnalytics({String? period}) async {
    if (period != null) _selectedPeriod = period;
    await _trackRequest(() async {
      try {
        final res = await _apiService.get(
          'admin/analytics/?period=$_selectedPeriod',
        );
        if (res is Map<String, dynamic>) {
          _analytics = res;
        }
      } catch (e) {
        debugPrint('Admin analytics error: $e');
        _errorMessage = 'Failed to load analytics: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<void> fetchOrders({String? status, String? search}) async {
    if (status != null) _orderStatusFilter = status;
    if (search != null) _orderSearchQuery = search;

    await _trackRequest(() async {
      try {
        String endpoint = 'admin/orders/?status=$_orderStatusFilter';
        if (_orderSearchQuery.isNotEmpty) {
          endpoint += '&search=${Uri.encodeComponent(_orderSearchQuery)}';
        }
        final res = await _apiService.get(endpoint);
        if (res is List) {
          _orders = res;
        } else if (res is Map && res['results'] is List) {
          _orders = res['results'];
        }
      } catch (e) {
        debugPrint('Admin fetch orders error: $e');
        _errorMessage = 'Failed to load orders: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<bool> assignDriver(int orderId, int driverId) async {
    bool ok = false;
    await _trackRequest(() async {
      try {
        await _apiService.post('admin/orders/$orderId/assign_driver/', {
          'driver_id': driverId,
        });
        await fetchOrders();
        await fetchAnalytics();
        ok = true;
      } catch (e) {
        debugPrint('Admin assign driver error: $e');
        _errorMessage = 'Failed to assign driver: ${ApiService.formatError(e)}';
      }
    }, clearError: false);
    return ok;
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    bool ok = false;
    await _trackRequest(() async {
      try {
        await _apiService.post('admin/orders/$orderId/cancel_order/', {
          'cancellation_reason': reason,
        });
        await fetchOrders();
        await fetchAnalytics();
        ok = true;
      } catch (e) {
        debugPrint('Admin cancel order error: $e');
        _errorMessage = 'Failed to cancel order: ${ApiService.formatError(e)}';
      }
    }, clearError: false);
    return ok;
  }

  Future<void> fetchUsers({String? role, String? search}) async {
    if (role != null) _userRoleFilter = role;
    if (search != null) _userSearchQuery = search;

    await _trackRequest(() async {
      try {
        String endpoint = 'admin/users/?role=$_userRoleFilter';
        if (_userSearchQuery.isNotEmpty) {
          endpoint += '&search=${Uri.encodeComponent(_userSearchQuery)}';
        }
        final res = await _apiService.get(endpoint);
        if (res is List) {
          _users = res;
        } else if (res is Map && res['results'] is List) {
          _users = res['results'];
        }
      } catch (e) {
        debugPrint('Admin fetch users error: $e');
        _errorMessage = 'Failed to load users: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<bool> toggleUserStatus(int userId) async {
    try {
      await _apiService.post('admin/users/$userId/toggle_status/', {});
      await fetchUsers();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin toggle user error: $e');
      _errorMessage =
          'Failed to update user status: ${ApiService.formatError(e)}';
      return false;
    }
  }

  Future<void> fetchRestaurants({String? search}) async {
    await _trackRequest(() async {
      try {
        String endpoint = 'admin/restaurants/';
        if (search != null && search.isNotEmpty) {
          endpoint += '?search=${Uri.encodeComponent(search)}';
        }
        final res = await _apiService.get(endpoint);
        if (res is List) {
          _restaurants = res;
        } else if (res is Map && res['results'] is List) {
          _restaurants = res['results'];
        }
      } catch (e) {
        debugPrint('Admin fetch restaurants error: $e');
        _errorMessage =
            'Failed to load restaurants: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<bool> toggleRestaurantStatus(int restaurantId) async {
    try {
      await _apiService.post(
        'admin/restaurants/$restaurantId/toggle_status/',
        {},
      );
      await fetchRestaurants();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin toggle restaurant error: $e');
      _errorMessage =
          'Failed to update restaurant status: ${ApiService.formatError(e)}';
      return false;
    }
  }

  Future<void> fetchAuditLogs() async {
    await _trackRequest(() async {
      try {
        final res = await _apiService.get('admin/audit-logs/');
        if (res is List) {
          _auditLogs = res;
        } else if (res is Map && res['results'] is List) {
          _auditLogs = res['results'];
        }
      } catch (e) {
        debugPrint('Admin fetch audit logs error: $e');
        _errorMessage = 'Failed to load audit logs: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<void> fetchPayments({String? status, String? search}) async {
    if (status != null) _paymentStatusFilter = status;
    if (search != null) _paymentSearchQuery = search;

    await _trackRequest(() async {
      try {
        String endpoint = 'admin/payments/?status=$_paymentStatusFilter';
        if (_paymentSearchQuery.isNotEmpty) {
          endpoint += '&search=${Uri.encodeComponent(_paymentSearchQuery)}';
        }
        final res = await _apiService.get(endpoint);
        if (res is List) {
          _payments = res;
        } else if (res is Map && res['results'] is List) {
          _payments = res['results'];
        }
      } catch (e) {
        debugPrint('Admin fetch payments error: $e');
        _errorMessage = 'Failed to load payments: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<bool> refundPayment(int paymentId, {String? reason}) async {
    bool ok = false;
    await _trackRequest(() async {
      try {
        await _apiService.post('admin/payments/$paymentId/refund/', {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        });
        await fetchPayments();
        await fetchAnalytics();
        ok = true;
      } catch (e) {
        debugPrint('Admin refund payment error: $e');
        _errorMessage = 'Failed to process refund: ${ApiService.formatError(e)}';
      }
    });
    return ok;
  }

  Future<void> fetchDrivers({String? filter, String? search}) async {
    if (filter != null) _driverFilter = filter;
    if (search != null) _driverSearchQuery = search;

    await _trackRequest(() async {
      try {
        String endpoint = 'admin/drivers/';
        final params = <String>[];
        if (_driverFilter == 'online') {
          params.add('online=true');
        } else if (_driverFilter == 'offline') {
          params.add('online=false');
        } else if (_driverFilter == 'pending') {
          params.add('approved=false');
        }
        if (_driverSearchQuery.isNotEmpty) {
          params.add('search=${Uri.encodeComponent(_driverSearchQuery)}');
        }
        if (params.isNotEmpty) {
          endpoint += '?${params.join('&')}';
        }

        final res = await _apiService.get(endpoint);
        if (res is List) {
          _drivers = res;
        } else if (res is Map && res['results'] is List) {
          _drivers = res['results'];
        }
      } catch (e) {
        debugPrint('Admin fetch drivers error: $e');
        _errorMessage = 'Failed to load drivers: ${ApiService.formatError(e)}';
      }
    });
  }

  Future<bool> approveDriver(int driverId) async {
    try {
      await _apiService.post('admin/drivers/$driverId/approve/', {});
      await fetchDrivers();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin approve driver error: $e');
      _errorMessage = 'Failed to approve driver: ${ApiService.formatError(e)}';
      return false;
    }
  }

  Future<bool> suspendDriver(int driverId) async {
    try {
      await _apiService.post('admin/drivers/$driverId/suspend/', {});
      await fetchDrivers();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin suspend driver error: $e');
      _errorMessage = 'Failed to suspend driver: ${ApiService.formatError(e)}';
      return false;
    }
  }
}
