import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only HTTP logger that prints formatted requests, responses, and cURL equivalents.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP REQUEST] ${options.method.toUpperCase()} ${options.uri}',
      );
      if (options.data != null) {
        debugPrint('[HTTP BODY] ${_formatPayload(options.data)}');
      }
      debugPrint('[CURL] ${_generateCurl(options)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP ERROR] ${err.response?.statusCode ?? "NET_ERR"} ${err.requestOptions.method} ${err.requestOptions.uri} -> ${err.message}',
      );
    }
    handler.next(err);
  }

  String _formatPayload(dynamic data) {
    try {
      if (data is Map || data is List) {
        return jsonEncode(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  String _generateCurl(RequestOptions options) {
    final buffer = StringBuffer(
      'curl -X ${options.method.toUpperCase()} "${options.uri}"',
    );
    options.headers.forEach((key, value) {
      if (key.toLowerCase() != 'content-length') {
        buffer.write(' -H "$key: $value"');
      }
    });
    if (options.data != null) {
      final body = _formatPayload(options.data).replaceAll('"', '\\"');
      buffer.write(' -d "$body"');
    }
    return buffer.toString();
  }
}
