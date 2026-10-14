import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';

void main() {
  group('buscador', () {
    test('sin tildes ni mayúsculas en los dos lados', () {
      expect(
          premiosNormalize('  Guachinche  Casa JOSÉ '), 'guachinche casa jose');
      expect(premiosNormalize('Señorío Güímar'), 'senorio guimar');
      // Diacríticos combinados (texto en NFD).
      expect(premiosNormalize('Jose\u0301 Gu\u0308i\u0301mar'), 'jose guimar');
      final list = [
        PremiosCandidate.fromApi('1', 'GUACHINCHE CASA JOSE (El Tejadito)'),
        PremiosCandidate.fromApi('2', 'Bodega Zacatín'),
        PremiosCandidate.fromApi(
            '3', 'GUACHINCHE SALON EL CUBANO (Santa Úrsula)'),
      ];
      expect(premiosFilter(list, 'josé').map((c) => c.value), ['1']);
      expect(premiosFilter(list, 'zacatin').map((c) => c.value), ['2']);
      expect(premiosFilter(list, 'URSULA').map((c) => c.value), ['3']);
      expect(premiosFilter(list, 'tasca del puerto'), isEmpty);
      expect(premiosFilter(list, '   '), hasLength(3));
    });

    test('los nombres en mayúsculas se pintan en tipo título', () {
      String n(String s) => PremiosCandidate.fromApi('x', s).name;
      expect(n('GUACHINCHE LA BREVERA'), 'Guachinche La Brevera');
      expect(n('GUACHINCHE LA CUADRA (Los Realejos)'),
          'Guachinche La Cuadra (Los Realejos)');
      expect(n('BODEGON DE LA ERA'), 'Bodegon de la Era');
      expect(n('GUACHINCHE "El Borgoñón" de Sandra'),
          'Guachinche «El Borgoñón» de Sandra');
      expect(n('Guachinche Casa Francis'), 'Guachinche Casa Francis');
      expect(n('BAR BBQ'), 'Bar BBQ');
    });
  });

  group('ranking', () {
    test('puestos compartidos: 7·6·6·5 → 1,2,2,4 y 4·4·3 → 1,1,3', () {
      expect(premiosCompetitionRanks([7, 6, 6, 5]), [1, 2, 2, 4]);
      expect(premiosCompetitionRanks([4, 4, 3]), [1, 1, 3]);
      expect(premiosCompetitionRanks([]), isEmpty);
    });

    test('una opción sin restaurante ya no tumba la pantalla', () {
      final r = [
        Restaurant(id: 'a', nombre: 'BODEGA ZACATIN', municipio: 'LA OROTAVA')
      ];
      final ok = SurveyResult.fromJsonWithRestaurants(
          {'option': 'a', 'votes': '7'}, r);
      final missing = SurveyResult.fromJsonWithRestaurants(
          {'option': 'zz', 'votes': '6'}, r);
      expect(missing.restaurant, isNull);
      final ranked = premiosRank([missing, ok]);
      expect(ranked.first.name, 'Bodega Zacatin');
      expect(ranked.first.municipio, 'La Orotava');
      expect(ranked.last.name, kPremiosMissingName);
      expect([for (final e in ranked) e.rank], [1, 2]);
    });

    test('empates marcados y nombre con paréntesis aparte', () {
      SurveyResult res(String id, int v) => SurveyResult(
          restaurantId: id,
          votes: v,
          restaurant: Restaurant(id: id, nombre: id));
      final e = premiosRank([res('a', 4), res('b', 4), res('c', 3)]);
      expect(e.map((x) => (x.rank, x.tied)).toList(),
          [(1, true), (1, true), (3, false)]);
      // Empate: por nombre.
      final t = premiosRank([res('Zeta', 4), res('Alfa', 4), res('Beta', 5)]);
      expect(t.map((x) => x.name).toList(), ['Beta', 'Alfa', 'Zeta']);
      expect(premiosSplitName('Bodega Zacatín (Guachinche El Churrasco)'),
          ('Bodega Zacatín', '(Guachinche El Churrasco)'));
      expect(premiosSplitName('Casa Pepe'), ('Casa Pepe', ''));
      expect(premiosVotes(1), '1 voto');
      expect(premiosVotes(6), '6 votos');
    });
  });

  group('errores del presenter actual', () {
    test('fallos del presenter v3 → avisos y bloqueos', () {
      expect(premiosErrorKindOf(const SurveyAlreadyVoted([])),
          PremiosErrorKind.alreadyVoted);
      expect(
          premiosErrorKindOf(const SurveyIntegrityFailed('integrity_failed')),
          PremiosErrorKind.deviceUnverified);
      expect(premiosErrorKindOf(const SurveyVerificationUnavailable()),
          PremiosErrorKind.verificationUnavailable);
      expect(premiosErrorKindOf(const SurveyInvalidOption()),
          PremiosErrorKind.invalidOption);
      expect(premiosErrorKindOf(const SurveyInsecureConnection()),
          PremiosErrorKind.insecureConnection);
      expect(premiosErrorKindOf(const SurveyVotingUnavailable()),
          PremiosErrorKind.votingUnavailable);
      expect(
          premiosErrorCopy(PremiosErrorKind.votingUnavailable).retry, isFalse);
      expect(premiosErrorCopy(PremiosErrorKind.insecureConnection).title,
          'No podemos conectar de forma segura');
      expect(premiosErrorKindOf(const SurveyDeviceBlocked()), isNull);
      expect(
          premiosGateOf(SurveyVoteStage.unsupported), PremiosGate.unsupported);
      expect(premiosGateOf(SurveyVoteStage.upcoming), PremiosGate.upcoming);
      expect(premiosGateOf(SurveyVoteStage.ready), isNull);
    });

    test('el copy nunca enseña la excepción y 403/429 tienen el suyo', () {
      for (final k in PremiosErrorKind.values) {
        final c = premiosErrorCopy(k);
        expect('${c.title} ${c.message}', isNot(contains('Exception')));
      }
      expect(premiosErrorCopy(PremiosErrorKind.deviceUnverified).title,
          'No hemos podido comprobar este\u00A0móvil');
      expect(
          premiosErrorCopy(PremiosErrorKind.alreadyVoted, rowFlagged: true)
              .title,
          'Ese ya tenía tu voto');
    });
  });

  group('cuenta atrás y hoja del Inicio', () {
    final ed = PremiosEdition(votingEndsAt: DateTime.utc(2026, 3, 20, 23, 59));
    test('días; el último día, horas; después, cerrada (todo en UTC)', () {
      expect(ed.countdown(DateTime.utc(2026, 3, 8, 10)), (12, 'días'));
      expect(ed.remainingLabel(DateTime.utc(2026, 3, 19, 10)), 'Queda 1 día');
      expect(ed.phase(DateTime.utc(2026, 3, 20, 15)), PremiosPhase.lastDay);
      expect(ed.countdown(DateTime.utc(2026, 3, 20, 15)), (9, 'horas'));
      expect(ed.phase(DateTime.utc(2026, 3, 21)), PremiosPhase.closed);
      expect(ed.untilLabel, 'Se vota hasta el 20 de marzo');
    });

    test('el cambio de hora no resta un día (fechas UTC)', () {
      // 29 de marzo de 2026: en Canarias se adelanta la hora.
      final e = PremiosEdition(votingEndsAt: DateTime.utc(2026, 4, 1, 22, 59));
      expect(e.daysLeft(DateTime.utc(2026, 3, 28, 23, 30)), 4);
      expect(e.daysLeft(DateTime.utc(2026, 3, 29, 0, 30)), 3);
    });

    test('sin fecha: estado neutro, nunca «cerrada»', () {
      final none = PremiosEdition.none;
      expect(none.phase(DateTime.utc(2030)), PremiosPhase.unknown);
      expect(none.phase(DateTime.utc(2030)).canVote, isTrue);
      expect(none.untilLabel, isEmpty);
    });

    test('la edición del contrato v3 (editions/current)', () {
      final e = PremiosEdition.fromApi({
        'votingStartsAt': '2027-02-01T00:00:00Z',
        'votingEndsAt': '2027-03-20T23:59:00Z',
      });
      expect(e.phase(DateTime.utc(2027, 1, 15)), PremiosPhase.upcoming);
      expect(e.phase(DateTime.utc(2027, 1, 15)).canVote, isFalse);
      expect(e.phase(DateTime.utc(2027, 3, 1)), PremiosPhase.open);
      expect(e.votingEndsAt!.isUtc, isTrue);
    });

    test('la hoja solo si se vota, no votó ni la descartó en 7 días', () {
      final now = DateTime.utc(2026, 3, 10);
      bool show(PremiosPhase p, bool v, DateTime? d) =>
          premiosShouldShowSheet(phase: p, voted: v, dismissedAt: d, now: now);
      expect(show(PremiosPhase.open, false, null), isTrue);
      expect(show(PremiosPhase.open, true, null), isFalse);
      expect(show(PremiosPhase.closed, false, null), isFalse);
      expect(show(PremiosPhase.unknown, false, null), isFalse);
      expect(show(PremiosPhase.open, false, DateTime.utc(2026, 3, 6)), isFalse);
      expect(show(PremiosPhase.open, false, DateTime.utc(2026, 3, 2)), isTrue);
    });
  });
}
