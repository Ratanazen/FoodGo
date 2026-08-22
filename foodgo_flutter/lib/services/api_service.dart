import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';

class ApiService {
  final ApiClient _apiClient;
  
  ApiService() : _apiClient = ApiClient(SecureStorage());

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      print('GET error: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      print('POST error: ${e.message}');
      rethrow;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        'token/',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await SecureStorage().saveTokens(
          accessToken: data['access'], 
          refreshToken: data['refresh']
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage().clearTokens();
  }
}
