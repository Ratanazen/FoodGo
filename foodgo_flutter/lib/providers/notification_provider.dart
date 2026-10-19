import 'package:flutter/material.dart';
import '../core/theme/glass_theme.dart';
import '../services/api_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String
  notificationType; // 'order', 'promo', 'rate', 'system', 'account'
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final int? orderId;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    this.data = const {},
    this.createdAt,
    this.orderId,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    int? parsedOrderId;
    if (json['order_id'] != null) {
      parsedOrderId = int.tryParse(json['order_id'].toString());
    } else if (json['data'] is Map && json['data']['order_id'] != null) {
      parsedOrderId = int.tryParse(json['data']['order_id'].toString());
    }

    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return NotificationModel(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? 'FoodGo Alert',
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? 'system',
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
      createdAt: parsedDate,
      orderId: parsedOrderId,
      isRead: json['is_read'] == true,
    );
  }

  IconData get icon {
    switch (notificationType.toLowerCase()) {
      case 'order':
        return Icons.delivery_dining;
      case 'promo':
        return Icons.local_offer;
      case 'rate':
        return Icons.star;
      case 'account':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (notificationType.toLowerCase()) {
      case 'order':
        return GlassTheme.primaryGreen;
      case 'promo':
        return Colors.orange;
      case 'rate':
        return Colors.amber;
      case 'account':
        return Colors.blue;
      default:
        return GlassTheme.primaryGreen;
    }
  }

  String get timeAgo {
    if (createdAt == null) return 'Recent';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class NotificationProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get orderNotifications =>
      _notifications.where((n) => n.notificationType == 'order').toList();

  List<NotificationModel> get promoNotifications =>
      _notifications.where((n) => n.notificationType == 'promo').toList();

  NotificationProvider() {
    _initDefaults();
  }

  void _initDefaults() {
    _notifications = [
      NotificationModel(
        id: 'default_1',
        title: 'Order Delivered',
        message:
            'Your order #1024 has been delivered. Tap to view your order details.',
        notificationType: 'order',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        orderId: 1024,
      ),
      NotificationModel(
        id: 'default_2',
        title: 'Special Discount Voucher',
        message: 'Use code FOODGO50 for 50% off your next meal in Phnom Penh.',
        notificationType: 'promo',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        data: {'code': 'FOODGO50'},
      ),
      NotificationModel(
        id: 'default_3',
        title: 'Order Confirmed',
        message:
            'Your order from Angkor Delights has been confirmed and is being prepared.',
        notificationType: 'order',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        orderId: 1025,
      ),
    ];
    _isInitialized = true;
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('notifications/');
      final List<dynamic> list = res is List
          ? res
          : (res['results'] as List<dynamic>? ?? []);

      if (list.isNotEmpty) {
        _notifications = list
            .map(
              (item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {
      // Retain existing notifications if network error occurs
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();

      try {
        await _api.post('notifications/$id/read/', {});
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await _api.post('notifications/mark-all-read/', {});
    } catch (_) {}
  }

  void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
