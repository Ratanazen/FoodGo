import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';
import 'package:foodgo_flutter/widgets/glass/glass_bottom_navigation.dart';
import 'package:foodgo_flutter/widgets/delivery_qr_modal.dart';

void main() {
  group('GlassBottomNavigation Widget Tests', () {
    testWidgets('Renders floating pill with 5 navigation items and labels', (
      WidgetTester tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: GlassBottomNavigation(
                selectedIndex: 0,
                onDestinationSelected: (index) {
                  tappedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 5 navigation labels are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify tapping 'Saved' invokes onDestinationSelected callback with index 1
      await tester.tap(find.text('Saved'));
      await tester.pump();
      expect(tappedIndex, 1);

      // Verify tapping 'Cart' invokes onDestinationSelected callback with index 2
      await tester.tap(find.text('Cart'));
      await tester.pump();
      expect(tappedIndex, 2);
    });

    testWidgets('Renders cart badge count when items exist in cart', (
      WidgetTester tester,
    ) async {
      final cartProvider = CartProvider();
      cartProvider.addItem(1, 'Cheeseburger', 6.50, null);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cartProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: GlassBottomNavigation(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify badge displays '1' item
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('DeliveryQrModal Widget Tests', () {
    testWidgets(
      'Renders customer mode with confirmation title and payment warning badge',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DeliveryQrModal(
                orderId: '42',
                isDriver: false,
                autoFetch: false,
                initialPin: '123456',
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify customer delivery confirmation title and instruction
        expect(find.text('Delivery Confirmation QR'), findsOneWidget);
        expect(find.text('Order #42 • Show to driver'), findsOneWidget);
        expect(
          find.text('Delivery Confirmation (Not Payment)'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Show this QR code to your assigned FoodGo delivery driver upon arrival. The driver will scan it to verify and complete your delivery.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders driver mode with handover title and customer scan instruction',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DeliveryQrModal(
                orderId: '88',
                isDriver: true,
                autoFetch: false,
                initialPin: '654321',
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify driver handover title and instruction
        expect(find.text('Delivery Handover QR'), findsOneWidget);
        expect(find.text('Order #88 • Show to customer'), findsOneWidget);
        expect(find.text('Delivery Confirmation (Not Payment)'), findsNothing);
        expect(
          find.text(
            'Present this code at customer doorstep. Customer will scan with FoodGo app to confirm handover.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
