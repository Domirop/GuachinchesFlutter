/// Señales de contexto para el "Planificador por ocasión".
///
/// Capa de DOMINIO pura (sin Flutter), testeable en aislamiento. A diferencia
/// del motor de antojos (que mira el AHORA: hora + clima), aquí la señal clave
/// es la **anticipación**: qué día de la semana es y si hay un festivo HOY o
/// MAÑANA. Eso es lo que dispara "el finde a la vista" o "mañana es festivo".
library;

import 'package:guachinches/domain/occasions/canarian_holidays.dart';

/// Franja del día. Más gruesa que la de antojos: aquí solo necesitamos saber si
/// es momento de "planificar el día" (mañana) o "rematar la noche".
enum OccasionDayPart { morning, midday, afternoon, evening, night, lateNight }

/// Contexto resuelto que consume el motor. Inmutable y comparable por sus
/// señales DISCRETAS (no por `now`), para que la card solo se recalcule cuando
/// el plan podría cambiar — no en cada minuto ni en cada rebuild por scroll.
class OccasionContext {
  /// Instante de referencia (se conserva por si una regla quiere el detalle).
  final DateTime now;

  /// `DateTime.weekday`: Lun=1 … Dom=7.
  final int weekday;
  final OccasionDayPart dayPart;

  /// Festivo que cae HOY (o `null`).
  final Holiday? todayHoliday;

  /// Festivo que cae MAÑANA (o `null`) → dispara la "víspera".
  final Holiday? tomorrowHoliday;

  const OccasionContext({
    required this.now,
    required this.weekday,
    required this.dayPart,
    required this.todayHoliday,
    required this.tomorrowHoliday,
  });

  /// Construye el contexto desde el reloj y un calendario de festivos.
  factory OccasionContext.resolve({
    required DateTime now,
    List<Holiday> calendar = kCanarianHolidays,
  }) {
    final tomorrow = now.add(const Duration(days: 1));
    return OccasionContext(
      now: now,
      weekday: now.weekday,
      dayPart: occasionDayPartFromHour(now.hour),
      todayHoliday: holidayOn(now, calendar: calendar),
      tomorrowHoliday: holidayOn(tomorrow, calendar: calendar),
    );
  }

  // Igualdad por señales discretas: dos instantes distintos del mismo
  // "momento de plan" son equivalentes → no recomputa el ranking.
  @override
  bool operator ==(Object other) =>
      other is OccasionContext &&
      other.weekday == weekday &&
      other.dayPart == dayPart &&
      other.todayHoliday?.name == todayHoliday?.name &&
      other.tomorrowHoliday?.name == tomorrowHoliday?.name;

  @override
  int get hashCode => Object.hash(
        weekday,
        dayPart,
        todayHoliday?.name,
        tomorrowHoliday?.name,
      );
}

/// Hora local → franja de ocasión. Madrugada = 0-6.
OccasionDayPart occasionDayPartFromHour(int h) {
  if (h >= 7 && h <= 11) return OccasionDayPart.morning;
  if (h >= 12 && h <= 13) return OccasionDayPart.midday;
  if (h >= 14 && h <= 16) return OccasionDayPart.afternoon;
  if (h >= 17 && h <= 20) return OccasionDayPart.evening;
  if (h >= 21 && h <= 23) return OccasionDayPart.night;
  return OccasionDayPart.lateNight;
}
