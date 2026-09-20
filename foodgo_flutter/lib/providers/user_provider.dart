import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.get('me/');
      _user = data;
    } catch (e) {
      debugPrint('Error fetching user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
