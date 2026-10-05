import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  /// Default hosted Render backend URL
  static const String defaultLiveUrl = 'https://foodgo-53pl.onrender.com';

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
      defaultValue: 'wss://foodgo-53pl.onrender.com/ws/tracking/',
    );
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customApiUrl = prefs.getString('custom_api_url') ?? '';
    _customWsUrl = prefs.getString('custom_ws_url') ?? '';
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
