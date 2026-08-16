/// Calendario de festivos de Canarias — capa de DOMINIO pura (sin Flutter).
///
/// Solo festivos de **fecha fija** (mismo día cada año). Los movibles
/// (Viernes Santo, Jueves/Martes de Carnaval) dependen de la Pascua y de cada
/// municipio; quedan FUERA de v1 a propósito — se pueden añadir luego
/// inyectando un calendario alternativo en [OccasionContext.resolve], sin tocar
/// el motor. El que de verdad importa aquí es el **Día de Canarias** (30-may),
/// marcado con [canarian] = true para poder darle copy propio.
library;

/// Un festivo de calendario (fecha fija mes/día).
class Holiday {
  final int month;
  final int day;

  /// Nombre listo para copy en la frase "Mañana es {name}". Por eso algunos
  /// llevan artículo ("la Constitución") y otros no ("Navidad").
  final String name;

  /// `true` si es propio de Canarias (no nacional). Hoy solo el Día de Canarias.
  final bool canarian;

  const Holiday(this.month, this.day, this.name, {this.canarian = false});
}

/// Festivos fijos que aplican en todo el archipiélago.
const List<Holiday> kCanarianHolidays = [
  Holiday(1, 1, 'Año Nuevo'),
  Holiday(1, 6, 'Reyes'),
  Holiday(5, 1, 'el Día del Trabajo'),
  Holiday(5, 30, 'el Día de Canarias', canarian: true),
  Holiday(8, 15, 'la Asunción'),
  Holiday(10, 12, 'la Fiesta Nacional'),
  Holiday(11, 1, 'Todos los Santos'),
  Holiday(12, 6, 'el Día de la Constitución'),
  Holiday(12, 8, 'la Inmaculada'),
  Holiday(12, 25, 'Navidad'),
];

/// Devuelve el festivo que cae en [date] (comparando mes/día), o `null`.
Holiday? holidayOn(
  DateTime date, {
  List<Holiday> calendar = kCanarianHolidays,
}) {
  for (final h in calendar) {
    if (h.month == date.month && h.day == date.day) return h;
  }
  return null;
}
