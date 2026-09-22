import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _secureStorage;

  /// Whether a token refresh is currently in progress.
  bool _isRefreshing = false;

  /// Queue of pending requests waiting for the token refresh to complete.
  /// Each completer resolves with the new access token or an error.
  final List<Completer<String>> _pendingRequests = [];

  ApiClient(this._secureStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'FOODGO_API_URL',
            defaultValue: 'http://127.0.0.1:8000/api/',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Only handle 401 responses (unauthorized / token expired)
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          final requestOptions = e.requestOptions;

          // If the failed request was itself the refresh call, don't retry
          if (requestOptions.path.contains('token/refresh')) {
            return handler.next(e);
          }

          try {
            final newAccessToken = await _refreshToken();
            // Retry the original request with the new access token
            requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          } on DioException catch (refreshError) {
            return handler.reject(refreshError);
          }
        },
      ),
    );

    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(responseBody: true, requestBody: true),
      );
    }
  }

  Dio get dio => _dio;

  /// Attempts to refresh the access token using the stored refresh token.
  ///
  /// Uses a lock ([_isRefreshing]) to prevent multiple concurrent refresh
  /// calls. If a refresh is already in progress, the caller is queued and
  /// will receive the new token once the in-flight refresh completes.
  Future<String> _refreshToken() async {
    // If a refresh is already in progress, queue this caller.
    if (_isRefreshing) {
      final completer = Completer<String>();
      _pendingRequests.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw DioException(
          requestOptions: RequestOptions(path: 'token/refresh/'),
          message: 'No refresh token available',
        );
      }

      // Use a separate Dio instance to avoid interceptor recursion.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        'token/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'] as String;

      // Persist the new access token, keeping the same refresh token.
      await _secureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );

      // Resolve all pending requests with the new token.
      for (final completer in _pendingRequests) {
        completer.complete(newAccessToken);
      }
      _pendingRequests.clear();

      return newAccessToken;
    } catch (error) {
      // Refresh failed — clear stored tokens so the app can handle logout.
      await _secureStorage.clearTokens();

      // Reject all pending requests.
      for (final completer in _pendingRequests) {
        if (error is DioException) {
          completer.completeError(error);
        } else {
          completer.completeError(
            DioException(
              requestOptions: RequestOptions(path: 'token/refresh/'),
              error: error,
            ),
          );
        }
      }
      _pendingRequests.clear();

      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }
}
