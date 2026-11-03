import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/screens/map_screen.dart';

void main() {
  Widget buildMapTest(String orderId, {bool isDriver = false}) {
    return MaterialApp(
      home: MapScreen(
        orderId: orderId,
        isDriver: isDriver,
        initialLoading: false,
        initialStatus: 'on_the_way',
      ),
    );
  }

  group('MapScreen Driver vs Customer Mode Tests', () {
    testWidgets(
      'MapScreen in Driver mode renders Delivery title and customer card',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildMapTest('101', isDriver: true));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Delivery #101'), findsOneWidget);
        expect(find.text('Delivering to Somnang Cust'), findsOneWidget);
        expect(find.text('Somnang Cust'), findsOneWidget);
        expect(find.text('Recipient'), findsOneWidget);
        expect(find.text('+855 12 111 222'), findsOneWidget);
        expect(find.text('Note: Gate code 4321'), findsOneWidget);

        // Expand bottom sheet and scroll to bottom
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.text('Complete Delivery (Scan Drop-off QR)'),
          findsOneWidget,
        );
        expect(find.text('Show Courier Handover QR'), findsOneWidget);
        expect(find.text('Back to Driver Dashboard'), findsOneWidget);
      },
    );

    testWidgets(
      'MapScreen in Customer mode renders Order title and customer buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildMapTest('101', isDriver: false));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Order #101'), findsOneWidget);
        expect(find.text('On the way to you'), findsOneWidget);
        expect(find.text('Ahmad Faizal'), findsOneWidget);

        // Expand bottom sheet and scroll to bottom
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Show Delivery Confirmation QR'), findsOneWidget);
        expect(find.text('Scan Driver Handover QR'), findsOneWidget);
        expect(find.text('Back to Home'), findsOneWidget);
      },
    );
  });
}
