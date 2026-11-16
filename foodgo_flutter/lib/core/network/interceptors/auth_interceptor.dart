import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

/// Interceptor that attaches JWT Bearer tokens to outgoing HTTP requests.
class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  AuthInterceptor(this._storage);

  static const List<String> _publicEndpoints = [
    ApiEndpoints.login,
    ApiEndpoints.refresh,
    ApiEndpoints.register,
    ApiEndpoints.googleAuth,
    ApiEndpoints.phoneAuth,
    ApiEndpoints.verifyOtp,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicEndpoints.any(
      (endpoint) => options.path.contains(endpoint),
    );

    if (!isPublic) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }
}
