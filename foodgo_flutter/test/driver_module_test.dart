import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/features/dashboard/presentation/driver_dashboard_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleProfile = {
    'username': 'rider_borey',
    'full_name': 'Borey Sok',
    'phone': '+855 77 333 444',
    'vehicle_type': 'Honda Click 125i',
    'license_plate': 'PP-1AA-1234',
    'is_online': true,
    'is_approved': true,
    'rating': 4.9,
  };

  final sampleOrder = {
    'id': 101,
    'order_reference': 'FG-20261022-A1B2C3',
    'status': 'assigned',
    'payment_status': 'PAID',
    'total_amount': '17.50',
    'delivery_fee_charged': '2.50',
    'restaurant': {
      'name': 'Kravanh Bistro',
      'address': 'St 240, Daun Penh',
      'phone': '+855 23 888 777',
      'lat': 11.5580,
      'lng': 104.9280,
    },
    'address': {
      'street': 'Street 271, Boeng Tumpun',
      'lat': 11.5420,
      'lng': 104.9120,
    },
    'customer_info': {'name': 'Somnang Cust', 'phone': '+855 12 111 222'},
  };

  Widget buildDriverDashboard({
    List<dynamic>? active,
    List<dynamic>? available,
    List<dynamic>? history,
  }) {
    return MaterialApp(
      home: DriverDashboardScreen(
        initialLoading: false,
        initialProfile: sampleProfile,
        initialActive: active ?? [],
        initialAvailable: available ?? [],
        initialHistory: history ?? [],
      ),
    );
  }

  group('DriverDashboardScreen Widget Tests', () {
    testWidgets('Renders Driver Portal AppBar and Navigation Header', (
      tester,
    ) async {
      await tester.pumpWidget(buildDriverDashboard());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Driver Portal'), findsOneWidget);
      expect(find.text('Borey Sok'), findsOneWidget);
      expect(find.text('Honda Click 125i · PP-1AA-1234'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets(
      'Renders all 4 segmented tabs: Active, Available, Earnings, Profile',
      (tester) async {
        await tester.pumpWidget(buildDriverDashboard());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Active (0)'), findsOneWidget);
        expect(find.text('Available (0)'), findsOneWidget);
        expect(find.text('Earnings'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets('Active tab displays empty state when no active order', (
      tester,
    ) async {
      await tester.pumpWidget(buildDriverDashboard(active: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Active Deliveries'), findsOneWidget);
      expect(find.text('View Available Orders'), findsOneWidget);
    });

    testWidgets(
      'Active tab renders active delivery card with stepper and navigation buttons',
      (tester) async {
        await tester.pumpWidget(buildDriverDashboard(active: [sampleOrder]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Order #101'), findsOneWidget);
        expect(find.text('Pickup: Kravanh Bistro'), findsOneWidget);
        expect(find.text('Deliver to: Somnang Cust'), findsOneWidget);
        expect(find.text('Arrived at Restaurant'), findsOneWidget);
        expect(find.byIcon(Icons.navigation), findsNWidgets(2));
      },
    );

    testWidgets(
      'Tapping Earnings tab displays earnings metrics and completed trips',
      (tester) async {
        await tester.pumpWidget(buildDriverDashboard(history: [sampleOrder]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap on Earnings tab
        await tester.tap(find.text('Earnings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text("Today's Earnings"), findsOneWidget);
        expect(find.text('Total Trips'), findsOneWidget);
        expect(find.text('Lifetime Earned'), findsOneWidget);
        expect(find.text('Completed Deliveries'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Profile tab displays vehicle, license plate, phone, and rating',
      (tester) async {
        await tester.pumpWidget(buildDriverDashboard());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap on Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Vehicle & Registration'), findsOneWidget);
        expect(find.text('Honda Click 125i'), findsOneWidget);
        expect(find.text('PP-1AA-1234'), findsOneWidget);
        expect(find.text('+855 77 333 444'), findsOneWidget);
        expect(find.text('Approved & Active'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Available Orders tab shows available delivery request cards with Accept and Decline actions',
      (tester) async {
        await tester.pumpWidget(buildDriverDashboard(available: [sampleOrder]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap on Available tab
        await tester.tap(find.text('Available (1)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Order #101'), findsOneWidget);
        expect(find.text('Kravanh Bistro'), findsOneWidget);
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Decline'), findsOneWidget);
      },
    );

    testWidgets(
      'Active delivery on_the_way shows Arrived at Customer and Report Issue actions',
      (tester) async {
        final activeOrder = Map<String, dynamic>.from(sampleOrder);
        activeOrder['status'] = 'on_the_way';
        await tester.pumpWidget(buildDriverDashboard(active: [activeOrder]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Arrived at Customer'), findsOneWidget);
        expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
      },
    );
  });
}
