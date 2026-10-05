import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/favorites_provider.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';
import 'package:foodgo_flutter/core/config/map_config.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    test('Tile URLs contain Google Maps API Key', () {
      final roadmapUrl = MapConfig.getTileUrl(MapLayerType.googleRoadmap);
      expect(roadmapUrl.contains('key=AIzaSyC3asDbdqC77DpPZt8DSttWJ2r9hLGT2PA'), true);
      expect(roadmapUrl.contains('lyrs=m'), true);

      final satelliteUrl = MapConfig.getTileUrl(MapLayerType.googleSatellite);
      expect(satelliteUrl.contains('lyrs=y'), true);
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
}
