import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool isNetworkError;

  const AuthResult.success()
    : isSuccess = true,
      errorMessage = null,
      isNetworkError = false;

  const AuthResult.failure(this.errorMessage, {this.isNetworkError = false})
    : isSuccess = false;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  final ApiClient _apiClient;

  ApiService._internal() : _apiClient = ApiClient(SecureStorage());

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      debugPrint('GET error: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    try {
      final response = await _apiClient.dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('PATCH error: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final response = await _apiClient.dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('PUT error: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await _apiClient.dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('POST error: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _apiClient.dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      debugPrint('DELETE error: ${e.message}');
      rethrow;
    }
  }

  Future<AuthResult> login(String username, String password) async {
    final cleanUser = username.trim();
    try {
      final response = await _apiClient.dio.post(
        'token/',
        data: {'username': cleanUser, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await SecureStorage().saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );
        return const AuthResult.success();
      }
      return const AuthResult.failure(
        'Authentication failed. Please check your credentials.',
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('Login DioException: $e');
      if (e.response?.statusCode == 401) {
        return const AuthResult.failure(
          'Incorrect username/email or password.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const AuthResult.failure(
          'Unable to connect to server. Please check your network connection.',
          isNetworkError: true,
        );
      }
      final serverDetail = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.response?.data['error'])
          : null;
      return AuthResult.failure(
        serverDetail?.toString() ?? 'Login failed. Please try again.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      return const AuthResult.failure(
        'An unexpected error occurred during login.',
      );
    }
  }

  Future<bool> googleLogin({
    required String idToken,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{'id_token': idToken};
      if (email != null) payload['email'] = email;
      if (displayName != null) payload['name'] = displayName;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

      final response = await _apiClient.dio.post('auth/google/', data: payload);

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
      if (kDebugMode) debugPrint('Google login error: $e');
      return false;
    }
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
  }) async {
    try {
      final payload = <String, dynamic>{
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      if (firstName != null && firstName.isNotEmpty) {
        payload['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        payload['last_name'] = lastName;
      }
      if (phone != null && phone.isNotEmpty) {
        payload['phone'] = phone;
      }
      if (role != null && role.isNotEmpty) {
        payload['role'] = role;
      }

      final response = await _apiClient.dio.post('register/', data: payload);
      if (response.statusCode == 201) {
        return await login(username, password);
      }
      return const AuthResult.failure('Registration failed. Please try again.');
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('Registration error: ${e.message}');
      if (e.response?.data is Map) {
        final errMap = e.response!.data as Map;
        final firstKey = errMap.keys.firstOrNull;
        if (firstKey != null) {
          final val = errMap[firstKey];
          final msg = val is List ? val.firstOrNull : val;
          return AuthResult.failure('$firstKey: $msg');
        }
      }
      return const AuthResult.failure(
        'Registration failed. Please check your input.',
      );
    } catch (e) {
      return const AuthResult.failure(
        'An unexpected error occurred during registration.',
      );
    }
  }

  Future<void> logout() async {
    await SecureStorage().clearTokens();
  }
}
