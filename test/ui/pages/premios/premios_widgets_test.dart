import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/premios_review_page.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';

import 'premios_fakes.dart';

final _open = DateTime.utc(2026, 3, 8, 10);

/// Bombea sin esperar a que se asiente (las nubes del borde van en bucle).
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 30; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

PremiosCandidate _c(String v, String n) => PremiosCandidate(value: v, name: n);

void main() {
  setUp(() => PremiosEditionStore.instance.set(serverEdition()));
  tearDown(() => PremiosEditionStore.instance.reset());

  testWidgets('ranking: empates 7·6·6·5 → podio 1, 2, 2 y lista desde el 4',
      (t) async {
    phone(t);
    addTearDown(t.view.reset);
    final ranking = FakeRanking(PremiosRankingState(
      load: PremiosLoad.ready,
      tradicional: [
        entry('Bodega Zacatín (Guachinche El Churrasco)', 7, 1),
        entry('Guachinche Don Trino', 6, 2, tied: true),
        entry('Guachinche La Cuadra (La Victoria)', 6, 2, tied: true),
        entry('Guachinche Casa Pepe', 5, 4, mine: true),
      ],
      moderno: [
        entry('Casa Doña Vidalina', 4, 1, tied: true),
        entry('Tasca Corral del Chivo', 4, 1, tied: true),
        entry('Guachinche El Fogón', 3, 3),
      ],
    ));
    await t.pumpWidget(
        app(PremiosRankingPage(controller: ranking, clock: () => _open)));
    await _settle(t);

    final podium = find.byType(PodioPremios);
    expect(podium, findsOneWidget);
    String numbers(Finder f) => [
          for (final w in t.widgetList<Text>(
              find.descendant(of: f, matching: find.byType(Text))))
            w.data ?? ''
        ].where((s) => RegExp(r'^\d+$').hasMatch(s)).join(',');
    // Orden 2.º · 1.º · 3.º con el puesto real (dos platas, sin bronce).
    expect(numbers(podium), '2,1,2');
    expect(find.text('6 votos · empate'), findsNWidgets(2));
    expect(find.text('(Guachinche El Churrasco)'), findsOneWidget);
    // Fila del 4.º, marcada como mi voto.
    expect(
        find.bySemanticsLabel(
            RegExp(r'^4\.º, Guachinche Casa Pepe, 5 votos, tu voto')),
        findsOneWidget);
    expect(
        find.text('24 votos · 4 guachinches con algún voto'), findsOneWidget);
    expect(find.text('El resto'), findsOneWidget);
    expect(find.text('12'), findsOneWidget); // cuenta atrás en días

    // Modernos: 4·4·3 → 1, 1, 3.
    await t.tap(find.bySemanticsIdentifier('premios-ranking-tab-moderno'));
    await _settle(t);
    expect(numbers(find.byType(PodioPremios)), '1,1,3');
    expect(find.text('4 votos · empate'), findsNWidgets(2));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('votar: el buscador ignora tildes y mayúsculas', (t) async {
    phone(t);
    addTearDown(t.view.reset);
    final flow =
        FakeFlow(PremiosFlowState(load: PremiosLoad.ready, candidates: {
      PremiosCategory.tradicional: [
        _c('1', 'Guachinche Casa José (El Tejadito)'),
        _c('2', 'Bodega Zacatín'),
        _c('3', 'Guachinche Lala'),
      ],
      PremiosCategory.moderno: [_c('9', 'Tasca Las Dehesas')],
    }));
    await t.pumpWidget(app(PremiosVotePage(controller: flow), reduce: true));
    await _settle(t);
    expect(find.text('3 candidatos · elige uno o sáltate la categoría'),
        findsOneWidget);

    await t.enterText(find.byType(TextField), 'JOSE');
    await _settle(t);
    expect(find.text('Guachinche Casa José (El Tejadito)'), findsOneWidget);
    expect(find.text('Bodega Zacatín'), findsNothing);
    expect(find.text('1 resultado'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'zacatin');
    await _settle(t);
    expect(find.text('Bodega Zacatín'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'tasca del puerto');
    await _settle(t);
    expect(find.text('Ninguno se llama «tasca del puerto»'), findsOneWidget);
    expect(find.text('0 resultados'), findsOneWidget);

    // Elegir cambia la barra de «Saltar» a «Siguiente».
    await t.tap(find.text('Borrar búsqueda'));
    await _settle(t);
    expect(find.text('Saltar'), findsOneWidget);
    await t.tap(find.text('Guachinche Lala'));
    await _settle(t);
    expect(flow.state.picks[PremiosCategory.tradicional]?.value, '3');
    expect(find.text('Siguiente'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  group('revisar: resumen y avisos', () {
    Future<FakeFlow> pump(WidgetTester t, PremiosFlowState s) async {
      phone(t);
      addTearDown(t.view.reset);
      final flow = FakeFlow(s);
      await t
          .pumpWidget(app(PremiosReviewPage(controller: flow), reduce: true));
      await _settle(t);
      return flow;
    }

    String summary(WidgetTester t) => [
          for (final w in t.widgetList<Text>(find.descendant(
              of: find.bySemanticsIdentifier('premios-review-summary'),
              matching: find.byType(Text))))
            w.data
        ].join(' | ');

    testWidgets('dos votos', (t) async {
      final flow = await pump(
          t,
          PremiosFlowState(load: PremiosLoad.ready, picks: {
            PremiosCategory.tradicional: _c('1', 'Guachinche Nunca Es Lejos'),
            PremiosCategory.moderno: _c('9', 'Tasca Las Dehesas'),
          }));
      expect(summary(t), '2 votos | Tradicional y moderno');
      expect(find.text('Cambiar'), findsNWidgets(2));
      await t.tap(find.text('Enviar votos'));
      expect(flow.submits, 1);
    });

    testWidgets('uno solo', (t) async {
      await pump(
          t,
          PremiosFlowState(load: PremiosLoad.ready, picks: {
            PremiosCategory.moderno: _c('9', 'Tasca Las Dehesas'),
          }));
      expect(summary(t), '1 voto | Solo moderno');
      expect(find.text('Sin voto'), findsOneWidget);
      expect(find.text('Elegir'), findsOneWidget);
    });

    testWidgets('sin votos: aviso y botón deshabilitado', (t) async {
      final flow =
          await pump(t, const PremiosFlowState(load: PremiosLoad.ready));
      expect(summary(t), 'Ningún voto | Elige al menos uno');
      expect(find.text('Te falta elegir'), findsOneWidget);
      await t.tap(find.text('Enviar votos'));
      expect(flow.submits, 0);
    });

    testWidgets('409 con la fila marcada y servidor con «Reintentar»',
        (t) async {
      final picks = {
        PremiosCategory.tradicional: _c('1', 'Guachinche Nunca Es Lejos'),
      };
      // El presenter v3 quita el voto en conflicto de la papeleta.
      final flow = await pump(
          t,
          PremiosFlowState(
            load: PremiosLoad.ready,
            picks: const {
              PremiosCategory.moderno:
                  PremiosCandidate(value: '9', name: 'Tasca Las Dehesas'),
            },
            conflicts: {
              PremiosCategory.tradicional: _c('1', 'Guachinche Nunca Es Lejos'),
            },
            error: const PremiosError(PremiosErrorKind.alreadyVoted,
                category: PremiosCategory.tradicional, value: '1'),
          ));
      expect(find.text('Ese ya tenía tu voto'), findsOneWidget);
      expect(find.text('Ya votaste a este sitio desde este móvil'),
          findsOneWidget);

      flow.emit(PremiosFlowState(
          load: PremiosLoad.ready,
          picks: picks,
          error: const PremiosError(PremiosErrorKind.server)));
      await _settle(t);
      expect(find.text('No pudimos enviar tus votos'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      flow.emit(PremiosFlowState(
          load: PremiosLoad.ready,
          picks: picks,
          error: const PremiosError(PremiosErrorKind.deviceUnverified)));
      await _settle(t);
      expect(find.text('No hemos podido comprobar este\u00A0móvil'),
          findsOneWidget);

      flow.emit(PremiosFlowState(
          load: PremiosLoad.ready, picks: picks, submitting: true));
      await t.pump();
      expect(find.text('Enviando…'), findsOneWidget);
    });
  });

  group('escena «La papeleta a la barrica»', () {
    Widget scene({bool reduce = false, bool dark = false}) => app(
          const Scaffold(
            body: Align(
                alignment: Alignment.topCenter, child: PapeletaBarricaScene()),
          ),
          reduce: reduce,
          dark: dark,
        );

    testWidgets('movimiento reducido: fotograma final sin reloj', (t) async {
      await t.pumpWidget(scene(reduce: true));
      await t.pump(const Duration(milliseconds: 16));
      final s =
          t.state<PapeletaBarricaSceneState>(find.byType(PapeletaBarricaScene));
      expect(s.isStatic, isTrue);
      expect(s.isTicking, isFalse);
      // La etiqueta queda visible y quieta.
      final label = find.text('¡Ese es el mío!');
      expect(label, findsOneWidget);
      final op = t.widget<Opacity>(
          find.ancestor(of: label, matching: find.byType(Opacity)).first);
      expect(op.opacity, 1);
      await t.pump(const Duration(seconds: 3));
      expect(s.isTicking, isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets(
        'anima, duerme en el reposo y despierta para el siguiente bucle',
        (t) async {
      await t.pumpWidget(scene(dark: true));
      await t.pump(const Duration(milliseconds: 16));
      final s =
          t.state<PapeletaBarricaSceneState>(find.byType(PapeletaBarricaScene));
      expect(s.isStatic, isFalse);
      expect(s.isTicking, isTrue);
      for (var i = 0; i < 50; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(s.isTicking, isFalse); // reposo 3,8–8,8 s
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pump(const Duration(milliseconds: 16));
      expect(s.isTicking, isTrue); // se desvanece la etiqueta
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    test('tramos de reposo', () {
      expect(papeletaQuietRemaining(1.0), 0); // la barrica rueda
      expect(papeletaQuietRemaining(2.5), 0); // la papeleta cae
      expect(papeletaQuietRemaining(5.0), closeTo(3.8, 1e-9));
      expect(papeletaQuietRemaining(9.5), closeTo(2.0, 1e-9));
      final wake = 9.5 + papeletaQuietRemaining(9.5);
      expect(papeletaQuietRemaining(wake), 0);
    });

    testWidgets('celebración con movimiento reducido: 10 papelitos posados',
        (t) async {
      expect(confettiRestingCount, 10);
      await t.pumpWidget(app(const Scaffold(body: PapeletaBarricaCelebration()),
          reduce: true));
      await t.pump();
      final p = t.widget<CustomPaint>(find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CelebrationPainter));
      expect((p.painter! as CelebrationPainter).t, 1);
      expect(t.takeException(), isNull);
    });
  });
}
