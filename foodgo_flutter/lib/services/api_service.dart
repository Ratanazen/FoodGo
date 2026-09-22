import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';

class ApiService {
  final ApiClient _apiClient;

  ApiService() : _apiClient = ApiClient(SecureStorage());

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      debugPrint('GET error: ${e.message}');
      rethrow;
    }
  }

  
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('PATCH error: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('POST error: ${e.message}');
      rethrow;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        'token/',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await SecureStorage().saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        'register/',
        data: {'username': username, 'email': email, 'password': password},
      );
      if (response.statusCode != 201) return false;
      return await login(username, password);
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('Registration error: ${e.message}');
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage().clearTokens();
  }
}
