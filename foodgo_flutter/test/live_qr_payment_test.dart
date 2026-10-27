import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:foodgo_flutter/features/payment/models/payment_model.dart';
import 'package:foodgo_flutter/features/payment/screens/qr_payment_screen.dart';
import 'package:foodgo_flutter/features/payment/services/payment_service.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';

class MockPaymentService extends FlutterPaymentService {
  final StreamController<PaymentModel> statusController =
      StreamController<PaymentModel>.broadcast();
  PaymentModel? statusResponse;
  bool cancelCalled = false;
  bool createCalled = false;

  @override
  Stream<PaymentModel> subscribePaymentStatus(
    int paymentId, {
    String? customWsUrl,
  }) {
    return statusController.stream;
  }

  @override
  Future<PaymentModel> getPaymentStatus(
    int paymentId, {
    bool simulate = false,
  }) async {
    return statusResponse ??
        PaymentModel(
          id: paymentId,
          orderId: 999,
          provider: 'BAKONG',
          method: 'KHQR',
          amount: 15.50,
          currency: 'USD',
          status: 'PENDING',
        );
  }

  @override
  Future<void> cancelPayment(int paymentId) async {
    cancelCalled = true;
  }

  @override
  Future<PaymentModel> createPayment({
    required int orderId,
    required String provider,
    String currency = 'USD',
  }) async {
    createCalled = true;
    return PaymentModel(
      id: 888,
      orderId: orderId,
      provider: provider,
      method: 'KHQR',
      amount: 15.50,
      currency: currency,
      status: 'PENDING',
      qrPayload: 'khqr-recreated-payload',
    );
  }
}

