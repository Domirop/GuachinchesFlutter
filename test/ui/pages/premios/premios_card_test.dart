import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/ui/pages/premios/premios_home.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';

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
    PremiosEdition? edition,
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
            edition: edition ??
                PremiosEdition(votingEndsAt: DateTime.utc(2026, 3, 20, 23, 59)),
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
    // Con Ahem el título baja a dos líneas (+25); con SF cabe en una.
    final titleLines = t
            .renderObject<RenderParagraph>(find.text('¿Cuál es tu favorito?'))
            .size
            .height /
        25;
    expect(t.getSize(card()).height - (titleLines.round() - 1) * 25,
        closeTo(344, 4));
    await t.tap(find.text('Votar ahora'));
    await t.tap(find.text('Ver el ranking'));
    expect(taps, ['vote', 'ranking']);
  });

  testWidgets('título largo: baja a dos líneas sin cortarse ni desbordar',
      (t) async {
    // QA multidispositivo (I4): con texto grande se cortaba en «¿Cuá…». La
    // fuente de los tests (Ahem) es tan ancha que el título no cabe en una
    // línea junto a «Ver el ranking»: tiene que bajar a dos y la cabecera
    // dejarle sitio.
    await pumpCard(t);
    expect(t.takeException(), isNull);
    final title = find.text('¿Cuál es tu favorito?');
    expect(t.widget<Text>(title).maxLines, 2);
    final line = t.renderObject<RenderParagraph>(title);
    expect(line.size.height, closeTo(50, 1)); // 2 × 25
    final eyebrow = t.getRect(find.text('Premios Donde Comer Canarias 2026'));
    final seg = t.getRect(find.byType(PremiosSegmented));
    expect(t.getRect(title).bottom, lessThanOrEqualTo(seg.top));
    expect(t.getRect(title).top, greaterThanOrEqualTo(eyebrow.bottom));
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

  group('año de la edición', () {
    tearDown(PremiosEditionStore.instance.reset);

    test('del label; si no, del cierre; sin edición, ninguno', () {
      expect(
          PremiosEdition(
                  label: 'Premios Donde Comer Canarias 2027',
                  votingEndsAt: DateTime.utc(2026, 12, 31))
              .year,
          2027);
      expect(
          PremiosEdition(
                  label: 'Edición de primavera',
                  votingEndsAt: DateTime.utc(2028, 3, 20))
              .year,
          2028);
      expect(PremiosEdition(label: 'Ed. 120267').year, isNull);
      expect(PremiosEdition.none.year, isNull);
      expect(PremiosEdition.none.awardsTitle, 'Premios Donde Comer Canarias');
      expect(PremiosEdition.none.winnersTitle, 'Ganadores');
      expect(PremiosEdition.none.shortTitle, 'Premios');
      final e = PremiosEdition.fromSurvey(const SurveyEdition(
          editionId: 3,
          label: 'Premios 2027',
          status: SurveyEditionStatus.open));
      expect(e.awardsTitle, 'Premios Donde Comer Canarias 2027');
      expect(e.winnersTitle, 'Ganadores 2027');
    });

    testWidgets('card: el año sale de la edición', (t) async {
      await pumpCard(t,
          variant: PremiosCardVariant.closed,
          state: ranking(mine: true),
          edition: PremiosEdition(label: 'Premios 2027'));
      expect(find.text('Premios Donde Comer Canarias 2027'), findsOneWidget);
      expect(find.text('Ganadores 2027'), findsOneWidget);
      expect(find.textContaining('2026'), findsNothing);
    });

    testWidgets('card sin edición (404/red): sin año inventado', (t) async {
      await pumpCard(t,
          variant: PremiosCardVariant.closed,
          state: ranking(mine: true),
          edition: PremiosEdition.none);
      expect(find.text('Premios Donde Comer Canarias'), findsOneWidget);
      expect(find.text('Ganadores'), findsOneWidget);
      expect(find.textContaining(RegExp(r'20\d\d')), findsNothing);
    });

    testWidgets('papeleta, sello y antetítulo con el año de la edición',
        (t) async {
      phone(t);
      addTearDown(t.view.reset);
      PremiosEditionStore.instance.set(PremiosEdition(label: 'Premios 2027'));
      await t.pumpWidget(app(
          const Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [
                PremiosEyebrow(),
                PapeletaCard(rows: [], overlay: SelloVotado()),
              ]),
            ),
          ),
          reduce: true));
      await t.pump(const Duration(seconds: 2));
      expect(find.text('Premios Donde Comer Canarias 2027', findRichText: true),
          findsOneWidget);
      expect(find.text('Papeleta · Premios 2027'), findsOneWidget);
      expect(find.text('2027'), findsOneWidget); // sello
      // Sin edición: sin año en ninguno.
      PremiosEditionStore.instance.set(PremiosEdition.none);
      await t.pump();
      expect(find.text('Premios Donde Comer Canarias', findRichText: true),
          findsOneWidget);
      expect(find.text('Papeleta · Premios'), findsOneWidget);
      expect(find.textContaining(RegExp(r'20\d\d'), findRichText: true),
          findsNothing);
      await t.pump(const Duration(seconds: 2));
    });

    test('la barrica lleva el año de la edición en tiza', () {
      expect(PremiosSceneColors.of(false, year: 2027).chalk, '2027');
      expect(PremiosSceneColors.of(true).chalk, isEmpty);
      expect(PremiosSceneColors.of(true, year: 2027),
          PremiosSceneColors.of(true, year: 2027));
      expect(PremiosSceneColors.of(true, year: 2027),
          isNot(PremiosSceneColors.of(true, year: 2028)));
    });
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
