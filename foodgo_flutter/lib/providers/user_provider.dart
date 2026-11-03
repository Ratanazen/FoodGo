import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _lastError;

  UserProvider() {
    _loadCachedUser();
  }

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isAdmin => _user?['role'] == 'admin' || _user?['is_staff'] == true;

  String get displayName {
    if (_user == null) return 'Foodie';
    final firstName = _user?['first_name']?.toString().trim() ?? '';
    final lastName = _user?['last_name']?.toString().trim() ?? '';
    if (firstName.isNotEmpty) {
      return lastName.isNotEmpty ? '$firstName $lastName' : firstName;
    }
    final username = _user?['username']?.toString().trim() ?? '';
    if (username.isNotEmpty && !username.startsWith('adb_user_')) {
      return username;
    }
    final emailAddress = _user?['email']?.toString().trim() ?? '';
    if (emailAddress.isNotEmpty && emailAddress.contains('@')) {
      final handle = emailAddress.split('@').first;
      if (handle.isNotEmpty) {
        return handle[0].toUpperCase() + handle.substring(1);
      }
    }
    return username.isNotEmpty ? username : 'Foodie';
  }

  String get email => _user?['email']?.toString().trim() ?? '';
  String get phone => _user?['phone']?.toString().trim() ?? '';
  String? get avatarUrl => _user?['avatar_url'] ?? _user?['avatar'];
  String get role => _user?['role']?.toString().toLowerCase() ?? 'customer';

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty || name == 'Foodie' || name == 'Guest') {
      final username = _user?['username']?.toString().trim() ?? '';
      if (username.isNotEmpty) return username[0].toUpperCase();
      return 'F';
    }
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _loadCachedUser() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cachedJson = preferences.getString('cached_user_profile');
      if (cachedJson == null || cachedJson.isEmpty) return;
      final decoded = jsonDecode(cachedJson);
      if (decoded is Map<String, dynamic> && _user == null) {
        _user = decoded;
        notifyListeners();
      }
    } catch (e) {
      if (!e.toString().contains('MissingPluginException')) {
        debugPrint('Error loading cached user profile: $e');
      }
    }
  }

  void setUser(Map<String, dynamic> userData) {
    _user = Map<String, dynamic>.from(userData);
    _isLoading = false;
    _lastError = null;
    notifyListeners();
    _persistCachedUser();
  }

  Future<void> _persistCachedUser() async {
    if (_user == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('cached_user_profile', jsonEncode(_user));
    } catch (e) {
      if (!e.toString().contains('MissingPluginException')) {
        debugPrint('Error saving cached user profile: $e');
      }
    }
  }

  void clearUser() {
    _user = null;
    _lastError = null;
    notifyListeners();
    SharedPreferences.getInstance().then((preferences) {
      preferences.remove('cached_user_profile');
    });
  }

  Future<void> fetchUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.get('me/');
      if (data is Map<String, dynamic>) {
        _user = data;
        _persistCachedUser();
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        _user = null;
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove('cached_user_profile');
      }
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
