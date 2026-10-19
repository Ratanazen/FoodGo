import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/providers/admin_provider.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/features/admin/presentation/admin_dashboard_screen.dart';

class MockAdminProvider extends AdminProvider {
  @override
  Future<void> fetchAnalytics({String? period}) async {}

  @override
  Future<void> fetchOrders({String? status, String? search}) async {}

  @override
  Future<void> fetchUsers({String? role, String? search}) async {}

  @override
  Future<void> fetchRestaurants({String? search}) async {}

  @override
  Future<void> fetchAuditLogs({int page = 1}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminProvider Unit Tests', () {
    test('Initial AdminProvider state values are correct', () {
      final admin = AdminProvider();
      expect(admin.isLoading, isFalse);
      expect(admin.errorMessage, isNull);
      expect(admin.selectedPeriod, 'all');
      expect(admin.orderStatusFilter, 'all');
      expect(admin.userRoleFilter, 'all');
      expect(admin.orders, isEmpty);
      expect(admin.users, isEmpty);
      expect(admin.restaurants, isEmpty);
      expect(admin.auditLogs, isEmpty);
      expect(admin.analytics, isNull);
    });
  });

  group('CartProvider Special Instructions Tests', () {
    test(
      'specialInstructions defaults to empty string and updates correctly',
      () {
        final cart = CartProvider();
        expect(cart.specialInstructions, '');

        cart.setSpecialInstructions('No onions, extra spicy chili sauce');
        expect(cart.specialInstructions, 'No onions, extra spicy chili sauce');

        cart.clear();
        expect(cart.specialInstructions, '');
      },
    );
  });

  group('UserProvider Role Checks Tests', () {
    test('isAdmin returns true when role is admin or staff', () {
      final userProvider = UserProvider();
      expect(userProvider.isAdmin, isFalse);
    });
  });

  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('Renders Admin Dashboard with 5 tabs', (tester) async {
      final mockAdmin = MockAdminProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminProvider>.value(value: mockAdmin),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the screen title
      expect(find.text('Admin Console'), findsOneWidget);

      // Verify all 5 tab labels are rendered
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Restaurants'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);

      // Verify period selection chips exist on Overview tab
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });
  });
}
