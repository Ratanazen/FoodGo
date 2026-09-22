with open('foodgo_flutter/lib/services/api_service.dart', 'r') as f:
    content = f.read()

patch_method = """
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('PATCH error: ${e.message}');
      rethrow;
    }
  }
"""

if "Future<dynamic> patch" not in content:
    content = content.replace("Future<dynamic> post", patch_method + "\n  Future<dynamic> post")
    with open('foodgo_flutter/lib/services/api_service.dart', 'w') as f:
        f.write(content)
