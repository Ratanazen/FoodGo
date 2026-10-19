import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  int quantity;
  final String? image;
  final int? restaurantId;
  final String? restaurantName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.image,
    this.restaurantId,
    this.restaurantName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'image': image,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int? ?? 1,
    image: json['image'] as String?,
    restaurantId: json['restaurantId'] as int?,
    restaurantName: json['restaurantName'] as String?,
  );
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  int? _lastOrderId;
  double _deliveryFee = 2.99;
  String? _appliedPromoCode;
  double _discountAmount = 0.0;

  CartProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('foodgo_cart_items_v2');
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items.clear();
        for (final itemJson in decoded) {
          final item = CartItem.fromJson(itemJson as Map<String, dynamic>);
          _items[item.id] = item;
        }
        _deliveryFee = prefs.getDouble('foodgo_cart_delivery_fee') ?? 2.99;
        _recalculateDiscount();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.values.map((i) => i.toJson()).toList();
      await prefs.setString('foodgo_cart_items_v2', jsonEncode(list));
      await prefs.setDouble('foodgo_cart_delivery_fee', _deliveryFee);
    } catch (_) {}
  }

  bool isDifferentRestaurant(int? newRestId) {
    if (_items.isEmpty || newRestId == null) return false;
    final currentRestId = restaurantId;
    return currentRestId != null && currentRestId != newRestId;
  }

  Map<int, CartItem> get items => _items;
  int? get lastOrderId => _lastOrderId;
  String? get appliedPromoCode => _appliedPromoCode;
  double get discountAmount => _discountAmount;

  void setLastOrderId(int? id) {
    _lastOrderId = id;
    notifyListeners();
  }

  int get itemCount => _items.length;

  int? get restaurantId {
    if (_items.isEmpty) return null;
    return _items.values.first.restaurantId;
  }

  String? get restaurantName {
    if (_items.isEmpty) return null;
    return _items.values.first.restaurantName;
  }

  double get deliveryFee => _items.isEmpty ? 0.0 : _deliveryFee;

  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    _recalculateDiscount();
    notifyListeners();
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  double get grandTotal {
    if (totalAmount <= 0) return 0.0;
    final total = totalAmount + deliveryFee - _discountAmount;
    return total > 0 ? double.parse(total.toStringAsFixed(2)) : 0.0;
  }

  void _recalculateDiscount() {
    if (_appliedPromoCode == null || _items.isEmpty) {
      _discountAmount = 0.0;
      return;
    }

    switch (_appliedPromoCode) {
      case 'FOODGOFREE':
      case 'FREESHIP':
        _discountAmount = _deliveryFee;
        break;
      case 'FOODGO30':
      case 'FOODIE30':
        _discountAmount = double.parse((totalAmount * 0.30).toStringAsFixed(2));
        break;
      case 'FOODGO20':
      case 'BURGER20':
        _discountAmount = double.parse((totalAmount * 0.20).toStringAsFixed(2));
        break;
      case 'FOODGO50':
        _discountAmount = double.parse((totalAmount * 0.50).toStringAsFixed(2));
        break;
      case 'EXPRESS':
        _discountAmount = _deliveryFee > 2.0 ? 2.0 : _deliveryFee;
        break;
      default:
        _discountAmount = 0.0;
    }
  }

  bool applyPromoCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    const validCodes = [
      'FOODGOFREE',
      'FREESHIP',
      'FOODGO30',
      'FOODIE30',
      'FOODGO20',
      'BURGER20',
      'FOODGO50',
      'EXPRESS',
    ];

    if (validCodes.contains(code)) {
      _appliedPromoCode = code;
      _recalculateDiscount();
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _appliedPromoCode = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  void addItem(
    int id,
    String name,
    double price,
    String? image, {
    int? restaurantId,
    String? restaurantName,
    double? deliveryFee,
  }) {
    if (deliveryFee != null && deliveryFee >= 0) {
      _deliveryFee = deliveryFee;
    }
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
          image: existingItem.image,
          restaurantId: existingItem.restaurantId ?? restaurantId,
          restaurantName: existingItem.restaurantName ?? restaurantName,
        ),
      );
    } else {
      _items.putIfAbsent(
        id,
        () => CartItem(
          id: id,
          name: name,
          price: price,
          image: image,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      );
    }
    _recalculateDiscount();
    _saveToPrefs();
    notifyListeners();
  }

  /// Decreases item quantity by 1; removes completely if quantity reaches 0.
  void decrementItem(int id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      _items.update(
        id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity - 1,
          image: existingItem.image,
          restaurantId: existingItem.restaurantId,
          restaurantName: existingItem.restaurantName,
        ),
      );
    } else {
      _items.remove(id);
    }
    _recalculateDiscount();
    _saveToPrefs();
    notifyListeners();
  }

  /// Removes the item completely from the cart regardless of quantity.
  void removeItem(int id) {
    _items.remove(id);
    _recalculateDiscount();
    _saveToPrefs();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _appliedPromoCode = null;
    _discountAmount = 0.0;
    _saveToPrefs();
    notifyListeners();
  }
}
