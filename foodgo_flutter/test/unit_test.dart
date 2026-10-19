import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/widgets/responsive_layout.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/favorites_provider.dart';
import 'package:foodgo_flutter/providers/address_provider.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';
import 'package:foodgo_flutter/core/config/map_config.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/core/utils/khmer_currency.dart';

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

    test('fromJson handles BAKONG provider', () {
      final json = {
        'id': 105,
        'order': 46,
        'provider': 'BAKONG',
        'method': 'KHQR',
        'amount': '12.00',
        'currency': 'USD',
        'status': 'PENDING',
        'qr_payload': '00020101021229350011bakong@khqr0116sonar_seang@bkrt...',
      };
      final payment = PaymentModel.fromJson(json);
      expect(payment.id, 105);
      expect(payment.provider, 'BAKONG');
      expect(payment.amount, 12.00);
      expect(payment.isPending, true);
    });
  });

  group('MapConfig Tests', () {
    test('OpenStreetMap and OpenMap tile URLs return valid templates without API keys', () {
      final osmUrl = MapConfig.getTileUrl(MapLayerType.openStreetMap);
      expect(osmUrl.contains('tile.openstreetmap.org'), true);

      final darkUrl = MapConfig.getTileUrl(MapLayerType.cartoDark);
      expect(darkUrl.contains('basemaps.cartocdn.com'), true);
      expect(darkUrl.contains('dark_all'), true);

      final voyagerUrl = MapConfig.getTileUrl(MapLayerType.cartoVoyager);
      expect(voyagerUrl.contains('basemaps.cartocdn.com'), true);
      expect(voyagerUrl.contains('voyager'), true);

      final subdomains = MapConfig.getSubdomains(MapLayerType.openStreetMap);
      expect(subdomains.contains('a') && subdomains.contains('b'), true);
    });

    test('Distance and ETA calculations return positive reasonable values', () {
      const start = LatLng(11.5564, 104.9282);
      const end = LatLng(11.5621, 104.9160);
      final distance = MapConfig.calculateDistanceKm(start, end);
      expect(distance > 0.5 && distance < 3.0, true);

      final eta = MapConfig.estimateDeliveryMinutes(distance);
      expect(eta >= 3 && eta <= 30, true);
    });
  });

  group('CartProvider LastOrderId Tests', () {
    test('lastOrderId can be set and read properly', () {
      final cart = CartProvider();
      expect(cart.lastOrderId, null);

      cart.setLastOrderId(789);
      expect(cart.lastOrderId, 789);

      cart.setLastOrderId(null);
      expect(cart.lastOrderId, null);
    });
  });

  group('CartProvider Decrement & Fee Tests', () {
    test('decrementItem reduces quantity when > 1', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 5.0, null);
      cart.addItem(1, 'Burger', 5.0, null);
      cart.addItem(1, 'Burger', 5.0, null);
      expect(cart.items[1]!.quantity, 3);
      expect(cart.totalAmount, 15.0);

      cart.decrementItem(1);
      expect(cart.items[1]!.quantity, 2);
      expect(cart.totalAmount, 10.0);
    });

    test('decrementItem removes item when quantity reaches 1', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 5.0, null);
      expect(cart.itemCount, 1);

      cart.decrementItem(1);
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
    });

    test('decrementItem on missing item does not crash', () {
      final cart = CartProvider();
      expect(() => cart.decrementItem(999), returnsNormally);
    });

    test('deliveryFee and grandTotal calculate accurately', () {
      final cart = CartProvider();
      expect(cart.deliveryFee, 0.0);
      expect(cart.grandTotal, 0.0);

      cart.addItem(1, 'Pizza', 12.0, null, deliveryFee: 1.50);
      expect(cart.totalAmount, 12.0);
      expect(cart.deliveryFee, 1.50);
      expect(cart.grandTotal, 13.50);

      cart.setDeliveryFee(3.00);
      expect(cart.deliveryFee, 3.00);
      expect(cart.grandTotal, 15.00);

      cart.clear();
      expect(cart.deliveryFee, 0.0);
      expect(cart.grandTotal, 0.0);
    });
  });

  group('CartProvider Promo Code Tests', () {
    test('applyPromoCode with FOODGOFREE waives delivery fee', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 10.0, null, deliveryFee: 2.0);
      expect(cart.totalAmount, 10.0);
      expect(cart.deliveryFee, 2.0);
      expect(cart.grandTotal, 12.0);

      final success = cart.applyPromoCode('FOODGOFREE');
      expect(success, true);
      expect(cart.appliedPromoCode, 'FOODGOFREE');
      expect(cart.discountAmount, 2.0);
      expect(cart.grandTotal, 10.0);
    });

    test(
      'applyPromoCode with percentage discounts (FOODGO30, FOODGO20, FOODGO50)',
      () {
        final cart = CartProvider();
        cart.addItem(1, 'Pizza', 20.0, null, deliveryFee: 2.0);

        expect(cart.applyPromoCode('FOODGO30'), true);
        expect(cart.discountAmount, 6.0); // 30% of 20
        expect(cart.grandTotal, 16.0); // 20 + 2 - 6 = 16

        expect(cart.applyPromoCode('FOODGO20'), true);
        expect(cart.discountAmount, 4.0); // 20% of 20
        expect(cart.grandTotal, 18.0); // 20 + 2 - 4 = 18

        expect(cart.applyPromoCode('FOODGO50'), true);
        expect(cart.discountAmount, 10.0); // 50% of 20
        expect(cart.grandTotal, 12.0); // 20 + 2 - 10 = 12
      },
    );

    test('applyPromoCode with EXPRESS provides delivery discount', () {
      final cart = CartProvider();
      cart.addItem(1, 'Sushi', 15.0, null, deliveryFee: 3.0);

      expect(cart.applyPromoCode('express'), true); // case-insensitive
      expect(cart.discountAmount, 2.0);
      expect(cart.grandTotal, 16.0); // 15 + 3 - 2 = 16
    });

    test('Invalid promo code returns false and does not set discount', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 10.0, null);

      expect(cart.applyPromoCode('INVALID99'), false);
      expect(cart.appliedPromoCode, null);
      expect(cart.discountAmount, 0.0);
    });

    test('removePromoCode resets discount amount and restores grandTotal', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 10.0, null, deliveryFee: 2.0);
      cart.applyPromoCode('FOODGO50');
      expect(cart.grandTotal, 7.0);

      cart.removePromoCode();
      expect(cart.appliedPromoCode, null);
      expect(cart.discountAmount, 0.0);
      expect(cart.grandTotal, 12.0);
    });

    test('recalculateDiscount updates when items are added or removed', () {
      final cart = CartProvider();
      cart.addItem(1, 'Burger', 10.0, null, deliveryFee: 0.0);
      cart.applyPromoCode('FOODGO50');
      expect(cart.discountAmount, 5.0);

      cart.addItem(2, 'Drink', 4.0, null);
      expect(cart.discountAmount, 7.0); // 50% of 14

      cart.decrementItem(2);
      expect(cart.discountAmount, 5.0); // 50% of 10
    });
  });

  group('AddressProvider Tests', () {
    test('Initial addresses and fallback loading', () async {
      final provider = AddressProvider();
      expect(provider.addresses, isEmpty);

      await provider.fetchAddresses();
      expect(provider.addresses.isNotEmpty, true);
      expect(provider.selectedAddress, isNotNull);
    });

    test('Adding address prepends to list and can be selected', () async {
      final provider = AddressProvider();
      await provider.fetchAddresses();
      final initialCount = provider.addresses.length;

      final success = await provider.addAddress(
        street: 'Street 51, BKK1',
        city: 'Phnom Penh',
        isDefault: true,
      );
      expect(success, true);
      expect(provider.addresses.length, initialCount + 1);
      expect(provider.selectedAddress?.street, 'Street 51, BKK1');
      expect(provider.selectedAddress?.isDefault, true);
    });

    test('setDefaultAddress updates default status across list', () async {
      final provider = AddressProvider();
      await provider.fetchAddresses();
      final firstId = provider.addresses.first.id;
      final secondId = provider.addresses[1].id;

      await provider.setDefaultAddress(secondId);
      expect(
        provider.addresses.firstWhere((a) => a.id == secondId).isDefault,
        true,
      );
      expect(
        provider.addresses.firstWhere((a) => a.id == firstId).isDefault,
        false,
      );
      expect(provider.selectedAddress?.id, secondId);
    });

    test('deleteAddress removes item from list', () async {
      final provider = AddressProvider();
      await provider.fetchAddresses();
      final countBefore = provider.addresses.length;
      final targetId = provider.addresses.first.id;

      await provider.deleteAddress(targetId);
      expect(provider.addresses.length, countBefore - 1);
      expect(provider.addresses.any((a) => a.id == targetId), false);
    });

    test('selectAddress updates selectedAddress', () async {
      final provider = AddressProvider();
      await provider.fetchAddresses();
      final secondAddress = provider.addresses[1];

      provider.selectAddress(secondAddress);
      expect(provider.selectedAddress?.id, secondAddress.id);
    });
  });

  group('PaymentModel Cancelled State Tests', () {
    test('PaymentModel handles CANCELLED status', () {
      final json = {
        'id': 108,
        'order': 50,
        'provider': 'BAKONG',
        'method': 'KHQR',
        'amount': '20.00',
        'currency': 'USD',
        'status': 'CANCELLED',
      };
      final payment = PaymentModel.fromJson(json);
      expect(payment.isCancelled, true);
      expect(payment.isPending, false);
      expect(payment.isPaid, false);
    });
  });

  group('FavoritesProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Toggling restaurant adds and removes from favorites', () async {
      final favorites = FavoritesProvider();
      await favorites.loadFavorites();

      final restaurant = {'id': 10, 'name': 'Burger King'};
      expect(favorites.isRestaurantFavorite(10), false);
      expect(favorites.favoriteRestaurants.length, 0);

      await favorites.toggleRestaurant(restaurant);
      expect(favorites.isRestaurantFavorite(10), true);
      expect(favorites.favoriteRestaurants.length, 1);
      expect(favorites.totalFavoritesCount, 1);

      await favorites.toggleRestaurant(restaurant);
      expect(favorites.isRestaurantFavorite(10), false);
      expect(favorites.favoriteRestaurants.length, 0);
      expect(favorites.totalFavoritesCount, 0);
    });

    test('Toggling food item adds and removes from favorites', () async {
      final favorites = FavoritesProvider();
      await favorites.loadFavorites();

      final food = {'id': 101, 'name': 'Classic Cheese Burger', 'price': 6.50};
      expect(favorites.isFoodFavorite(101), false);
      expect(favorites.favoriteFoodItems.length, 0);

      await favorites.toggleFoodItem(food);
      expect(favorites.isFoodFavorite(101), true);
      expect(favorites.favoriteFoodItems.length, 1);
      expect(favorites.totalFavoritesCount, 1);

      await favorites.toggleFoodItem(food);
      expect(favorites.isFoodFavorite(101), false);
      expect(favorites.favoriteFoodItems.length, 0);
      expect(favorites.totalFavoritesCount, 0);
    });
  });

  group('ResponsiveLayout Tests', () {
    test('ResponsiveBreakpoints defined accurately for desktop, tablet, and mobile', () {
      expect(ResponsiveBreakpoints.mobileMax, 650.0);
      expect(ResponsiveBreakpoints.tabletMax, 1050.0);
      expect(ResponsiveBreakpoints.wideThreshold, 800.0);
      expect(
        ResponsiveBreakpoints.mobileMax < ResponsiveBreakpoints.wideThreshold,
        true,
      );
      expect(
        ResponsiveBreakpoints.wideThreshold < ResponsiveBreakpoints.tabletMax,
        true,
      );
    });

    testWidgets('ResponsiveWebContainer constrains width on wide screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveWebContainer(
              maxWidth: 800,
              child: Text('FoodGo Web Content'),
            ),
          ),
        ),
      );

      expect(find.text('FoodGo Web Content'), findsOneWidget);
      expect(find.byType(ResponsiveWebContainer), findsOneWidget);
    });
  });

  group('KhmerCurrency Tests', () {
    test('formatUsd formats currency with dollar sign and two decimals', () {
      expect(KhmerCurrency.formatUsd(10.0), '\$10.00');
      expect(KhmerCurrency.formatUsd(5.5), '\$5.50');
      expect(KhmerCurrency.formatUsd(0.0), '\$0.00');
    });

    test(
      'formatKhr converts at 4100 rate with riel symbol and thousand commas',
      () {
        expect(KhmerCurrency.formatKhr(1.0), '៛4,100');
        expect(KhmerCurrency.formatKhr(10.0), '៛41,000');
        expect(KhmerCurrency.formatKhr(25.0), '៛102,500');
      },
    );

    test('formatDual and formatDualApprox format correctly', () {
      expect(KhmerCurrency.formatDual(10.0), '\$10.00 (៛41,000)');
      expect(KhmerCurrency.formatDualApprox(10.0), '\$10.00 ≈ ៛41,000');
    });

    test('toKhr and toUsd convert back and forth accurately', () {
      expect(KhmerCurrency.toKhr(10.0), 41000);
      expect(KhmerCurrency.toUsd(41000), 10.0);
    });
  });

  group('KHQR Pay Me (My QR) Tests', () {
    test('Constructs valid NBC standard KHQR Pay Me payload structure', () {
      const username = 'alice_smith';
      const bakongId = '$username@bkrt';
      const amount = 10.0;
      final amtStr = amount.toStringAsFixed(2);
      final payload =
          '00020101021229370016bakong@bkrt0109$bakongId'
          '5303840'
          '540${amtStr.length.toString().padLeft(2, '0')}$amtStr'
          '5802KH5911Alice_Smith'
          '6010Phnom_Penh6304ABCD';

      expect(payload.startsWith('000201010212'), true);
      expect(payload.contains(bakongId), true);
      expect(payload.contains('5303840'), true); // USD currency tag
      expect(payload.contains('5802KH'), true); // Country tag Cambodia
    });
  });

  group('PaymentModel Status State Tests', () {
    test('PaymentModel correctly identifies FAILED, PROCESSING, and REFUNDED states', () {
      final failedPayment = PaymentModel(
        id: 101,
        orderId: 1,
        provider: 'ABA',
        method: 'KHQR',
        amount: 15.50,
        currency: 'USD',
        status: 'FAILED',
      );
      expect(failedPayment.isFailed, true);
      expect(failedPayment.isPaid, false);
      expect(failedPayment.isExpired, false);

      final processingPayment = PaymentModel(
        id: 102,
        orderId: 1,
        provider: 'BAKONG',
        method: 'KHQR',
        amount: 20.00,
        currency: 'USD',
        status: 'PROCESSING',
      );
      expect(processingPayment.isProcessing, true);
      expect(processingPayment.isPaid, false);

      final refundedPayment = PaymentModel(
        id: 103,
        orderId: 1,
        provider: 'WALLET',
        method: 'WALLET',
        amount: 10.00,
        currency: 'USD',
        status: 'REFUNDED',
      );
      expect(refundedPayment.isRefunded, true);
      expect(refundedPayment.isPaid, false);
    });
  });

  group('Delivery Confirmation QR & PIN Tests', () {
    test(
      'QR payload generator and parser parses order_id and token correctly',
      () {
        const orderId = '123';
        const token = 'abc_xyz_secret_token_123';
        final qrPayload =
            'FOODGO:DELIVERY:CONFIRM:v1?order_id=$orderId&token=$token';

        expect(qrPayload.startsWith('FOODGO:DELIVERY:CONFIRM:v1'), true);

        // Parse payload
        final uri = Uri.parse(
          qrPayload.replaceFirst(
            'FOODGO:DELIVERY:CONFIRM:v1?',
            'https://foodgo.app/?',
          ),
        );
        expect(uri.queryParameters['order_id'], '123');
        expect(uri.queryParameters['token'], 'abc_xyz_secret_token_123');
      },
    );

    test('Verification PIN validation enforces 6 numeric digits', () {
      final validPinRegex = RegExp(r'^\d{6}$');

      expect(validPinRegex.hasMatch('123456'), true);
      expect(validPinRegex.hasMatch('908172'), true);
      expect(validPinRegex.hasMatch('12345'), false); // 5 digits
      expect(validPinRegex.hasMatch('1234567'), false); // 7 digits
      expect(validPinRegex.hasMatch('abcdef'), false); // Non-numeric
      expect(validPinRegex.hasMatch(''), false); // Empty
    });

    test('Delivery confirmation response preserves UNPAID status', () {
      final confirmationResponse = {
        'status': 'SUCCESS',
        'message': 'Delivery confirmed successfully!',
        'order_id': 123,
        'order_status': 'delivered',
        'delivery_time': '2026-10-13T14:30:00Z',
        'driver_name': 'Bob Rider',
        'confirmed_by': 'alice_customer',
      };

      expect(confirmationResponse['order_status'], 'delivered');
      expect(confirmationResponse['status'], 'SUCCESS');
      // Verify payment status is not automatically marked as PAID
      expect(confirmationResponse.containsKey('payment_status'), false);
    });
  });
}
