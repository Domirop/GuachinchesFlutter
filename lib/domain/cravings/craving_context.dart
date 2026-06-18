/// Señales de contexto para el motor de "¿Qué te apetece ahora?".
///
/// Capa de DOMINIO pura (sin Flutter): se puede testear en aislamiento.
/// Convierte entradas crudas (reloj + clima) en bandas discretas que el motor
/// de scoring sabe puntuar.
library;

/// Franja del día. Derivada de la hora local.
enum DayPart { madrugada, desayuno, mediodia, sobremesa, tarde, noche }

/// Estado del cielo (mapeado desde `WeatherData.condition` del backend).
enum Sky { clear, clouds, rain, fog, storm, unknown }

/// Banda de temperatura (clima canario). `unknown` si no hay dato.
enum TempBand { cold, mild, warm, hot, unknown }

/// Tipo de día: el finde y el viernes cambian la intención del plan.
enum DayType { weekday, friday, weekend }

/// Contexto resuelto que consume el motor. Inmutable y comparable.
class CravingContext {
  final DayPart dayPart;
  final Sky sky;
  final TempBand tempBand;
  final DayType dayType;
  final int hour;

  const CravingContext({
    required this.dayPart,
    required this.sky,
    required this.tempBand,
    required this.dayType,
    required this.hour,
  });

  /// Construye el contexto desde señales crudas: el reloj (para franja y tipo
  /// de día) y el clima ya resuelto a [Sky] + temperatura.
  factory CravingContext.resolve({
    required DateTime now,
    Sky sky = Sky.unknown,
    double? tempC,
  }) {
    return CravingContext(
      dayPart: dayPartFromHour(now.hour),
      sky: sky,
      tempBand: tempBandFromCelsius(tempC),
      dayType: dayTypeFromWeekday(now.weekday),
      hour: now.hour,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CravingContext &&
      other.dayPart == dayPart &&
      other.sky == sky &&
      other.tempBand == tempBand &&
      other.dayType == dayType;

  @override
  int get hashCode => Object.hash(dayPart, sky, tempBand, dayType);
}

/// Hora local → franja. Madrugada = 0-6.
DayPart dayPartFromHour(int h) {
  if (h >= 7 && h <= 11) return DayPart.desayuno;
  if (h >= 12 && h <= 13) return DayPart.mediodia;
  if (h >= 14 && h <= 16) return DayPart.sobremesa;
  if (h >= 17 && h <= 19) return DayPart.tarde;
  if (h >= 20 && h <= 23) return DayPart.noche;
  return DayPart.madrugada;
}

/// °C → banda. Umbrales pensados para Canarias (templado todo el año).
TempBand tempBandFromCelsius(double? t) {
  if (t == null) return TempBand.unknown;
  if (t < 16) return TempBand.cold;
  if (t < 23) return TempBand.mild;
  if (t < 28) return TempBand.warm;
  return TempBand.hot;
}

/// `DateTime.weekday` (Lun=1..Dom=7) → tipo de día.
DayType dayTypeFromWeekday(int weekday) {
  if (weekday == DateTime.friday) return DayType.friday;
  if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
    return DayType.weekend;
  }
  return DayType.weekday;
}

/// Mapea la `condition` que sirve el backend (`WeatherData.condition`) a [Sky].
/// Vocabulario backend: 'sunny' | 'cloudy' | 'rain' | 'fog' | 'storm' | 'unknown'.
Sky skyFromCondition(String condition) {
  switch (condition) {
    case 'sunny':
      return Sky.clear;
    case 'cloudy':
      return Sky.clouds;
    case 'rain':
      return Sky.rain;
    case 'fog':
      return Sky.fog;
    case 'storm':
      return Sky.storm;
    default:
      return Sky.unknown;
  }
}
