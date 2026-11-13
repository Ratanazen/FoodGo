import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/features/home/presentation/widgets/floating_order_mini_tracker.dart';

void main() {
  Widget buildTestWidget({
    MiniTrackerDeliveryStatus status = MiniTrackerDeliveryStatus.onTheWay,
    VoidCallback? onDismiss,
    Brightness brightness = Brightness.dark,
  }) {
    return MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: brightness,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingOrderMiniTracker(
              orderId: 108,
              restaurantName: 'Glass Burger BKK1',
              totalAmount: 18.50,
              etaMinutes: 14,
              status: status,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );
  }

  group('FloatingOrderMiniTracker UI & UX Component Tests', () {
    testWidgets(
      'Renders order status, restaurant name, total price, and ETA countdown pill',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Courier is On The Way'), findsOneWidget);
        expect(find.text('#108'), findsOneWidget);
        expect(find.text('Glass Burger BKK1'), findsOneWidget);
        expect(find.text(' • \$18.50'), findsOneWidget);
        expect(find.text('14 min'), findsOneWidget);
        expect(find.text('Live Map'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders distinct status labels for confirmed, preparing, and arrived',
      (tester) async {
        // 1. Preparing
        await tester.pumpWidget(
          buildTestWidget(status: MiniTrackerDeliveryStatus.preparing),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Kitchen is Preparing'), findsOneWidget);

        // 2. Arrived
        await tester.pumpWidget(
          buildTestWidget(status: MiniTrackerDeliveryStatus.arrived),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Rider Has Arrived!'), findsOneWidget);

        // 3. Confirmed
        await tester.pumpWidget(
          buildTestWidget(status: MiniTrackerDeliveryStatus.confirmed),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Order Confirmed'), findsOneWidget);
      },
    );

    testWidgets(
      'Supports horizontal swipe dismiss and invokes onDismiss callback',
      (tester) async {
        bool dismissed = false;
        await tester.pumpWidget(
          buildTestWidget(onDismiss: () => dismissed = true),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(FloatingOrderMiniTracker), findsOneWidget);

        // Drag dismissible completely off-screen
        await tester.drag(find.byType(Dismissible), const Offset(-800, 0));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(dismissed, isTrue);
      },
    );

    testWidgets('Renders properly in both light and dark modes', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(brightness: Brightness.light));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Courier is On The Way'), findsOneWidget);

      await tester.pumpWidget(buildTestWidget(brightness: Brightness.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Courier is On The Way'), findsOneWidget);
    });
  });
}
