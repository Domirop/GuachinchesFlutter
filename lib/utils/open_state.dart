import 'package:guachinches/data/model/restaurant.dart';

/// Estado de apertura de un local: la ÚNICA fuente de verdad para «Abierto
/// ahora» (filtro) y para la etiqueta de las tarjetas.
///
/// Se calcula con los periodos de Google (`horarios_json`) sobre la semana
/// entera, así que los periodos que cruzan la medianoche (abre el viernes a
/// las 20:00 y cierra el sábado a las 2:00) funcionan, igual que el sábado →
/// domingo. «Cierra en N min» sigue contando como abierto.
enum OpenKind {
  /// Abierto y le queda más de una hora.
  open,

  /// Abierto, pero cierra en una hora o menos (ámbar, nunca rojo).
  closingSoon,

  /// Cerrado ahora (se dice cuándo abre si se sabe).
  closed,

  /// Sin horario fiable: nunca se pinta como cerrado.
  unknown,
}

/// Minutos que convierten «Abierto» en «Cierra en N min».
const int kClosingSoonMinutes = 60;

class OpenState {
  final OpenKind kind;

  /// Minutos hasta el cierre (abierto). `null` = 24 h o sin dato de cierre.
  final int? minutesToClose;

  /// Hora de cierre en minutos del día (0–1439).
  final int? closesAtMinute;

  /// Minutos hasta la próxima apertura (cerrado). `null` = no se sabe.
  final int? minutesToOpen;

  /// Hora de la próxima apertura en minutos del día (0–1439).
  final int? opensAtMinute;

  /// Días hasta la próxima apertura: 0 hoy, 1 mañana…
  final int? opensInDays;

  /// Día de la próxima apertura (Google: 0 domingo … 6 sábado).
  final int? opensGoogleDay;

  const OpenState(
    this.kind, {
    this.minutesToClose,
    this.closesAtMinute,
    this.minutesToOpen,
    this.opensAtMinute,
    this.opensInDays,
    this.opensGoogleDay,
  });

  bool get isOpen => kind == OpenKind.open || kind == OpenKind.closingSoon;

  /// Abre más tarde HOY (para el «N más: X abren más tarde…»).
  bool get opensLaterToday => kind == OpenKind.closed && opensInDays == 0;

  @override
  String toString() => 'OpenState($kind, close=$minutesToClose, '
      'open=$minutesToOpen, days=$opensInDays)';
}

const int _week = 7 * 1440;

int _hhmm(Object? raw) {
  final t = raw.toString();
  return int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(2, 4));
}

int _abs(Map p) => (p['day'] as num).toInt() * 1440 + _hhmm(p['time']);

/// Estado de apertura a partir de `horarios_json` (periodos de Google).
///
/// Sin periodos utilizables: [fallbackOpen] == true → abierto (sin hora de
/// cierre); si no, [OpenKind.unknown] («Horario sin confirmar»).
OpenState computeOpenState(
  Map<String, dynamic>? horariosJson,
  DateTime now, {
  bool? fallbackOpen,
}) {
  final periods = horariosJson == null ? null : horariosJson['periods'];
  if (periods is! List || periods.isEmpty) {
    return fallbackOpen == true
        ? const OpenState(OpenKind.open)
        : const OpenState(OpenKind.unknown);
  }
  try {
    final nowW = (now.weekday % 7) * 1440 + now.hour * 60 + now.minute;

    // ¿Dentro de algún periodo? (también los que cruzan medianoche o el
    // fin de semana: se prueba «ahora» y «ahora + 1 semana»).
    for (final p in periods) {
      final open = p is Map ? p['open'] : null;
      if (open is! Map) continue;
      final close = p['close'];
      if (close is! Map) {
        // Google: un único periodo sin cierre = abierto 24 h.
        return const OpenState(OpenKind.open);
      }
      final om = _abs(open);
      var cm = _abs(close);
      if (cm <= om) cm += _week;
      for (final n in [nowW, nowW + _week]) {
        if (n >= om && n < cm) {
          final left = cm - n;
          return OpenState(
            left <= kClosingSoonMinutes ? OpenKind.closingSoon : OpenKind.open,
            minutesToClose: left,
            closesAtMinute: cm % 1440,
          );
        }
      }
    }

    // Cerrado: la próxima apertura de la semana.
    int? best;
    for (final p in periods) {
      final open = p is Map ? p['open'] : null;
      if (open is! Map) continue;
      var d = _abs(open) - nowW;
      if (d <= 0) d += _week;
      if (best == null || d < best) best = d;
    }
    if (best == null) return const OpenState(OpenKind.closed);
    final at = nowW + best;
    return OpenState(
      OpenKind.closed,
      minutesToOpen: best,
      opensAtMinute: at % 1440,
      opensInDays: at ~/ 1440 - nowW ~/ 1440,
      opensGoogleDay: (at ~/ 1440) % 7,
    );
  } catch (_) {
    // Periodos con forma inesperada: sin horario fiable.
    return fallbackOpen == true
        ? const OpenState(OpenKind.open)
        : const OpenState(OpenKind.unknown);
  }
}

/// Estado de apertura de un local: `horarios_json` si lo tiene; si no, el
/// `open` que calcula el backend con el texto de Google.
OpenState restaurantOpenState(Restaurant r, DateTime now) =>
    computeOpenState(r.horariosJson, now,
        fallbackOpen: r.horariosJson == null ? r.open : null);

/// ¿Abierto ahora? La regla única de toda la app (home, «Hoy», listas,
/// badges y mapa).
bool isRestaurantOpenNow(Restaurant r, DateTime now) =>
    restaurantOpenState(r, now).isOpen;
