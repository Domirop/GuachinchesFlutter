import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';

void main() {
  group('buscador', () {
    test('sin tildes ni mayúsculas en los dos lados', () {
      expect(premiosNormalize('  Guachinche  Casa JOSÉ '), 'guachinche casa jose');
      expect(premiosNormalize('Señorío Güímar'), 'senorio guimar');
      final list = [
        PremiosCandidate.fromApi('1', 'GUACHINCHE CASA JOSE (El Tejadito)'),
        PremiosCandidate.fromApi('2', 'Bodega Zacatín'),
        PremiosCandidate.fromApi('3', 'GUACHINCHE SALON EL CUBANO (Santa Úrsula)'),
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
      final r = [Restaurant(id: 'a', nombre: 'BODEGA ZACATIN', municipio: 'LA OROTAVA')];
      final ok = SurveyResult.fromJsonWithRestaurants({'option': 'a', 'votes': '7'}, r);
      final missing = SurveyResult.fromJsonWithRestaurants({'option': 'zz', 'votes': '6'}, r);
      expect(missing.restaurant, isNull);
      final ranked = premiosRank([missing, ok]);
      expect(ranked.first.name, 'Bodega Zacatin');
      expect(ranked.first.municipio, 'La Orotava');
      expect(ranked.last.name, kPremiosMissingName);
      expect([for (final e in ranked) e.rank], [1, 2]);
    });

    test('empates marcados y nombre con paréntesis aparte', () {
      SurveyResult res(String id, int v) => SurveyResult(
          restaurantId: id, votes: v, restaurant: Restaurant(id: id, nombre: id));
      final e = premiosRank([res('a', 4), res('b', 4), res('c', 3)]);
      expect(e.map((x) => (x.rank, x.tied)).toList(), [(1, true), (1, true), (3, false)]);
      expect(premiosSplitName('Bodega Zacatín (Guachinche El Churrasco)'),
          ('Bodega Zacatín', '(Guachinche El Churrasco)'));
      expect(premiosSplitName('Casa Pepe'), ('Casa Pepe', ''));
      expect(premiosVotes(1), '1 voto');
      expect(premiosVotes(6), '6 votos');
    });
  });

  group('errores del presenter actual', () {
    test('mensajes literales → errores tipados', () {
      expect(premiosErrorFromLegacyMessage('Por favor, tómate tu tiempo para votar.'),
          PremiosErrorKind.tooFast);
      expect(premiosErrorFromLegacyMessage('Debes seleccionar al menos una opción.'),
          PremiosErrorKind.noSelection);
      expect(premiosErrorFromLegacyMessage('Ya has votado a este negocio anteriormente.'),
          PremiosErrorKind.alreadyVoted);
      expect(premiosErrorFromLegacyMessage('No se pudo enviar tu voto. Inténtalo de nuevo.'),
          PremiosErrorKind.server);
      expect(
          premiosErrorFromLegacyMessage(
              'Error al enviar: Exception: Error al enviar votos: SocketException: Failed host lookup'),
          PremiosErrorKind.network);
    });

    test('el copy nunca enseña la excepción y 403/429 tienen el suyo', () {
      for (final k in PremiosErrorKind.values) {
        final c = premiosErrorCopy(k);
        expect('${c.title} ${c.message}', isNot(contains('Exception')));
      }
      expect(premiosErrorCopy(PremiosErrorKind.deviceUnverified).title,
          'No hemos podido comprobar este móvil');
      expect(premiosErrorCopy(PremiosErrorKind.alreadyVoted, rowFlagged: true).title,
          'Ese ya tenía tu voto');
    });
  });

  group('cuenta atrás y hoja del Inicio', () {
    final ed = PremiosEdition(DateTime(2026, 3, 20, 23, 59));
    test('días; el último día, horas; después, cerrada', () {
      expect(ed.countdown(DateTime(2026, 3, 8, 10)), (12, 'días'));
      expect(ed.remainingLabel(DateTime(2026, 3, 19, 10)), 'Queda 1 día');
      expect(ed.phase(DateTime(2026, 3, 20, 15)), PremiosPhase.lastDay);
      expect(ed.countdown(DateTime(2026, 3, 20, 15)), (9, 'horas'));
      expect(ed.phase(DateTime(2026, 3, 21)), PremiosPhase.closed);
      expect(ed.untilLabel, 'Se vota hasta el 20 de marzo');
    });

    test('la hoja solo si no votó ni la descartó en 7 días', () {
      final now = DateTime(2026, 3, 10);
      expect(premiosShouldShowSheet(phase: PremiosPhase.open, voted: false, dismissedAt: null, now: now), isTrue);
      expect(premiosShouldShowSheet(phase: PremiosPhase.open, voted: true, dismissedAt: null, now: now), isFalse);
      expect(premiosShouldShowSheet(phase: PremiosPhase.closed, voted: false, dismissedAt: null, now: now), isFalse);
      expect(premiosShouldShowSheet(phase: PremiosPhase.open, voted: false, dismissedAt: DateTime(2026, 3, 6), now: now), isFalse);
      expect(premiosShouldShowSheet(phase: PremiosPhase.open, voted: false, dismissedAt: DateTime(2026, 3, 2), now: now), isTrue);
    });
  });
}
