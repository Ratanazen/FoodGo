import 'package:flutter/material.dart';

import '../core/storage/secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  final ApiService _apiService = ApiService();
  final SecureStorage _secureStorage = SecureStorage();

  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    final success = await _apiService.login(username, password);
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final success = await _apiService.register(
      username: username,
      email: email,
      password: password,
    );
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> requestOTP(String phone) async {
    try {
      await _apiService.post('auth/phone-login/request/', {'phone': phone});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    try {
      final response = await _apiService.post('auth/phone-login/verify/', {
        'phone': phone,
        'otp': otp,
      });
      
      final access = response['access'];
      final refresh = response['refresh'];
      
      if (access != null) {
        await _secureStorage.saveTokens(accessToken: access, refreshToken: refresh);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginWithGoogle({
    required String idToken,
    String? email,
    String? displayName,
  }) async {
    final success = await _apiService.googleLogin(
      idToken: idToken,
      email: email,
      displayName: displayName,
    );
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}
