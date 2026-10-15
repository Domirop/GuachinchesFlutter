import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/zone.dart';

/// Lógica pura de la hoja «¿Dónde en <isla>?» (tablero HojaZona): glifo,
/// tinta y descripción de cada zona, chip del tiempo y estado de la hoja.
/// Sin widgets.

/// Glifo propio de cada zona (rejilla 24, sin emoji).
enum ZoneGlyph { island, leaf, sun, city, mountain, sunset, pin }

/// Tono del azulejo: fondo suave + tinta del glifo (se resuelve con
/// `GmColors` en el widget).
enum ZoneTone {
  /// banda crema + tinta de banda (toda la isla, interior).
  band,

  /// verde suave + texto verde (norte).
  ok,

  /// ámbar suave + texto ámbar (sur, oeste).
  warn,

  /// relleno neutro + gris secundario (área metropolitana, desconocidas).
  neutral,
}

class ZoneLook {
  final ZoneGlyph glyph;
  final ZoneTone tone;
  const ZoneLook(this.glyph, this.tone);

  @override
  bool operator ==(Object other) =>
      other is ZoneLook && other.glyph == glyph && other.tone == tone;

  @override
  int get hashCode => Object.hash(glyph, tone);

  @override
  String toString() => 'ZoneLook($glyph, $tone)';
}

/// Glifo y tono por clave de zona (claves reales de `/zones/island/:id`:
/// `all`, `norte`, `sur`, `metro`, `interior`, `oeste`).
ZoneLook zoneLookFor(String key) {
  switch (key.trim().toLowerCase()) {
    case 'all':
      return const ZoneLook(ZoneGlyph.island, ZoneTone.band);
    case 'norte':
      return const ZoneLook(ZoneGlyph.leaf, ZoneTone.ok);
    case 'sur':
      return const ZoneLook(ZoneGlyph.sun, ZoneTone.warn);
    case 'metro':
      return const ZoneLook(ZoneGlyph.city, ZoneTone.neutral);
    case 'interior':
      return const ZoneLook(ZoneGlyph.mountain, ZoneTone.band);
    case 'oeste':
      return const ZoneLook(ZoneGlyph.sunset, ZoneTone.warn);
    default:
      return const ZoneLook(ZoneGlyph.pin, ZoneTone.neutral);
  }
}

