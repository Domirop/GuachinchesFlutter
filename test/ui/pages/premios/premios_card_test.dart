import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/premios/premios_home.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';

import 'premios_fakes.dart';

/// Card compacta de Premios del Inicio (vino y oro, tablero
/// EncuestaInicioCard).
void main() {
  PremiosRankingState ranking({bool mine = false}) => PremiosRankingState(
        load: PremiosLoad.ready,
        tradicional: [
          entry('Bodega Zacatín', 7, 1),
          entry('Guachinche Don Trino', 6, 2, tied: true, muni: 'Santa Úrsula'),
          entry('Guachinche La Cuadra', 6, 2, tied: true),
          entry('Guachinche Casa Pepe', 5, 4, mine: mine),
        ],
        moderno: [
          entry('Tasca Las Dehesas', 4, 1, tied: true),
          entry('Bistró Sur', 4, 1, tied: true),
        ],
      );

  final taps = <String>[];

  Future<void> pumpCard(
    WidgetTester t, {
    PremiosCardVariant variant = PremiosCardVariant.notVoted,
    PremiosRankingState? state,
    bool reduce = true,
    bool dark = false,
  }) async {
    phone(t);
    addTearDown(t.view.reset);
    taps.clear();
    await t.pumpWidget(app(
      Scaffold(
        body: SingleChildScrollView(
          child: PremiosWineCard(
            variant: variant,
            ranking: state ?? ranking(),
            totalVotes: 130,
            remaining: 'Quedan 12 días',
            untilShort: 'hasta el 20 de marzo',
            onVote: () => taps.add('vote'),
            onRanking: () => taps.add('ranking'),
            onMyVotes: () => taps.add('mine'),
            onHowTo: () => taps.add('howto'),
          ),
        ),
      ),
      reduce: reduce,
      dark: dark,
    ));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Finder card() => find.byType(PremiosWineCard);

  testWidgets('sin votar: compacta, enlace al ranking y estado con la fecha',
      (t) async {
    await pumpCard(t);
    expect(find.text('Premios Donde Comer Canarias 2026'), findsOneWidget);
    expect(find.text('¿Cuál es tu favorito?'), findsOneWidget);
    expect(find.byType(PodioPremios), findsOneWidget);
    expect(find.text('Votar ahora'), findsOneWidget);
    expect(find.text('Ver el ranking'), findsOneWidget);
    expect(find.text('Quedan 12 días · hasta el 20 de marzo'), findsOneWidget);
    expect(find.bySemanticsIdentifier('home-premios-mine'), findsNothing);
    expect(find.text('Ahora no'), findsNothing);
    expect(find.text('Muestra'), findsNothing);
    // Card compacta: ≈ 344 de alto en «sin votar» (antes 588; el tablero
    // cuenta además la etiqueta «Muestra» de la línea de estado).
    expect(t.getSize(card()).height, closeTo(344, 4));
    await t.tap(find.text('Votar ahora'));
    await t.tap(find.text('Ver el ranking'));
    expect(taps, ['vote', 'ranking']);
  });

  testWidgets('enlace y segmentado con área táctil de 44', (t) async {
    await pumpCard(t);
    expect(t.getSize(find.bySemanticsIdentifier('home-premios-link')).height,
        greaterThanOrEqualTo(42));
    expect(t.getSize(find.byType(PremiosSegmented)).height, 44);
  });

  testWidgets(
      'podio compacto: nombre corto en una línea, sin municipio, '
      'empates reales (2·1·2) y cambio de pestaña', (t) async {
    await pumpCard(t);
    expect(find.text('Don Trino'), findsOneWidget);
    expect(find.text('La Cuadra'), findsOneWidget);
    expect(find.text('Guachinche Don Trino'), findsNothing);
    expect(find.text('Santa Úrsula'), findsNothing);
    // El nombre completo va en el texto accesible.
    expect(find.bySemanticsLabel(RegExp('2.º puesto.*Guachinche Don Trino')),
        findsOneWidget);
    expect(find.text('6 votos · empate'), findsNWidgets(2));
    expect(find.text('7 votos'), findsOneWidget);
    await t.tap(find.text('Moderno'));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Tasca Las Dehesas'), findsOneWidget);
    expect(find.text('4 votos · empate'), findsNWidgets(2));
    expect(find.text('Bodega Zacatín'), findsNothing);
  });

  testWidgets('ya votaste: «Así va la votación», «Tu voto» en una línea',
      (t) async {
    await pumpCard(t,
        variant: PremiosCardVariant.voted, state: ranking(mine: true));
    expect(find.text('Así va la votación'), findsOneWidget);
    expect(find.text('Votar a otros sitios'), findsOneWidget);
    expect(find.text('Casa Pepe'), findsOneWidget);
    expect(find.text('4.º · 5 votos'), findsOneWidget);
    expect(find.text('Ya votaste · quedan 12 días'), findsOneWidget);
    final mine = find.bySemanticsIdentifier('home-premios-mine');
    expect(t.getSize(mine).height, 34);
    expect(find.text('Ahora no'), findsNothing);
  });

  testWidgets('cerrada: «Ganadores 2026», «Mis votos ›» y votos totales',
      (t) async {
    await pumpCard(t,
        variant: PremiosCardVariant.closed, state: ranking(mine: true));
    expect(find.text('Ganadores 2026'), findsOneWidget);
    expect(find.text('4.º · 5 votos'), findsOneWidget);
    expect(find.text('Ver el ranking completo'), findsOneWidget);
    expect(find.text('Mis votos'), findsOneWidget);
    expect(find.text('Votación cerrada · 130 votos'), findsOneWidget);
    await t.tap(find.text('Ver el ranking completo'));
    await t.tap(find.text('Mis votos'));
    expect(taps, ['ranking', 'mine']);
  });

  testWidgets('ranking oculto: podio compacto en silueta, «Cómo se vota ›»',
      (t) async {
    await pumpCard(t,
        state:
            const PremiosRankingState(load: PremiosLoad.ready, hidden: true));
    expect(find.byType(PremiosSilhouettePodium), findsOneWidget);
    expect(find.text('El ranking se desvela al cierre'), findsOneWidget);
    expect(find.byType(PremiosSegmented), findsNothing);
    expect(find.byType(PodioPremios), findsNothing);
    expect(find.text('Cómo se vota'), findsOneWidget);
    expect(find.text('Votar ahora'), findsOneWidget);
    expect(find.text('Quedan 12 días · hasta el 20 de marzo'), findsOneWidget);
    await t.tap(find.text('Cómo se vota'));
    expect(taps, ['howto']);
  });

  testWidgets('error o 404: discreto, sin podio ni mensaje de fallo',
      (t) async {
    await pumpCard(t,
        state: const PremiosRankingState(load: PremiosLoad.error));
    expect(find.byType(PodioPremios), findsNothing);
    expect(find.byType(PremiosSilhouettePodium), findsNothing);
    expect(find.text('Votar ahora'), findsOneWidget);
    expect(find.text('Cómo se vota'), findsOneWidget);
  });

  test('línea de estado', () {
    String line(PremiosCardVariant v, {String r = 'Quedan 3 días'}) =>
        PremiosWineCard.statusLine(
            variant: v,
            remaining: r,
            untilShort: 'hasta el 20 de marzo',
            totalVotes: 1);
    expect(line(PremiosCardVariant.notVoted),
        'Quedan 3 días · hasta el 20 de marzo');
    expect(line(PremiosCardVariant.voted, r: 'Queda 1 día'),
        'Ya votaste · queda 1 día');
    expect(line(PremiosCardVariant.closed), 'Votación cerrada · 1 voto');
    expect(line(PremiosCardVariant.notVoted, r: ''), 'hasta el 20 de marzo');
  });

  test('nombre corto del podio', () {
    expect(premiosShortName('Guachinche Don Trino'), 'Don Trino');
    expect(premiosShortName('Bodega Zacatín'), 'Bodega Zacatín');
    expect(premiosShortName('Guachinche'), 'Guachinche');
  });

  testWidgets('noche: misma card', (t) async {
    await pumpCard(t, dark: true);
    expect(find.byType(PodioPremios), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('CTA: tres respiraciones desde 2,4 s y luego quieta', (t) async {
    await pumpCard(t, reduce: false);
    final s = t.state<PremiosCardCtaState>(find.byType(PremiosCardCta));
    expect(s.isPulsing, isFalse); // 1 s: aún no
    await t.pump(const Duration(milliseconds: 1500));
    expect(s.isPulsing, isTrue);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    expect(s.pulsesDone, PremiosCardCta.pulses);
    expect(s.isPulsing, isFalse);
    await t.pump(const Duration(seconds: 30));
    expect(s.pulsesDone, 3);
    expect(t.hasRunningAnimations, isFalse);
    expect(find.bySemanticsIdentifier('home-premios-cta'), findsOneWidget);
  });

  testWidgets('movimiento reducido: sin pulso ni brillo, cuadro final',
      (t) async {
    await pumpCard(t);
    final s = t.state<PremiosCardCtaState>(find.byType(PremiosCardCta));
    await t.pump(const Duration(seconds: 15));
    expect(s.isPulsing, isFalse);
    expect(s.pulsesDone, 0);
    expect(t.hasRunningAnimations, isFalse);
    expect(find.text('6 votos · empate'), findsNWidgets(2));
  });
}
