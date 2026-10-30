import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _lastError;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isAdmin => _user?['role'] == 'admin' || _user?['is_staff'] == true;

  void clearUser() {
    _user = null;
    _lastError = null;
    notifyListeners();
  }

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.get('me/');
      if (data is Map<String, dynamic>) {
        _user = data;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    String? avatarFilePath,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      dynamic payload;
      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        final formData = FormData();
        if (firstName != null) {
          formData.fields.add(MapEntry('first_name', firstName));
        }
        if (lastName != null) {
          formData.fields.add(MapEntry('last_name', lastName));
        }
        if (email != null) {
          formData.fields.add(MapEntry('email', email));
        }
        if (phone != null) {
          formData.fields.add(MapEntry('phone', phone));
        }
        if (role != null) {
          formData.fields.add(MapEntry('role', role));
        }
        if (avatarUrl != null) {
          formData.fields.add(MapEntry('avatar_url', avatarUrl));
        }
        final fileName = avatarFilePath.split('/').last;
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(avatarFilePath, filename: fileName),
          ),
        );
        payload = formData;
      } else {
        final map = <String, dynamic>{};
        if (firstName != null) map['first_name'] = firstName;
        if (lastName != null) map['last_name'] = lastName;
        if (email != null) map['email'] = email;
        if (phone != null) map['phone'] = phone;
        if (role != null) map['role'] = role;
        if (avatarUrl != null) map['avatar_url'] = avatarUrl;
        payload = map;
      }

      final updated = await _apiService.patch('me/', payload);
      if (updated is Map<String, dynamic>) {
        _user = updated;
      } else {
        final updatedUser = Map<String, dynamic>.from(_user ?? {});
        if (firstName != null) updatedUser['first_name'] = firstName;
        if (lastName != null) updatedUser['last_name'] = lastName;
        if (email != null) updatedUser['email'] = email;
        if (phone != null) updatedUser['phone'] = phone;
        if (role != null) updatedUser['role'] = role;
        if (avatarUrl != null) updatedUser['avatar_url'] = avatarUrl;
        _user = updatedUser;
      }
      _isLoading = false;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          if (data.containsKey('detail') && data['detail'] != null) {
            _lastError = data['detail'].toString();
          } else if (data.containsKey('error') && data['error'] != null) {
            _lastError = data['error'].toString();
          } else if (data.isNotEmpty) {
            final firstVal = data.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              _lastError = firstVal.first.toString();
            } else if (firstVal is String) {
              _lastError = firstVal;
            }
          }
        } else if (e.response?.statusCode == 401) {
          _lastError = 'Session expired. Please log in again.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          _lastError =
              'Unable to connect to server. Please check your network connection.';
        }
      }
      _lastError ??= 'Failed to update profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRole(String newRole) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final updated = await _apiService.patch('me/', {'role': newRole});
      if (updated is Map<String, dynamic>) {
        _user = updated;
      } else if (_user != null) {
        _user!['role'] = newRole;
      }
      _isLoading = false;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating role: $e');
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        _lastError = data['detail']?.toString() ?? data['error']?.toString();
      }
      _lastError ??= 'Failed to update role. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
