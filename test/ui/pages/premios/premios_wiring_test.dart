import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/ui/pages/myVotedRestaurants/myVotedRestaurants.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_home.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_my_votes_page.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRanking.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_page.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';

import '../../../survey_v3/survey_fakes.dart';
import 'premios_fakes.dart';

class _Rc implements RemoteConfigBridge {
  final Map<String, Object> values;
  _Rc(this.values);
  @override
  Future<void> configure(
      {required Duration fetchTimeout,
      required Duration minimumFetchInterval}) async {}
  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}
  @override
  Future<bool> fetchAndActivate() async => true;
  @override
  bool getBool(String key) => values[key] as bool? ?? false;
  @override
  int getInt(String key) => values[key] as int? ?? 0;
  @override
  String getString(String key) => values[key] as String? ?? '';
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PremiosEditionStore.instance.reset();
    PremiosHomeStore.sheetShownThisSession = false;
    PremiosVotedStore.instance.reset();
  });
  tearDown(() {
    DccRemoteConfig.testOverride = null;
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

    test('sin API ni Remote Config: no sale «cerrada»', () async {
      DccRemoteConfig.testOverride = DccRemoteConfig.test(_Rc({}));
      final repo = FakeSurveyRepo()
        ..editionSteps.add(() => throw const SurveyNetworkException());
      await PremiosEditionStore.instance.refresh(repo);
      final e = PremiosEditionStore.instance.current;
      expect(e.known, isFalse);
      expect(e.phase(DateTime.utc(2099)), isNot(PremiosPhase.closed));
    });

    test('sin API: respaldo de Remote Config (ISO UTC)', () async {
      DccRemoteConfig.testOverride = DccRemoteConfig.test(
          _Rc({'premios_closes_at': '2027-03-20T23:59:00Z'}));
      final repo = FakeSurveyRepo()
        ..editionSteps.add(() => throw const SurveyNetworkException());
      await PremiosEditionStore.instance.refresh(repo);
      final e = PremiosEditionStore.instance.current;
      expect(e.votingEndsAt, DateTime.utc(2027, 3, 20, 23, 59));
      expect(e.phase(DateTime.utc(2027, 3, 21)), PremiosPhase.closed);
    });

    test('fecha mal escrita → sin fecha', () {
      DccRemoteConfig.testOverride =
          DccRemoteConfig.test(_Rc({'premios_closes_at': 'mañana'}));
      expect(DccRemoteConfig.instance.premiosClosesAt, isNull);
    });
  });

  group('Inicio', () {
    testWidgets('PremiosHomeSlot apagado no pinta nada', (t) async {
      await t.pumpWidget(
          app(const Scaffold(body: PremiosHomeSlot(enabled: false))));
      await t.pump();
      expect(find.byType(PremiosLiveSection), findsNothing);
      expect(t.getSize(find.byType(PremiosHomeSlot)), Size.zero);
    });

    testWidgets('encendido pero sin fecha de cierre: tampoco', (t) async {
      PremiosEditionStore.instance.loadFromRemoteConfig(null);
      await t.pumpWidget(app(Scaffold(
          body: PremiosHomeSlot(
              enabled: true,
              ranking: FakeRanking(const PremiosRankingState())))));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(PremiosLiveSection), findsNothing);
      expect(find.text('Ganadores 2026'), findsNothing);
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
                      enabled: true,
                      ranking: FakeRanking(r),
                      clock: () => now ?? DateTime.utc(2026, 3, 8)))),
          reduce: true));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('abierta y sin votar: módulo en directo con podio 2·1·2',
        (t) async {
      addTearDown(t.view.reset);
      PremiosEditionStore.instance
          .loadFromRemoteConfig(DateTime.utc(2026, 3, 20, 23, 59));
      await pumpSlot(t, rk());
      expect(find.text('Así va la votación'), findsOneWidget);
      expect(find.byType(PodioPremios), findsOneWidget);
      expect(find.text('¿Cuál es tu guachinche favorito?'), findsOneWidget);
      expect(find.text('Quedan 12 días'), findsOneWidget);
      expect(find.text('Votar'), findsOneWidget);
      expect(find.text('6 votos · empate'), findsNWidgets(2));
      expect(find.bySemanticsIdentifier('home-premios-mine'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('ya votó (my-votes en caché): «Tu voto · Va 4.º»', (t) async {
      addTearDown(t.view.reset);
      PremiosEditionStore.instance
          .loadFromRemoteConfig(DateTime.utc(2026, 3, 20, 23, 59));
      PremiosVotedStore.instance.update({
        PremiosCategory.tradicional.apiName: {'Guachinche Casa Pepe'}
      });
      await pumpSlot(t, rk(mine: true));
      expect(find.text('Ya has votado'), findsOneWidget);
      expect(find.text('Votar a otros sitios'), findsOneWidget);
      expect(find.text('Va 4.º con 5 votos'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('cerrada: «Ganadores 2026» 15 días y luego nada', (t) async {
      addTearDown(t.view.reset);
      PremiosEditionStore.instance
          .loadFromRemoteConfig(DateTime.utc(2026, 3, 20, 23, 59));
      await pumpSlot(t, rk(), now: DateTime.utc(2026, 3, 25));
      expect(find.text('Ganadores 2026'), findsOneWidget);
      expect(find.text('Ver el ranking completo'), findsOneWidget);
      await pumpSlot(t, rk(), now: DateTime.utc(2026, 4, 10));
      expect(find.byType(PremiosLiveSection), findsNothing);
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
      PremiosEditionStore.instance
          .loadFromRemoteConfig(DateTime.utc(2026, 3, 20, 23, 59));
      await t.pumpWidget(app(
          Scaffold(
              body: SingleChildScrollView(
                  child: PremiosHomeSlot(
                      enabled: true,
                      ranking: FakeRanking(r),
                      clock: () => DateTime.utc(2026, 3, 8)))),
          reduce: true));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('oculto: anuncio, «se desvela al cierre» y Votar', (t) async {
      addTearDown(t.view.reset);
      await pump(
          t, const PremiosRankingState(load: PremiosLoad.ready, hidden: true));
      expect(find.text('Votación en marcha'), findsOneWidget);
      expect(find.text('El ranking se desvela al cierre'), findsOneWidget);
      expect(find.byType(PodioPremios), findsNothing);
      expect(find.text('Votar'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('sin resultados (404/red): sin podio ni fallo, con Votar',
        (t) async {
      addTearDown(t.view.reset);
      await pump(t, const PremiosRankingState(load: PremiosLoad.error));
      expect(find.byType(PodioPremios), findsNothing);
      expect(find.textContaining('No pudimos'), findsNothing);
      expect(find.text('Votar'), findsOneWidget);
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

    testWidgets('SurveyRanking y MyVotedRestaurants abren las pantallas v3',
        (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          SurveyRanking(
            guachinchesTradicionales: const [],
            guachinchesModernos: const [],
            isInitialTraditional: true,
            allRestaurants: const [],
            onRefresh: () {},
          ),
          reduce: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(PremiosRankingPage), findsOneWidget);
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
