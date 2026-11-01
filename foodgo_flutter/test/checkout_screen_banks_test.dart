import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/features/checkout/presentation/checkout_screen.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/address_provider.dart';
import 'package:foodgo_flutter/providers/currency_provider.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';

void main() {
  testWidgets(
    'CheckoutScreen renders Bank options and Live KHQR Active banner',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cartProvider = CartProvider();
      cartProvider.addItem(
        1,
        'Beef Burger',
        12.99,
        '',
        restaurantId: 1,
        restaurantName: 'Burger Joint',
      );

      final addressProvider = AddressProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<AddressProvider>.value(
              value: addressProvider,
            ),
            ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Title & Sections
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);

      // Verify Bank Options
      expect(find.text('Bakong KHQR (ធនាគារជាតិនៃកម្ពុជា)'), findsOneWidget);
      expect(find.text('ABA KHQR (ABA Mobile / PayWay)'), findsOneWidget);
      expect(find.text('ACLEDA KHQR (ACLEDA Mobile)'), findsOneWidget);

      // Verify Live KHQR Active banner & Bank Chips
      expect(find.text('Live Real-Time KHQR Active'), findsOneWidget);
      expect(find.text('15m Session'), findsOneWidget);
      expect(find.text('Bakong'), findsOneWidget);
      expect(find.text('ABA Bank'), findsOneWidget);
      expect(find.text('ACLEDA'), findsOneWidget);
      expect(find.text('Wing'), findsOneWidget);
      expect(find.text('Canadia'), findsOneWidget);

      // Verify Button Text
      expect(
        find.text('Proceed to Pay with Bakong KHQR'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'CheckoutScreen supports 10 zero-dollar items with Bakong KHQR checkout',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cartProvider = CartProvider();
      final zeroItems = [
        'Classic Double Smash Cheeseburger',
        'Truffle Bacon Swiss Burger',
        'Crispy Spicy Chicken Burger',
        'Smoky BBQ Bacon Burger',
        'Golden Truffle Parmesan Fries',
        'Beer-Battered Onion Rings',
        'Crispy Mozzarella Sticks',
        'Salted Caramel Milkshake',
        'Fresh Mint Craft Lemonade',
        'Garden Fresh Salad',
      ];
      for (int i = 0; i < zeroItems.length; i++) {
        cartProvider.addItem(
          i + 2,
          zeroItems[i],
          0.00,
          '',
          restaurantId: 1,
          restaurantName: 'Glass Burger',
        );
      }

      final addressProvider = AddressProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
            ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ],
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cartProvider.itemCount, 10);
      expect(cartProvider.totalAmount, 0.00);
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Bakong KHQR (ធនាគារជាតិនៃកម្ពុជា)'), findsOneWidget);
      expect(
        find.text('Proceed to Pay with Bakong KHQR'),
        findsOneWidget,
      );
    },
  );
}
