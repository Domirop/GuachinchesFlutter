import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_reviews_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';

Restaurant _fakeRestaurant() {
  final reviews = [
    Review(id: '1', rating: '5', review: 'review-cinco-a', usuario: User(nombre: 'Ana')),
    Review(id: '2', rating: '5', review: 'review-cinco-b', usuario: User(nombre: 'Ben')),
    Review(id: '3', rating: '4', review: 'review-cuatro-a', usuario: User(nombre: 'Carlos')),
    Review(id: '4', rating: '4', review: 'review-cuatro-b', usuario: User(nombre: 'Diana')),
    Review(id: '5', rating: '3', review: 'review-tres', usuario: User(nombre: 'Eva')),
    Review(id: '6', rating: '1', review: 'review-uno', usuario: User(nombre: 'Félix')),
  ];
  return Restaurant(
    id: 'r1',
    nombre: 'Test Restaurant',
    valoraciones: reviews,
    avgRating: 3.7,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: appDarkTheme,
      home: child,
    );

void _setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('RestaurantReviewsScreen', () {
    testWidgets('(a) renders all 6 ReviewCard widgets and counter shows 6',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        RestaurantReviewsScreen(restaurant: _fakeRestaurant()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewCard), findsNWidgets(6));
      expect(find.text('(6)'), findsOneWidget);
    });

    testWidgets('(b) tap filter-chip-5 shows 2 ReviewCards', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        RestaurantReviewsScreen(restaurant: _fakeRestaurant()),
      ));
      await tester.pumpAndSettle();

      final chip5 = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'restaurant-reviews-filter-chip-5',
      );
      await tester.tap(chip5);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewCard), findsNWidgets(2));
    });

    testWidgets(
        '(c) tap filter-chip-2 shows empty state (no ReviewCard + empty-state widget)',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        RestaurantReviewsScreen(restaurant: _fakeRestaurant()),
      ));
      await tester.pumpAndSettle();

      final chip2 = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'restaurant-reviews-filter-chip-2',
      );
      await tester.tap(chip2);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewCard), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'restaurant-reviews-empty-state',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '(d) sort "Mejor puntuadas" → first ReviewCard rating 5, last rating 1',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        RestaurantReviewsScreen(restaurant: _fakeRestaurant()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(
          find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mejor puntuadas'));
      await tester.pumpAndSettle();

      final cards = tester.widgetList<ReviewCard>(find.byType(ReviewCard)).toList();
      expect(cards.first.review.rating, '5');
      expect(cards.last.review.rating, '1');
    });

    testWidgets(
        '(e) tap "Quitar filtros" from empty state resets to all 6 ReviewCards',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        RestaurantReviewsScreen(restaurant: _fakeRestaurant()),
      ));
      await tester.pumpAndSettle();

      // Go to empty state via filter-chip-2
      final chip2 = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'restaurant-reviews-filter-chip-2',
      );
      await tester.tap(chip2);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewCard), findsNothing);

      await tester.tap(find.text('Quitar filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewCard), findsNWidgets(6));
    });
  });
}