void main() {
  group('PaymentModel Unit Tests', () {
    test('PaymentModel parses enriched fields from JSON', () {
      final json = {
        'id': 101,
        'order': 55,
        'provider': 'BAKONG',
        'method': 'KHQR',
        'transaction_id': 'TXN-98765',
        'merchant_reference': 'MR-55-101',
        'order_reference': 'ORD-20261020-055',
        'restaurant_name': 'Lotus Garden',
        'order_summary': {
          'restaurant': 'Lotus Garden',
          'items': [
            {'name': 'Fish Amok', 'quantity': 2, 'price': 7.50},
          ],
          'items_count': 1,
        },
        'amount': '15.00',
        'currency': 'USD',
        'qr_payload': 'khqr://test-payload-12345',
        'status': 'PENDING',
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.id, 101);
      expect(payment.orderId, 55);
      expect(payment.provider, 'BAKONG');
      expect(payment.transactionId, 'TXN-98765');
      expect(payment.merchantReference, 'MR-55-101');
      expect(payment.orderReference, 'ORD-20261020-055');
      expect(payment.restaurantName, 'Lotus Garden');
      expect(payment.amount, 15.00);
      expect(payment.currency, 'USD');
      expect(payment.qrPayload, 'khqr://test-payload-12345');
      expect(payment.isPending, isTrue);
      expect(payment.isPaid, isFalse);
      expect(payment.isExpired, isFalse);
    });

    test('PaymentModel copyWith updates fields immutably', () {
      final payment = PaymentModel(
        id: 1,
        orderId: 10,
        provider: 'ABA',
        method: 'KHQR',
        amount: 25.0,
        currency: 'USD',
        status: 'PENDING',
      );

      final updated = payment.copyWith(
        status: 'PAID',
        transactionId: 'ABA-TXN-1122',
        paidAt: DateTime(2026, 10, 20, 10, 30),
      );

      expect(payment.status, 'PENDING');
      expect(updated.status, 'PAID');
      expect(updated.isPaid, isTrue);
      expect(updated.transactionId, 'ABA-TXN-1122');
      expect(updated.paidAt, isNotNull);
    });
  });

  group('QRPaymentScreen Widget Tests', () {
    late MockPaymentService mockService;

    setUp(() {
      mockService = MockPaymentService();
    });

    tearDown(() {
      mockService.statusController.close();
    });

    Widget createTestWidget(PaymentModel payment) {
      return MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
        child: MaterialApp(
          home: QRPaymentScreen(payment: payment, paymentService: mockService),
        ),
      );
    }

    testWidgets(
      'Renders Order Summary, Status Badge, and QR frame on mobile screen',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final payment = PaymentModel(
          id: 42,
          orderId: 789,
          provider: 'BAKONG',
          method: 'KHQR',
          restaurantName: 'Angkor Kitchen',
          orderReference: 'ORD-789',
          amount: 18.25,
          currency: 'USD',
          qrPayload: '00020101021229490016A0000007270499990108BAKONGSG',
          status: 'PENDING',
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          orderSummary: {
            'restaurant': 'Angkor Kitchen',
            'items': [
              {'name': 'Beef Lok Lak', 'quantity': 1, 'price': 9.25},
              {'name': 'Fresh Coconut', 'quantity': 2, 'price': 4.50},
            ],
          },
        );

        await tester.pumpWidget(createTestWidget(payment));
        await tester.pumpAndSettle();

        // Order summary verification
        expect(find.text('Order #ORD-789'), findsOneWidget);
        expect(find.text('Angkor Kitchen'), findsOneWidget);
        expect(find.text('USD 18.25'), findsOneWidget);
        expect(find.textContaining('KHR'), findsOneWidget);
        expect(find.text('Bakong KHQR (NBC Open API)'), findsOneWidget);

        // Status badge verification
        expect(find.text('WAITING FOR PAYMENT'), findsOneWidget);
        expect(
          find.text('Scan QR code with your mobile banking app'),
          findsOneWidget,
        );

        // QR Code widget verification
        expect(find.byType(QrImageView), findsOneWidget);

        // Live Time Card verification
        expect(find.text('LIVE TIME'), findsOneWidget);
        expect(find.text('Live WebSocket'), findsOneWidget);

        // Supported Banks Showcase verification
        expect(
          find.text('Supported Banks & Apps (ធនាគារស្កេនបាន)'),
          findsOneWidget,
        );
        expect(find.text('Bakong'), findsOneWidget);
        expect(find.text('ABA Bank'), findsOneWidget);
        expect(find.text('ACLEDA'), findsOneWidget);
        expect(find.text('Wing Bank'), findsOneWidget);

        // Action buttons
        expect(find.text('Check Payment Status'), findsOneWidget);
        expect(find.text('Simulate Webhook Pay (Test Mode)'), findsOneWidget);
        expect(find.text('Cancel Payment'), findsOneWidget);

        // Expand order details
        expect(find.text('View Order Items (2)'), findsOneWidget);
        await tester.tap(find.text('View Order Items (2)'));
        await tester.pumpAndSettle();

        expect(find.text('Beef Lok Lak x1'), findsOneWidget);
        expect(find.text('Fresh Coconut x2'), findsOneWidget);
        expect(find.text('Hide Order Items (2)'), findsOneWidget);
      },
    );

    testWidgets(
      'Live WebSocket event pushes PAID status and transitions to in-screen success card',
      (tester) async {
        final payment = PaymentModel(
          id: 42,
          orderId: 789,
          provider: 'BAKONG',
          method: 'KHQR',
          amount: 18.25,
          currency: 'USD',
          status: 'PENDING',
        );

        await tester.pumpWidget(createTestWidget(payment));
        await tester.pump();

        expect(find.text('WAITING FOR PAYMENT'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);

        // Push real-time payment update via WebSocket stream
        mockService.statusController.add(
          PaymentModel(
            id: 42,
            orderId: 789,
            provider: 'BAKONG',
            method: 'KHQR',
            transactionId: 'NBC-LIVE-998877',
            amount: 18.25,
            currency: 'USD',
            status: 'PAID',
            paidAt: DateTime.now(),
          ),
        );

        await tester.pumpAndSettle();

        // UI transitioned to in-screen Success confirmation
        expect(find.text('PAID · CONFIRMED'), findsOneWidget);
        expect(find.text('Payment Confirmed!'), findsOneWidget);
        expect(find.text('ការទូទាត់ទទួលបានជោគជ័យ!'), findsOneWidget);
        expect(find.text('NBC-LIVE-998877'), findsOneWidget);
        expect(find.text('Track Order'), findsOneWidget);
        expect(find.text('View All Orders'), findsOneWidget);
        expect(find.text('Return to Home'), findsOneWidget);

        // QR Code is hidden in success state to avoid duplicate scanning
        expect(find.byType(QrImageView), findsNothing);
      },
    );

    testWidgets('Renders expired state when payment is expired', (
      tester,
    ) async {
      final expiredPayment = PaymentModel(
        id: 42,
        orderId: 789,
        provider: 'BAKONG',
        method: 'KHQR',
        amount: 18.25,
        currency: 'USD',
        status: 'EXPIRED',
      );

      await tester.pumpWidget(createTestWidget(expiredPayment));
      await tester.pumpAndSettle();

      expect(find.text('QR EXPIRED'), findsOneWidget);
      expect(find.text('Payment QR Expired'), findsOneWidget);
      expect(find.text('Regenerate QR Code'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('Renders failed state when payment has failed', (tester) async {
      final failedPayment = PaymentModel(
        id: 42,
        orderId: 789,
        provider: 'ABA',
        method: 'KHQR',
        amount: 18.25,
        currency: 'USD',
        status: 'FAILED',
      );

      await tester.pumpWidget(createTestWidget(failedPayment));
      await tester.pumpAndSettle();

      expect(find.text('PAYMENT FAILED'), findsOneWidget);
      expect(find.text('Payment Failed'), findsOneWidget);
      expect(find.text('Retry Payment'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });
  });
}
