import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo_flutter/core/errors/error_mapper.dart';
import 'package:foodgo_flutter/core/errors/failure.dart';
import 'package:foodgo_flutter/core/storage/local_cache.dart';
import 'package:foodgo_flutter/shared/widgets/app_button.dart';
import 'package:foodgo_flutter/shared/widgets/app_text_field.dart';
import 'package:foodgo_flutter/shared/widgets/empty_state.dart';
import 'package:foodgo_flutter/shared/widgets/error_state.dart';
import 'package:foodgo_flutter/shared/widgets/offline_banner.dart';
import 'package:foodgo_flutter/shared/widgets/skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Core: Failure & Sealed Classes', () {
    test('Failure subclasses instantiate with expected defaults', () {
      const serverFail = ServerFailure();
      expect(serverFail.statusCode, 500);
      expect(serverFail.message, contains('Internal server error'));

      const networkFail = NetworkFailure();
      expect(networkFail.message, contains('No internet connection'));

      const unauthFail = UnauthorizedFailure();
      expect(unauthFail.statusCode, 401);

      const notFoundFail = NotFoundFailure();
      expect(notFoundFail.statusCode, 404);

      const valFail = ValidationFailure(
        'Invalid form input',
        errors: {
          'email': ['Must be valid format'],
        },
      );
      expect(valFail.statusCode, 422);
      expect(valFail.errors['email']?.first, 'Must be valid format');
    });

    test('Dart 3 sealed pattern matching is exhaustive', () {
      const Failure failure = NetworkFailure('Dropped');

      final description = switch (failure) {
        NetworkFailure f => 'Network: ${f.message}',
        ServerFailure f => 'Server: ${f.message}',
        UnauthorizedFailure f => 'Auth: ${f.message}',
        ValidationFailure f => 'Validation: ${f.message}',
        NotFoundFailure f => 'NotFound: ${f.message}',
        CacheFailure f => 'Cache: ${f.message}',
        UnknownFailure f => 'Unknown: ${f.message}',
      };

      expect(description, 'Network: Dropped');
    });
  });

  group('Phase 2 Core: ErrorMapper', () {
    test('maps connection timeout to NetworkFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/foods/'),
        type: DioExceptionType.connectionTimeout,
      );

      final failure = ErrorMapper.fromDioException(dioException);
      expect(failure, isA<NetworkFailure>());
    });

    test('maps 401 response to UnauthorizedFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/orders/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/orders/'),
          statusCode: 401,
          data: {'detail': 'Invalid signature'},
        ),
      );

      final failure = ErrorMapper.fromDioException(dioException);
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, 'Invalid signature');
    });

    test('maps 400 validation payload to ValidationFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/register/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/register/'),
          statusCode: 400,
          data: {
            'username': ['Username taken.'],
          },
        ),
      );

      final failure = ErrorMapper.fromDioException(dioException);
      expect(failure, isA<ValidationFailure>());
      final valFail = failure as ValidationFailure;
      expect(valFail.errors['username']?.first, 'Username taken.');
    });

    test('maps 500 internal server error to ServerFailure', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/foods/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/foods/'),
          statusCode: 500,
        ),
      );

      final failure = ErrorMapper.fromDioException(dioException);
      expect(failure, isA<ServerFailure>());
    });
  });

  group('Phase 2 Core: LocalCacheService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sets and retrieves cached payload', () async {
      final cache = LocalCacheService();
      await cache.set('user_city', 'Phnom Penh');

      final result = await cache.get<String>('user_city');
      expect(result, 'Phnom Penh');
    });

    test('expires items past TTL', () async {
      final cache = LocalCacheService();
      // TTL in the past
      await cache.set(
        'quick_token',
        'expired_data',
        ttl: const Duration(milliseconds: -100),
      );

      final result = await cache.get<String>('quick_token');
      expect(result, isNull);
    });

    test('removes and clears keys correctly', () async {
      final cache = LocalCacheService();
      await cache.set('key1', 'val1');
      await cache.set('key2', 'val2');

      await cache.remove('key1');
      expect(await cache.get<String>('key1'), isNull);
      expect(await cache.get<String>('key2'), 'val2');

      await cache.clear();
      expect(await cache.get<String>('key2'), isNull);
    });
  });

  group('Phase 2 Shared Widgets: AppButton', () {
    testWidgets('renders primary button and handles tap event', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Confirm Order',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Confirm Order'), findsOneWidget);
      await tester.tap(find.text('Confirm Order'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('displays progress spinner and disables tap when loading', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Submit',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });

  group('Phase 2 Shared Widgets: AppTextField', () {
    testWidgets('renders label and manages text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              labelText: 'Phone Number',
              hintText: '012 345 678',
            ),
          ),
        ),
      );

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('012 345 678'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '012999888');
      expect(controller.text, '012999888');
    });

    testWidgets('password field toggles visibility on icon tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(labelText: 'Password', isPassword: true),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.visibility_off_outlined);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group(
    'Phase 2 Shared Widgets: SkeletonLoader, EmptyState, ErrorState, OfflineBanner',
    () {
      testWidgets(
        'SkeletonLoader renders rectangular, circular, and text shapes',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    SkeletonLoader.rectangular(height: 50),
                    SkeletonLoader.circular(diameter: 40),
                    SkeletonLoader.text(width: 100),
                  ],
                ),
              ),
            ),
          );

          expect(find.byType(SkeletonLoader), findsNWidgets(3));
        },
      );

      testWidgets('EmptyState renders title, description, and calls action', (
        tester,
      ) async {
        var actionTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: 'Your cart is empty',
                description: 'Add dishes from local restaurants to begin.',
                actionText: 'Browse Restaurants',
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Your cart is empty'), findsOneWidget);
        expect(find.text('Browse Restaurants'), findsOneWidget);

        await tester.tap(find.text('Browse Restaurants'));
        await tester.pump();

        expect(actionTapped, isTrue);
      });

      testWidgets('ErrorState renders from Failure and handles retry', (
        tester,
      ) async {
        var retryTapped = false;
        const failure = NetworkFailure('Connection dropped in Daun Penh');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorState.fromFailure(
                failure,
                onRetry: () => retryTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('No Connection'), findsOneWidget);
        expect(find.text('Connection dropped in Daun Penh'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);

        await tester.tap(find.text('Try Again'));
        await tester.pump();

        expect(retryTapped, isTrue);
      });

      testWidgets(
        'OfflineBanner displays offline notification and triggers retry',
        (tester) async {
          var retryCalled = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: OfflineBanner(
                  isOffline: true,
                  message: 'Offline mode active',
                  onRetry: () => retryCalled = true,
                ),
              ),
            ),
          );

          expect(find.text('Offline mode active'), findsOneWidget);
          await tester.tap(find.text('Retry'));
          await tester.pump();

          expect(retryCalled, isTrue);
        },
      );
    },
  );
}
