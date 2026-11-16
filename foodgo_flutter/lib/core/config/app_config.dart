import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  /// Production live Vercel backend API domain
  static const String defaultLiveUrl = 'https://food-go-app.vercel.app';

  /// Cloudflare Edge Gateway host (50% load balanced & failover protected)
  static const String cloudflareEdgeUrl =
      'https://foodgo.rtnaeam611.workers.dev';

  static String _customApiUrl = '';
  static String _customWsUrl = '';
  static bool _useEdgeFallback = false;

  static String get edgeApiBaseUrl => '$cloudflareEdgeUrl/api/';
  static String get primaryLiveApiBaseUrl => '$defaultLiveUrl/api/';
  static bool get isUsingEdgeFallback => _useEdgeFallback;

  static bool canFallbackToEdge(String currentBaseUrl) {
    if (_customApiUrl.isNotEmpty) return false;
    const envUrl = String.fromEnvironment('FOODGO_API_URL');
    if (envUrl.isNotEmpty) return false;
    return currentBaseUrl.startsWith(defaultLiveUrl);
  }

  static void activateEdgeFallback() {
    _useEdgeFallback = true;
  }

  static void resetEdgeFallback() {
    _useEdgeFallback = false;
  }

  /// Returns true only for public auth endpoints where attaching an existing
  /// Bearer token or attempting a 401 refresh loop should be skipped.
  static bool isPublicAuthEndpoint(String path) {
    final normalized = path.trim().replaceFirst(RegExp(r'^/+'), '');
    return normalized == 'token/' ||
        normalized == 'token/refresh/' ||
        normalized == 'auth/token/' ||
        normalized == 'auth/refresh/' ||
        normalized == 'auth/login/' ||
        normalized == 'auth/google/' ||
        normalized == 'register/' ||
        normalized == 'auth/register/' ||
        normalized == 'drivers/register/' ||
        normalized == 'forgot-password/' ||
        normalized.startsWith('auth/phone-login/') ||
        normalized.startsWith('auth/otp/');
  }

  /// Primary REST API Base URL
  static String get apiBaseUrl {
    if (_customApiUrl.isNotEmpty) {
      return _customApiUrl.endsWith('/') ? _customApiUrl : '$_customApiUrl/';
    }
    const envUrl = String.fromEnvironment('FOODGO_API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/') ? envUrl : '$envUrl/';
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://$host:8000/api/';
      }
      if (host.contains('workers.dev') || host.contains('foodgo.app')) {
        return '${Uri.base.origin}/api/';
      }
    }
    return _useEdgeFallback
        ? '$cloudflareEdgeUrl/api/'
        : '$defaultLiveUrl/api/';
  }

  static String _effectiveConfiguredApiUrl() {
    if (_customApiUrl.isNotEmpty) return _customApiUrl;
    return const String.fromEnvironment('FOODGO_API_URL');
  }

  /// WebSocket URL for live driver & order delivery tracking (Render ASGI container)
  static String get wsBaseUrl {
    if (_customWsUrl.isNotEmpty) {
      return _customWsUrl;
    }
    final configuredApi = _effectiveConfiguredApiUrl();
    if (configuredApi.contains('10.0.2.2')) {
      return 'ws://10.0.2.2:8000/ws/tracking/';
    }
    if (configuredApi.contains('127.0.0.1') ||
        configuredApi.contains('localhost')) {
      return 'ws://127.0.0.1:8000/ws/tracking/';
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'ws://$host:8000/ws/tracking/';
      }
    }
    return const String.fromEnvironment(
      'FOODGO_WS_URL',
      defaultValue: 'wss://foodgo-53pl.onrender.com/ws/tracking/',
    );
  }

  /// WebSocket URL for live real-time payment status updates
  static String get wsPaymentBaseUrl {
    if (_customWsUrl.isNotEmpty) {
      return _customWsUrl.replaceAll('/tracking/', '/payments/');
    }
    final configuredApi = _effectiveConfiguredApiUrl();
    if (configuredApi.contains('10.0.2.2')) {
      return 'ws://10.0.2.2:8000/ws/payments/';
    }
    if (configuredApi.contains('127.0.0.1') ||
        configuredApi.contains('localhost')) {
      return 'ws://127.0.0.1:8000/ws/payments/';
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'ws://$host:8000/ws/payments/';
      }
    }
    return const String.fromEnvironment(
      'FOODGO_PAYMENT_WS_URL',
      defaultValue: 'wss://foodgo-53pl.onrender.com/ws/payments/',
    );
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customApiUrl = prefs.getString('custom_api_url') ?? '';
    _customWsUrl = prefs.getString('custom_ws_url') ?? '';

    // Auto-migrate away from decommissioned or unresolved hosts
    if (_customApiUrl.contains('onrender.com') ||
        _customApiUrl.contains('food-go-backend.vercel.app') ||
        _customApiUrl.contains('foodgo-backend-a.vercel.app') ||
        _customApiUrl.contains('foodgo-backend-b.vercel.app') ||
        _customApiUrl.contains('api.foodgo.app')) {
      _customApiUrl = '';
      await prefs.remove('custom_api_url');
    }
  }

  static Future<void> setCustomApiUrl(String url) async {
    final clean = url.trim();
    _customApiUrl = clean;
    resetEdgeFallback();
    final prefs = await SharedPreferences.getInstance();
    if (clean.isEmpty) {
      await prefs.remove('custom_api_url');
    } else {
      await prefs.setString('custom_api_url', clean);
    }
  }
}
