import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

// URLs que nunca se resuelven en el entorno de test (no hay red ni
// path_provider): el visor cae a sus ramas de carga / error sin tocar la red.
const _dishes = [
  VisitDish(
      name: 'Churritos de pescado',
      photoUrl: 'https://example.invalid/0.jpg',
      sentiment: 'liked'),
  VisitDish(
      name: 'Conejo',
      price: 26,
      sentiment: 'loved',
      description: 'Se sirve en bandeja entera; muy bien dorado.',
      photoUrl: 'https://example.invalid/1.jpg'),
  VisitDish(
      name: 'Steak tartar',
      sentiment: 'disliked',
      photoUrl: 'https://example.invalid/2.jpg'),
];

Future<void> _open(
  WidgetTester tester, {
  List<VisitDish> dishes = _dishes,
  int initialIndex = 1,
  Visit? visit,
  String? placeName,
  String? visitDateIso,
}) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: appLightTheme,
    home: Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showDishPhotoViewer(
            ctx,
            dishes: dishes,
            initialIndex: initialIndex,
            heroPrefix: 'test',
            visit: visit,
            placeName: placeName,
            visitDateIso: visitDateIso,
          ),
          child: const Text('Abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('contador, sello «Les encantó», precio y pie del sitio',
      (tester) async {
    await _open(tester,
        placeName: 'Casa Ángela', visitDateIso: '2026-10-08T12:00:00Z');

    expect(_bySemId('dish-viewer-close'), findsOneWidget);
    expect(_bySemId('dish-viewer-share'), findsOneWidget);
    expect(_bySemId('dish-viewer-counter'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Conejo'), findsOneWidget);
    expect(find.text('26 €'), findsOneWidget);
    expect(find.byType(DishLovedStamp), findsOneWidget);
    expect(find.text('Se sirve en bandeja entera; muy bien dorado.'),
        findsOneWidget);
    expect(find.text('Casa Ángela · Visita del 8 oct 2026'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(_bySemId('dish-viewer-thumb-$i'), findsOneWidget);
    }
  });

  testWidgets('tocar una miniatura salta a ese plato (sello ámbar)',
      (tester) async {
    await _open(tester);

    await tester.tap(_bySemId('dish-viewer-thumb-2'));
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('Steak tartar'), findsOneWidget);
    expect(find.byType(DishDislikedStamp), findsOneWidget);
    expect(find.text('No les convenció'), findsOneWidget);
    expect(find.byType(DishLovedStamp), findsNothing);
    // Sin sitio ni fecha no hay pie.
    expect(find.textContaining('Visita del'), findsNothing);
  });

  testWidgets('neutro/«les gustó» no lleva sello; pie desde la visita',
      (tester) async {
    final visit = Visit(
      id: 'v',
      restaurantId: 'r',
      videoPublishedAt: '2026-10-07T12:00:00Z',
      restaurant: Restaurant(id: 'r', nombre: 'El Moral'),
    );
    await _open(tester, initialIndex: 0, visit: visit);

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Churritos de pescado'), findsOneWidget);
    expect(find.byType(DishLovedStamp), findsNothing);
    expect(find.byType(DishDislikedStamp), findsNothing);
    expect(find.text('El Moral · Visita del 7 oct 2026'), findsOneWidget);
  });

  testWidgets('una sola foto: sin contador ni miniaturas; Cerrar cierra',
      (tester) async {
    await _open(tester, dishes: [_dishes[1]], initialIndex: 0);

    expect(_bySemId('dish-viewer-counter'), findsNothing);
    expect(_bySemId('dish-viewer-thumb-0'), findsNothing);
    expect(find.text('Conejo'), findsOneWidget);

    await tester.tap(_bySemId('dish-viewer-close'));
    await tester.pumpAndSettle();
    expect(find.text('Conejo'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('arrastrar hacia abajo cierra; un arrastre corto vuelve',
      (tester) async {
    await _open(tester);

    await tester.drag(find.text('Conejo'), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text('Conejo'), findsOneWidget);

    await tester.drag(find.text('Conejo'), const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(find.text('Conejo'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('foto que no carga: error con «Reintentar» que vuelve a pedirla',
      (tester) async {
    final cache = _FailingCacheManager();
    // URL propia: la caché de imágenes en memoria se comparte entre tests.
    const url = 'https://example.invalid/error.jpg';
    await tester.pumpWidget(MaterialApp(
      theme: appDarkTheme,
      home: DishPhotoViewer(
        dishes: const [
          VisitDish(
              name: 'Conejo', price: 26, sentiment: 'loved', photoUrl: url)
        ],
        cacheManager: cache,
      ),
    ));
    await _settleImages(tester);
    expect(find.text('No pudimos cargar la foto'), findsOneWidget);
    expect(
        find.text('Revisa tu conexión e inténtalo de nuevo.'), findsOneWidget);
    expect(_bySemId('dish-viewer-retry-button'), findsOneWidget);
    // El resto de la página sigue: nombre, precio y sello.
    expect(find.text('Conejo'), findsOneWidget);
    final before = cache.requests;

    await tester.tap(find.text('Reintentar'));
    await _settleImages(tester);
    expect(cache.removed, contains(url));
    expect(cache.requests, greaterThan(before));
    expect(find.text('No pudimos cargar la foto'), findsOneWidget);
  });
}

/// El error de la imagen llega tras un par de vueltas del bucle de eventos.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Caché que siempre falla (sin red ni disco).
class _FailingCacheManager extends Fake implements BaseCacheManager {
  int requests = 0;
  final removed = <String>[];

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    requests++;
    return Stream<FileResponse>.error(
        HttpExceptionWithStatus(404, 'not found', uri: Uri.parse(url)));
  }

  @override
  Future<void> removeFile(String key) async => removed.add(key);
}
