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
    }
    return '$defaultLiveUrl/api/';
  }

  /// WebSocket URL for live driver & order delivery tracking (Render ASGI container)
  static String get wsBaseUrl {
    if (_customWsUrl.isNotEmpty) {
      return _customWsUrl;
    }
    if (_customApiUrl.contains('10.0.2.2')) {
      return 'ws://10.0.2.2:8000/ws/tracking/';
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
    if (_customApiUrl.contains('10.0.2.2')) {
      return 'ws://10.0.2.2:8000/ws/payments/';
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
        _customApiUrl.contains('workers.dev') ||
        _customApiUrl.contains('api.foodgo.app')) {
      _customApiUrl = '';
      await prefs.remove('custom_api_url');
    }
  }

  static Future<void> setCustomApiUrl(String url) async {
    final clean = url.trim();
    _customApiUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    if (clean.isEmpty) {
      await prefs.remove('custom_api_url');
    } else {
      await prefs.setString('custom_api_url', clean);
    }
  }
}
