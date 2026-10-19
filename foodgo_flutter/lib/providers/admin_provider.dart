import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
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

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  Future<void> fetchAnalytics({String? period}) async {
    if (period != null) _selectedPeriod = period;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.get(
        'admin/analytics/?period=$_selectedPeriod',
      );
      if (res is Map<String, dynamic>) {
        _analytics = res;
      }
    } catch (e) {
      debugPrint('Admin analytics error: $e');
      _errorMessage = 'Failed to load analytics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders({String? status, String? search}) async {
    if (status != null) _orderStatusFilter = status;
    if (search != null) _orderSearchQuery = search;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignDriver(int orderId, int driverId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('admin/orders/$orderId/assign_driver/', {
        'driver_id': driverId,
      });
      await fetchOrders();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin assign driver error: $e');
      _errorMessage = 'Failed to assign driver: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('admin/orders/$orderId/cancel_order/', {
        'cancellation_reason': reason,
      });
      await fetchOrders();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin cancel order error: $e');
      _errorMessage = 'Failed to cancel order: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers({String? role, String? search}) async {
    if (role != null) _userRoleFilter = role;
    if (search != null) _userSearchQuery = search;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
      _errorMessage = 'Failed to load users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(int userId) async {
    try {
      await _apiService.post('admin/users/$userId/toggle_status/', {});
      await fetchUsers();
      await fetchAnalytics();
      return true;
    } catch (e) {
      debugPrint('Admin toggle user error: $e');
      _errorMessage = 'Failed to update user status: $e';
      return false;
    }
  }

  Future<void> fetchRestaurants({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
      _errorMessage = 'Failed to load restaurants: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _errorMessage = 'Failed to update restaurant status: $e';
      return false;
    }
  }

  Future<void> fetchAuditLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.get('admin/audit-logs/');
      if (res is List) {
        _auditLogs = res;
      } else if (res is Map && res['results'] is List) {
        _auditLogs = res['results'];
      }
    } catch (e) {
      debugPrint('Admin fetch audit logs error: $e');
      _errorMessage = 'Failed to load audit logs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
