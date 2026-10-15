import 'dart:math' as math;

import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/utils/open_state.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Lógica pura de la pestaña Mapa (tableros TabMapa, MapaCoche y
/// MapaEmpujado). Sin Flutter ni plugins: se prueba con `flutter_test`.

/// Distancias por encima de esto no se pintan (DISENO-FINAL §8).
const double kMapMaxDistanceMeters = 200000;

/// Radio de «Cerca de ti» (tablero MapaEmpujado).
const double kNearbyRadiusKm = 3;

/// Orden de los chips de tipo (tablero TabMapa · `CHIP_TYPES`).
const List<ListThemeKind> kMapChipOrder = [
  ListThemeKind.moderno,
  ListThemeKind.tradicional,
  ListThemeKind.bodegon,
  ListThemeKind.tasca,
  ListThemeKind.restaurante,
  ListThemeKind.bar,
  ListThemeKind.cofradia,
  ListThemeKind.mercado,
  ListThemeKind.lounge,
  ListThemeKind.experiencia,
];

/// Un sitio del mapa: el restaurante con su tipo (tema), su estado de
/// apertura (fuente única `open_state.dart`) y la distancia al usuario.
class MapSite {
  final Restaurant restaurant;

  /// Tema del tipo (`null` = sin tipo: chincheta neutra pequeña).
  final ListThemeKind? kind;
  final OpenState open;

  /// Metros al usuario (`null` sin ubicación o > 200 km).
  final double? meters;

  const MapSite({
    required this.restaurant,
    required this.kind,
    required this.open,
    this.meters,
  });

  String get id => restaurant.id;
  double get lat => restaurant.lat;
  double get lon => restaurant.lon;

  /// Cerrado ahora (la chincheta se atenúa). «Horario sin confirmar» nunca
  /// cuenta como cerrado.
  bool get closed => open.kind == OpenKind.closed;

  /// Abierto ahora («Cierra en N min» incluido).
  bool get isOpen => open.isOpen;

  /// Etiqueta del tipo en singular («Guachinche moderno»), o vacía.
  String get typeLabel => restaurantTypeLabel(restaurant.type);
}

/// ¿Tiene coordenadas utilizables?
bool mapHasCoords(Restaurant r) =>
    !(r.lat == 0 && r.lon == 0) && r.lat.abs() <= 90 && r.lon.abs() <= 180;

/// Tema del tipo de un restaurante (por el UUID de `restaurantTypeId`).
ListThemeKind? mapKindOf(Restaurant r) {
  final id = r.type.trim();
  if (id.isEmpty || id.toLowerCase() == 'vacio') return null;
  final k = listThemeForType(id, restaurantTypeLabel(id));
  return (k != null && kListThemes[k]!.isType) ? k : null;
}

/// Construye los sitios con coordenadas a partir de los restaurantes.
List<MapSite> buildMapSites(
  List<Restaurant> restaurants,
  DateTime now, {
  double? userLat,
  double? userLon,
}) {
  final out = <MapSite>[];
  final seen = <String>{};
  for (final r in restaurants) {
    if (!mapHasCoords(r)) continue;
    if (r.id.isNotEmpty && !seen.add(r.id)) continue;
    out.add(MapSite(
      restaurant: r,
      kind: mapKindOf(r),
      open: restaurantOpenState(r, now),
      meters: mapDistanceMeters(r.lat, r.lon, userLat, userLon),
    ));
  }
  return out;
}

/// Metros entre el usuario y un punto (`null` sin ubicación o > 200 km).
double? mapDistanceMeters(
    double lat, double lon, double? userLat, double? userLon) {
  if (userLat == null || userLon == null) return null;
  final m = haversineDistanceMeters(userLat, userLon, lat, lon);
  return m > kMapMaxDistanceMeters ? null : m;
}

/// Recalcula la distancia de cada sitio a una nueva ubicación.
List<MapSite> withUserLocation(
        List<MapSite> sites, double? userLat, double? userLon) =>
    [
      for (final s in sites)
        MapSite(
          restaurant: s.restaurant,
          kind: s.kind,
          open: s.open,
          meters: mapDistanceMeters(s.lat, s.lon, userLat, userLon),
        )
    ];

// ── Filtros ────────────────────────────────────────────────────────────────

class MapFilters {
  final bool openNow;
  final Set<String> typeIds;
  final String query;

  const MapFilters({
    this.openNow = false,
    this.typeIds = const {},
    this.query = '',
  });

  bool get any => openNow || typeIds.isNotEmpty || query.trim().isNotEmpty;

  MapFilters copyWith({bool? openNow, Set<String>? typeIds, String? query}) =>
      MapFilters(
        openNow: openNow ?? this.openNow,
        typeIds: typeIds ?? this.typeIds,
        query: query ?? this.query,
      );

  MapFilters toggleType(String id) {
    final next = {...typeIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    return copyWith(typeIds: next);
  }
}

/// Minúsculas y sin tildes (para buscar por nombre).
String mapNormalize(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  final lower = s.toLowerCase().trim();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ');
}

List<MapSite> applyMapFilters(List<MapSite> sites, MapFilters f) {
  if (!f.any) return sites;
  final q = mapNormalize(f.query);
  return [
    for (final s in sites)
      if ((!f.openNow || s.isOpen) &&
          (f.typeIds.isEmpty || f.typeIds.contains(s.restaurant.type)) &&
          (q.isEmpty || mapNormalize(s.restaurant.nombre).contains(q)))
        s
  ];
}

/// Chip de tipo de la fila de filtros.
class MapTypeChip {
  final String id;
  final String label;
  final ListThemeKind? kind;
  const MapTypeChip(this.id, this.label, this.kind);
}

/// Chips de tipo a partir de los tipos del servidor: título del tema en
/// plural, en el orden del tablero; los que no tienen ningún sitio en la
/// isla se ocultan (salvo que estén activos). Activos primero.
List<MapTypeChip> mapTypeChips(
  List<Types> types, {
  Set<String> active = const {},
  Set<String>? presentTypeIds,
}) {
  final chips = <MapTypeChip>[];
  for (final t in types) {
    if (t.id.isEmpty) continue;
    if (presentTypeIds != null &&
        !presentTypeIds.contains(t.id) &&
        !active.contains(t.id)) {
      continue;
    }
    final k = listThemeForType(t.id, t.nombre);
    final label = k == null ? t.nombre.trim() : kListThemes[k]!.title;
    if (label.isEmpty) continue;
    chips.add(MapTypeChip(t.id, label, k));
  }
  int rank(MapTypeChip c) {
    final i = c.kind == null ? -1 : kMapChipOrder.indexOf(c.kind!);
    return i < 0 ? kMapChipOrder.length : i;
  }

  chips.sort((a, b) {
    final aa = active.contains(a.id) ? 0 : 1;
    final bb = active.contains(b.id) ? 0 : 1;
    if (aa != bb) return aa - bb;
    return rank(a) - rank(b);
  });
  return chips;
}

// ── Zona visible ───────────────────────────────────────────────────────────

/// Rectángulo geográfico (sur, oeste, norte, este).
class MapBox {
  final double south, west, north, east;
  const MapBox(this.south, this.west, this.north, this.east);

  bool contains(double lat, double lon) {
    if (lat < south || lat > north) return false;
    if (west <= east) return lon >= west && lon <= east;
    return lon >= west || lon <= east; // cruza el antimeridiano
  }

  double get centerLat => (south + north) / 2;
  double get centerLon => (west + east) / 2;
}

List<MapSite> sitesIn(List<MapSite> sites, MapBox box) => [
      for (final s in sites)
        if (box.contains(s.lat, s.lon)) s
    ];

/// Ordena por cercanía a un punto (el usuario o, sin ubicación, el centro
/// del mapa). Estable ante empates.
List<MapSite> sortByProximity(List<MapSite> sites, double lat, double lon) {
  final d = {
    for (final s in sites) s: haversineDistanceMeters(lat, lon, s.lat, s.lon)
  };
  final out = [...sites];
  out.sort((a, b) => d[a]!.compareTo(d[b]!));
  return out;
}

/// «16 abiertos de 37 en esta zona».
String zoneSummary(List<MapSite> zone) {
  final open = zone.where((s) => s.isOpen).length;
  final n = zone.length;
  return '$open ${open == 1 ? 'abierto' : 'abiertos'} de $n en esta zona';
}

/// «21 de 37 en esta zona · por cercanía» (sin ubicación, sin el final).
String zonePosition(int index, int total, {required bool byDistance}) =>
    '${index + 1} de $total en esta zona${byDistance ? ' · por cercanía' : ''}';

/// Paso cíclico prev/next dentro de la zona.
int zoneStep(int current, int delta, int total) {
  if (total <= 0) return -1;
  final base = current < 0 ? 0 : current;
  return (base + delta) % total;
}

String loadingCopy(String islandLabel) =>
    'Cargando sitios de ${islandLabel.isEmpty ? 'la isla' : islandLabel}…';

// ── Vacío con filtros ──────────────────────────────────────────────────────

class MapEmptyCopy {
  final String title;
  final String text;

  /// Botón principal («Ver las 2 en el mapa»); `null` si en la isla
  /// tampoco hay nada con esos filtros.
  final String? showAllLabel;
  final ListThemeKind? kind;
  const MapEmptyCopy(this.title, this.text, this.showAllLabel, this.kind);
}

String _joinMunicipalities(List<String> m) {
  if (m.isEmpty) return '';
  if (m.length == 1) return m.first;
  return '${m.sublist(0, m.length - 1).join(', ')} y ${m.last}';
}

/// Copia del vacío con filtros en la zona visible: dice qué falta y ofrece
/// lo que sí hay en la isla con los mismos filtros (tablero TabMapa ·
/// «Ninguna cofradía abierta por aquí»).
MapEmptyCopy emptyWithFiltersCopy({
  required MapFilters filters,
  required ListThemeKind? singleKind,
  required List<MapSite> islandMatches,
  required String islandLabel,
  required String Function(String raw) placeName,
}) {
  final theme = singleKind == null ? null : kListThemes[singleKind];
  final fem = theme?.feminine ?? false;
  final q = filters.query.trim();
  final island = islandLabel.isEmpty ? 'la isla' : islandLabel;

  String title;
  if (q.isNotEmpty) {
    title = 'Nada se llama «$q» por aquí';
  } else if (theme != null) {
    title = filters.openNow
        ? '${theme.none} ${fem ? 'abierta' : 'abierto'} por aquí'
        : '${theme.none} por aquí';
  } else if (filters.openNow && filters.typeIds.isEmpty) {
    title = 'Nada abierto por aquí';
  } else {
    title = 'Nada con estos filtros por aquí';
  }

  final n = islandMatches.length;
  if (n == 0) {
    return MapEmptyCopy(
      title,
      'Tampoco hay en $island con estos filtros. Quita alguno y seguimos.',
      null,
      singleKind,
    );
  }

  final lead =
      singleKind == ListThemeKind.cofradia ? 'El mar no se acaba: ' : '';
  final noun = theme?.noun ?? 'sitios';
  String count;
  if (filters.openNow) {
    final adj = n == 1
        ? (fem ? 'una abierta' : 'uno abierto')
        : '$n ${fem ? 'abiertas' : 'abiertos'}';
    count = 'ahora hay $adj en $island';
  } else {
    count = n == 1
        ? 'hay ${fem ? 'una' : 'uno'} en $island'
        : 'hay $n $noun en $island';
  }
  final munis = <String>[];
  for (final s in islandMatches) {
    final m = placeName(s.restaurant.municipio);
    if (m.isNotEmpty) munis.add(m);
  }
  String where = '';
  if (n == 1 && munis.length == 1) {
    where = ', en ${munis.first}';
  } else if (n == 2 && munis.length == 2) {
    where = munis[0] == munis[1]
        ? ', ${fem ? 'las' : 'los'} dos en ${munis[0]}'
        : ', ${fem ? 'una' : 'uno'} en ${munis[0]} y '
            '${fem ? 'otra' : 'otro'} en ${munis[1]}';
  } else if (n == 3 && munis.length == 3) {
    where = ', en ${_joinMunicipalities(munis)}';
  }
  final sentence = '$count$where.';
  final text = lead.isEmpty
      ? '${sentence[0].toUpperCase()}${sentence.substring(1)}'
      : '$lead$sentence';
  final showAll = n == 1
      ? 'Ver${fem ? 'la' : 'lo'} en el mapa'
      : 'Ver ${fem ? 'las' : 'los'} $n en el mapa';
  return MapEmptyCopy(title, text, showAll, singleKind);
}

// ── «Cerca de ti» ──────────────────────────────────────────────────────────

int _openRank(OpenState s) {
  switch (s.kind) {
    case OpenKind.open:
    case OpenKind.closingSoon:
      return 0;
    case OpenKind.unknown:
      return 1;
    case OpenKind.closed:
      return 2;
  }
}

/// Sitios a menos de [km] del usuario: abiertos primero, luego por
/// distancia (tablero MapaEmpujado).
List<MapSite> nearbySites(List<MapSite> sites, {double km = kNearbyRadiusKm}) {
  final limit = km * 1000;
  final near = [
    for (final s in sites)
      if (s.meters != null && s.meters! <= limit) s
  ];
  near.sort((a, b) {
    final r = _openRank(a.open) - _openRank(b.open);
    if (r != 0) return r;
    return a.meters!.compareTo(b.meters!);
  });
  return near;
}

String nearbyRangeLabel(int n, {double km = kNearbyRadiusKm}) =>
    '$n ${n == 1 ? 'sitio' : 'sitios'} a menos de ${_kmText(km)} km';

String nearbyListSubtitle(int n, {double km = kNearbyRadiusKm}) =>
    '${nearbyRangeLabel(n, km: km)} · abiertos primero';

String nearbyOpenEyebrow(int open) => open == 0
    ? 'Nada abierto ahora'
    : '$open ${open == 1 ? 'abierto' : 'abiertos'} ahora';

String _kmText(double km) => km == km.roundToDouble()
    ? km.toStringAsFixed(0)
    : '$km'.replaceAll('.', ',');

// ── Modo coche ─────────────────────────────────────────────────────────────

/// Minutos estimados sin ruta real: 1,3 × la línea recta a 40 km/h (mínimo
/// 1 min). Tablero MapaCoche · `eta_min`.
int driveEtaMinutes(double meters) =>
    math.max(1, (meters / 1000 * 1.3 / 40 * 60).ceil());

/// Estado de un sitio para el modo coche.
class DriveStatus {
  /// Abierto ahora, pero cierra antes de llegar (o en menos de 10 min).
  final bool closedOnArrival;

  /// «16:00» cuando [closedOnArrival].
  final String? closesAt;
  const DriveStatus(this.closedOnArrival, [this.closesAt]);
}

DriveStatus driveStatus(OpenState s, int etaMinutes) {
  if (s.isOpen && s.minutesToClose != null) {
    final left = s.minutesToClose!;
    if (left < 10 || left <= etaMinutes) {
      final at = s.closesAtMinute;
      return DriveStatus(true, at == null ? null : clockText(at));
    }
  }
  return const DriveStatus(false);
}

/// Candidatos del modo coche: solo abiertos o sin horario confirmado, por
/// cercanía; a menos de 5 km (si hay menos de 3, hasta 15 km).
List<MapSite> driveCandidates(List<MapSite> sites, {int max = 20}) {
  List<MapSite> within(double km) {
    final l = [
      for (final s in sites)
        if (s.meters != null &&
            s.meters! <= km * 1000 &&
            (s.isOpen || s.open.kind == OpenKind.unknown))
          s
    ];
    l.sort((a, b) => a.meters!.compareTo(b.meters!));
    return l;
  }

  var l = within(5);
  if (l.length < 3) l = within(15);
  return l.length > max ? l.sublist(0, max) : l;
}

String driveOpenCount(List<MapSite> cands) {
  final n = cands.where((s) => s.isOpen).length;
  return '$n ${n == 1 ? 'abierto' : 'abiertos'} cerca de ti';
}

/// «Más cerca» para la primera; «3 de 12» para el resto.
String driveCardEyebrow(int index, int total) =>
    index == 0 ? 'Más cerca' : '${index + 1} de $total';

/// Punto a [meters] por delante de (lat, lon) siguiendo [bearingDeg] (gran
/// círculo). La cámara de conducción mira ahí para que el usuario quede
/// abajo y se vea la carretera de delante.
(double, double) projectAhead(
    double lat, double lon, double bearingDeg, double meters) {
  const earthR = 6371000.0;
  final br = bearingDeg * math.pi / 180.0;
  final dr = meters / earthR;
  final lat1 = lat * math.pi / 180.0;
  final lon1 = lon * math.pi / 180.0;
  final lat2 = math.asin(math.sin(lat1) * math.cos(dr) +
      math.cos(lat1) * math.sin(dr) * math.cos(br));
  final lon2 = lon1 +
      math.atan2(math.sin(br) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2));
  return (lat2 * 180.0 / math.pi, lon2 * 180.0 / math.pi);
}

/// «16:00», «7:05».
String clockText(int minuteOfDay) =>
    '${minuteOfDay ~/ 60}:${(minuteOfDay % 60).toString().padLeft(2, '0')}';

/// Distancia legible («560 m», «1,4 km»).
String mapKm(double meters) => formatDistance(meters);
