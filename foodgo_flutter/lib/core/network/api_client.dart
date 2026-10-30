import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _secureStorage;

  /// Whether a token refresh is currently in progress.
  bool _isRefreshing = false;

  /// Queue of pending requests waiting for the token refresh to complete.
  /// Each completer resolves with the new access token or an error.
  final List<Completer<String>> _pendingRequests = [];

  /// Optional listener called when the user session has expired or cannot be refreshed.
  static void Function()? onSessionExpired;

  ApiClient(this._secureStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = AppConfig.apiBaseUrl;
          final isAuthEndpoint =
              options.path == 'register/' ||
              options.path.contains('register') ||
              options.path == 'token/' ||
              options.path.contains('token/refresh') ||
              options.path.contains('auth/login') ||
              options.path.contains('auth/google') ||
              options.path.contains('auth/phone') ||
              options.path.contains('auth/register');
          if (!isAuthEndpoint) {
            final token = await _secureStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Only handle 401 responses (unauthorized / token expired)
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          final requestOptions = e.requestOptions;

          // Never attempt token refresh on login or authentication endpoints
          final isAuthEndpoint =
              requestOptions.path == 'register/' ||
              requestOptions.path.contains('register') ||
              requestOptions.path == 'token/' ||
              requestOptions.path.contains('token/refresh') ||
              requestOptions.path.contains('auth/login') ||
              requestOptions.path.contains('auth/google') ||
              requestOptions.path.contains('auth/phone') ||
              requestOptions.path.contains('auth/register');
          if (isAuthEndpoint) {
            return handler.next(e);
          }

          // Do not retry if request already underwent a refresh retry
          if (requestOptions.extra['is_retry'] == true) {
            onSessionExpired?.call();
            return handler.next(e);
          }

          // Check if there is an active refresh token stored.
          // If none exists, this is an unauthenticated request or the user has logged out.
          // In that case, DO NOT attempt to refresh or throw "No refresh token available".
          // Pass through the original 401 error so the app/caller receives standard 401 response.
          final refreshToken = await _secureStorage.getRefreshToken();
          if (refreshToken == null || refreshToken.trim().isEmpty) {
            onSessionExpired?.call();
            return handler.next(e);
          }

          try {
            final newAccessToken = await _refreshToken();
            // Retry the original request with the new access token
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            requestOptions.extra['is_retry'] = true;
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          } on DioException catch (refreshError) {
            onSessionExpired?.call();
            // If the refresh failed with a response, return it, otherwise return original 401
            if (refreshError.response != null) {
              return handler.reject(refreshError);
            }
            return handler.reject(e);
          } catch (unexpected) {
            onSessionExpired?.call();
            return handler.reject(e);
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
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: 'token/refresh/'),
          response: Response(
            requestOptions: RequestOptions(path: 'token/refresh/'),
            statusCode: 401,
            data: {'detail': 'No refresh token available. Please log in.'},
          ),
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
