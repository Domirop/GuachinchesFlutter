import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/services/survey_integrity/survey_integrity.dart';
import 'package:guachinches/ui/pages/myVotedRestaurants/myVotedRestaurants.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_home.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_my_votes_page.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_page.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';

import '../../../survey_v3/survey_fakes.dart';
import 'premios_fakes.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PremiosEditionStore.instance.reset();
    PremiosHomeStore.sheetShownThisSession = false;
    PremiosVotedStore.instance.reset();
  });
  tearDown(() {
    PremiosEditionStore.instance.reset();
  });

  group('controlador sobre el presenter v3', () {
    late FakeSurveyRepo repo;
    late DateTime now;
    SurveyVotePresenter presenter() => SurveyVotePresenter(
          repository: repo,
          identity: identity(),
          appVersion: '4.7.0',
          clock: () => now,
          sleep: (_) async {},
          random: Random(1),
        );

    setUp(() {
      repo = FakeSurveyRepo();
      now = DateTime.utc(2027, 2, 10, 12);
      PremiosVotedStore.instance.reset();
    });

    test('carga: candidatos en tipo título, edición publicada y lo votado',
        () async {
      repo.mine =
          const SurveyMyVotes(status: SurveyDeviceStatus.active, voted: {
        kMod: ['r-m1']
      });
      final c = V3PremiosFlowController(presenter: presenter());
      await c.load();
      expect(c.state.load, PremiosLoad.ready);
      expect(c.state.candidatesOf(PremiosCategory.tradicional).length, 3);
      expect(c.state.candidatesOf(PremiosCategory.moderno).map((x) => x.value),
          isNot(contains('r-m1')));
      expect(PremiosEditionStore.instance.current.id, 2);
      expect(PremiosVotedStore.instance.isMine('r-m1'), isTrue);
    });

    test('409: aviso tipado y la fila en conflicto se enseña aunque se quite',
        () async {
      repo.voteSteps
          .add(() => apiError(409, 'already_voted_this_business', details: {
                'conflicts': [
                  {'category': kTrad, 'value': 'r-t1'}
                ]
              }));
      final c = V3PremiosFlowController(presenter: presenter());
      await c.load();
      c.pick(
          PremiosCategory.tradicional,
          c.state
              .candidatesOf(PremiosCategory.tradicional)
              .firstWhere((x) => x.value == 'r-t1'));
      c.pick(PremiosCategory.moderno,
          c.state.candidatesOf(PremiosCategory.moderno).first);
      now = now.add(const Duration(seconds: 5));
      await c.submit();
      expect(c.state.error?.kind, PremiosErrorKind.alreadyVoted);
      expect(c.state.error?.category, PremiosCategory.tradicional);
      expect(c.state.picks.containsKey(PremiosCategory.tradicional), isFalse);
      expect(c.state.conflicts[PremiosCategory.tradicional]?.name,
          'Tradicional 1');
    });

    test('errores del servidor → avisos y «Reintentar»', () async {
      final c = V3PremiosFlowController(presenter: presenter());
      await c.load();
      c.pick(PremiosCategory.moderno,
          c.state.candidatesOf(PremiosCategory.moderno).first);
      now = now.add(const Duration(seconds: 5));
      for (final (step, kind) in [
        (() => apiError(429, 'rate_limited'), PremiosErrorKind.rateLimited),
        (
          () => apiError(503, 'verification_unavailable'),
          PremiosErrorKind.verificationUnavailable
        ),
        (
          () => apiError(403, 'integrity_failed',
              details: {'reason': 'app_check_invalid'}),
          PremiosErrorKind.deviceUnverified
        ),
        (() => throw const SurveyNetworkException(), PremiosErrorKind.network),
      ]) {
        repo.voteSteps.add(step);
        await c.submit();
        expect(c.state.error?.kind, kind);
        expect(premiosErrorCopy(kind).retry, isTrue);
      }
      // 503 integrity_unavailable: la votación no está disponible (sin
      // «Reintentar»).
      repo.voteSteps.add(() => apiError(503, 'integrity_unavailable'));
      await c.submit();
      expect(c.state.error?.kind, PremiosErrorKind.votingUnavailable);
      expect(
          premiosErrorCopy(PremiosErrorKind.votingUnavailable).retry, isFalse);
    });

    test('bloqueos: cerrada, móvil bloqueado y versión antigua', () async {
      repo.currentEdition = edition(status: SurveyEditionStatus.closed);
      final c = V3PremiosFlowController(presenter: presenter());
      await c.load();
      expect(c.state.gate, PremiosGate.closed);

      repo.currentEdition = edition();
      repo.mine = const SurveyMyVotes(status: SurveyDeviceStatus.blocked);
      await c.load();
      expect(c.state.gate, PremiosGate.blocked);

      repo.currentEdition =
          edition(minAppVersion: const {'ios': '9.0.0', 'android': '9.0.0'});
      await c.load();
      expect(c.state.gate, PremiosGate.upgradeRequired);
      expect(c.state.minAppVersion, '9.0.0');
      expect(
          premiosGateCopy(PremiosGate.upgradeRequired, store: 'la App Store')
              .action,
          'Abrir la App Store');
    });

    test('envío correcto: Gracias con nombres y caché de lo votado', () async {
      var voted = 0;
      final c = V3PremiosFlowController(
          presenter: presenter(), onVoted: () => voted++);
      await c.load();
      c.pick(PremiosCategory.moderno,
          c.state.candidatesOf(PremiosCategory.moderno).first);
      now = now.add(const Duration(seconds: 5));
      await c.submit();
      expect(c.state.sent?[PremiosCategory.moderno]?.name, isNotEmpty);
      expect(voted, 1);
      expect(PremiosVotedStore.instance.hasVoted, isTrue);
      await c.voteAgain();
      expect(c.state.sent, isNull);
    });
  });

  group('fecha de la edición', () {
    test('sale de editions/current (estado y fechas del servidor)', () async {
      final repo = FakeSurveyRepo()
        ..currentEdition = SurveyEdition(
          editionId: 3,
          label: 'Premios 2027',
          status: SurveyEditionStatus.open,
          votingEndsAt: DateTime.utc(2027, 3, 20, 23, 59),
        );
      await PremiosEditionStore.instance.refresh(repo);
      final e = PremiosEditionStore.instance.current;
      expect(e.id, 3);
      expect(e.phase(DateTime.utc(2027, 3, 8)), PremiosPhase.open);
      // El estado del servidor manda sobre el reloj del móvil.
      expect(e.phase(DateTime.utc(2027, 3, 25)), PremiosPhase.lastDay);
    });

    test('sin respuesta (red): sin edición y sin campaña', () async {
      final repo = FakeSurveyRepo()
        ..editionSteps.add(() => throw const SurveyNetworkException());
      await PremiosEditionStore.instance.refresh(repo);
      final e = PremiosEditionStore.instance.current;
      expect(e.status, isNull);
      expect(e.showOnHome(DateTime.utc(2027, 3, 8)), isFalse);
      expect(e.phase(DateTime.utc(2099)), isNot(PremiosPhase.closed));
    });

    test('404 edition_not_found: sin edición', () async {
      PremiosEditionStore.instance.set(serverEdition());
      final repo = FakeSurveyRepo()
        ..editionSteps.add(
            () => throw const SurveyApiException(404, 'edition_not_found'));
      await PremiosEditionStore.instance.refresh(repo);
      expect(PremiosEditionStore.instance.current, PremiosEdition.none);
    });

    test('caché: pinta con la última respuesta y el servidor manda', () async {
      final fresh = DateTime.now().toUtc().toIso8601String();
      FlutterSecureStorage.setMockInitialValues({
        'premiosEditionCache': jsonEncode({
          'at': fresh,
          'edition': serverEdition(id: 3, label: 'Premios 2027').toJson(),
        }),
      });
      final repo = FakeSurveyRepo()
        ..editionSteps.add(
            () => throw const SurveyApiException(404, 'edition_not_found'));
      final store = PremiosEditionStore.instance..ensureLoaded(repo);
      await store.cacheRead;
      expect(store.current.id, 3);
      expect(store.fromServer, isFalse);
      await store.loading;
      expect(store.current, PremiosEdition.none);
      expect(store.fromServer, isTrue);
    });

    test('caché caducada (TTL): no cuenta', () async {
      final old = DateTime.now()
          .toUtc()
          .subtract(PremiosEditionStore.cacheTtl + const Duration(minutes: 1));
      FlutterSecureStorage.setMockInitialValues({
        'premiosEditionCache': jsonEncode({
          'at': old.toIso8601String(),
          'edition': serverEdition(id: 3).toJson(),
        }),
      });
      final repo = FakeSurveyRepo()
        ..editionSteps.add(() => throw const SurveyNetworkException());
      final store = PremiosEditionStore.instance..ensureLoaded(repo);
      await store.cacheRead;
      expect(store.current.id, isNull);
    });

    test('la respuesta del servidor queda en caché', () async {
      final repo = FakeSurveyRepo()
        ..currentEdition = SurveyEdition(
            editionId: 3,
            label: 'Premios 2027',
            status: SurveyEditionStatus.open,
            votingEndsAt: DateTime.utc(2027, 3, 20, 23, 59, 59));
      await PremiosEditionStore.instance.refresh(repo);
      await Future<void>.delayed(Duration.zero);
      final raw = await AppStorage.instance.read(key: 'premiosEditionCache');
      final cached = PremiosEdition.fromJson(
          (jsonDecode(raw!) as Map<String, dynamic>)['edition']);
      expect(cached, PremiosEditionStore.instance.current);
      expect(cached!.year, 2027);
    });

    test('al volver a la app: solo pide otra vez con la caché caducada',
        () async {
      final repo = FakeSurveyRepo();
      final store = PremiosEditionStore.instance;
      await store.refresh(repo);
      expect(repo.editionCalls, 1);
      await store.refreshIfStale(repo, DateTime.now());
      expect(repo.editionCalls, 1);
      await store.refreshIfStale(
          repo, DateTime.now().add(PremiosEditionStore.cacheTtl));
      expect(repo.editionCalls, 2);
    });

    test('hora del servidor: cabecera Date y desfase', () {
      final now = DateTime.utc(2026, 10, 15, 9, 41, 10);
      expect(
          surveyClockSkew('Thu, 15 Oct 2026 09:41:10 GMT', now), Duration.zero);
      expect(surveyClockSkew('Thu, 15 Oct 2026 11:41:10 GMT', now),
          const Duration(hours: 2));
      expect(surveyClockSkew('ayer', now), Duration.zero);
      expect(surveyClockSkew(null, now), Duration.zero);
      // Móvil con el reloj 2 días atrasado: el servidor dice que ya han
      // pasado 16 días del cierre, aunque el móvil cuente 14.
      final end = DateTime.utc(2026, 3, 20, 23, 59);
      final e = PremiosEdition(
          id: 2,
          status: SurveyEditionStatus.closed,
          votingEndsAt: end,
          skew: const Duration(days: 2));
      expect(e.showOnHome(end.add(const Duration(days: 14))), isFalse);
      expect(
          PremiosEdition(
                  id: 2, status: SurveyEditionStatus.closed, votingEndsAt: end)
              .showOnHome(end.add(const Duration(days: 14))),
          isTrue);
    });

    test('no queda Remote Config para los premios', () {
      final hits = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        for (final k in const [
          'show_premios',
          'premios_closes_at',
          'showPremios',
          'premiosClosesAt',
          'ENABLE_PREMIOS',
          'PREMIOS_CLOSES_AT',
          'premiosHomeEnabled',
        ]) {
          if (RegExp('\\b$k\\b').hasMatch(src)) hits.add('${f.path}: $k');
        }
      }
      for (final env in Directory('env_files').listSync()) {
        if (env is File && env.readAsStringSync().contains('PREMIOS')) {
          hits.add(env.path);
        }
      }
      expect(hits, isEmpty);
    });
  });

  group('Inicio', () {
    Future<void> pumpBare(WidgetTester t, {DateTime? now}) async {
      PremiosHomeStore.sheetShownThisSession = true;
      await t.pumpWidget(app(Scaffold(
          body: PremiosHomeSlot(
              ranking: FakeRanking(const PremiosRankingState()),
              clock: () => now ?? DateTime.utc(2026, 3, 8)))));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('sin edición del servidor (404 o red): no pinta nada',
        (t) async {
      final repo = FakeSurveyRepo()
        ..editionSteps.add(
            () => throw const SurveyApiException(404, 'edition_not_found'));
      PremiosEditionStore.instance.ensureLoaded(repo);
      await t.runAsync(() => PremiosEditionStore.instance.loading);
      await pumpBare(t);
      expect(find.byType(PremiosWineCard), findsNothing);
      expect(t.getSize(find.byType(PremiosHomeSlot)), Size.zero);
    });

    testWidgets('upcoming: nada en el Inicio (aún no se vota)', (t) async {
      PremiosEditionStore.instance.set(serverEdition(
          status: SurveyEditionStatus.upcoming,
          end: DateTime.utc(2026, 5, 20)));
      await pumpBare(t);
      expect(find.byType(PremiosWineCard), findsNothing);
      expect(t.getSize(find.byType(PremiosHomeSlot)), Size.zero);
    });

    PremiosRankingState rk({bool mine = false}) => PremiosRankingState(
          load: PremiosLoad.ready,
          tradicional: [
            entry('Bodega Zacatín', 7, 1),
            entry('Guachinche Don Trino', 6, 2, tied: true),
            entry('Guachinche La Cuadra', 6, 2, tied: true),
            entry('Guachinche Casa Pepe', 5, 4, mine: mine),
          ],
          moderno: [entry('Tasca Las Dehesas', 4, 1)],
        );

    Future<void> pumpSlot(WidgetTester t, PremiosRankingState r,
        {DateTime? now}) async {
      phone(t);
      PremiosHomeStore.sheetShownThisSession = true; // sin hoja
      await t.pumpWidget(app(
          Scaffold(
              body: SingleChildScrollView(
                  child: PremiosHomeSlot(
                      ranking: FakeRanking(r),
                      clock: () => now ?? DateTime.utc(2026, 3, 8)))),
          reduce: true));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('abierta y sin votar: card compacta con podio 2·1·2',
        (t) async {
      addTearDown(t.view.reset);
      PremiosEditionStore.instance.set(serverEdition());
      await pumpSlot(t, rk());
      expect(find.byType(PremiosWineCard), findsOneWidget);
      expect(find.byType(PodioPremios), findsOneWidget);
      expect(find.text('¿Cuál es tu favorito?'), findsOneWidget);
      // Fechas de la edición (API v3 o, sin ella, Remote Config).
      expect(
          find.text('Quedan 12 días · hasta el 20 de marzo'), findsOneWidget);
      expect(find.text('Votar ahora'), findsOneWidget);
      expect(find.text('Ver el ranking'), findsOneWidget);
      expect(find.text('Ahora no'), findsNothing);
      expect(find.text('6 votos · empate'), findsNWidgets(2));
      expect(find.bySemanticsIdentifier('home-premios-mine'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('ya votó (my-votes en caché): «Tu voto · 4.º»', (t) async {
      addTearDown(t.view.reset);
      PremiosEditionStore.instance.set(serverEdition());
      PremiosVotedStore.instance.update(edition: 2, {
        PremiosCategory.tradicional.apiName: {'Guachinche Casa Pepe'}
      });
      await pumpSlot(t, rk(mine: true));
      expect(find.text('Así va la votación'), findsOneWidget);
      expect(find.text('Votar a otros sitios'), findsOneWidget);
      expect(find.text('4.º · 5 votos'), findsOneWidget);
      expect(find.text('Ya votaste · quedan 12 días'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('cerrada hace 10 días: «Ganadores 2026»', (t) async {
      addTearDown(t.view.reset);
      final end = DateTime.utc(2026, 3, 20, 23, 59);
      PremiosEditionStore.instance
          .set(serverEdition(status: SurveyEditionStatus.closed, end: end));
      await pumpSlot(t, rk(), now: end.add(const Duration(days: 10)));
      expect(find.text('Ganadores 2026'), findsOneWidget);
      expect(find.text('Ver el ranking completo'), findsOneWidget);
      expect(find.text('Mis votos'), findsOneWidget);
      expect(find.text('Votación cerrada'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('cerrada hace 20 días: nada', (t) async {
      addTearDown(t.view.reset);
      final end = DateTime.utc(2026, 3, 20, 23, 59);
      PremiosEditionStore.instance
          .set(serverEdition(status: SurveyEditionStatus.closed, end: end));
      await pumpSlot(t, rk(), now: end.add(const Duration(days: 20)));
      expect(find.byType(PremiosWineCard), findsNothing);
      expect(find.text('Ganadores 2026'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('lo votado en otra edición no cuenta', (t) async {
      addTearDown(t.view.reset);
      PremiosVotedStore.instance.update(edition: 1, {
        PremiosCategory.tradicional.apiName: {'Guachinche Casa Pepe'}
      });
      PremiosEditionStore.instance.set(serverEdition(id: 3));
      await pumpSlot(t, rk());
      expect(PremiosVotedStore.instance.hasVoted, isFalse);
      expect(find.text('¿Cuál es tu favorito?'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('ranking por edición (v3)', () {
    SurveyEditionResults results({bool hidden = false}) =>
        SurveyEditionResults.fromJson({
          'editionId': 2,
          'status': 'open',
          'hidden': hidden,
          'categories': hidden
              ? []
              : [
                  {
                    'category': kTrad,
                    'totalVotes': 9,
                    'results': [
                      {
                        'value': 'r-t1',
                        'name': 'Tradicional 1',
                        'votes': 5,
                        'rank': 1,
                        'municipality': 'Tacoronte'
                      },
                      {
                        'value': 'r-t2',
                        'name': 'Tradicional 2',
                        'votes': 2,
                        'rank': 2,
                        'photoUrl': null
                      },
                      {
                        'value': 'r-both',
                        'name': 'En las dos',
                        'votes': 2,
                        'rank': 2
                      },
                      {
                        'value': 'r-0',
                        'name': 'Sin votos',
                        'votes': 0,
                        'rank': 4
                      },
                    ]
                  },
                  {'category': kMod, 'totalVotes': 0, 'results': []},
                ],
        });

    setUp(() => PremiosVotedStore.instance.reset());

    test('usa el editionId de editions/current y el puesto del servidor',
        () async {
      final repo = _ResultsRepo(results());
      PremiosVotedStore.instance.update({
        kTrad: {'r-t2'}
      });
      final c = PremiosResultsController(repository: repo);
      await c.refresh();
      expect(repo.resultsFor, [2]);
      final s = c.state;
      expect(s.load, PremiosLoad.ready);
      expect(s.hidden, isFalse);
      expect(s.tradicional.map((e) => e.rank).toList(), [1, 2, 2]);
      expect(s.tradicional.first.municipio, 'Tacoronte');
      expect(s.tradicional.where((e) => e.mine).single.id, 'r-t2');
      expect(s.totalVotes, 9);
      expect(s.moderno, isEmpty);
    });

    test('oculto hasta el cierre: sin filas y con la marca', () async {
      final c = PremiosResultsController(
          repository: _ResultsRepo(results(hidden: true)));
      await c.refresh();
      expect(c.state.load, PremiosLoad.ready);
      expect(c.state.hidden, isTrue);
      expect(c.state.tradicional, isEmpty);
    });

    test('404 edition_not_found → error discreto (sin excepción)', () async {
      final repo = _ResultsRepo(results())
        ..resultsError = const SurveyApiException(404, 'edition_not_found');
      final c = PremiosResultsController(repository: repo);
      await c.refresh();
      expect(c.state.load, PremiosLoad.error);
    });
  });

  group('Inicio: ranking oculto o sin resultados', () {
    Future<void> pump(WidgetTester t, PremiosRankingState r) async {
      phone(t);
      PremiosHomeStore.sheetShownThisSession = true;
      PremiosEditionStore.instance.set(serverEdition());
      await t.pumpWidget(app(
          Scaffold(
              body: SingleChildScrollView(
                  child: PremiosHomeSlot(
                      ranking: FakeRanking(r),
                      clock: () => DateTime.utc(2026, 3, 8)))),
          reduce: true));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('oculto: silueta, «se desvela al cierre» y Votar ahora',
        (t) async {
      addTearDown(t.view.reset);
      await pump(
          t, const PremiosRankingState(load: PremiosLoad.ready, hidden: true));
      expect(find.text('¿Cuál es tu favorito?'), findsOneWidget);
      expect(find.text('Cómo se vota'), findsOneWidget);
      expect(find.text('El ranking se desvela al cierre'), findsOneWidget);
      expect(find.byType(PremiosSilhouettePodium), findsOneWidget);
      expect(find.byType(PodioPremios), findsNothing);
      expect(find.text('Votar ahora'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('sin resultados (404/red): sin podio ni fallo, con Votar',
        (t) async {
      addTearDown(t.view.reset);
      await pump(t, const PremiosRankingState(load: PremiosLoad.error));
      expect(find.byType(PodioPremios), findsNothing);
      expect(find.textContaining('No pudimos'), findsNothing);
      expect(find.text('Votar ahora'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Ranking oculto: la tarjeta del cierre en vez del podio',
        (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          PremiosRankingPage(
              controller: FakeRanking(const PremiosRankingState(
                  load: PremiosLoad.ready, hidden: true))),
          reduce: true));
      await t.pump(const Duration(milliseconds: 200));
      expect(
          find.bySemanticsIdentifier('premios-ranking-hidden'), findsOneWidget);
      expect(find.byType(PodioPremios), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('envoltorios de siempre', () {
    testWidgets('SurveyInAppPage pinta la Entrada nueva', (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(const SurveyInAppPage(), reduce: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(PremiosEntryPage), findsOneWidget);
      expect(find.text('¿Cuál es tu favorito?'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('MyVotedRestaurants abre la pantalla v3', (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          const MyVotedRestaurants(tradicionales: [], modernos: []),
          reduce: true));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(PremiosMyVotesPage), findsOneWidget);
      // Sin red en el test: estado de error, nunca un spinner infinito.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    test('my-votes: con App Check fallando, sync falla (nunca «ok»)',
        () async {
      final appCheck = FakeAppCheck()
        ..tokenErrors.addAll(List.filled(
            5, const SurveyIntegrityException(SurveyIntegrityError.failed)));
      final p = SurveyVotePresenter(
        repository: FakeSurveyRepo(),
        identity: identity(appCheck: appCheck),
        appVersion: '4.7.0',
        clock: () => DateTime.utc(2027, 2, 10, 12),
        sleep: (_) async {},
        random: Random(1),
      );
      await PremiosVotedStore.instance.refreshFromServer(presenter: p);
      expect(PremiosVotedStore.instance.sync.value, PremiosVotedSync.failed);
      expect(PremiosVotedStore.instance.syncError,
          PremiosErrorKind.deviceUnverified);
      expect(PremiosVotedStore.instance.hasVoted, isFalse);
      p.dispose();
    });

    testWidgets(
        'Mis votos: si my-votes falla, error con «Reintentar» y nunca '
        '«Aún no has votado»', (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          PremiosMyVotesPage(
            controller: FakeRanking(const PremiosRankingState(
                load: PremiosLoad.ready, tradicional: [])),
          ),
          reduce: true));
      // Sin red en el test: la consulta real falla.
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(PremiosVotedStore.instance.sync.value, PremiosVotedSync.failed);
      expect(find.bySemanticsIdentifier('premios-my-votes-sync-error'),
          findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.textContaining('Aún no has votado'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Mis votos: puesto real del ranking (no index + 1)', (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          PremiosMyVotesPage(
            refreshVoted: false,
            controller: FakeRanking(PremiosRankingState(
              load: PremiosLoad.ready,
              tradicional: [
                entry('Alfa', 7, 1),
                entry('Beta', 6, 2, tied: true),
                entry('Gama', 6, 2, tied: true, mine: true),
              ],
            )),
          ),
          reduce: true));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('2.º'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  });
}

class _ResultsRepo extends FakeSurveyRepo {
  final SurveyEditionResults res;
  Object? resultsError;
  final resultsFor = <int>[];
  _ResultsRepo(this.res);

  @override
  Future<SurveyEditionResults> getSurveyEditionResults(int editionId) async {
    resultsFor.add(editionId);
    if (resultsError != null) throw resultsError!;
    return res;
  }
}
