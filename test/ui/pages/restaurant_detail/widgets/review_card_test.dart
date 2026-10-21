import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/ui/pages/restaurant_detail/review_moderation.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';

class _FakeRepo extends Fake implements RemoteRepository {}

Finder _id(String id) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);

void main() {
  late ReviewModeration mod;

  setUp(() => mod =
      ReviewModeration(repository: _FakeRepo(), readUserId: () async => null));

  Widget wrap(Widget child) => MaterialApp(
        theme: appDarkTheme,
        home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(16), child: child)),
      );

  testWidgets('nombre de pila y estrellas', (tester) async {
    final review = Review(
        id: '1',
        rating: '3',
        review: 'Muy buena comida',
        usuario: User(nombre: 'María Pérez'));
    await tester.pumpWidget(wrap(ReviewCard(review: review, moderation: mod)));
    await tester.pumpAndSettle();

    expect(find.text('María'), findsOneWidget);
    expect(_id('review-star-filled'), findsNWidgets(3));
    expect(_id('review-star-empty'), findsNWidgets(2));
    expect(find.text('Muy buena comida'), findsOneWidget);
  });

  testWidgets('no pinta los rellenos «Título» ni «Sin descripción»',
      (tester) async {
    final review = Review(
        id: '2',
        rating: '5',
        title: 'Título',
        review: 'Sin descripción',
        usuario: User(nombre: 'Pedro'));
    await tester.pumpWidget(wrap(ReviewCard(review: review, moderation: mod)));
    await tester.pumpAndSettle();

    expect(find.text('Título'), findsNothing);
    expect(find.text('Sin descripción'), findsNothing);
    expect(find.text('Pedro'), findsOneWidget);
  });

  testWidgets('«Anónimo» sin usuario', (tester) async {
    final review = Review(id: '3', rating: '2', review: 'Regular');
    await tester.pumpWidget(wrap(ReviewCard(review: review, moderation: mod)));
    await tester.pumpAndSettle();
    expect(find.text('Anónimo'), findsOneWidget);
  });

  testWidgets('«⋯» de 44 y «Leer más» en las largas', (tester) async {
    final review = Review(
        id: '4',
        rating: '5',
        review: 'Pedimos garbanzada y champiñones como entrantes. ' * 6,
        usuario: User(nombre: 'Laura'));
    await tester.pumpWidget(wrap(ReviewCard(review: review, moderation: mod)));
    await tester.pumpAndSettle();

    final more = _id('restaurant-review-more-4');
    expect(more, findsOneWidget);
    expect(tester.getSize(more).width, greaterThanOrEqualTo(44));
    expect(find.text('Leer más'), findsOneWidget);
    await tester.tap(find.text('Leer más'));
    await tester.pumpAndSettle();
    expect(find.text('Leer menos'), findsOneWidget);
  });

  testWidgets('reportada → «Reseña oculta» con «Deshacer»', (tester) async {
    final review =
        Review(id: '5', rating: '5', review: 'x', usuario: User(nombre: 'Eva'));
    await tester.pumpWidget(wrap(ReviewCard(review: review, moderation: mod)));
    mod.report(
        reviewId: '5', reporterId: 'me', reason: ReviewReportReason.spam);
    await tester.pumpAndSettle();
    expect(find.text('Reseña oculta'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('Eva'), findsOneWidget);
  });
}
