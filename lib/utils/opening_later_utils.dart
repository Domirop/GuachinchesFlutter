import 'horarios_utils.dart' show getOpenStatus;

/// Helpers para descubrir cuándo abre HOY un restaurante que ahora mismo
/// está cerrado. Pensado para el fallback de la sección "HOY EN …" en
/// islas donde la cocina arranca más tarde (El Hierro, La Gomera, etc.).
///
/// Reglas:
/// - "Hoy" = el mismo Google-day que `now` (no cruza medianoche aunque el
///   periodo lo haga; si el restaurante abre a las 23:00 sigue contando
///   como hoy).
/// - Devolvemos minutos hasta la apertura — `null` si no abre más tarde
///   hoy (cerrado el día entero, sin horarios estructurados, o ya está
///   abierto ahora — para eso ya está `isOpenNow`).
///
/// `horariosJson` shape: mismo que `horarios_utils.dart`:
/// `{ "periods": [{ "open": {"day": int, "time": "HHMM"}, "close": {...} }] }`.

/// Minutos desde ahora hasta la próxima apertura HOY. `null` si:
/// - `horariosJson` es null/inválido,
/// - ya está abierto ahora,
/// - no abre más durante el día actual.
int? minutesUntilOpenToday(Map<String, dynamic>? horariosJson, DateTime now) {
  if (horariosJson == null) return null;
  try {
    // Si está abierto ahora, no es candidato a "abre pronto".
    final status = getOpenStatus(horariosJson, now);
    if (status == 'Abierto' || status.startsWith('Cierra en')) return null;

    final periods = horariosJson['periods'] as List?;
    if (periods == null || periods.isEmpty) return null;

    final int googleDay = now.weekday % 7;
    final int nowMinutes = now.hour * 60 + now.minute;

    int? earliest;
    for (final p in periods) {
      final open = p['open'];
      if (open == null || open['day'] != googleDay) continue;
      final timeStr = open['time'] as String?;
      if (timeStr == null || timeStr.length < 4) continue;
      final h = int.tryParse(timeStr.substring(0, 2));
      final m = int.tryParse(timeStr.substring(2, 4));
      if (h == null || m == null) continue;
      final openMin = h * 60 + m;
      if (openMin <= nowMinutes) continue; // ya pasó hoy
      if (earliest == null || openMin < earliest) earliest = openMin;
    }
    if (earliest == null) return null;
    return earliest - nowMinutes;
  } catch (_) {
    return null;
  }
}

/// Hora de apertura formateada `"13:30"`. Devuelve `null` si no abre hoy
/// más tarde.
String? nextOpenLabel(Map<String, dynamic>? horariosJson, DateTime now) {
  final minutes = minutesUntilOpenToday(horariosJson, now);
  if (minutes == null) return null;
  final opensAt = now.add(Duration(minutes: minutes));
  final hh = opensAt.hour.toString().padLeft(2, '0');
  final mm = opensAt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// `true` si el restaurante abre más tarde HOY (y por tanto no ahora).
bool opensLaterToday(Map<String, dynamic>? horariosJson, DateTime now) {
  return minutesUntilOpenToday(horariosJson, now) != null;
}
