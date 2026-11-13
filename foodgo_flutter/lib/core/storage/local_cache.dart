import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod provider for LocalCacheService.
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

/// High-performance local cache and persistent key-value store with TTL support.
class LocalCacheService {
  final SharedPreferences? prefs;
  final Map<String, dynamic> _memoryStore = {};

  LocalCacheService({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    if (prefs != null) return prefs!;
    return await SharedPreferences.getInstance();
  }

  /// Saves a value with an optional [ttl] (time-to-live).
  Future<bool> set<T>(String key, T value, {Duration? ttl}) async {
    final expiryTimestamp = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : null;

    final cacheEnvelope = {
      'payload': value,
      'expiry': expiryTimestamp,
      'type': value.runtimeType.toString(),
    };

    _memoryStore[key] = cacheEnvelope;

    try {
      final p = await _getPrefs();
      final serialized = jsonEncode(cacheEnvelope);
      return await p.setString(key, serialized);
    } catch (_) {
      // Return true if memory cache succeeded even if storage IO fails
      return true;
    }
  }

  /// Retrieves a value by [key], returning `null` if expired or missing.
  Future<T?> get<T>(String key) async {
    // 1. Check in-memory fast cache first
    if (_memoryStore.containsKey(key)) {
      final envelope = _memoryStore[key] as Map<String, dynamic>;
      if (_isEnvelopeValid(envelope)) {
        return envelope['payload'] as T?;
      } else {
        _memoryStore.remove(key);
      }
    }

    // 2. Fall back to persistent SharedPreferences
    try {
      final p = await _getPrefs();
      final raw = p.getString(key);
      if (raw == null) return null;

      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (_isEnvelopeValid(envelope)) {
        _memoryStore[key] = envelope;
        return envelope['payload'] as T?;
      } else {
        await p.remove(key);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  bool _isEnvelopeValid(Map<String, dynamic> envelope) {
    final expiry = envelope['expiry'] as int?;
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch < expiry;
  }

  /// Removes an entry by [key].
  Future<bool> remove(String key) async {
    _memoryStore.remove(key);
    try {
      final p = await _getPrefs();
      return await p.remove(key);
    } catch (_) {
      return false;
    }
  }

  /// Clears all keys in the cache.
  Future<void> clear() async {
    _memoryStore.clear();
    try {
      final p = await _getPrefs();
      await p.clear();
    } catch (_) {}
  }
}
