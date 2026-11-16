import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/core/config/app_config.dart';
import 'package:foodgo_flutter/core/network/api_client.dart';
import 'package:foodgo_flutter/core/storage/secure_storage.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetEdgeFallback();
    ApiClient.onSessionExpired = null;
  });

  group('SecureStorage Token Management Tests', () {
    test(
      'hasAccessToken and hasRefreshToken return false when empty',
      () async {
        final storage = SecureStorage();
        await storage.clearTokens();
        expect(await storage.hasAccessToken(), isFalse);
        expect(await storage.hasRefreshToken(), isFalse);
      },
    );

    test(
      'saveTokens persists access token and optional refresh token',
      () async {
        final storage = SecureStorage();
        await storage.saveTokens(
          accessToken: 'access_abc_123',
          refreshToken: 'refresh_xyz_789',
        );

        expect(await storage.hasAccessToken(), isTrue);
        expect(await storage.hasRefreshToken(), isTrue);
        expect(await storage.getAccessToken(), 'access_abc_123');
        expect(await storage.getRefreshToken(), 'refresh_xyz_789');
      },
    );

    test(
      'saveTokens with null refreshToken does not overwrite existing refresh token',
      () async {
        final storage = SecureStorage();
        await storage.saveTokens(
          accessToken: 'initial_access',
          refreshToken: 'initial_refresh',
        );

        await storage.saveTokens(accessToken: 'updated_access');
        expect(await storage.getAccessToken(), 'updated_access');
        expect(await storage.getRefreshToken(), 'initial_refresh');
      },
    );

    test('clearTokens wipes both access and refresh tokens', () async {
      final storage = SecureStorage();
      await storage.saveTokens(
        accessToken: 'access_1',
        refreshToken: 'refresh_1',
      );
      await storage.clearTokens();

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.hasRefreshToken(), isFalse);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });

  group('ApiClient 401 & Refresh Token Resilience Tests', () {
    test(
      '401 error on unauthenticated request does not crash with No refresh token error',
      () async {
        final storage = SecureStorage();
        await storage.clearTokens();

        bool sessionExpiredFired = false;
        ApiClient.onSessionExpired = () {
          sessionExpiredFired = true;
        };

        final client = ApiClient(storage);
        client.dio.httpClientAdapter = _Mock401HttpClientAdapter();

        await expectLater(
          () => client.dio.get('orders/'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status code',
              401,
            ),
          ),
        );

        expect(sessionExpiredFired, isTrue);
      },
    );

    test(
      'AuthProvider automatically syncs isAuthenticated when session expires',
      () async {
        final storage = SecureStorage();
        await storage.saveTokens(
          accessToken: 'valid_test_token',
          refreshToken: 'valid_refresh_token',
        );

        final authProvider = AuthProvider();
        await authProvider.checkAuth();
        expect(authProvider.isAuthenticated, isTrue);

        // Trigger session expiration event
        ApiClient.onSessionExpired?.call();
        expect(authProvider.isAuthenticated, isFalse);
      },
    );

    test(
      'ApiClient dynamically injects current AppConfig.apiBaseUrl on each request',
      () async {
        final storage = SecureStorage();
        final client = ApiClient(storage);
        String? executedBaseUrl;

        client.dio.interceptors.insert(
          0,
          InterceptorsWrapper(
            onRequest: (options, handler) {
              executedBaseUrl = options.baseUrl;
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'intercepted_test',
                ),
              );
            },
          ),
        );

        try {
          await client.dio.get('probe/');
        } catch (_) {}

        expect(executedBaseUrl, equals(AppConfig.apiBaseUrl));
      },
    );

    test(
      'SecureStorage transparently falls back to SharedPreferences and cache',
      () async {
        final storage = SecureStorage();
        await storage.clearTokens();

        await storage.saveTokens(
          accessToken: 'resilient_access_token',
          refreshToken: 'resilient_refresh_token',
        );

        final token = await storage.getAccessToken();
        expect(token, equals('resilient_access_token'));
        final refresh = await storage.getRefreshToken();
        expect(refresh, equals('resilient_refresh_token'));
      },
    );

    test(
      'AppConfig.isPublicAuthEndpoint preserves Bearer auth on phone status/change/OTP verification while skipping login endpoints',
      () {
        expect(AppConfig.isPublicAuthEndpoint('auth/phone/status/'), isFalse);
        expect(AppConfig.isPublicAuthEndpoint('auth/phone/change/'), isFalse);
        expect(AppConfig.isPublicAuthEndpoint('auth/phone/send-otp/'), isFalse);
        expect(
          AppConfig.isPublicAuthEndpoint('auth/phone/verify-otp/'),
          isFalse,
        );
        expect(AppConfig.isPublicAuthEndpoint('me/'), isFalse);

        expect(AppConfig.isPublicAuthEndpoint('token/'), isTrue);
        expect(AppConfig.isPublicAuthEndpoint('/token/refresh/'), isTrue);
        expect(AppConfig.isPublicAuthEndpoint('auth/login/'), isTrue);
        expect(AppConfig.isPublicAuthEndpoint('auth/google/'), isTrue);
        expect(
          AppConfig.isPublicAuthEndpoint('auth/phone-login/request/'),
          isTrue,
        );
        expect(
          AppConfig.isPublicAuthEndpoint('auth/phone-login/verify/'),
          isTrue,
        );
        expect(AppConfig.isPublicAuthEndpoint('forgot-password/'), isTrue);
        expect(AppConfig.isPublicAuthEndpoint('register/'), isTrue);
      },
    );

    test(
      'ApiClient attaches Bearer token on auth/phone/status/ and omits it on auth/phone-login/request/',
      () async {
        final storage = SecureStorage();
        await storage.saveTokens(
          accessToken: 'jwt_access_token_123',
          refreshToken: 'jwt_refresh_token_456',
        );

        final client = ApiClient(storage);
        final recordedHeaders = <String, String?>{};
        client.dio.httpClientAdapter = _RecordingHttpClientAdapter((options) {
          recordedHeaders[options.path] = options.headers['Authorization']
              ?.toString();
        });

        await client.dio.get('auth/phone/status/');
        await client.dio.post('auth/phone/change/', data: {'new_phone': '012'});
        await client.dio.post(
          'auth/phone-login/request/',
          data: {'phone': '012'},
        );
        await client.dio.post('forgot-password/', data: {'identifier': '012'});

        expect(
          recordedHeaders['auth/phone/status/'],
          equals('Bearer jwt_access_token_123'),
        );
        expect(
          recordedHeaders['auth/phone/change/'],
          equals('Bearer jwt_access_token_123'),
        );
        expect(recordedHeaders['auth/phone-login/request/'], isNull);
        expect(recordedHeaders['forgot-password/'], isNull);
      },
    );

    test(
      '401 on protected auth/phone/status/ fires session expiration while 401 on public auth/phone-login/verify/ does not',
      () async {
        final storage = SecureStorage();
        await storage.clearTokens();

        bool sessionExpiredFired = false;
        ApiClient.onSessionExpired = () {
          sessionExpiredFired = true;
        };

        final client = ApiClient(storage);
        client.dio.httpClientAdapter = _Mock401HttpClientAdapter();

        await expectLater(
          () => client.dio.post('auth/phone-login/verify/', data: {}),
          throwsA(isA<DioException>()),
        );
        expect(sessionExpiredFired, isFalse);

        await expectLater(
          () => client.dio.get('auth/phone/status/'),
          throwsA(isA<DioException>()),
        );
        expect(sessionExpiredFired, isTrue);
      },
    );

    test(
      'AppConfig edge failover switches apiBaseUrl between defaultLiveUrl and cloudflareEdgeUrl',
      () {
        expect(AppConfig.isUsingEdgeFallback, isFalse);
        expect(
          AppConfig.canFallbackToEdge('${AppConfig.defaultLiveUrl}/api/'),
          isTrue,
        );
        expect(
          AppConfig.canFallbackToEdge('http://127.0.0.1:8000/api/'),
          isFalse,
        );

        AppConfig.activateEdgeFallback();
        expect(AppConfig.isUsingEdgeFallback, isTrue);
        if (AppConfig.apiBaseUrl.contains('http://localhost') == false &&
            AppConfig.apiBaseUrl.contains('http://127.0.0.1') == false) {
          expect(AppConfig.apiBaseUrl, equals(AppConfig.edgeApiBaseUrl));
        }

        AppConfig.resetEdgeFallback();
        expect(AppConfig.isUsingEdgeFallback, isFalse);
      },
    );
  });
}

class _Mock401HttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"detail":"Authentication credentials were not provided."}',
      401,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  final void Function(RequestOptions options) onRequest;

  _RecordingHttpClientAdapter(this.onRequest);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
