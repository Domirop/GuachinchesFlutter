import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_reviews_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/review_moderation.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';

class _FakeRepo extends Fake implements RemoteRepository {
  final reported = <(String, String)>[];
  final blocked = <(String, String)>[];

  @override
  Future<bool> reportReview(String userId, String reviewId) async {
    reported.add((userId, reviewId));
    return true;
  }

  @override
  Future<bool> blockUser(String userId, String userIdToBlock) async {
    blocked.add((userId, userIdToBlock));
    return true;
  }
}

Restaurant _fakeRestaurant() {
  final reviews = [
    Review(id: '1', rating: '5', usuario: User(id: 'ua', nombre: 'Ana')),
    Review(
        id: '2',
        rating: '5',
        title: 'Título',
        review: 'review-cinco-b',
        usuario: User(id: 'ub', nombre: 'Ben')),
    Review(
        id: '3',
        rating: '4',
        review: 'review-cuatro-a',
        usuario: User(id: 'uc', nombre: 'Carlos')),
    Review(
        id: '4',
        rating: '1',
        review: 'review-uno',
        usuario: User(id: 'ud', nombre: 'Diana')),
  ];
  return Restaurant(
    id: 'r1',
    nombre: 'Guachinche El Fogón',
    municipio: 'La Laguna',
    valoraciones: reviews,
    avgRating: 3.7,
  );
}

Finder _id(String id) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);

void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late _FakeRepo repo;

  ReviewModeration mod({String? userId}) => ReviewModeration(
        repository: repo,
        readUserId: () async => userId,
        sendDelay: const Duration(seconds: 5),
      );

  Future<void> pumpScreen(WidgetTester tester, ReviewModeration m,
      {ThemeData? theme}) async {
    _bigSurface(tester);
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? appLightTheme,
      home:
          RestaurantReviewsScreen(restaurant: _fakeRestaurant(), moderation: m),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> reportCarlos(WidgetTester tester, String reasonCode) async {
    await tester.tap(_id('restaurant-review-more-3'));
    await tester.pumpAndSettle();
    expect(find.text('Bloquear a Carlos'), findsOneWidget);
    await tester.tap(_id('restaurant-reviews-action-report'));
    await tester.pumpAndSettle();
    expect(_id('restaurant-reviews-report-sheet'), findsOneWidget);
    await tester.tap(_id('restaurant-reviews-report-reason-$reasonCode'));
    await tester.pumpAndSettle();
    await tester.tap(_id('restaurant-reviews-report-send'));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = _FakeRepo());

  testWidgets('pinta todas las reseñas, sin rellenos y relevantes primero',
      (tester) async {
    await pumpScreen(tester, mod(userId: 'me'), theme: appDarkTheme);

    expect(find.byType(ReviewCard), findsNWidgets(4));
    expect(find.text('Reseñas'), findsOneWidget);
    expect(find.text('Guachinche El Fogón · La Laguna'), findsOneWidget);
    expect(find.text('Título'), findsNothing);
    final cards =
        tester.widgetList<ReviewCard>(find.byType(ReviewCard)).toList();
    // Ana (sin comentario) baja al final.
    expect(cards.last.review.id, '1');
  });

  testWidgets('menú de orden: «Peor puntuadas»', (tester) async {
    await pumpScreen(tester, mod(userId: 'me'));

    await tester.tap(_id('restaurant-reviews-sort-button'));
    await tester.pumpAndSettle();
    expect(_id('restaurant-reviews-sort-menu'), findsOneWidget);

    await tester.tap(_id('restaurant-reviews-sort-worst'));
    await tester.pumpAndSettle();

    final cards =
        tester.widgetList<ReviewCard>(find.byType(ReviewCard)).toList();
    expect(cards.first.review.rating, '1');
    expect(find.text('Peor puntuadas'), findsOneWidget);
  });

  testWidgets('reportar: oculta con «Deshacer» y manda tras la espera',
      (tester) async {
    await pumpScreen(tester, mod(userId: 'me'));
    await reportCarlos(tester, 'offensive');

    expect(_id('restaurant-review-hidden'), findsOneWidget);
    expect(find.text('Gracias. Ya no la verás.'), findsOneWidget);
    expect(repo.reported, isEmpty);

    await tester.pump(const Duration(seconds: 6));
    expect(repo.reported, [('me', '3')]);
    await tester.pumpAndSettle();
  });

  testWidgets('«Deshacer» antes del envío no manda nada', (tester) async {
    await pumpScreen(tester, mod(userId: 'me'));
    await reportCarlos(tester, 'spam');

    await tester.tap(_id('restaurant-review-undo'));
    await tester.pumpAndSettle();
    expect(_id('restaurant-review-hidden'), findsNothing);

    await tester.pump(const Duration(seconds: 10));
    expect(repo.reported, isEmpty);
  });

  testWidgets('bloquear: confirma y oculta las reseñas de esa persona',
      (tester) async {
    await pumpScreen(tester, mod(userId: 'me'));

    await tester.tap(_id('restaurant-review-more-4'));
    await tester.pumpAndSettle();
    await tester.tap(_id('restaurant-reviews-action-block'));
    await tester.pumpAndSettle();
    expect(find.text('¿Bloquear a Diana?'), findsOneWidget);

    await tester.tap(_id('restaurant-reviews-block-confirm'));
    await tester.pumpAndSettle();

    expect(repo.blocked, [('me', 'ud')]);
    expect(find.byType(ReviewCard), findsNWidgets(3));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('invitado: «Entra para reportar»', (tester) async {
    await pumpScreen(tester, mod());

    await tester.tap(_id('restaurant-review-more-2'));
    await tester.pumpAndSettle();

    expect(_id('restaurant-reviews-guest-alert'), findsOneWidget);
    expect(find.text('Entra para reportar'), findsOneWidget);
    expect(find.text('Escribir a soporte'), findsOneWidget);

    await tester.tap(_id('restaurant-reviews-guest-dismiss'));
    await tester.pumpAndSettle();
    expect(_id('restaurant-reviews-guest-alert'), findsNothing);
    expect(repo.reported, isEmpty);
  });

  testWidgets('volver cierra la pantalla', (tester) async {
    _bigSurface(tester);
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
            builder: (_) => RestaurantReviewsScreen(
                restaurant: _fakeRestaurant(), moderation: mod()),
          )),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(_id('restaurant-reviews-back-button'));
    await tester.pumpAndSettle();
    expect(find.byType(RestaurantReviewsScreen), findsNothing);
  });
}
