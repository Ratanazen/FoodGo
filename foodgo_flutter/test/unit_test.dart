import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';

void main() {
  group('CartProvider Tests', () {
    test('Add item updates quantity and totalAmount', () {
      final cart = CartProvider();
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);

      cart.addItem(1, 'Glass Burger', 5.50, null);
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 5.50);

      cart.addItem(1, 'Glass Burger', 5.50, null);
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 11.00);

      cart.addItem(2, 'Fries', 2.00, null);
      expect(cart.itemCount, 2);
      expect(cart.totalAmount, 13.00);

      cart.removeItem(1);
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 2.00);

      cart.clear();
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
    });
  });

  group('PaymentModel Tests', () {
    test('fromJson deserializes correctly', () {
      final json = {
        'id': 101,
        'order': 42,
        'provider': 'ABA',
        'method': 'KHQR',
        'amount': '15.50',
        'currency': 'USD',
        'status': 'PENDING',
        'qr_payload': '00020101...',
      };

      final payment = PaymentModel.fromJson(json);
      expect(payment.id, 101);
      expect(payment.orderId, 42);
      expect(payment.provider, 'ABA');
      expect(payment.amount, 15.50);
      expect(payment.isPending, true);
      expect(payment.isPaid, false);
      expect(payment.isExpired, false);
    });
  });
}
