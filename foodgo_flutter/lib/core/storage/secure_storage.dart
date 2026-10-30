import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
            lOptions: LinuxOptions(),
          );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _fallbackAccessKey = 'foodgo_sec_access_token';
  static const String _fallbackRefreshKey = 'foodgo_sec_refresh_token';

  // In-memory cache for ultra-fast and fail-safe access across platforms
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      _cachedRefreshToken = refreshToken;
    }

    // 1. Attempt writing to platform secure storage
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'SecureStorage platform write warning (falling back to SharedPreferences): $e',
        );
      }
    }

    // 2. Persist to SharedPreferences fallback for robustness across Linux/Web/mobile
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fallbackAccessKey, accessToken);
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await prefs.setString(_fallbackRefreshKey, refreshToken);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage SharedPreferences fallback write error: $e');
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.trim().isNotEmpty) {
      return _cachedAccessToken;
    }

    // 1. Try secure storage
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null && token.trim().isNotEmpty) {
        _cachedAccessToken = token;
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage platform read error: $e');
      }
    }

    // 2. Try SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fallbackAccessKey);
      if (token != null && token.trim().isNotEmpty) {
        _cachedAccessToken = token;
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage fallback read error: $e');
      }
    }

    return null;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.trim().isNotEmpty) {
      return _cachedRefreshToken;
    }

    // 1. Try secure storage
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (token != null && token.trim().isNotEmpty) {
        _cachedRefreshToken = token;
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage platform refresh read error: $e');
      }
    }

    // 2. Try SharedPreferences fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fallbackRefreshKey);
      if (token != null && token.trim().isNotEmpty) {
        _cachedRefreshToken = token;
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage fallback refresh read error: $e');
      }
    }

    return null;
  }

  Future<bool> hasAccessToken() async {
    final t = await getAccessToken();
    return t != null && t.trim().isNotEmpty;
  }

  Future<bool> hasRefreshToken() async {
    final t = await getRefreshToken();
    return t != null && t.trim().isNotEmpty;
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;

    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage platform delete warning: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fallbackAccessKey);
      await prefs.remove(_fallbackRefreshKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage fallback clear error: $e');
      }
    }
  }
}
