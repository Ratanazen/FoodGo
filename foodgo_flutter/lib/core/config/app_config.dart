import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  /// Default hosted Vercel backend URL (active & live)
  static const String defaultLiveUrl = 'https://food-go-app.vercel.app';

  static String _customApiUrl = '';
  static String _customWsUrl = '';

  /// Primary REST API Base URL
  static String get apiBaseUrl {
    if (_customApiUrl.isNotEmpty) {
      return _customApiUrl.endsWith('/') ? _customApiUrl : '$_customApiUrl/';
    }
    return const String.fromEnvironment(
      'FOODGO_API_URL',
      defaultValue: '$defaultLiveUrl/api/',
    );
  }

  /// WebSocket URL for live driver & order delivery tracking
  static String get wsBaseUrl {
    if (_customWsUrl.isNotEmpty) {
      return _customWsUrl;
    }
    return const String.fromEnvironment(
      'FOODGO_WS_URL',
      defaultValue: 'wss://food-go-app.vercel.app/ws/tracking/',
    );
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customApiUrl = prefs.getString('custom_api_url') ?? '';
    _customWsUrl = prefs.getString('custom_ws_url') ?? '';

    // Auto-migrate away from decommissioned Render or incorrect Vercel URLs
    if (_customApiUrl.contains('onrender.com') || _customApiUrl.contains('food-go-backend.vercel.app')) {
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
