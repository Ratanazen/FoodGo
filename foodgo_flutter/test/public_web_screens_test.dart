import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:foodgo_flutter/features/support/presentation/support_screen.dart';
import 'package:foodgo_flutter/features/legal/presentation/legal_screen.dart';
import 'package:foodgo_flutter/features/tracking/presentation/public_tracking_screen.dart';
import 'package:foodgo_flutter/providers/theme_provider.dart';

Widget _createTestWidget(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('Public Web Screens Widget Tests', () {
    testWidgets(
      'SupportScreen renders contact channels, FAQs, and inquiry form',
      (WidgetTester tester) async {
        await tester.pumpWidget(_createTestWidget(const SupportScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Help & Support'), findsOneWidget);
        expect(find.text('FoodGo Customer Support Center'), findsOneWidget);
        expect(find.text('Contact Channels'), findsOneWidget);
        expect(find.text('Phone Hotline'), findsOneWidget);
        expect(find.text('Telegram Support'), findsOneWidget);
        expect(find.text('Frequently Asked Questions'), findsOneWidget);
        expect(find.text('Send an Inquiry'), findsOneWidget);
        expect(find.text('Submit Inquiry'), findsOneWidget);
      },
    );

    testWidgets(
      'LegalScreen renders Terms of Service and Privacy Policy tabs',
      (WidgetTester tester) async {
        await tester.pumpWidget(_createTestWidget(const LegalScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Legal & Compliance'), findsOneWidget);
        expect(find.text('Terms of Service'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('FoodGo Terms of Service'), findsOneWidget);

        // Tap Privacy Policy tab
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        expect(find.text('FoodGo Privacy Policy'), findsOneWidget);
      },
    );

    testWidgets('PublicTrackingScreen renders search input and Track button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestWidget(const PublicTrackingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Live Delivery Tracking'), findsOneWidget);
      expect(find.text('Public Order Tracker'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
