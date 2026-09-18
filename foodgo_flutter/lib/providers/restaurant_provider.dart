import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RestaurantProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _restaurants = [];
  bool _isLoading = false;

  List<dynamic> get restaurants => _restaurants;
  bool get isLoading => _isLoading;

  Future<void> fetchRestaurants() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.get('restaurants/');
      _restaurants = data;
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
