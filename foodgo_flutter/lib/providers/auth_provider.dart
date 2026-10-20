import 'package:flutter/material.dart';

import '../core/storage/secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _lastAuthError;
  final ApiService _apiService = ApiService();
  final SecureStorage _secureStorage = SecureStorage();

  bool get isAuthenticated => _isAuthenticated;
  String? get lastAuthError => _lastAuthError;

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
    _lastAuthError = null;
    final result = await _apiService.login(username, password);
    if (result.isSuccess) {
      _isAuthenticated = true;
      _lastAuthError = null;
      notifyListeners();
      return true;
    } else {
      _lastAuthError = result.errorMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _lastAuthError = null;
    final result = await _apiService.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
    if (result.isSuccess) {
      _isAuthenticated = true;
      _lastAuthError = null;
      notifyListeners();
      return true;
    } else {
      _lastAuthError = result.errorMessage;
      notifyListeners();
      return false;
    }
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
        await _secureStorage.saveTokens(
          accessToken: access,
          refreshToken: refresh,
        );
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
    String? avatarUrl,
  }) async {
    final success = await _apiService.googleLogin(
      idToken: idToken,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
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
