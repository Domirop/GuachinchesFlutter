import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';
import 'package:guachinches/utils/contextual_pool.dart';

Finder _bySemId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

/// En tests no hay plataforma de WebView: el player falla al crearse y la
/// hoja pinta su respaldo (como cuando YouTube no deja incrustar el vídeo).
Future<void> _open(
  WidgetTester tester, {
  String videoId = 'dQw4w9WgXcW',
  Visit? visit,
  String? placeName,
  String? placeMeta,
  String? publishedAtIso,
  int? durationSeconds,
}) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: appDarkTheme,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => YoutubeEmbedSheet.show(
              ctx,
              videoId: videoId,
              visit: visit,
              placeName: placeName,
              placeMeta: placeMeta,
              publishedAtIso: publishedAtIso,
              durationSeconds: durationSeconds,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('YoutubeEmbedSheet', () {
    testWidgets(
        '(a) show() renders sheet-root and open-external-button with valid videoId',
        (tester) async {
      await _open(tester);

      expect(_bySemId('youtube-embed-sheet-root'), findsOneWidget);
      expect(_bySemId('youtube-embed-open-external-button'), findsWidgets);
      expect(_bySemId('youtube-embed-close-button'), findsOneWidget);
    });

    testWidgets('(b) close button dismisses the sheet', (tester) async {
      await _open(tester);
      expect(_bySemId('youtube-embed-sheet-root'), findsOneWidget);

      await tester.tap(_bySemId('youtube-embed-close-button'));
      await tester.pumpAndSettle();

      expect(_bySemId('youtube-embed-sheet-root'), findsNothing);
    });

    testWidgets('(c) footer: Jonay y Joana · fecha · duración y el sitio',
        (tester) async {
      await _open(
        tester,
        placeName: 'Casa Ángela',
        placeMeta: 'Guachinche moderno · La Victoria',
        publishedAtIso: '2026-10-08T12:00:00Z',
        durationSeconds: 95,
      );

      expect(find.text('Jonay y Joana · 8 oct 2026 · 1:35', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('Casa Ángela', findRichText: true),
          findsOneWidget);
      expect(
          find.textContaining('Guachinche moderno · La Victoria',
              findRichText: true),
          findsOneWidget);
    });

    testWidgets(
        '(d) footer desde la visita (sitio, tipo · municipio, fecha, duración)',
        (tester) async {
      await _open(
        tester,
        visit: Visit(
          id: 'v',
          restaurantId: 'r',
          videoPublishedAt: '2026-10-07T12:00:00Z',
          durationSeconds: 61,
          restaurant: Restaurant(
            id: 'r',
            nombre: 'El Moral',
            municipio: 'Santa Cruz de Tenerife',
            type: RestaurantTypeIds.restaurantes,
          ),
        ),
      );
      expect(find.text('Jonay y Joana · 7 oct 2026 · 1:01', findRichText: true),
          findsOneWidget);
      expect(
          find.textContaining('El Moral', findRichText: true), findsOneWidget);
      expect(
          find.textContaining('Restaurante · Santa Cruz de Tenerife',
              findRichText: true),
          findsOneWidget);
    });

    testWidgets('(e) sin datos: solo el crédito, sin línea de sitio',
        (tester) async {
      await _open(tester);
      expect(find.text('Jonay y Joana', findRichText: true), findsOneWidget);
    });

    testWidgets(
        '(f) id no válido: respaldo con su copia y «Ver en YouTube»; '
        'sin «Abrir en YouTube» arriba', (tester) async {
      await _open(tester, videoId: 'abc');

      expect(_bySemId('youtube-embed-fallback'), findsOneWidget);
      expect(_bySemId('youtube-embed-player'), findsNothing);
      expect(find.text('Este vídeo no se puede ver aquí'), findsOneWidget);
      expect(
          find.text('YouTube no deja reproducirlo dentro de la app. Ábrelo '
              'allí y vuelves cuando quieras.'),
          findsOneWidget);
      expect(find.text('Ver en YouTube'), findsOneWidget);
      expect(find.text('Abrir en YouTube'), findsNothing);
      expect(_bySemId('youtube-embed-open-external-button'), findsOneWidget);
    });
  });
}