String _norm(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüû';
  const to = 'aaaaeeeeiiiioooouuuu';
  final buf = StringBuffer();
  for (final rune in s.toLowerCase().trim().runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
}

bool _isTenerife(String islandLabel) => _norm(islandLabel) == 'tenerife';

/// Nombre que se pinta: «Área Metro» → «Área metropolitana». El resto
/// (incluidas las capitales de las otras islas: «Las Palmas», «Arrecife»…)
/// se respeta.
String zoneDisplayLabel(String label) {
  final n = _norm(label);
  if (n == 'area metro' || n == 'area metro.') return 'Área metropolitana';
  return label.trim();
}

/// Descripción de la fila (13/18, secundaria). `null` si la zona no es
/// conocida (no se inventa nada).
String? zoneDescription(String key, String islandLabel) {
  final tf = _isTenerife(islandLabel);
  switch (key.trim().toLowerCase()) {
    case 'all':
      return 'Sin filtrar por zona';
    case 'norte':
      return tf
          ? 'Guachinches, viñedos y laurisilva'
          : 'Pueblos y costa del norte';
    case 'sur':
      return 'Terrazas al sol y pueblos de costa';
    case 'metro':
      return tf
          ? 'Santa Cruz, La Laguna y alrededores'
          : 'La capital y alrededores';
    case 'interior':
      return tf
          ? 'Medianías y cumbre: La Esperanza, Vilaflor'
          : 'Medianías y cumbre';
    case 'oeste':
      return 'Acantilados y atardeceres';
    default:
      return null;
  }
}

/// Título de la hoja.
String zoneSheetTitle(String islandLabel) => '¿Dónde en ${islandLabel.trim()}?';

const String kZoneSheetSubtitle = 'Elige zona y te enseñamos dónde comer';
const String kZoneSheetCaptionWeather = 'Temperatura ahora en cada zona.';
const String kZoneSheetCaptionNoWeather =
    'El tiempo no está disponible ahora mismo. Las zonas funcionan igual.';
const String kZoneSheetErrorTitle = 'No pudimos cargar las zonas';
const String kZoneSheetErrorText =
    'Revisa tu conexión e inténtalo de nuevo. Mientras, seguimos en toda la isla.';

/// Glifo del chip del tiempo (propios, sin emoji).
enum ZoneWeatherGlyph { sun, partly, cloud }

/// `sunny` → sol; `cloudy` (el backend lo pinta como «sol y nube») → nubes y
/// claros; niebla, lluvia y tormenta → nube; desconocido con temperatura →
/// nubes y claros.
ZoneWeatherGlyph zoneWeatherGlyph(String condition) {
  switch (condition) {
    case 'sunny':
      return ZoneWeatherGlyph.sun;
    case 'cloudy':
      return ZoneWeatherGlyph.partly;
    case 'fog':
    case 'rain':
    case 'storm':
      return ZoneWeatherGlyph.cloud;
    default:
      return ZoneWeatherGlyph.partly;
  }
}

/// Palabra para lectores de pantalla. `null` si la condición no se conoce.
String? zoneWeatherWord(String condition) {
  switch (condition) {
    case 'sunny':
      return 'soleado';
    case 'cloudy':
      return 'nubes y claros';
    case 'fog':
      return 'niebla';
    case 'rain':
      return 'lluvia';
    case 'storm':
      return 'tormenta';
    default:
      return null;
  }
}

/// «20°». `null` si no hay temperatura.
String? zoneWeatherText(WeatherData w) =>
    w.tempC == null ? null : '${w.tempC!.round()}°';

/// «20 grados, soleado» (o «20 grados» si la condición no se conoce).
String? zoneWeatherSemantics(WeatherData w) {
  if (w.tempC == null) return null;
  final t = w.tempC!.round();
  final deg = t == 1 || t == -1 ? 'grado' : 'grados';
  final word = zoneWeatherWord(w.condition);
  return word == null ? '$t $deg' : '$t $deg, $word';
}

/// Tiempo de una zona (o desconocido si no hay id o no llegó).
WeatherData zoneWeatherFor(Zone z, Map<String, WeatherData> byZoneId) {
  final id = z.id;
  if (id == null) return const WeatherData.unknown();
  return byZoneId[id] ?? const WeatherData.unknown();
}

/// ¿Hay tiempo para alguna de las zonas? Si no, la hoja quita todos los
/// chips y lo dice en el pie («sin tiempo»).
bool zoneSheetHasWeather(List<Zone> zones, Map<String, WeatherData> byZoneId) =>
    zones.any((z) => zoneWeatherFor(z, byZoneId).isAvailable);

String zoneSheetCaption({required bool hasWeather}) =>
    hasWeather ? kZoneSheetCaptionWeather : kZoneSheetCaptionNoWeather;

enum ZoneSheetStatus { list, loading, error }

/// Qué pinta la hoja: con zonas, la lista; sin zonas, cargando mientras el
/// cubit carga (o no hay cubit al que preguntar) y error si falló o volvió
/// vacío.
ZoneSheetStatus zoneSheetStatus(
    {required bool hasZones, required ZonesState? state}) {
  if (hasZones) return ZoneSheetStatus.list;
  if (state is ZonesFailure || state is ZonesLoaded) {
    return ZoneSheetStatus.error;
  }
  return ZoneSheetStatus.loading;
}

/// Zonas a pintar: las del cubit si ya las tiene (se actualizan con la hoja
/// abierta), si no las que pasó quien abre la hoja.
List<Zone> zoneSheetZones(List<Zone> passed, ZonesState? state) {
  if (state is ZonesLoaded && state.zones.isNotEmpty) return state.zones;
  return passed;
}
