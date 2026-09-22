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

  group('CartProvider Edge Cases', () {
    test('Remove item that does not exist does nothing', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 5.00, null);
      cart.removeItem(999); // non-existent
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 5.00);
    });

    test('Clear empty cart does not throw', () {
      final cart = CartProvider();
      expect(() => cart.clear(), returnsNormally);
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
    });

    test('Adding multiple different items calculates total correctly', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 5.50, null);
      cart.addItem(2, 'Fries', 2.00, null);
      cart.addItem(3, 'Drink', 1.50, null);
      expect(cart.itemCount, 3);
      expect(cart.totalAmount, 9.00);
    });

    test('Adding same item multiple times increases quantity', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 5.50, null);
      cart.addItem(1, 'Burger', 5.50, null);
      cart.addItem(1, 'Burger', 5.50, null);
      expect(cart.itemCount, 1);
      expect(cart.items[1]!.quantity, 3);
      expect(cart.totalAmount, 16.50);
    });
  });

  group('PaymentModel Edge Cases', () {
    test('fromJson handles PAID status', () {
      final json = {
        'id': 102,
        'order': 43,
        'provider': 'ACLEDA',
        'method': 'KHQR',
        'amount': '25.00',
        'currency': 'USD',
        'status': 'PAID',
        'qr_payload': '00020101...',
      };
      final payment = PaymentModel.fromJson(json);
      expect(payment.isPaid, true);
      expect(payment.isPending, false);
      expect(payment.provider, 'ACLEDA');
    });

    test('fromJson handles EXPIRED status', () {
      final json = {
        'id': 103,
        'order': 44,
        'provider': 'ABA',
        'method': 'KHQR',
        'amount': '10.00',
        'currency': 'USD',
        'status': 'EXPIRED',
        'qr_payload': '',
      };
      final payment = PaymentModel.fromJson(json);
      expect(payment.isExpired, true);
      expect(payment.isPaid, false);
      expect(payment.isPending, false);
    });

    test('fromJson handles null qr_payload', () {
      final json = {
        'id': 104,
        'order': 45,
        'provider': 'ABA',
        'method': 'COD',
        'amount': '5.00',
        'currency': 'USD',
        'status': 'PENDING',
        'qr_payload': null,
      };
      final payment = PaymentModel.fromJson(json);
      expect(payment.id, 104);
      expect(payment.isPending, true);
    });
  });
}
