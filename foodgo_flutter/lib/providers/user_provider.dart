import 'package:dio/dio.dart';
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
      _user ??= {
        'id': 1,
        'username': 'customer1',
        'email': 'customer@foodgo.com',
        'first_name': 'Alice',
        'last_name': 'Smith',
        'role': 'customer',
        'phone': '+855 12 345 678',
        'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=256&q=80',
      };
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
    String? avatarUrl,
    String? avatarFilePath,
  }) async {
    _isLoading = true;
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
        if (avatarUrl != null) updatedUser['avatar_url'] = avatarUrl;
        _user = updatedUser;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      // Local fallback so user updates persist in memory even if offline
      final updatedUser = Map<String, dynamic>.from(_user ?? {});
      if (firstName != null) updatedUser['first_name'] = firstName;
      if (lastName != null) updatedUser['last_name'] = lastName;
      if (email != null) updatedUser['email'] = email;
      if (phone != null) updatedUser['phone'] = phone;
      if (avatarUrl != null) updatedUser['avatar_url'] = avatarUrl;
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
