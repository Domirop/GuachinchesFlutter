import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/domain/occasions/canarian_holidays.dart';
import 'package:guachinches/domain/occasions/occasion.dart';
import 'package:guachinches/domain/occasions/occasion_catalog.dart';
import 'package:guachinches/domain/occasions/occasion_context.dart';
import 'package:guachinches/domain/occasions/occasion_engine.dart';

/// Helper: construye un contexto sin depender de aritmética de fechas reales.
OccasionContext ctx({
  required int weekday,
  OccasionDayPart dayPart = OccasionDayPart.midday,
  Holiday? today,
  Holiday? tomorrow,
}) {
  return OccasionContext(
    now: DateTime(2026, 1, 1, 12),
    weekday: weekday,
    dayPart: dayPart,
    todayHoliday: today,
    tomorrowHoliday: tomorrow,
  );
}

Occasion? resolve(OccasionContext c) => activeOccasion(kOccasionCatalog, c);

void main() {
  group('canarian_holidays', () {
    test('Día de Canarias (30-may) se reconoce y es canario', () {
      final h = holidayOn(DateTime(2026, 5, 30));
      expect(h, isNotNull);
      expect(h!.canarian, isTrue);
      expect(h.name.toLowerCase(), contains('canarias'));
    });

    test('un día normal no es festivo', () {
      expect(holidayOn(DateTime(2026, 5, 12)), isNull);
    });

    test('resolve() detecta víspera: 29-may → mañana Día de Canarias', () {
      final c = OccasionContext.resolve(now: DateTime(2026, 5, 29, 18));
      expect(c.tomorrowHoliday?.canarian, isTrue);
      expect(c.todayHoliday, isNull);
    });
  });

  group('activeOccasion — selección por contexto', () {
    test('jueves → finde a la vista', () {
      final o = resolve(ctx(weekday: DateTime.thursday));
      expect(o!.id, 'thursday_weekend');
    });

    test('viernes tarde → reserva brunch del domingo', () {
      final o = resolve(
          ctx(weekday: DateTime.friday, dayPart: OccasionDayPart.evening));
      expect(o!.id, 'friday_brunch');
      expect(o.ctaKind, OccasionCtaKind.reserve);
    });

    test('viernes por la mañana NO dispara el brunch (es de tarde/noche)', () {
      final o = resolve(
          ctx(weekday: DateTime.friday, dayPart: OccasionDayPart.morning));
      expect(o!.id, isNot('friday_brunch'));
    });

    test('domingo mediodía → sobremesa', () {
      final o = resolve(
          ctx(weekday: DateTime.sunday, dayPart: OccasionDayPart.midday));
      expect(o!.id, 'sunday_sobremesa');
    });

    test('sábado mañana → ¿dónde caemos hoy?', () {
      final o = resolve(
          ctx(weekday: DateTime.saturday, dayPart: OccasionDayPart.morning));
      expect(o!.id, 'saturday_plan');
    });

    test('martes cualquier hora → comodín entre semana', () {
      final o = resolve(ctx(weekday: DateTime.tuesday));
      expect(o!.id, 'weekday_lowkey');
    });
  });

  group('activeOccasion — prioridades', () {
    final canarias = holidayOn(DateTime(2026, 5, 30));

    test('víspera de festivo gana al brunch del viernes', () {
      // Viernes tarde + mañana festivo → debe ganar la víspera.
      final o = resolve(ctx(
        weekday: DateTime.friday,
        dayPart: OccasionDayPart.evening,
        tomorrow: canarias,
      ));
      expect(o!.id, 'eve_holiday');
      expect(o.priority, 100);
    });

    test('hoy festivo (Día de Canarias) → copy canario', () {
      final o = resolve(ctx(
        weekday: DateTime.saturday,
        dayPart: OccasionDayPart.midday,
        today: canarias,
      ));
      expect(o!.id, 'today_holiday');
      expect(o.eyebrow.toUpperCase(), contains('CANARIAS'));
    });
  });

  group('motor — pureza y robustez', () {
    test('determinista: mismo contexto → misma ocasión', () {
      final c = ctx(weekday: DateTime.friday, dayPart: OccasionDayPart.evening);
      expect(resolve(c)!.id, resolve(c)!.id);
    });

    test('siempre devuelve una ocasión (comodín de prioridad mínima)', () {
      for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
        for (final p in OccasionDayPart.values) {
          expect(resolve(ctx(weekday: wd, dayPart: p)), isNotNull,
              reason: 'weekday=$wd dayPart=$p');
        }
      }
    });
  });
}
