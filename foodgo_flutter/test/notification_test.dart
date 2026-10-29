import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/providers/notification_provider.dart';
import 'package:foodgo_flutter/features/profile/presentation/notifications_screen.dart';
import 'package:foodgo_flutter/widgets/glass/glass_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationModel Tests', () {
    test('Parses from valid JSON payload with orderId', () {
      final json = {
        'id': '99',
        'title': 'Courier Arrived',
        'message': 'Driver is waiting at your gate.',
        'notification_type': 'order',
        'data': {'order_id': 1050, 'status': 'arrived'},
        'is_read': false,
        'created_at': '2026-10-19T10:00:00Z',
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, '99');
      expect(model.title, 'Courier Arrived');
      expect(model.message, 'Driver is waiting at your gate.');
      expect(model.notificationType, 'order');
      expect(model.orderId, 1050);
      expect(model.isRead, false);
      expect(model.icon, Icons.delivery_dining);
    });

    test('Parses promo notification type and maps icon', () {
      final json = {
        'id': '100',
        'title': 'Weekend Promo',
        'message': 'Get 30% off with KHQR30',
        'notification_type': 'promo',
        'data': {'code': 'KHQR30'},
        'is_read': true,
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, '100');
      expect(model.notificationType, 'promo');
      expect(model.isRead, true);
      expect(model.icon, Icons.local_offer);
      expect(model.timeAgo, 'Recent');
    });
  });

  group('NotificationProvider Tests', () {
    test('Initializes empty and waits for server data', () {
      final provider = NotificationProvider();
      expect(provider.isInitialized, true);
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.orderNotifications, isEmpty);
    });

    test(
      'Seeds caller-supplied notifications without inventing order data',
      () {
        final provider = NotificationProvider(
          initialNotifications: [
            NotificationModel(
              id: 'api-1',
              title: 'Order Confirmed',
              message: 'Restaurant accepted your order.',
              notificationType: 'order',
              orderId: 1050,
              isRead: false,
            ),
          ],
        );

        expect(provider.notifications, hasLength(1));
        expect(provider.orderNotifications.single.orderId, 1050);
        expect(provider.unreadCount, 1);
      },
    );

    test('markAllAsRead marks all notifications as read', () async {
      final provider = _seededProvider();
      expect(provider.unreadCount, greaterThan(0));

      await provider.markAllAsRead();
      expect(provider.unreadCount, 0);
      expect(provider.notifications.every((n) => n.isRead), true);
    });

    test('dismiss removes item from list', () {
      final provider = _seededProvider();
      final initialCount = provider.notifications.length;
      final firstId = provider.notifications.first.id;

      provider.dismiss(firstId);
      expect(provider.notifications.length, initialCount - 1);
      expect(provider.notifications.any((n) => n.id == firstId), false);
    });

    test('clearAll empties the notification list', () {
      final provider = _seededProvider();
      expect(provider.notifications.isNotEmpty, true);

      provider.clearAll();
      expect(provider.notifications.isEmpty, true);
      expect(provider.unreadCount, 0);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    testWidgets('Renders NotificationsScreen with filter chips and items', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => _seededProvider(),
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar title
      expect(find.text('Notifications'), findsOneWidget);

      // Check Segmented filter tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Promos'), findsOneWidget);

      // Check Clear All sweep button in AppBar
      expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);

      // Check Unread header
      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('Tapping filter chip updates active filter', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => _seededProvider(),
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Orders chip
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Tap Promos chip
      await tester.tap(find.text('Promos'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Tapping Clear All button displays theme-adaptive dialog with buttons',
      (tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => _seededProvider(),
            child: const MaterialApp(home: NotificationsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Clear All Notifications?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Clear All'), findsWidgets);
      },
    );
  });

  group('GlassButton & GlassTextField Mobile Flow Ergonomics', () {
    testWidgets(
      'GlassButton renders with mobile touch target height and variants',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassButton(
                  text: 'Order Now',
                  variant: GlassButtonVariant.accent,
                  isFullWidth: true,
                  onPressed: () => tapped = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Order Now'), findsOneWidget);
        final size = tester.getSize(find.byType(GlassButton));
        expect(size.height, greaterThanOrEqualTo(48.0));

        await tester.tap(find.text('Order Now'));
        await tester.pumpAndSettle();
        expect(tapped, true);
      },
    );

    testWidgets(
      'GlassTextField renders with ergonomic form styling and controller binding',
      (tester) async {
        final controller = TextEditingController(text: 'Great food!');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassTextField(
                  controller: controller,
                  hintText: 'Feedback',
                  prefixIcon: Icons.feedback_outlined,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Great food!'), findsOneWidget);
        expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
      },
    );
  });
}

NotificationProvider _seededProvider() {
  return NotificationProvider(
    initialNotifications: [
      NotificationModel(
        id: 'api-1',
        title: 'Order Confirmed',
        message: 'Restaurant accepted your order.',
        notificationType: 'order',
        orderId: 1050,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 'api-2',
        title: 'Weekend Promo',
        message: 'Use code KHQR30 for 30% off.',
        notificationType: 'promo',
        data: {'code': 'KHQR30'},
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  );
}
