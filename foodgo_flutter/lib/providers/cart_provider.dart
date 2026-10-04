import 'package:flutter/material.dart';

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
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  int? _lastOrderId;
  double _deliveryFee = 2.99;

  Map<int, CartItem> get items => _items;
  int? get lastOrderId => _lastOrderId;

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
    notifyListeners();
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  double get grandTotal => totalAmount > 0 ? totalAmount + deliveryFee : 0.0;

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
    notifyListeners();
  }

  /// Removes the item completely from the cart regardless of quantity.
  void removeItem(int id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
