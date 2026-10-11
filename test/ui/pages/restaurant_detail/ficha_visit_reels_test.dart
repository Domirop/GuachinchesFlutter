import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ficha_visit_reels.dart';

Visit _visit(String id, String date, List<String> dishes,
        {List<VisitQuote> quotes = const []}) =>
    Visit(
      id: id,
      restaurantId: 'r',
      videoPublishedAt: date,
      durationSeconds: 95,
      overallSentiment: 'muy_positivo',
      dishes: [
        for (final d in dishes) VisitDish(name: d, sentiment: 'loved'),
      ],
      quotes: quotes,
    );

Future<List<String>> _pump(WidgetTester tester, List<Visit> visits) async {
  final opened = <String>[];
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: appLightTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: FichaVisitReels(
          restaurant: Restaurant(id: 'r'),
          visits: fichaSortedVisits(visits),
          onOpenVisit: (v) => opened.add(v.id),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets(
      'carrusel: tocar otra portada la elige (platos y citas cambian); '
      'tocar la elegida abre el reproductor', (tester) async {
    final semantics = tester.ensureSemantics();
    final opened = await _pump(tester, [
      _visit('vieja', '2025-05-06T13:27:54Z', ['Bocadillo de cochino'],
          quotes: const [VisitQuote(text: 'Es enorme.')]),
      _visit('nueva', '2026-03-10T12:58:49Z', ['Arepas', 'Bocadillos'],
          quotes: const [VisitQuote(text: 'Qué buenas están las arepas.')]),
    ]);

    expect(find.text('2 visitas · YouTube Shorts'), findsOneWidget);
    expect(find.text('Lo que pidieron el 10 mar · 2 les encantaron'),
        findsOneWidget);
    expect(find.text('«Qué buenas están las arepas.»'), findsOneWidget);
    // La anterior lleva su fecha debajo.
    expect(find.text('6 may 2025'), findsOneWidget);

    // Tocar la anterior: la elige, no abre nada.
    await tester.tap(find.bySemanticsLabel('Elegir la visita del 6 may 2025'));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(find.text('Lo que pidieron el 6 may · 1 les encantó'), findsOneWidget);
    expect(find.text('Lo que pidieron el 10 mar · 2 les encantaron'), findsNothing);
    expect(find.text('«Es enorme.»'), findsOneWidget);

    // Tocar la elegida: abre el reproductor de esa visita.
    await tester.tap(find.bySemanticsLabel('Ver la visita del 6 may 2025'));
    await tester.pumpAndSettle();
    expect(opened, ['vieja']);

    // «Ver visita completa» abre la elegida.
    await tester.tap(find.bySemanticsLabel('Ver visita completa'));
    await tester.pumpAndSettle();
    expect(opened, ['vieja', 'vieja']);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('una visita: portada + columna con la cita, sin carrusel',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final opened = await _pump(tester, [
      _visit('a', '2026-10-08T17:32:43Z',
          ['Churritos', 'Favada', 'Tomates', 'Chuleta', 'Conejo', 'Quesillo'],
          quotes: const [VisitQuote(text: 'La salsa está buenísima.')]),
    ]);
    expect(find.text('1 visita · YouTube Shorts'), findsOneWidget);
    expect(find.text('Última visita'), findsOneWidget);
    expect(find.text('Short · 1:35 · 6 platos'), findsOneWidget);
    // La cita va en la columna, no repetida en «Lo que dicen en el vídeo».
    expect(find.text('«La salsa está buenísima.»'), findsOneWidget);
    expect(find.text('Lo que dicen en el vídeo'), findsNothing);
    expect(find.text('Les encantó'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Ver la visita del 8 oct 2026'));
    await tester.pumpAndSettle();
    expect(opened, ['a']);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
