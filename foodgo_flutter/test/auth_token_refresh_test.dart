import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/core/network/api_client.dart';
import 'package:foodgo_flutter/core/storage/secure_storage.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('SecureStorage Token Management Tests', () {
    test('hasAccessToken and hasRefreshToken return false when empty', () async {
      final storage = SecureStorage();
      await storage.clearTokens();
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.hasRefreshToken(), isFalse);
    });

    test('saveTokens persists access token and optional refresh token', () async {
      final storage = SecureStorage();
      await storage.saveTokens(
        accessToken: 'access_abc_123',
        refreshToken: 'refresh_xyz_789',
      );

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.hasRefreshToken(), isTrue);
      expect(await storage.getAccessToken(), 'access_abc_123');
      expect(await storage.getRefreshToken(), 'refresh_xyz_789');
    });

    test('saveTokens with null refreshToken does not overwrite existing refresh token', () async {
      final storage = SecureStorage();
      await storage.saveTokens(
        accessToken: 'initial_access',
        refreshToken: 'initial_refresh',
      );

      await storage.saveTokens(accessToken: 'updated_access');
      expect(await storage.getAccessToken(), 'updated_access');
      expect(await storage.getRefreshToken(), 'initial_refresh');
    });

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
    test('401 error on unauthenticated request does not crash with No refresh token error', () async {
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
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status code',
          401,
        )),
      );

      expect(sessionExpiredFired, isTrue);
    });

    test('AuthProvider automatically syncs isAuthenticated when session expires', () async {
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
    });
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
