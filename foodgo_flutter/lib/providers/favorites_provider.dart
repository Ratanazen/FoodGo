import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  static const String _prefKeyRestaurants = 'favorite_restaurants_v1';
  static const String _prefKeyFoodItems = 'favorite_foods_v1';

  final List<Map<String, dynamic>> _favoriteRestaurants = [];
  final List<Map<String, dynamic>> _favoriteFoodItems = [];
  bool _isInitialized = false;
  Future<void>? _loadFuture;

  FavoritesProvider() {
    _loadFuture = _loadFromPreferences();
  }

  List<Map<String, dynamic>> get favoriteRestaurants =>
      List.unmodifiable(_favoriteRestaurants);
  List<Map<String, dynamic>> get favoriteFoodItems =>
      List.unmodifiable(_favoriteFoodItems);
  bool get isInitialized => _isInitialized;

  int get totalFavoritesCount =>
      _favoriteRestaurants.length + _favoriteFoodItems.length;

  Future<void> loadFavorites() async {
    await (_loadFuture ??= _loadFromPreferences());
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final resStrings = prefs.getStringList(_prefKeyRestaurants) ?? [];
      _favoriteRestaurants.clear();
      for (final str in resStrings) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is Map<String, dynamic>) {
            _favoriteRestaurants.add(decoded);
          }
        } catch (_) {}
      }

      final foodStrings = prefs.getStringList(_prefKeyFoodItems) ?? [];
      _favoriteFoodItems.clear();
      for (final str in foodStrings) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is Map<String, dynamic>) {
            _favoriteFoodItems.add(decoded);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _favoriteRestaurants.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList(_prefKeyRestaurants, list);
    } catch (e) {
      debugPrint('Error saving favorite restaurants: $e');
    }
  }

  Future<void> _saveFoodItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _favoriteFoodItems.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList(_prefKeyFoodItems, list);
    } catch (e) {
      debugPrint('Error saving favorite food items: $e');
    }
  }

  bool isRestaurantFavorite(dynamic restaurantId) {
    if (restaurantId == null) return false;
    final idStr = restaurantId.toString();
    return _favoriteRestaurants.any((r) => r['id']?.toString() == idStr);
  }

  bool isFoodFavorite(dynamic foodId) {
    if (foodId == null) return false;
    final idStr = foodId.toString();
    return _favoriteFoodItems.any((f) => f['id']?.toString() == idStr);
  }

  Future<bool> toggleRestaurant(Map<String, dynamic> restaurant) async {
    if (_loadFuture != null) await _loadFuture;
    final id = restaurant['id']?.toString();
    if (id == null) return false;

    final existingIndex = _favoriteRestaurants.indexWhere(
      (r) => r['id']?.toString() == id,
    );
    bool added;
    if (existingIndex >= 0) {
      _favoriteRestaurants.removeAt(existingIndex);
      added = false;
    } else {
      _favoriteRestaurants.add(Map<String, dynamic>.from(restaurant));
      added = true;
    }
    notifyListeners();
    await _saveRestaurants();
    return added;
  }

  Future<bool> toggleFoodItem(Map<String, dynamic> foodItem) async {
    if (_loadFuture != null) await _loadFuture;
    final id = foodItem['id']?.toString();
    if (id == null) return false;

    final existingIndex = _favoriteFoodItems.indexWhere(
      (f) => f['id']?.toString() == id,
    );
    bool added;
    if (existingIndex >= 0) {
      _favoriteFoodItems.removeAt(existingIndex);
      added = false;
    } else {
      _favoriteFoodItems.add(Map<String, dynamic>.from(foodItem));
      added = true;
    }
    notifyListeners();
    await _saveFoodItems();
    return added;
  }

  Future<void> clearAll() async {
    if (_loadFuture != null) await _loadFuture;
    _favoriteRestaurants.clear();
    _favoriteFoodItems.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRestaurants);
    await prefs.remove(_prefKeyFoodItems);
  }
}
