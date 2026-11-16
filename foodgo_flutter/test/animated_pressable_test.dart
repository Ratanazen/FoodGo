import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/widgets/glass/animated_pressable.dart';

void main() {
  testWidgets('AnimatedPressable supports keyboard activation and focus', (
    tester,
  ) async {
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedPressable(
              onTap: () => tapped++,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Apply theme'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(tapped, 1);
  });
}
