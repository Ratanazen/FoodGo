import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/widgets/phone_verification_modal.dart';

void main() {
  group('PhoneVerificationModal Widget Tests', () {
    testWidgets('Renders Cambodian phone verification modal components', (
      tester,
    ) async {
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  return ElevatedButton(
                    onPressed: () {
                      PhoneVerificationModal.show(
                        ctx,
                        initialPhone: '012 345 678',
                        purpose: 'customer_verification',
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check header titles
      expect(find.text('Verify Cambodian Phone'), findsOneWidget);
      expect(
        find.text('Carrier SMS verification (Smart, Cellcard, Metfone)'),
        findsOneWidget,
      );

      // Check country prefix and carrier hint
      expect(find.text('KH +855'), findsOneWidget);
      expect(
        find.text(
          'Supported carriers: Smart, Cellcard, Metfone, Seatel, Cootel.',
        ),
        findsOneWidget,
      );

      // Check phone input prefilled
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '012 345 678');

      // Check send code button
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('Shows error message when phone number is empty', (
      tester,
    ) async {
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  return ElevatedButton(
                    onPressed: () {
                      PhoneVerificationModal.show(
                        ctx,
                        initialPhone: '',
                        purpose: 'customer_verification',
                      );
                    },
                    child: const Text('Open Modal'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Clear input and tap Send
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(
        find.text('Please enter your Cambodian mobile number.'),
        findsOneWidget,
      );
    });
  });
}
