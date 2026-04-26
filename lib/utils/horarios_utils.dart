/// Returns one of: "Abierto", "Cerrado", "Abre en X min", "Cierra en X min"
/// horariosJson shape: { "periods": [...], "weekday_text": [...], "syncedAt": "..." }
/// Period shape: { "open": { "day": int, "time": "HHMM" }, "close": { "day": int, "time": "HHMM" } }
/// Dart weekday → Google day: googleDay = now.weekday % 7
///   Dart 1=Mon…7=Sun  →  Google 0=Sun,1=Mon…6=Sat
String getOpenStatus(Map<String, dynamic>? horariosJson, DateTime now) {
  if (horariosJson == null) return "Cerrado";
  final periods = horariosJson['periods'] as List?;
  if (periods == null || periods.isEmpty) return "Cerrado";

  final int googleDay = now.weekday % 7;
  final int nowMinutes = now.hour * 60 + now.minute;

  // Check if currently inside an open period
  for (final p in periods) {
    final open = p['open'];
    final close = p['close'];
    if (open == null || open['day'] != googleDay) continue;

    final int openMin = _toMinutes(open['time'] as String);

    if (close == null) return "Abierto"; // 24h

    final int closeMin = _toMinutes(close['time'] as String);

    if (nowMinutes >= openMin && nowMinutes < closeMin) {
      final int remaining = closeMin - nowMinutes;
      return remaining <= 60 ? "Cierra en $remaining min" : "Abierto";
    }
  }

  // Check if will open within the next 60 min
  for (final p in periods) {
    final open = p['open'];
    if (open == null || open['day'] != googleDay) continue;
    final int openMin = _toMinutes(open['time'] as String);
    if (openMin > nowMinutes) {
      final int remaining = openMin - nowMinutes;
      if (remaining <= 60) return "Abre en $remaining min";
    }
  }

  return "Cerrado";
}

int _toMinutes(String hhmm) {
  final h = int.parse(hhmm.substring(0, 2));
  final m = int.parse(hhmm.substring(2, 4));
  return h * 60 + m;
}
