import 'dart:async';
import 'package:dio/dio.dart';

/// Interceptor that retries failed requests due to transient network drops or 5xx server errors
/// using exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final currentAttempt = (requestOptions.extra['retry_attempt'] as int?) ?? 0;

    final shouldRetry = _isTransientError(err) && currentAttempt < maxRetries;

    if (!shouldRetry) {
      return handler.next(err);
    }

    final nextAttempt = currentAttempt + 1;
    requestOptions.extra['retry_attempt'] = nextAttempt;

    // Calculate exponential delay: 500ms, 1000ms, 2000ms
    final delay = initialDelay * (1 << (currentAttempt));
    await Future.delayed(delay);

    try {
      final response = await dio.fetch(requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    } catch (_) {
      return handler.next(err);
    }
  }

  bool _isTransientError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    return false;
  }
}
