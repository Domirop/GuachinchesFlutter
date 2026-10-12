import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/utils/horarios_utils.dart';
import 'package:guachinches/utils/open_state.dart';

/// Periodos de Google: día 0 = domingo … 6 = sábado.
Map<String, dynamic> _h(List<(int, String, int?, String?)> ps) => {
      'periods': [
        for (final p in ps)
          {
            'open': {'day': p.$1, 'time': p.$2},
            if (p.$3 != null) 'close': {'day': p.$3, 'time': p.$4},
          }
      ]
    };

// 2026-10-10 es sábado (Google 6); 2026-10-11 domingo (0); 2026-10-12 lunes.
DateTime _sat(int h, int m) => DateTime(2026, 10, 10, h, m);

void main() {
  group('computeOpenState', () {
    final cafe = _h([
      for (var d = 1; d <= 6; d++) (d, '0700', d, '1300'),
    ]);

    test('abierto con más de una hora: «hasta» la hora de cierre', () {
      final s = computeOpenState(cafe, _sat(9, 15));
      expect(s.kind, OpenKind.open);
      expect(s.isOpen, isTrue);
      expect(s.closesAtMinute, 13 * 60);
      expect(s.minutesToClose, 225);
    });

    test('a 20 min del cierre: «Cierra en», y sigue contando como abierto', () {
      final s = computeOpenState(cafe, _sat(12, 40));
      expect(s.kind, OpenKind.closingSoon);
      expect(s.isOpen, isTrue);
      expect(s.minutesToClose, 20);
      expect(getOpenStatus(cafe, _sat(12, 40)), 'Cierra en 20 min');
    });

    test('cerrado: dice cuándo abre (hoy, mañana o el día)', () {
      final today = computeOpenState(cafe, _sat(6, 30));
      expect(today.kind, OpenKind.closed);
      expect(today.opensInDays, 0);
      expect(today.opensLaterToday, isTrue);
      // Sábado por la tarde → el lunes (el domingo no abre).
      final monday = computeOpenState(cafe, _sat(15, 0));
      expect(monday.opensInDays, 2);
      expect(monday.opensGoogleDay, 1);
      expect(monday.opensAtMinute, 7 * 60);
    });

    test('periodos que cruzan la medianoche (viernes 20:00 → sábado 2:00)', () {
      final bar = _h([(5, '2000', 6, '0200')]);
      // Sábado 1:30: el periodo empezó el viernes.
      final s = computeOpenState(bar, _sat(1, 30));
      expect(s.kind, OpenKind.closingSoon);
      expect(s.minutesToClose, 30);
      expect(getOpenStatus(bar, _sat(1, 30)), 'Cierra en 30 min');
      // Sábado 0:10: abierto (antes, «Cerrado»).
      expect(computeOpenState(bar, _sat(0, 10)).kind, OpenKind.open);
    });

    test('sábado → domingo de madrugada (vuelta de semana)', () {
      final bar = _h([(6, '2200', 0, '0300')]);
      final sunday = DateTime(2026, 10, 11, 1, 0);
      expect(computeOpenState(bar, sunday).isOpen, isTrue);
    });

    test('sin horario: «sin confirmar» (nunca cerrado); 24 h sin cierre', () {
      expect(computeOpenState(null, _sat(9, 0)).kind, OpenKind.unknown);
      expect(computeOpenState(const {'periods': []}, _sat(9, 0)).kind,
          OpenKind.unknown);
      expect(computeOpenState(_h([(0, '0000', null, null)]), _sat(3, 0)).kind,
          OpenKind.open);
    });

    test('restaurantOpenState: usa r.open solo si no hay horarios_json', () {
      final noHours = Restaurant(id: 'a', open: true);
      expect(restaurantOpenState(noHours, _sat(9, 0)).isOpen, isTrue);
      final closedText = Restaurant(id: 'b', open: false);
      expect(restaurantOpenState(closedText, _sat(9, 0)).kind,
          OpenKind.unknown);
      final withHours = Restaurant(id: 'c', open: true)..horariosJson = cafe;
      expect(restaurantOpenState(withHours, _sat(15, 0)).kind,
          OpenKind.closed);
    });
  });
}
