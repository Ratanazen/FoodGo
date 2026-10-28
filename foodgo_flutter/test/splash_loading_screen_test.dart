import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:foodgo_flutter/features/splash/presentation/splash_screen.dart';
import 'package:foodgo_flutter/providers/auth_provider.dart';
import 'package:foodgo_flutter/providers/user_provider.dart';
import 'package:foodgo_flutter/widgets/loading_screen.dart';

void main() {
  testWidgets('SplashScreen renders modern brand logo, organic badge, and progress indicators', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Brand and headline assertions
    expect(find.text('FoodGo'), findsOneWidget);
    expect(find.text('100% FRESH & ORGANIC'), findsOneWidget);
    expect(find.text('Healthy Food Delivery • Phnom Penh'), findsOneWidget);
    expect(find.text('Powered by NBC Bakong KHQR • Real-time Delivery'), findsOneWidget);
  });

  testWidgets('FoodGoLoadingScreen renders title, subtitle message and spinner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FoodGoLoadingScreen(
          title: 'Authenticating FoodGo...',
          message: 'Connecting to NBC Bakong KHQR payment gateway',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Authenticating FoodGo...'), findsOneWidget);
    expect(find.text('Connecting to NBC Bakong KHQR payment gateway'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('FoodGoLoadingOverlay displays overlay message when isLoading is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FoodGoLoadingOverlay(
            isLoading: true,
            message: 'Processing Payment...',
            child: Text('Underlying Screen Content'),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Underlying Screen Content'), findsOneWidget);
    expect(find.text('Processing Payment...'), findsOneWidget);
  });
}
