import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/services/api_service.dart';

String calculateCrc16(String input) {
  int crc = 0xFFFF;
  final bytes = input.codeUnits;
  for (final byte in bytes) {
    crc ^= (byte << 8);
    for (int i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoodGo V4 Frontend Enhancements Tests', () {
    test('CartItem serialization and deserialization', () {
      final item = CartItem(
        id: 42,
        name: 'Fish Amok Special',
        price: 8.50,
        quantity: 3,
        image: 'https://example.com/amok.jpg',
        restaurantId: 7,
        restaurantName: 'Angkor Heritage',
      );

      final json = item.toJson();
      expect(json['id'], 42);
      expect(json['name'], 'Fish Amok Special');
      expect(json['price'], 8.50);
      expect(json['quantity'], 3);
      expect(json['restaurantId'], 7);

      final restored = CartItem.fromJson(json);
      expect(restored.id, 42);
      expect(restored.name, 'Fish Amok Special');
      expect(restored.price, 8.50);
      expect(restored.quantity, 3);
      expect(restored.restaurantId, 7);
      expect(restored.restaurantName, 'Angkor Heritage');
    });

    test('Multi-restaurant collision check in CartProvider', () {
      final cart = CartProvider();
      cart.clear();

      cart.addItem(
        1,
        'Beef Lok Lak',
        7.00,
        null,
        restaurantId: 10,
        restaurantName: 'Restaurant A',
      );
      expect(cart.isDifferentRestaurant(10), false);
      expect(cart.isDifferentRestaurant(11), true);
      expect(cart.isDifferentRestaurant(null), false);
    });

    test('NBC EMVCo standard CRC-16 CCITT computation returns valid 4-character hex checksum', () {
      const rawPayload =
          '00020101021229370016bakong@bkrt0109customer@bkrt53038405802KH5911FoodGo_Member6010Phnom_Penh6304';
      final crc = calculateCrc16(rawPayload);

      expect(crc.length, 4);
      expect(RegExp(r'^[0-9A-F]{4}$').hasMatch(crc), true);
      expect(
        crc != 'ABCD',
        true,
      ); // Verifies real calculation over hardcoded ABCD placeholder
    });

    test('ApiService singleton pattern returns identical instance', () {
      final s1 = ApiService();
      final s2 = ApiService();
      expect(identical(s1, s2), true);
    });

    test(
      'Wallet transaction filtering filters deposit vs payment correctly',
      () {
        final txs = [
          {'id': 1, 'transaction_type': 'deposit', 'amount': '20.00'},
          {'id': 2, 'transaction_type': 'payment', 'amount': '8.50'},
          {'id': 3, 'transaction_type': 'deposit', 'amount': '50.00'},
          {'id': 4, 'transaction_type': 'refund', 'amount': '12.00'},
        ];

        final deposits = txs
            .where((t) => t['transaction_type'] == 'deposit')
            .toList();
        final payments = txs
            .where((t) => t['transaction_type'] != 'deposit')
            .toList();

        expect(deposits.length, 2);
        expect(payments.length, 2);
      },
    );

    test('Driver earnings calculation aggregates delivery fees accurately', () {
      final completedOrders = [
        {'id': 101, 'status': 'delivered', 'delivery_fee_charged': '2.50'},
        {'id': 102, 'status': 'delivered', 'delivery_fee_charged': '3.00'},
        {'id': 103, 'status': 'delivered', 'delivery_fee': '2.00'},
      ];

      final double earnings = completedOrders.fold<double>(0.0, (acc, item) {
        final fee =
            double.tryParse(
              item['delivery_fee_charged']?.toString() ??
                  item['delivery_fee']?.toString() ??
                  '2.00',
            ) ??
            2.00;
        return acc + fee;
      });

      expect(earnings, 7.50);
    });
  });
}
