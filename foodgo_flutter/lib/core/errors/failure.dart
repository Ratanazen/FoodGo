import 'package:equatable/equatable.dart';

/// Base sealed class for all domain and infrastructure failures in FoodGo.
/// Dart 3 sealed class enables exhaustive pattern matching without default fallbacks.
sealed class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType: $message (code: $statusCode)';
}

/// Returned when the remote server responds with a 5xx status or unhandled payload.
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Internal server error. Please try again later.',
    super.statusCode = 500,
  ]);
}

/// Returned when internet connectivity drops or DNS resolution fails.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please verify your network.',
    super.statusCode,
  ]);
}

/// Returned when the authentication token is invalid or expired (401 / 403).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Session expired. Please log in again.',
    super.statusCode = 401,
  ]);
}

/// Returned when client payload validation fails (400 / 422).
final class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;

  const ValidationFailure(
    String message, {
    this.errors = const {},
    int? statusCode = 422,
  }) : super(message, statusCode);

  @override
  List<Object?> get props => [message, statusCode, errors];
}

/// Returned when an entity or resource does not exist on the server (404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'Requested resource was not found.',
    super.statusCode = 404,
  ]);
}

/// Returned when local storage or cache reading/writing fails.
final class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Local cache error occurred.',
    super.statusCode,
  ]);
}

/// Fallback for unexpected exceptions.
final class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
  ]);
}
