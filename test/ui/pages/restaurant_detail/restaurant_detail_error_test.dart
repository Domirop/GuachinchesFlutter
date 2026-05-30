import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

// Fake repo: getRestaurantById always throws; everything else returns benign
// empty Futures so _loadVisits / _loadListAppearances fail silently (they have
// their own try/catch). _loadIsFav is also guarded in the screen, so no sqflite
// mocking is needed.
class _ThrowingRepo implements RemoteRepository {
  @override
  Future<Restaurant> getRestaurantById(String id) async =>
      throw Exception('boom');

  @override
  dynamic noSuchMethod(Invocation i) => Future.value(null);
}

void main() {
  group('RestaurantDetailScreen — error state (A1)', () {
    testWidgets(
      '(a) error widget visible, spinner absent when repo throws',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: appDarkTheme,
            home: RestaurantDetailScreen(
              id: 'x',
              repository: _ThrowingRepo(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.identifier == 'restaurant-detail-error',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.identifier == 'restaurant-detail-retry-button',
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '(b) retry reloads the screen',
      (tester) async {
        // Building a full valid Restaurant fixture is non-trivial;
        // covered by integration tests once fixtures are available.
      },
      skip: true,
    );
  });
}
