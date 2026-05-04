import 'horarios_utils.dart';

/// Extiende horarios_utils.dart con helpers de open-now/closing-soon.
/// Siempre usa try/catch: horariosJson puede tener shapes inconsistentes.

bool isOpenNow(Map<String, dynamic>? horariosJson, DateTime now) {
  if (horariosJson == null) return false;
  try {
    final s = getOpenStatus(horariosJson, now);
    return s == 'Abierto' || s.startsWith('Cierra en');
  } catch (_) {
    return false;
  }
}

bool closingSoon(
  Map<String, dynamic>? horariosJson,
  DateTime now, {
  int withinMinutes = 60,
}) {
  if (horariosJson == null) return false;
  try {
    final s = getOpenStatus(horariosJson, now);
    if (!s.startsWith('Cierra en')) return false;
    final mins = int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 999;
    return mins <= withinMinutes;
  } catch (_) {
    return false;
  }
}

int minutesUntilClose(Map<String, dynamic>? horariosJson, DateTime now) {
  if (horariosJson == null) return 9999;
  try {
    final s = getOpenStatus(horariosJson, now);
    if (!s.startsWith('Cierra en')) return 9999;
    return int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 9999;
  } catch (_) {
    return 9999;
  }
}
