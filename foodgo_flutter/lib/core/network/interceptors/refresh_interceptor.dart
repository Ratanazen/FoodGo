import 'dart:async';
import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

/// Interceptor that intercepts 401 Unauthorized responses,
/// requests a fresh access token using the stored refresh token,
/// and replays the original failed request seamlessly.
class RefreshInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorage storage;
  final void Function()? onSessionExpired;

  RefreshInterceptor({
    required this.dio,
    required this.storage,
    this.onSessionExpired,
  });

  bool _isRefreshing = false;
  final List<Completer<String>> _queuedRequests = [];

  static const List<String> _authEndpoints = [
    ApiEndpoints.login,
    ApiEndpoints.refresh,
    ApiEndpoints.register,
    ApiEndpoints.googleAuth,
    ApiEndpoints.phoneAuth,
  ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final requestOptions = err.requestOptions;

    // Do not attempt refresh on auth endpoints
    final isAuth = _authEndpoints.any(
      (endpoint) => requestOptions.path.contains(endpoint),
    );
    if (isAuth) {
      return handler.next(err);
    }

    // Guard against infinite refresh retry loops
    if (requestOptions.extra['is_refresh_retry'] == true) {
      onSessionExpired?.call();
      return handler.next(err);
    }

    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      onSessionExpired?.call();
      return handler.next(err);
    }

    try {
      final newAccessToken = await _performTokenRefresh(refreshToken);
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['is_refresh_retry'] = true;

      final retryResponse = await dio.fetch(requestOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (refreshErr) {
      onSessionExpired?.call();
      return handler.reject(refreshErr);
    } catch (_) {
      onSessionExpired?.call();
      return handler.reject(err);
    }
  }

  Future<String> _performTokenRefresh(String refreshToken) async {
    if (_isRefreshing) {
      final completer = Completer<String>();
      _queuedRequests.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'] as String;
      final newRefreshToken =
          (response.data['refresh'] as String?) ?? refreshToken;

      await storage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      for (final completer in _queuedRequests) {
        completer.complete(newAccessToken);
      }
      _queuedRequests.clear();

      return newAccessToken;
    } catch (error) {
      await storage.clearTokens();
      for (final completer in _queuedRequests) {
        completer.completeError(error);
      }
      _queuedRequests.clear();
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }
}
