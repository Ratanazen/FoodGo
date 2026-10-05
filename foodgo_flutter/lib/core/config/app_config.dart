class AppConfig {
  /// Live hosted Render backend URL
  static const String liveHostUrl = 'https://foodgo-53pl.onrender.com';

  /// Primary REST API Base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'FOODGO_API_URL',
    defaultValue: '$liveHostUrl/api/',
  );

  /// WebSocket URL for live driver & order delivery tracking
  static const String wsBaseUrl = String.fromEnvironment(
    'FOODGO_WS_URL',
    defaultValue: 'wss://foodgo-53pl.onrender.com/ws/tracking/',
  );
}
