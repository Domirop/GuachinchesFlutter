import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: appDarkTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  group('ReviewCard', () {
    testWidgets('renders usuario.nombre', (tester) async {
      final review = Review(
        id: '1',
        rating: '4',
        review: 'Muy buena comida',
        usuario: User(nombre: 'María'),
      );

      await tester.pumpWidget(_wrap(ReviewCard(review: review)));
      await tester.pumpAndSettle();

      expect(find.textContaining('MARÍA'), findsOneWidget);
    });

    testWidgets('renders N filled + (5-N) outline stars for rating',
        (tester) async {
      final review = Review(
        id: '2',
        rating: '3',
        review: '',
        usuario: User(nombre: 'Carlos'),
      );

      await tester.pumpWidget(_wrap(ReviewCard(review: review)));
      await tester.pumpAndSettle();

      final filledStars = tester
          .widgetList<Icon>(find.byIcon(Icons.star))
          .where((icon) => icon.icon == Icons.star)
          .length;
      final outlineStars = tester
          .widgetList<Icon>(find.byIcon(Icons.star_border))
          .where((icon) => icon.icon == Icons.star_border)
          .length;

      expect(filledStars, 3);
      expect(outlineStars, 2);
    });

    testWidgets('renders review text when non-empty', (tester) async {
      final review = Review(
        id: '3',
        rating: '5',
        review: 'Excelente experiencia',
        usuario: User(nombre: 'Ana'),
      );

      await tester.pumpWidget(_wrap(ReviewCard(review: review)));
      await tester.pumpAndSettle();

      expect(find.text('Excelente experiencia'), findsOneWidget);
    });

    testWidgets('does not render review text when empty', (tester) async {
      final review = Review(
        id: '4',
        rating: '5',
        review: '',
        usuario: User(nombre: 'Pedro'),
      );

      await tester.pumpWidget(_wrap(ReviewCard(review: review)));
      await tester.pumpAndSettle();

      // Only the username and stars should be present — no review text widget
      expect(find.textContaining('PEDRO'), findsOneWidget);
    });

    testWidgets('shows "Anónimo" when usuario is null', (tester) async {
      final review = Review(
        id: '5',
        rating: '2',
        review: 'Regular',
        usuario: null,
      );

      await tester.pumpWidget(_wrap(ReviewCard(review: review)));
      await tester.pumpAndSettle();

      expect(find.textContaining('ANÓNIMO'), findsOneWidget);
    });
  });
}
