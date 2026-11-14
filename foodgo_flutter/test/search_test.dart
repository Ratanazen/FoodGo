import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodgo_flutter/core/utils/location_helper.dart';
import 'package:foodgo_flutter/features/search/presentation/search_screen.dart';
import 'package:foodgo_flutter/providers/cart_provider.dart';
import 'package:foodgo_flutter/providers/favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'foodgo_recent_searches': ['Burgers', 'Fish Amok', 'Iced Latte'],
    });
  });

  group('SearchScreen Widget Tests', () {
    test(
      'LocationHelper popularLandmarks and searchLocations resolve Phnom Penh landmarks',
      () async {
        final popular = LocationHelper.popularLandmarks;
        expect(popular, isNotEmpty);
        expect(popular.any((l) => l.title.contains('BKK1')), isTrue);

        // Single-char query uses instant offline landmark matching
        final matches = await LocationHelper.searchLocations('B');
        expect(matches.any((l) => l.title.contains('BKK1')), isTrue);
      },
    );
    testWidgets('Renders SearchScreen header, search bar, and tune button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<FavoritesProvider>(
              create: (_) => FavoritesProvider(),
            ),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and input
      expect(find.text('Search FoodGo'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);

      // Check Recent Searches header and items
      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('Burgers'), findsWidgets);
      expect(find.text('Fish Amok'), findsOneWidget);

      // Check Quick Cravings header and chips
      expect(find.text('Quick Cravings'), findsOneWidget);
      expect(find.text('Khmer Food'), findsOneWidget);
      expect(find.text('Coffee & Drinks'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
    });

    testWidgets('Tapping tune button opens Filter & Sorting modal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<FavoritesProvider>(
              create: (_) => FavoritesProvider(),
            ),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tune button
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Filters & Sorting'), findsOneWidget);
      expect(find.text('SORT BY'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Price: Low to High'), findsOneWidget);
      expect(find.text('PRICE TIER'), findsOneWidget);
      expect(find.text('All Prices'), findsOneWidget);
      expect(find.text('Vegetarian Friendly'), findsOneWidget);
      expect(find.text('MINIMUM RATING'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });

    testWidgets('Clearing recent searches empties the list', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<FavoritesProvider>(
              create: (_) => FavoritesProvider(),
            ),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Searches'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Recent Searches header disappears when list is empty
      expect(find.text('Recent Searches'), findsNothing);
    });

    testWidgets('SearchScope enum has all, dishes, and restaurants values', (
      tester,
    ) async {
      expect(SearchScope.values.length, 3);
      expect(SearchScope.values, contains(SearchScope.all));
      expect(SearchScope.values, contains(SearchScope.dishes));
      expect(SearchScope.values, contains(SearchScope.restaurants));
    });
  });
}
