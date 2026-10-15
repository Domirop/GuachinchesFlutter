import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_logic.dart';

void main() {
  final today = DateTime(2026, 10, 14); // miércoles

  group('fechas', () {
    test('fecha larga en minúscula: «miércoles 14 de octubre»', () {
      expect(canarismoLongDate(today), 'miércoles 14 de octubre');
      expect(canarismoLongDate(DateTime(2026, 10, 12)), 'lunes 12 de octubre');
      expect(canarismoLongDate(DateTime(2026, 6, 14)), 'domingo 14 de junio');
    });

    test('fecha completa: «14 de octubre de 2026»', () {
      expect(canarismoFullDate(today), '14 de octubre de 2026');
      expect(canarismoFullDate(DateTime(2027, 1, 1)), '1 de enero de 2027');
    });

    test('relativa: Hoy / Ayer / Hace N días', () {
      expect(canarismoRelativeLabel(today, today), 'Hoy');
      expect(canarismoRelativeLabel(DateTime(2026, 10, 13), today), 'Ayer');
      expect(
          canarismoRelativeLabel(DateTime(2026, 10, 9), today), 'Hace 5 días');
      // La hora del día no cuenta.
      expect(
          canarismoRelativeLabel(
              DateTime(2026, 10, 13, 23, 59), DateTime(2026, 10, 14, 0, 1)),
          'Ayer');
    });

    test('cruzando el cambio de hora (25 oct 2026) sigue contando días', () {
      expect(
          canarismoRelativeLabel(
              DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
          'Hace 2 días');
    });

    test('mismo día ignora la hora', () {
      expect(canarismoIsSameDay(DateTime(2026, 10, 14, 23), today), isTrue);
      expect(canarismoIsSameDay(DateTime(2026, 10, 13, 23), today), isFalse);
    });
  });

  group('antetítulos', () {
    test('hoy dice «del día»; un día pasado no', () {
      expect(canarismoDetailEyebrow(today, isToday: true),
          'El canarismo del día · miércoles 14 de octubre');
      final past =
          canarismoDetailEyebrow(DateTime(2026, 10, 12), isToday: false);
      expect(past, 'Canarismo · lunes 12 de octubre');
      expect(past, isNot(contains('del día')));
    });

    test('tarjeta y bloque de compartir', () {
      expect(canarismoCardEyebrow(isToday: true), 'El canarismo del día');
      expect(canarismoCardEyebrow(isToday: false), 'Un canarismo');
      expect(canarismoShareTitle(isToday: true), 'Comparte el canarismo');
      expect(canarismoShareTitle(isToday: false), isNot(contains('del día')));
    });

    test('antetítulo de anteriores según cantidad y día', () {
      expect(
          canarismoHistoryEyebrow(5, isToday: true), 'Los últimos cinco días');
      expect(
          canarismoHistoryEyebrow(3, isToday: true), 'Los últimos tres días');
      expect(canarismoHistoryEyebrow(5, isToday: false),
          'Los cinco días anteriores');
      expect(canarismoHistoryEyebrow(1, isToday: true), 'El día de ayer');
      expect(canarismoHistoryEyebrow(1, isToday: false), 'El día anterior');
    });
  });

  group('canarismos anteriores', () {
    test('hoy: los 5 días previos con etiquetas relativas', () {
      final h = canarismoHistory(today, today);
      expect(h.map((e) => e.label).toList(), [
        'Ayer',
        'Hace 2 días',
        'Hace 3 días',
        'Hace 4 días',
        'Hace 5 días',
      ]);
      expect(h.first.date, DateTime(2026, 10, 13));
      expect(h.first.canarismo.palabra,
          canarismoOfDay(DateTime(2026, 10, 13)).palabra);
      expect(h.last.date, DateTime(2026, 10, 9));
    });

    test('día pasado: días previos a ESA fecha, etiquetas respecto a hoy', () {
      final h = canarismoHistory(DateTime(2026, 10, 12), today);
      expect(h.first.date, DateTime(2026, 10, 11));
      expect(h.first.label, 'Hace 3 días');
      expect(h.last.label, 'Hace 7 días');
    });

    test('solo los que ya han salido (nunca antes del lanzamiento)', () {
      final launch = kCanarismoLaunchDate;
      expect(canarismoHistory(launch, launch), isEmpty);
      final d2 = DateTime(launch.year, launch.month, launch.day + 2);
      final h = canarismoHistory(d2, d2);
      expect(h, hasLength(2));
      expect(h.last.date, DateTime(launch.year, launch.month, launch.day));
    });
  });

  test('texto para compartir lleva palabra, significado y marca', () {
    const c = Canarismo('Guagua', 'Autobús.');
    final t = canarismoShareText(c);
    expect(t, contains('Guagua'));
    expect(t, contains('Autobús.'));
    expect(t, contains('Dónde Comer Canarias'));
  });
}
