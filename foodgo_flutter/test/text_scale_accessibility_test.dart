import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:foodgo_flutter/providers/locale_provider.dart';
import 'package:foodgo_flutter/widgets/glass/glass_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Text Scale Factors & Labels', () {
    test('4-tier accessibility scaling defines exact factors', () {
      expect(AppTextScale.small.factor, 0.85);
      expect(AppTextScale.standard.factor, 1.0);
      expect(AppTextScale.large.factor, 1.15);
      expect(AppTextScale.extraLarge.factor, 1.30);
    });

    test('Bilingual labels return correct localized names', () {
      // English
      expect(AppTextScale.small.label(false), 'Small');
      expect(AppTextScale.standard.label(false), 'Default');
      expect(AppTextScale.large.label(false), 'Large');
      expect(AppTextScale.extraLarge.label(false), 'Extra Large');

      // Khmer
      expect(AppTextScale.small.label(true), 'តូច (85%)');
      expect(AppTextScale.standard.label(true), 'ធម្មតា (100%)');
      expect(AppTextScale.large.label(true), 'ធំ (115%)');
      expect(AppTextScale.extraLarge.label(true), 'ធំពិសេស (130%)');
    });

    test('fromName deserializes enum safely with fallback', () {
      expect(AppTextScale.fromName('small'), AppTextScale.small);
      expect(AppTextScale.fromName('standard'), AppTextScale.standard);
      expect(AppTextScale.fromName('large'), AppTextScale.large);
      expect(AppTextScale.fromName('extraLarge'), AppTextScale.extraLarge);
      expect(AppTextScale.fromName('unknown'), AppTextScale.standard);
      expect(AppTextScale.fromName(null), AppTextScale.standard);
    });
  });

  group('LocaleProvider Text Scaling Reactivity & Persistence', () {
    test('Initializes with standard scale (1.0)', () {
      final provider = LocaleProvider();
      expect(provider.textScale, AppTextScale.standard);
      expect(provider.scaleFactor, 1.0);
    });

    test('setTextScale notifies listeners and updates factor', () async {
      final provider = LocaleProvider();
      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      await provider.setTextScale(AppTextScale.extraLarge);

      expect(provider.textScale, AppTextScale.extraLarge);
      expect(provider.scaleFactor, 1.30);
      expect(notificationCount, 1);
    });

    test('Persists text scale to SharedPreferences', () async {
      final provider = LocaleProvider();
      await provider.setTextScale(AppTextScale.large);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_text_scale'), 'large');
    });

    test('Loads persisted text scale on startup', () async {
      SharedPreferences.setMockInitialValues({'app_text_scale': 'extraLarge'});

      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.textScale, AppTextScale.extraLarge);
      expect(provider.scaleFactor, 1.30);
    });
  });

  group('Widget Layout Accessibility at Extra Large Scale (1.30x)', () {
    Widget buildTestHarness({
      required Widget child,
      required LocaleProvider localeProvider,
      Size size = const Size(360, 640),
    }) {
      return ChangeNotifierProvider<LocaleProvider>.value(
        value: localeProvider,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(localeProvider.scaleFactor),
            ),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets(
      'GlassButton with Khmer text renders without overflow at 1.30x scale',
      (tester) async {
        final provider = LocaleProvider();
        await provider.setLanguage(AppLanguage.khmer);
        await provider.setTextScale(AppTextScale.extraLarge);

        await tester.pumpWidget(
          buildTestHarness(
            localeProvider: provider,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassButton(
                text: 'បន្តទៅការទូទាត់ប្រាក់',
                onPressed: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('បន្តទៅការទូទាត់ប្រាក់'), findsOneWidget);
      },
    );

    testWidgets(
      'Bilingual text rows do not overflow at 1.30x extra large scale',
      (tester) async {
        final provider = LocaleProvider();
        await provider.setLanguage(AppLanguage.khmer);
        await provider.setTextScale(AppTextScale.extraLarge);

        await tester.pumpWidget(
          buildTestHarness(
            localeProvider: provider,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'ចំនួនទឹកប្រាក់ត្រូវទូទាត់',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r'$12.50 (៛51,250)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'គាំទ្របាគង, ABA, អេស៊ីលីដា និងធនាគារជាង ៣០ ផ្សេងទៀត',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('ចំនួនទឹកប្រាក់ត្រូវទូទាត់'), findsOneWidget);
        expect(find.text(r'$12.50 (៛51,250)'), findsOneWidget);
      },
    );
  });
}
