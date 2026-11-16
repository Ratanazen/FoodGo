import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgo_flutter/features/dashboard/presentation/driver_dashboard_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleProfile = {
    'username': 'driver1',
    'full_name': 'Bob Rider',
    'phone': '+855 12 888 999',
    'vehicle_type': 'Motorcycle (Honda Wave)',
    'license_plate': 'PP-2026',
    'is_online': true,
    'is_approved': true,
    'rating': 4.9,
  };

  Map<String, dynamic> buildCodOrder({
    required String orderStatus,
    required String deliveryStatus,
  }) {
    return {
      'id': 303,
      'order_reference': 'FG-20261116-COD303',
      'status': orderStatus,
      'payment_status': 'PENDING',
      'total_amount': '14.00',
      'delivery_fee_charged': '1.50',
      'payment_info': {'provider': 'COD', 'method': 'COD', 'status': 'PENDING'},
      'assigned_driver': {
        'id': 1,
        'name': 'Bob Rider',
        'status': deliveryStatus,
      },
      'delivery_token_info': {'delivery_status': deliveryStatus},
      'restaurant': {
        'name': 'Glass Burger',
        'address': 'St 308, Phnom Penh',
        'phone': '+855 23 888 777',
        'lat': 11.5564,
        'lng': 104.9282,
      },
      'address': {
        'street': 'Street 271, Phnom Penh',
        'lat': 11.5621,
        'lng': 104.9160,
      },
      'customer_info': {'name': 'Alice Smith', 'phone': '+855 12 345 678'},
    };
  }

  Widget wrapDashboard(Map<String, dynamic> order) {
    return MaterialApp(
      home: DriverDashboardScreen(
        initialLoading: false,
        initialProfile: sampleProfile,
        initialActive: [order],
        initialAvailable: const [],
        initialHistory: const [],
      ),
    );
  }

  testWidgets(
    'Confirmed COD order with assigned delivery starts at Arrived at Restaurant',
    (tester) async {
      await tester.pumpWidget(
        wrapDashboard(
          buildCodOrder(orderStatus: 'confirmed', deliveryStatus: 'assigned'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Order #303'), findsOneWidget);
      expect(find.text('CASH DUE ON DELIVERY'), findsOneWidget);
      expect(find.text('Arrived at Restaurant'), findsOneWidget);
      expect(find.text('Complete Delivery Handover'), findsNothing);
    },
  );

  testWidgets(
    'Confirmed COD order after arrive-restaurant advances to Confirm Food Picked Up',
    (tester) async {
      await tester.pumpWidget(
        wrapDashboard(
          buildCodOrder(
            orderStatus: 'confirmed',
            deliveryStatus: 'arrived_at_restaurant',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('AT RESTAURANT'), findsOneWidget);
      expect(find.text('Confirm Food Picked Up'), findsOneWidget);
    },
  );

  testWidgets(
    'Arrived COD order requires cash-collection confirmation in Direct Handover dialog',
    (tester) async {
      await tester.pumpWidget(
        wrapDashboard(
          buildCodOrder(
            orderStatus: 'driver_arrived',
            deliveryStatus: 'arrived',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final handoverBtn = find.text('Complete Delivery Handover');
      expect(handoverBtn, findsOneWidget);
      await tester.ensureVisible(handoverBtn);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(handoverBtn);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Complete Delivery #303'), findsOneWidget);
      expect(find.text('Payment Due Upon Delivery'), findsOneWidget);

      final directTile = find.text('Direct Handover Confirmation');
      await tester.ensureVisible(directTile);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(directTile);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Confirm delivery #303'), findsOneWidget);
      final confirmBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm delivered'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.tap(
        find.text('I collected the cash payment from the customer'),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final enabledConfirmBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm delivered'),
      );
      expect(enabledConfirmBtn.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Multi-order S22 portrait DriverDashboard scrolls action button into hit-testable viewport',
    (tester) async {
      final prevFatal = WidgetController.hitTestWarningShouldBeFatal;
      WidgetController.hitTestWarningShouldBeFatal = true;
      tester.view.physicalSize = const Size(384, 823.5);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        WidgetController.hitTestWarningShouldBeFatal = prevFatal;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final orders = [
        for (final id in [303, 302, 301, 300])
          {
            ...buildCodOrder(
              orderStatus: 'confirmed',
              deliveryStatus: 'assigned',
            ),
            'id': id,
            'order_reference': 'FG-20261116-COD$id',
          },
      ];

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: const EdgeInsets.only(top: 36, bottom: 20)),
            child: child!,
          ),
          home: DriverDashboardScreen(
            initialLoading: false,
            initialProfile: sampleProfile,
            initialActive: orders,
            initialAvailable: const [],
            initialHistory: const [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final codCardFinder = find.byKey(const ValueKey('driver_order_card_303'));
      expect(codCardFinder, findsOneWidget);
      final btnFinder = find.descendant(
        of: codCardFinder,
        matching: find.text('Arrived at Restaurant'),
      );
      expect(btnFinder, findsOneWidget);

      final h = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final verticalScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      for (var i = 0; i < 20; i++) {
        final dy = tester.getCenter(btnFinder.first).dy;
        if (dy >= 180 && dy <= h - 160) break;
        final enclosing = find.ancestor(
          of: btnFinder.first,
          matching: verticalScrollable,
        );
        final scroller = enclosing.evaluate().isNotEmpty
            ? enclosing.first
            : verticalScrollable.last;
        final totalDelta = dy > h - 160 ? -100.0 : 100.0;
        final gesture = await tester.startGesture(tester.getCenter(scroller));
        for (var s = 0; s < 4; s++) {
          await gesture.moveBy(Offset(0, totalDelta / 4));
          await tester.pump(const Duration(milliseconds: 30));
        }
        await tester.pump(const Duration(milliseconds: 180));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 200));
      }

      final finalDy = tester.getCenter(btnFinder.first).dy;
      expect(finalDy, inInclusiveRange(160.0, h - 120.0));
      await tester.tap(btnFinder.first);
      await tester.pump(const Duration(milliseconds: 150));
    },
  );
}
