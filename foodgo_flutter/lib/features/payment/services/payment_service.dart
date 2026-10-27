import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../services/api_service.dart';
import '../models/payment_model.dart';

class FlutterPaymentService {
  final ApiService _api = ApiService();

  Future<PaymentModel> createPayment({
    required int orderId,
    required String provider,
    String currency = 'USD',
  }) async {
    final response = await _api.post('payments/create/', {
      'order_id': orderId,
      'provider': provider,
      'currency': currency,
    });
    return PaymentModel.fromJson(response);
  }

  Future<PaymentModel> getPayment(int paymentId) async {
    final response = await _api.get('payments/$paymentId/');
    return PaymentModel.fromJson(response);
  }

  Future<PaymentModel> getPaymentStatus(
    int paymentId, {
    bool simulate = false,
  }) async {
    final body = simulate
        ? {'simulate': true, 'status': 'PAID'}
        : <String, dynamic>{};
    final response = await _api.post('payments/$paymentId/status/', body);
    return PaymentModel.fromJson(response);
  }

  Future<void> cancelPayment(int paymentId) async {
    await _api.post('payments/$paymentId/cancel/', {});
  }

  /// Connects to real-time Daphne ASGI WebSocket stream for instant payment push notifications
  Stream<PaymentModel> subscribePaymentStatus(
    int paymentId, {
    String? customWsUrl,
  }) async* {
    WebSocketChannel? channel;
    try {
      final token = await SecureStorage().getAccessToken() ?? '';
      final wsBase = customWsUrl ?? AppConfig.wsPaymentBaseUrl;
      final normalizedWsBase = wsBase.endsWith('/') ? wsBase : '$wsBase/';
      final tokenParam = token.isNotEmpty
          ? '?token=$token'
          : '?token=simulator-token';
      final wsUri = Uri.parse('$normalizedWsBase$paymentId/$tokenParam');

      channel = WebSocketChannel.connect(wsUri);
      await for (final rawMessage in channel.stream) {
        try {
          final data = jsonDecode(rawMessage.toString());
          if (data is Map<String, dynamic> &&
              data['type'] == 'payment_status_update') {
            yield PaymentModel(
              id:
                  int.tryParse(data['payment_id']?.toString() ?? '') ??
                  paymentId,
              orderId: int.tryParse(data['order_id']?.toString() ?? '') ?? 0,
              provider: data['provider'] ?? 'BAKONG',
              method: 'KHQR',
              transactionId: data['transaction_id'],
              merchantReference: data['merchant_reference'],
              orderReference: data['order_reference'],
              restaurantName: data['restaurant_name'],
              amount: double.tryParse(data['amount']?.toString() ?? '') ?? 0.0,
              currency: data['currency'] ?? 'USD',
              status: data['status'] ?? 'PENDING',
              paidAt: data['paid_at'] != null
                  ? DateTime.tryParse(data['paid_at'].toString())
                  : null,
            );
          }
        } catch (e) {
          debugPrint('Error parsing payment WebSocket event: $e');
        }
      }
    } catch (e) {
      debugPrint('Payment WebSocket connection error: $e');
    } finally {
      channel?.sink.close();
    }
  }
}
