import 'open_state.dart';

/// Returns one of: "Abierto", "Cerrado", "Abre en X min", "Cierra en X min"
/// horariosJson shape: { "periods": [...], "weekday_text": [...], "syncedAt": "..." }
/// Period shape: { "open": { "day": int, "time": "HHMM" }, "close": { "day": int, "time": "HHMM" } }
/// Dart weekday → Google day: googleDay = now.weekday % 7
///   Dart 1=Mon…7=Sun  →  Google 0=Sun,1=Mon…6=Sat
///
/// Delega en [computeOpenState] (única fuente de verdad): los periodos que
/// cruzan la medianoche funcionan y «Cierra en X min» sigue abierto.
String getOpenStatus(Map<String, dynamic>? horariosJson, DateTime now) {
  final s = computeOpenState(horariosJson, now);
  switch (s.kind) {
    case OpenKind.open:
      return 'Abierto';
    case OpenKind.closingSoon:
      return 'Cierra en ${s.minutesToClose} min';
    case OpenKind.closed:
      final m = s.minutesToOpen;
      return (m != null && m <= 60) ? 'Abre en $m min' : 'Cerrado';
    case OpenKind.unknown:
      return 'Cerrado';
  }
}
