import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_visit.dart';

Visit _visit() => Visit.fromJson({
      'id': 'v1',
      'restaurantId': 'r1',
      'name': 'Mercado de San Mateo',
      'zone': 'Gran Canaria',
      'summary': 'El Mercado de San Mateo es un lugar vibrante y accesible.',
      'youtubeVideo': {
        'videoId': 'abc123',
        'publishedAt': '2026-03-02T10:00:00.000Z',
      },
      // sin thumbnail/mainFoto → placeholder, evita red en el test
    });

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );

void main() {
  testWidgets('card web-style: fecha vídeo + zona + título + play, sin overflow',
      (tester) async {
    await tester.pumpWidget(_host(
      CardVisit(visit: _visit(), onTap: () {}),
    ));
    await tester.pump();

    // Chip de fecha del vídeo (no la de publicación en app): «2 mar»
    // (+ año si no es el año en curso).
    expect(find.text(CardVisit.formatVideoDate('2026-03-02T10:00:00.000Z')!),
        findsOneWidget);
    // Antetítulo de zona y título en tipo frase (rediseño iOS 27).
    expect(find.text('Gran Canaria'), findsOneWidget);
    expect(find.text('Mercado de San Mateo'), findsOneWidget);
    // Botón de play (hay vídeo de YouTube).
    expect(find.byKey(CardVisit.playKey), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('sin vídeo no muestra play', (tester) async {
    final v = Visit.fromJson({
      'id': 'v2',
      'restaurantId': 'r2',
      'name': 'Sitio sin vídeo',
      'zone': 'La Laguna',
    });
    await tester.pumpWidget(_host(CardVisit(visit: v, onTap: () {})));
    await tester.pump();

    expect(find.byKey(CardVisit.playKey), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
