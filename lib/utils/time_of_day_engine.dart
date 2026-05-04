enum TimeOfDayWindow {
  madrugada,
  desayuno,
  manana,
  menuUrgente,
  sobremesa,
  goldenHour,
  noche,
  cierre,
}

class TimeOfDayEngine {
  TimeOfDayEngine._();

  static TimeOfDayWindow computeWindow(DateTime now) {
    final h = now.hour;
    if (h < 6) return TimeOfDayWindow.madrugada;
    if (h < 10) return TimeOfDayWindow.desayuno;
    if (h < 13) return TimeOfDayWindow.manana;
    if (h < 14) return TimeOfDayWindow.menuUrgente;
    if (h < 17) return TimeOfDayWindow.sobremesa;
    if (h < 20) return TimeOfDayWindow.goldenHour;
    if (h < 23) return TimeOfDayWindow.noche;
    return TimeOfDayWindow.cierre;
  }

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 6) return 'Buenas noches';
    if (h < 13) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static String editorialCopy(DateTime now, {String? zona, bool isRaining = false}) {
    final h = now.hour;
    if (h == 13 || h == 14) return 'Menú del día. La hora sagrada.';
    if (h >= 17 && h <= 19) return 'El sol pinta el Atlántico de naranja.';
    if (h >= 20) return 'La noche canaria empieza aquí.';
    if (zona == 'Norte' && isRaining) return 'Con esta lluvia, un guachinche cae solo.';
    if (zona == 'Sur') return 'Día de terraza. El sur está espléndido.';
    return 'Hace un sol que raja las piedras.';
  }

  static String sunEmoji(int hour) {
    if (hour >= 17 && hour < 20) return '🌅';
    if (hour >= 6 && hour < 20) return '☀️';
    return '🌙';
  }
}
