import 'package:dio/dio.dart';
import 'failure.dart';

/// Translates raw exceptions (such as [DioException]) into typed [Failure] instances.
class ErrorMapper {
  ErrorMapper._();

  /// Maps a [DioException] to the appropriate [Failure] subclass.
  static Failure fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          'Connection timed out. Please check your internet connection.',
        );

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Unable to reach server. Please check your connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        final data = exception.response?.data;
        return _mapStatusCodeToFailure(statusCode, data);

      case DioExceptionType.cancel:
        return const UnknownFailure('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          'Security certificate error. Connection aborted.',
        );

      case DioExceptionType.unknown:
      default:
        final message =
            exception.message ?? 'An unexpected network error occurred.';
        return NetworkFailure(message);
    }
  }

  /// Maps generic exceptions to a typed [Failure].
  static Failure fromException(Object exception) {
    if (exception is Failure) {
      return exception;
    }
    if (exception is DioException) {
      return fromDioException(exception);
    }
    return UnknownFailure(exception.toString());
  }

  static Failure _mapStatusCodeToFailure(int? statusCode, dynamic data) {
    final extractedMessage = _extractMessage(data);

    switch (statusCode) {
      case 400:
        if (data is Map<String, dynamic>) {
          final validationErrors = <String, List<String>>{};
          data.forEach((key, value) {
            if (value is List) {
              validationErrors[key] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              validationErrors[key] = [value];
            }
          });
          return ValidationFailure(
            extractedMessage ?? 'Invalid request data.',
            errors: validationErrors,
            statusCode: 400,
          );
        }
        return ValidationFailure(
          extractedMessage ?? 'Invalid request payload.',
          statusCode: 400,
        );

      case 401:
        return UnauthorizedFailure(
          extractedMessage ?? 'Authentication session expired. Please log in.',
          401,
        );

      case 403:
        return UnauthorizedFailure(
          extractedMessage ??
              'You do not have permission to access this resource.',
          403,
        );

      case 404:
        return NotFoundFailure(
          extractedMessage ?? 'The requested item could not be found.',
          404,
        );

      case 422:
        return ValidationFailure(
          extractedMessage ?? 'Unprocessable entity data.',
          statusCode: 422,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure(
          extractedMessage ??
              'Server temporarily unavailable. Please retry in a few moments.',
          statusCode ?? 500,
        );

      default:
        return ServerFailure(
          extractedMessage ?? 'Server returned error ($statusCode).',
          statusCode ?? 500,
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) return data['detail'] as String;
      if (data['error'] is String) return data['error'] as String;
      if (data['message'] is String) return data['message'] as String;
      if (data['non_field_errors'] is List &&
          (data['non_field_errors'] as List).isNotEmpty) {
        return (data['non_field_errors'] as List).first.toString();
      }
    }
    return null;
  }
}
