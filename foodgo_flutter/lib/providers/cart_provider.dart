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

  Map<int, CartItem> get items => _items;

  int get itemCount => _items.length;

  int? get restaurantId {
    if (_items.isEmpty) return null;
    return _items.values.first.restaurantId;
  }

  String? get restaurantName {
    if (_items.isEmpty) return null;
    return _items.values.first.restaurantName;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
    int id,
    String name,
    double price,
    String? image, {
    int? restaurantId,
    String? restaurantName,
  }) {
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

  void removeItem(int id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
