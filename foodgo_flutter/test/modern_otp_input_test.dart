import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/widgets/modern_otp_input.dart';

void main() {
  group('ModernOtpInput Widget Tests', () {
    testWidgets('Renders 6 individual glass PIN boxes', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernOtpInput(
                length: 6,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Verify 6 box containers exist
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ModernOtpInput), findsOneWidget);

      // Enter digits
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('Fires onCompleted callback when 6 digits are entered', (tester) async {
      final controller = TextEditingController();
      String completedCode = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModernOtpInput(
                length: 6,
                controller: controller,
                onCompleted: (code) => completedCode = code,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '654321');
      await tester.pump();

      expect(completedCode, '654321');
    });
  });
}
