import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/error_mapper.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Riverpod provider for secure storage.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Riverpod provider for the central DioClient.
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(storage: storage);
});

/// Production-ready Dio HTTP client configured with full interceptor pipeline.
class DioClient {
  final Dio _dio;
  final SecureStorage storage;

  DioClient({
    required this.storage,
    Dio? dio,
    void Function()? onSessionExpired,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConfig.apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    _dio.interceptors.addAll([
      AuthInterceptor(storage),
      RefreshInterceptor(
        dio: _dio,
        storage: storage,
        onSessionExpired: onSessionExpired,
      ),
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  /// GET request with automatic error mapping to typed [Failure].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// POST request with automatic error mapping.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// PUT request with automatic error mapping.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// PATCH request with automatic error mapping.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }

  /// DELETE request with automatic error mapping.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDioException(e);
    }
  }
}
