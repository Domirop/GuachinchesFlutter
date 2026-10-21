import 'package:guachinches/data/canarismos.dart';

/// Lógica pura del Canarismo del día (detalle + tarjeta para historias):
/// fechas en español, etiquetas relativas, antetítulos «del día» frente a un
/// canarismo pasado y la lista de canarismos anteriores.

const List<String> kCanarismoWeekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const List<String> kCanarismoMonths = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Cuántos canarismos anteriores se enseñan como máximo.
const int kCanarismoHistoryMax = 5;

/// «miércoles 14 de octubre».
String canarismoLongDate(DateTime d) =>
    '${kCanarismoWeekdays[d.weekday - 1]} ${d.day} de ${kCanarismoMonths[d.month - 1]}';

/// «14 de octubre de 2026».
String canarismoFullDate(DateTime d) =>
    '${d.day} de ${kCanarismoMonths[d.month - 1]} de ${d.year}';

/// Días de calendario entre [from] y [to] (en UTC para no perder un día al
/// cruzar el cambio de hora). Positivo si [from] es anterior a [to].
int canarismoDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// `true` si [d] cae el mismo día de calendario que [today].
bool canarismoIsSameDay(DateTime d, DateTime today) =>
    canarismoDaysBetween(d, today) == 0;

/// «Hoy», «Ayer» o «Hace N días», siempre respecto a [today].
String canarismoRelativeLabel(DateTime d, DateTime today) {
  final days = canarismoDaysBetween(d, today);
  if (days <= 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  return 'Hace $days días';
}

/// Antetítulo del hero del detalle: «El canarismo del día · miércoles 14 de
/// octubre» para el de hoy; «Canarismo · lunes 12 de octubre» para uno pasado
/// (nunca dice «del día» si no es el de hoy).
String canarismoDetailEyebrow(DateTime date, {required bool isToday}) => isToday
    ? 'El canarismo del día · ${canarismoLongDate(date)}'
    : 'Canarismo · ${canarismoLongDate(date)}';

/// Antetítulo de la tarjeta para historias.
String canarismoCardEyebrow({required bool isToday}) =>
    isToday ? 'El canarismo del día' : 'Un canarismo';

/// Título del bloque «Comparte…» del detalle.
String canarismoShareTitle({required bool isToday}) =>
    isToday ? 'Comparte el canarismo' : 'Comparte este canarismo';

const List<String> _kNumberWords = ['', 'un', 'dos', 'tres', 'cuatro', 'cinco'];

/// Antetítulo de «Canarismos anteriores» según cuántos hay y si se parte de
/// hoy («Los últimos cinco días») o de un día pasado («Los cinco días
/// anteriores»).
String canarismoHistoryEyebrow(int count, {required bool isToday}) {
  if (count <= 1) return isToday ? 'El día de ayer' : 'El día anterior';
  final n = count < _kNumberWords.length ? _kNumberWords[count] : '$count';
  return isToday ? 'Los últimos $n días' : 'Los $n días anteriores';
}

/// Texto que acompaña a la imagen al compartir.
String canarismoShareText(Canarismo c) =>
    '«${c.palabra}»: ${c.significado}\n\nvía Dónde Comer Canarias · dondecomercanarias.com';

/// Una fila de «Canarismos anteriores».
class CanarismoHistoryEntry {
  final DateTime date;
  final Canarismo canarismo;

  /// «Ayer» / «Hace N días», calculada respecto a HOY (no a la fecha
  /// mostrada), así abrir un canarismo pasado sigue diciendo la verdad.
  final String label;

  const CanarismoHistoryEntry({
    required this.date,
    required this.canarismo,
    required this.label,
  });
}

/// Canarismos de los días anteriores a [date] (el más reciente primero),
/// solo los que YA han aparecido (nunca antes del lanzamiento) y como mucho
/// [max]. Las etiquetas relativas se calculan respecto a [today].
List<CanarismoHistoryEntry> canarismoHistory(
  DateTime date,
  DateTime today, {
  int max = kCanarismoHistoryMax,
}) {
  final count = canarismoDayIndex(date).clamp(0, max);
  final base = DateTime(date.year, date.month, date.day);
  return List.generate(count, (i) {
    // Restar días de calendario (no 24 h) para no saltar días con el DST.
    final d = DateTime(base.year, base.month, base.day - (i + 1));
    return CanarismoHistoryEntry(
      date: d,
      canarismo: canarismoOfDay(d),
      label: canarismoRelativeLabel(d, today),
    );
  });
}
