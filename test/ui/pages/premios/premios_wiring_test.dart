import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/myVotedRestaurants/myVotedRestaurants.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_home_card.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_my_votes_page.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRanking.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_page.dart';

import 'premios_fakes.dart';

/// Repositorio falso: solo lo que usan los presenters de la encuesta.
class _Repo extends Fake implements RemoteRepository {
  Map<String, List<String>> voted = const {};

  @override
  Future<Map<String, List<String>>> getVotedByDevice(
          int surveySchemaId, String deviceToken) async =>
      voted;

  @override
  Future<List<SurveyInAppChoice>> getSurveyInAppChoices(
          String categoryName, String userId) async =>
      const [];

  @override
  Future<List<Restaurant>> getAllSurveyRestaurants(String surveyId) async =>
      const [];

  @override
  Future<List<SurveyResult>> getSurveyResults(
          int surveyId, String surveyName, List<Restaurant> all) async =>
      const [];

  @override
  Future<List<String>> getVotedRestaurantsByUser(
          String surveySchemaId, String userId) async =>
      const [];
}

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

SurveyResult _res(String id, int v, {bool mine = false}) => SurveyResult(
    restaurantId: id,
    votes: v,
    restaurant: Restaurant(id: id, nombre: id, municipio: 'La Orotava'))
  ..isVotedByUser = mine;

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PremiosEditionStore.instance.reset();
    PremiosHomeStore.sheetShownThisSession = false;
  });
  tearDown(() {
    DccRemoteConfig.testOverride = null;
    PremiosEditionStore.instance.reset();
  });

  group('adaptador sobre el presenter actual', () {
    LegacyPremiosFlowController make(_Repo repo, {VoidCallback? onVoted}) =>
        LegacyPremiosFlowController(repository: repo, onVoted: onVoted);

    test('opciones → candidatos en tipo título; fin de carga → listo', () {
      final c = make(_Repo());
      expect(c.state.load, PremiosLoad.loading);
      c.setChoices(
        tradicionales: [
          SurveyInAppChoice(value: 't1', text: 'GUACHINCHE LALA')
        ],
        modernos: [SurveyInAppChoice(value: 'm1', text: 'Tasca Las Dehesas')],
      );
      c.setLoading(false);
      expect(c.state.load, PremiosLoad.ready);
      expect(c.state.candidatesOf(PremiosCategory.tradicional).single.name,
          'Guachinche Lala');
    });

    test('la carga que falla deja un solo estado de error y ningún aviso', () {
      final c = make(_Repo());
      var notes = 0;
      c.addListener(() => notes++);
      // initialize() del presenter: setLoading(false) y luego showError.
      c.setLoading(false);
      c.showError('Error al inicializar la encuesta: x');
      expect(c.state.load, PremiosLoad.error);
      expect(c.state.error, isNull);
      expect(notes, 1);
    });

    test('elegir dos veces quita el voto; sin votos el envío avisa', () async {
      final c = make(_Repo());
      const x = PremiosCandidate(value: 't1', name: 'Lala');
      c.pick(PremiosCategory.tradicional, x);
      expect(c.state.picks[PremiosCategory.tradicional], x);
      c.pick(PremiosCategory.tradicional, x);
      expect(c.state.picks, isEmpty);
      await c.submit();
      expect(c.state.error?.kind, PremiosErrorKind.noSelection);
    });

    test('409: errores tipados y fila marcada tras repetir by-device',
        () async {
      final repo = _Repo()
        ..voted = {
          'Mejor-Guachinche-Tradicional': ['t1']
        };
      final c = make(repo);
      c.setChoices(tradicionales: const [], modernos: const []);
      c.setLoading(false);
      c.pick(PremiosCategory.tradicional,
          const PremiosCandidate(value: 't1', name: 'Lala'));
      c.pick(PremiosCategory.moderno,
          const PremiosCandidate(value: 'm1', name: 'Dehesas'));
      c.showError('Ya has votado a este negocio anteriormente.');
      expect(c.state.error?.kind, PremiosErrorKind.alreadyVoted);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.flagged, {'t1'});
      expect(c.state.error?.category, PremiosCategory.tradicional);

      c.showError('No se pudo enviar tu voto. Inténtalo de nuevo.');
      expect(c.state.error?.kind, PremiosErrorKind.server);
      c.setSubmitting(true);
      expect(c.state.submitting, isTrue);
    });

    test('envío correcto: guarda lo enviado y avisa', () async {
      var voted = 0;
      final c = make(_Repo(), onVoted: () => voted++);
      c.setChoices(tradicionales: const [], modernos: const []);
      c.pick(PremiosCategory.moderno,
          const PremiosCandidate(value: 'm1', name: 'Dehesas'));
      c.onSubmitSuccess();
      expect(c.state.sent?[PremiosCategory.moderno]?.value, 'm1');
      expect(voted, 1);
      expect(await PremiosHomeStore.hasVoted(), isTrue);
    });
  });

  group('fecha de cierre desde Remote Config', () {
    test('sin fecha no sale «cerrada»', () {
      DccRemoteConfig.testOverride = DccRemoteConfig.test(_Rc({}));
      PremiosEditionStore.instance.ensureLoaded();
      final e = PremiosEditionStore.instance.current;
      expect(e.known, isFalse);
      expect(e.phase(DateTime.utc(2099)), isNot(PremiosPhase.closed));
    });

    test('con fecha ISO UTC: cuenta atrás y cierre', () {
      DccRemoteConfig.testOverride = DccRemoteConfig.test(
          _Rc({'premios_closes_at': '2027-03-20T23:59:00Z'}));
      PremiosEditionStore.instance.ensureLoaded();
      final e = PremiosEditionStore.instance.current;
      expect(e.votingEndsAt, DateTime.utc(2027, 3, 20, 23, 59));
      expect(e.phase(DateTime.utc(2027, 3, 8)), PremiosPhase.open);
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
      expect(find.byType(PremiosHomeCard), findsNothing);
      expect(t.getSize(find.byType(PremiosHomeSlot)), Size.zero);
    });

    testWidgets('encendido pero sin fecha de cierre: tampoco', (t) async {
      await t.pumpWidget(
          app(const Scaffold(body: PremiosHomeSlot(enabled: true))));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(PremiosHomeCard), findsNothing);
      expect(find.text('Ya tenemos ganadores'), findsNothing);
    });

    testWidgets('con votación abierta pinta la tarjeta «sin votar»', (t) async {
      PremiosHomeStore.sheetShownThisSession = true; // sin hoja
      PremiosEditionStore.instance
          .loadFromRemoteConfig(DateTime.utc(2026, 3, 20, 23, 59));
      await t.pumpWidget(app(Scaffold(
          body: PremiosHomeSlot(
              enabled: true, clock: () => DateTime.utc(2026, 3, 8)))));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('¿Cuál es tu guachinche favorito?'), findsOneWidget);
      expect(find.text('Quedan 12 días'), findsOneWidget);
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

    testWidgets('SurveyRanking pinta el ranking con los resultados que trae',
        (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          SurveyRanking(
            guachinchesTradicionales: [_res('Alfa', 3), _res('Beta', 2)],
            guachinchesModernos: [_res('Gama', 1)],
            isInitialTraditional: true,
            allRestaurants: const [],
            onRefresh: () {},
          ),
          reduce: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(PremiosRankingPage), findsOneWidget);
      expect(find.byType(PodioPremios), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('MyVotedRestaurants: puesto real y sin carga infinita',
        (t) async {
      phone(t);
      addTearDown(t.view.reset);
      await t.pumpWidget(app(
          MyVotedRestaurants(
            tradicionales: [
              _res('Alfa', 7),
              _res('Beta', 6),
              _res('Gama', 6, mine: true),
            ],
            modernos: const [],
          ),
          reduce: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(PremiosMyVotesPage), findsOneWidget);
      // Gama empata en el 2.º (no «1» por ser la primera de la lista).
      expect(find.text('2.º'), findsOneWidget);

      // Sin datos: se cargan (vacío) y sale el estado vacío, no un spinner.
      await t.pumpWidget(app(
          const MyVotedRestaurants(tradicionales: [], modernos: []),
          reduce: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  });
}
