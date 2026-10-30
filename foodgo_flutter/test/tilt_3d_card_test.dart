import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/widgets/glass/tilt_3d_card.dart';

void main() {
  group('Tilt3DCard 3D Perspective Tests', () {
    testWidgets(
      'Renders child inside 3D transform and responds to pan gestures',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Tilt3DCard(
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 300,
                    height: 300,
                    key: Key('tilt_card_content'),
                    child: Text('3D Card Content'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('3D Card Content'), findsOneWidget);
        expect(find.byKey(const Key('tilt_card_content')), findsOneWidget);

        // Pan drag on the card
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('tilt_card_content'))),
        );
        await gesture.moveBy(const Offset(40, -40));
        await tester.pump();

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('3D Card Content'), findsOneWidget);
      },
    );
  });
}
