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

  Future<PaymentModel> getPaymentStatus(int paymentId) async {
    final response = await _api.post('payments/$paymentId/status/', {});
    return PaymentModel.fromJson(response);
  }

  Future<void> cancelPayment(int paymentId) async {
    await _api.post('payments/$paymentId/cancel/', {});
  }
}
