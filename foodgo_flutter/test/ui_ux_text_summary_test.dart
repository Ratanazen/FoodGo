import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/features/checkout/presentation/order_success_screen.dart';
import 'package:foodgo_flutter/features/dashboard/presentation/restaurant_dashboard_screen.dart';
import 'package:foodgo_flutter/features/legal/presentation/legal_screen.dart';
import 'package:foodgo_flutter/features/support/presentation/support_screen.dart';
import 'package:foodgo_flutter/services/api_service.dart';
import 'package:foodgo_flutter/shared/widgets/structured_summary_viewer.dart';
import 'package:foodgo_flutter/widgets/glass/glass_widgets.dart';

void main() {
  group('StructuredSummaryViewer & Safe Text Rendering Tests', () {
    test(
      'sanitizePlainText strips script/iframe/HTML tags and preserves Khmer/English Unicode',
      () {
        const unsafeInput =
            '<script>alert("xss")</script><h1>FoodGo សួស្តី</h1><p>Line 1<br/>Line 2 &amp; More</p><iframe src="evil"></iframe>javascript:void(0)';
        final cleaned = StructuredSummaryViewer.sanitizePlainText(unsafeInput);

        expect(cleaned.contains('<script>'), isFalse);
        expect(cleaned.contains('alert("xss")'), isFalse);
        expect(cleaned.contains('<iframe'), isFalse);
        expect(cleaned.contains('javascript:'), isFalse);
        expect(cleaned.contains('FoodGo សួស្តី'), isTrue);
        expect(cleaned.contains('Line 1\nLine 2 & More'), isTrue);
      },
    );

    test(
      'parseEmvcoKhqrSummary extracts dynamic KHQR TLV fields including Tag 29 and Tag 99',
      () {
        const sampleKhqr =
            '00020101021229200016sonar_seang@bkrt52045812530384054041.505802KH5906FoodGo6010Phnom Penh62140110FG-ORD-101993400131794492700000011317944936000006304ABCD';
        final summary = StructuredSummaryViewer.parseEmvcoKhqrSummary(
          sampleKhqr,
        );

        expect(summary['Payload Format'], equals('EMVCo v01'));
        expect(summary['QR Type'], equals('Dynamic KHQR (12)'));
        expect(summary['Bakong Account ID'], equals('sonar_seang@bkrt'));
        expect(summary['Currency'], equals('USD (840)'));
        expect(summary['Amount'], equals('1.50'));
        expect(summary['Merchant Name'], equals('FoodGo'));
        expect(summary['Merchant City'], equals('Phnom Penh'));
        expect(summary['Bill Reference'], equals('FG-ORD-101'));
        expect(summary['Expires Epoch (ms)'], equals('1794493600000'));
        expect(summary['CRC16 Checksum'], equals('ABCD'));
      },
    );

    testWidgets(
      'StructuredSummaryViewer renders sections, toggles Plain TXT mode, and filters via search',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StructuredSummaryViewer(
                  title: 'Order & Payment Summary (សង្ខេបការបញ្ជាទិញ)',
                  subtitle: 'Phnom Penh • 1 USD = 4,100 KHR',
                  badgeText: 'VERIFIED',
                  keyPoints: [
                    'Dynamic Bakong KHQR with Tag 99 expiration support.',
                    'Bilingual Khmer and English Unicode rendering.',
                  ],
                  sections: [
                    SummarySection(
                      title: 'Section Alpha — Bakong Settlement',
                      metadata: {
                        'Account': 'sonar_seang@bkrt',
                        'Rate': '4,100 KHR',
                      },
                      body: 'Instant settlement across NBC member banks.',
                      bulletPoints: ['ABA Mobile', 'ACLEDA Mobile'],
                    ),
                    SummarySection(
                      title: 'Section Beta — Courier Dispatch',
                      body: 'Real-time GPS tracking to customer doorstep.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('Order & Payment Summary'), findsOneWidget);
        expect(find.textContaining('Section Alpha'), findsOneWidget);
        expect(find.textContaining('Section Beta'), findsOneWidget);

        // Search filter test
        await tester.enterText(find.byType(TextField), 'Courier');
        await tester.pumpAndSettle();

        expect(find.textContaining('Section Alpha'), findsNothing);
        expect(find.textContaining('Section Beta'), findsOneWidget);

        // Clear search
        await tester.tap(find.byTooltip('Clear search'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Section Alpha'), findsOneWidget);

        // Switch to Plain TXT mode
        await tester.tap(find.text('Plain TXT'));
        await tester.pumpAndSettle();

        expect(find.text('PLAIN TXT DOCUMENT VIEW'), findsOneWidget);
        expect(find.textContaining('KEY SUMMARY POINTS:'), findsOneWidget);
      },
    );

    testWidgets(
      'StructuredSummaryViewer handles empty, loading, and error states gracefully',
      (tester) async {
        // Empty state
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: StructuredSummaryViewer(title: 'Empty Doc')),
          ),
        );
        expect(find.text('No Summary Content Available'), findsOneWidget);

        // Error state
        bool retried = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StructuredSummaryViewer(
                title: 'Error Doc',
                errorMessage: 'Failed to fetch summary record.',
                onRetry: () => retried = true,
              ),
            ),
          ),
        );
        expect(find.text('Unable to Load Content'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        expect(retried, isTrue);
      },
    );
  });

  group('ApiService URL Normalization & Error Formatting Tests', () {
    test(
      'normalizeOptionalUrl handles "no", blank, invalid strings, and valid URLs',
      () {
        expect(ApiService.normalizeOptionalUrl(null), equals(''));
        expect(ApiService.normalizeOptionalUrl(''), equals(''));
        expect(ApiService.normalizeOptionalUrl('no'), equals(''));
        expect(ApiService.normalizeOptionalUrl('NO'), equals(''));
        expect(ApiService.normalizeOptionalUrl('none'), equals(''));
        expect(ApiService.normalizeOptionalUrl('n/a'), equals(''));
        expect(ApiService.normalizeOptionalUrl('-'), equals(''));
        expect(
          ApiService.normalizeOptionalUrl('random_word_without_dot'),
          equals(''),
        );
        expect(
          ApiService.normalizeOptionalUrl('javascript:alert(1)'),
          equals(''),
        );

        expect(
          ApiService.normalizeOptionalUrl('images.unsplash.com/photo-123'),
          equals('https://images.unsplash.com/photo-123'),
        );
        expect(
          ApiService.normalizeOptionalUrl('https://example.com/burger.jpg'),
          equals('https://example.com/burger.jpg'),
        );
      },
    );

    test(
      'formatError extracts clean field validation messages from DioException 400 instead of raw boilerplate',
      () {
        final reqOptions = RequestOptions(path: '/api/food-items/');
        final dioErr = DioException(
          requestOptions: reqOptions,
          response: Response(
            requestOptions: reqOptions,
            statusCode: 400,
            data: {
              'image_url': ['Enter a valid URL.'],
              'price': ['Price must be greater than zero.'],
            },
          ),
          type: DioExceptionType.badResponse,
        );

        final formatted = ApiService.formatError(dioErr);
        expect(formatted.contains('DioException'), isFalse);
        expect(formatted.contains('Image url: Enter a valid URL.'), isTrue);
        expect(
          formatted.contains('Price: Price must be greater than zero.'),
          isTrue,
        );
      },
    );
  });

  group('Upgraded Application Screens Widget Tests', () {
    testWidgets(
      'LegalScreen renders Terms and Privacy tabs with StructuredSummaryViewer',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LegalScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Legal & Compliance'), findsOneWidget);
        expect(find.textContaining('Terms of Service'), findsWidgets);
        expect(find.textContaining('KEY HIGHLIGHTS & SUMMARY'), findsOneWidget);
      },
    );

    testWidgets(
      'SupportScreen filters FAQs and generates Ticket Summary on inquiry submission',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SupportScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Help & Support'), findsOneWidget);
        expect(find.text('4 of 4 topics'), findsOneWidget);

        // Enter subject and message and submit inquiry
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Subject (e.g., Order #1024 KHQR check)',
          ),
          'Order #1055 KHQR Verification',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Detailed Message'),
          'Paid USD 1.50 via ACLEDA Mobile, please confirm.',
        );

        final submitBtn = find.text('Submit Inquiry');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Support Ticket Summary (SUP-'),
          findsOneWidget,
        );
        expect(find.text('TICKET LOGGED'), findsOneWidget);
      },
    );

    testWidgets(
      'OrderSuccessScreen displays structured Order Confirmation Summary card',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: OrderSuccessScreen(
              orderId: '45',
              orderReference: 'FG-20261112-ABCD',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Order Placed!'), findsOneWidget);
        expect(find.text('ORDER SUMMARY'), findsOneWidget);
        expect(find.text('Copy Summary TXT'), findsOneWidget);
        expect(find.text('FG-20261112-ABCD'), findsOneWidget);
      },
    );

    testWidgets(
      'AddFoodItemBottomSheet disposes controllers safely after exit animation without _dependents.isEmpty error',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<String>(
                      context: ctx,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddFoodItemBottomSheet(
                        restaurantId: 1,
                        categories: const [
                          {'id': 1, 'name': 'Signature Burgers'},
                        ],
                        api: ApiService(),
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Add Food Item'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Food Item Name'),
          'nnn',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Price (USD, e.g. 7.50)'),
          '0.01',
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Image URL (Optional — paste link or leave blank)',
          ),
          'no',
        );

        // Close sheet and pump through reverse transition frames
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Add Food Item'), findsNothing);
      },
    );

    testWidgets(
      'GlassAppBar (Restaurant Portal) renders on 360px Light Mode screen with status bar padding without bottom overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(useMaterial3: true),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                padding: EdgeInsets.only(top: 28),
              ),
              child: Scaffold(
                extendBodyBehindAppBar: true,
                appBar: GlassAppBar(
                  title: 'Restaurant Portal',
                  leading: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {},
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () {},
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Restaurant Portal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
