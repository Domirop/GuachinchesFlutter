import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/discover/widgets/sort_sheet.dart';
import 'package:guachinches/ui/pages/discover/visit_filter_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaNamedDishes;
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/utils/island_bounds.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Lógica de presentación de la pestaña Visitas (tablero TabVisitas):
/// isla de cada visita, recuentos, búsqueda/filtros/orden, agrupado por mes,
/// «Lo que más piden» y la sugerencia del estado vacío. Funciones puras.

// ── Normalización ──────────────────────────────────────────────────────────

/// Minúsculas y sin tildes/diéresis («José» ≈ «jose», «Añaza» ≈ «anaza»),
/// para que buscar no dependa de escribir los acentos.
String discoverNormalize(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñçºª';
  const to = 'aaaaaeeeeiiiiooooouuuunc  ';
  final buf = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final idx = from.indexOf(ch);
    buf.write(idx >= 0 ? to[idx] : ch);
  }
  return buf.toString();
}

// ── Isla de cada visita ────────────────────────────────────────────────────

/// `key` de isla (TF, GC…) de una visita, con la referencia fiable:
///  1. `municipios.islandId` del negocio, traducido a `key` con
///     [islandIdToKey] (las islas del backend).
///  2. Si falta (o no se conoce ese id), la isla de sus lat/lon.
/// `null` si no se puede ubicar: esas visitas no se cuelan en ninguna isla.
///
/// (El endpoint de visitas no manda `restaurant.island`, por eso no se usa.)
String? discoverVisitIslandKey(Visit v, Map<String, String> islandIdToKey) {
  final r = v.restaurant;
  if (r == null) return null;
  final muniIsland = r.municipioIslandId;
  if (muniIsland != null && muniIsland.isNotEmpty) {
    final key = islandIdToKey[muniIsland];
    if (key != null && key.isNotEmpty) return key.toUpperCase();
  }
  if (r.lat != 0.0 || r.lon != 0.0) return islandKeyAt(r.lat, r.lon);
  return null;
}

/// Visitas de la isla [islandKey].
List<Visit> discoverVisitsOfIsland(
  List<Visit> visits,
  String islandKey,
  Map<String, String> islandIdToKey,
) {
  final wanted = islandKey.toUpperCase();
  return [
    for (final v in visits)
      if (discoverVisitIslandKey(v, islandIdToKey) == wanted) v
  ];
}

/// Visitas por isla (`key` → recuento). Las que no se ubican no cuentan.
Map<String, int> discoverIslandCounts(
  List<Visit> visits,
  Map<String, String> islandIdToKey,
) {
  final out = <String, int>{};
  for (final v in visits) {
    final k = discoverVisitIslandKey(v, islandIdToKey);
    if (k != null) out[k] = (out[k] ?? 0) + 1;
  }
  return out;
}

/// Isla del backend reducida a lo que pinta un chip.
class DiscoverIsland {
  final String id;
  final String key;
  final String label;
  const DiscoverIsland({
    required this.id,
    required this.key,
    required this.label,
  });
}

/// Chip de isla: «Tenerife 297».
class DiscoverIslandChip {
  final DiscoverIsland island;
  final int count;
  final bool selected;
  const DiscoverIslandChip({
    required this.island,
    required this.count,
    required this.selected,
  });
}

/// Un chip por isla con al menos una visita, de más a menos visitas (a
/// igualdad, en el orden del backend). La isla elegida siempre aparece,
/// aunque no tenga visitas, para que se vea dónde estás.
List<DiscoverIslandChip> discoverIslandChips(
  List<DiscoverIsland> islands,
  Map<String, int> counts,
  String selectedKey,
) {
  final sel = selectedKey.toUpperCase();
  final indexed = [
    for (var i = 0; i < islands.length; i++)
      if ((counts[islands[i].key.toUpperCase()] ?? 0) > 0 ||
          islands[i].key.toUpperCase() == sel)
        (i, islands[i]),
  ];
  indexed.sort((a, b) {
    final ca = counts[a.$2.key.toUpperCase()] ?? 0;
    final cb = counts[b.$2.key.toUpperCase()] ?? 0;
    if (ca != cb) return cb.compareTo(ca);
    return a.$1.compareTo(b.$1);
  });
  return [
    for (final (_, island) in indexed)
      DiscoverIslandChip(
        island: island,
        count: counts[island.key.toUpperCase()] ?? 0,
        selected: island.key.toUpperCase() == sel,
      ),
  ];
}

/// Isla con más visitas que no sea [excludeKey]; `null` si no hay otra.
String? discoverTopIsland(Map<String, int> counts, String excludeKey) {
  final ex = excludeKey.toUpperCase();
  String? best;
  var bestN = 0;
  for (final e in counts.entries) {
    if (e.key == ex || e.value <= 0) continue;
    if (e.value > bestN) {
      best = e.key;
      bestN = e.value;
    }
  }
  return best;
}

// ── Cabecera ───────────────────────────────────────────────────────────────

/// Sitios distintos (por negocio) entre las visitas.
int discoverPlaceCount(List<Visit> visits) => {
      for (final v in visits)
        v.restaurantId.isNotEmpty
            ? v.restaurantId
            : (v.restaurant?.id.isNotEmpty == true ? v.restaurant!.id : v.id)
    }.length;

/// «297 vídeos en 232 sitios de Tenerife».
String discoverSubtitle(List<Visit> islandVisits, String islandLabel) {
  final n = islandVisits.length;
  if (n == 0) return 'Aún sin vídeos en $islandLabel';
  final places = discoverPlaceCount(islandVisits);
  final videos = n == 1 ? '1 vídeo' : '$n vídeos';
  final sites = places == 1 ? '1 sitio' : '$places sitios';
  return '$videos en $sites de $islandLabel';
}

// ── Fechas ─────────────────────────────────────────────────────────────────

const _monthNames = [
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

DateTime? discoverVisitDate(Visit v) =>
    DateTime.tryParse(v.sortDate ?? '')?.toLocal();

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// «1 visita» / «5 visitas».
String discoverVisitCount(int n) => n == 1 ? '1 visita' : '$n visitas';

/// Las [n] visitas más recientes por la fecha del vídeo.
List<Visit> discoverLatest(List<Visit> visits, {int n = 3}) =>
    discoverSort(visits, VisitSort.newest).take(n).toList();

/// «5 visitas en octubre»: visitas del mes (y año) de la más reciente.
/// `null` si ninguna tiene fecha.
String? discoverLatestEyebrow(List<Visit> visits) {
  DateTime? newest;
  for (final v in visits) {
    final d = discoverVisitDate(v);
    if (d != null && (newest == null || d.isAfter(newest))) newest = d;
  }
  if (newest == null) return null;
  final n = visits.where((v) {
    final d = discoverVisitDate(v);
    return d != null && d.year == newest!.year && d.month == newest.month;
  }).length;
  return '${discoverVisitCount(n)} en ${_monthNames[newest.month - 1]}';
}

/// Grupo de la lista «Todas las visitas».
class DiscoverGroup {
  /// «Octubre de 2026 · 5 visitas»; `null` = sin título (un solo grupo).
  final String? caption;
  final List<Visit> visits;
  const DiscoverGroup({required this.caption, required this.visits});
}

/// Agrupa por mes de `sortDate` respetando el orden recibido (ya ordenado
/// por fecha). Las visitas sin fecha van juntas en «Sin fecha».
List<DiscoverGroup> discoverMonthGroups(List<Visit> sorted) {
  final groups = <(String, List<Visit>)>[];
  for (final v in sorted) {
    final d = discoverVisitDate(v);
    final label = d == null
        ? 'Sin fecha'
        : '${_cap(_monthNames[d.month - 1])} de ${d.year}';
    if (groups.isNotEmpty && groups.last.$1 == label) {
      groups.last.$2.add(v);
    } else {
      groups.add((label, [v]));
    }
  }
  return [
    for (final (label, list) in groups)
      DiscoverGroup(
          caption: '$label · ${discoverVisitCount(list.length)}', visits: list),
  ];
}

/// Grupos de «Todas las visitas»: por mes si se ordena por fecha; si no, uno
/// solo sin título.
List<DiscoverGroup> discoverGroups(List<Visit> sorted, VisitSort sort) {
  if (sorted.isEmpty) return const [];
  if (sort == VisitSort.newest || sort == VisitSort.oldest) {
    return discoverMonthGroups(sorted);
  }
  return [DiscoverGroup(caption: null, visits: sorted)];
}

/// Antetítulo de «Todas las visitas» según el orden.
String discoverListEyebrow(VisitSort sort) {
  switch (sort) {
    case VisitSort.newest:
    case VisitSort.oldest:
      return 'Por fecha del vídeo';
    case VisitSort.ratingDesc:
      return 'Según lo que dicen en el vídeo';
    case VisitSort.nearest:
      return 'Por distancia';
    case VisitSort.alphaAsc:
      return 'Por nombre';
  }
}

/// «1 resultado» / «12 resultados».
String discoverResultsEyebrow(int n) =>
    n == 1 ? '1 resultado' : '$n resultados';

// ── Filas ──────────────────────────────────────────────────────────────────

/// Nombre del sitio en tipo título (el del negocio; si falta, el de la
/// visita).
String discoverVisitName(Visit v) {
  final r = v.restaurant?.nombre.trim() ?? '';
  final raw = r.isNotEmpty ? r : (v.name?.trim() ?? '');
  return gmDisplayName(raw);
}

/// Municipios largos que se acortan en filas y portadas.
const _shortMunicipios = {
  'santa cruz de tenerife': 'Santa Cruz',
  'san cristobal de la laguna': 'La Laguna',
  'las palmas de gran canaria': 'Las Palmas',
  'la victoria de acentejo': 'La Victoria',
  'la matanza de acentejo': 'La Matanza',
  'santa maria de guia de gran canaria': 'Guía',
  'santa maria de guia': 'Guía',
  'san bartolome de tirajana': 'San Bartolomé',
  'san miguel de abona': 'San Miguel',
  'santiago del teide': 'Santiago del Teide',
};

/// Municipio de la visita en tipo título y abreviado («Santa Cruz»,
/// «La Laguna»). `null` si no hay dato.
String? discoverShortMunicipio(Visit v) {
  final raw = (v.restaurant?.municipio.trim().isNotEmpty == true
          ? v.restaurant!.municipio
          : v.zone ?? '')
      .trim();
  if (raw.isEmpty) return null;
  return _shortMunicipios[discoverNormalize(raw)] ?? gmPlaceName(raw);
}

/// Tipo del local en singular («Bodegón»); `null` si no se conoce.
String? discoverTypeLabel(Visit v) {
  final t = restaurantTypeLabel(v.restaurant?.type);
  return t.isEmpty ? null : t;
}

/// «Churritos de pescado, Favada y 4 más»: hasta tres platos se nombran
/// todos; con más, los dos primeros y «y N más». `null` sin platos.
String? discoverDishLine(Visit v) {
  final names = [
    for (final d in fichaNamedDishes(v)) _cap(d.name.trim()),
  ];
  if (names.isEmpty) return null;
  if (names.length == 1) return names.first;
  if (names.length <= 3) {
    return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  }
  return '${names[0]}, ${names[1]} y ${names.length - 2} más';
}

// ── «Lo que más piden» ─────────────────────────────────────────────────────

/// Platos estrella que salen en los vídeos.
enum DiscoverDish {
  cabra('Cabra', 'cabra'),
  cochino('Cochino', 'cochino'),
  vieja('Vieja', 'vieja'),
  barraquito('Barraquito', 'barraquito');

  final String label;

  /// Palabra que se escribe en el buscador al tocar la tarjeta.
  final String query;
  const DiscoverDish(this.label, this.query);
}

final _viejaWord = RegExp(r'(^|[^a-z])vieja($|[^a-z])');

/// ¿El nombre del plato es de [kind]? Sin tildes ni mayúsculas. «Cabra»
/// excluye el queso de cabra; «vieja» (el pescado) va como palabra suelta y
/// excluye la «ropa vieja», que es otro plato.
bool discoverDishMatches(DiscoverDish kind, String dishName) {
  final n = discoverNormalize(dishName);
  switch (kind) {
    case DiscoverDish.cabra:
      return n.contains('cabra') && !n.contains('queso');
    case DiscoverDish.cochino:
      return n.contains('cochino');
    case DiscoverDish.vieja:
      return _viejaWord.hasMatch(n) && !n.contains('ropa vieja');
    case DiscoverDish.barraquito:
      return n.contains('barraquito');
  }
}

/// Visitas con al menos un plato de cada tipo.
Map<DiscoverDish, int> discoverDishCounts(List<Visit> visits) => {
      for (final kind in DiscoverDish.values)
        kind: visits
            .where(
                (v) => v.dishes.any((d) => discoverDishMatches(kind, d.name)))
            .length,
    };

// ── Búsqueda, filtros y orden ──────────────────────────────────────────────

/// ¿Hay búsqueda o filtros activos?
bool discoverIsFiltering(String query, VisitFilterValues filters) =>
    query.trim().isNotEmpty || filters.count > 0;

/// ¿La visita pasa los filtros y la búsqueda? La búsqueda va por palabras
/// (todas deben aparecer, en cualquier orden y sin tildes): «carne tegueste»
/// encuentra una visita con plato «carne» en Tegueste.
bool discoverMatches(Visit v, String query, VisitFilterValues filters) {
  if (!visitPassesFilters(v, filters, discoverShortMunicipio)) return false;
  final tokens = discoverNormalize(query)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return true;
  final haystack = discoverNormalize([
    v.creator,
    v.name,
    v.restaurant?.nombre,
    v.zone,
    v.restaurant?.municipio,
    v.summary,
    v.extraText,
    ...v.highlights,
    ...v.dishes.map((d) => d.name),
    ...v.quotes.map((qt) => qt.text),
  ].where((e) => e != null && e.isNotEmpty).join(' '));
  return tokens.every(haystack.contains);
}

/// Punto desde el que se mide «Más cerca de ti».
typedef DiscoverOrigin = ({double lat, double lon});

/// Distancia en metros de [origin] al sitio de la visita; `null` sin
/// coordenadas.
double? discoverDistanceMeters(Visit v, DiscoverOrigin origin) {
  final r = v.restaurant;
  if (r == null || (r.lat == 0.0 && r.lon == 0.0)) return null;
  return haversineDistanceMeters(origin.lat, origin.lon, r.lat, r.lon);
}

/// Copia ordenada según [sort]. «Más cerca de ti» necesita [origin] (sin
/// ubicación se queda por fecha); las visitas sin coordenadas van al final.
List<Visit> discoverSort(List<Visit> visits, VisitSort sort,
    {DiscoverOrigin? origin}) {
  final list = [...visits];
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime date(Visit v) => DateTime.tryParse(v.sortDate ?? '') ?? epoch;
  String name(Visit v) =>
      (v.name?.isNotEmpty == true ? v.name! : v.restaurant?.nombre ?? '')
          .toLowerCase();
  switch (sort) {
    case VisitSort.newest:
      list.sort((a, b) => date(b).compareTo(date(a)));
    case VisitSort.oldest:
      list.sort((a, b) => date(a).compareTo(date(b)));
    case VisitSort.ratingDesc:
      list.sort(
          (a, b) => (b.ratingImplicit ?? 0).compareTo(a.ratingImplicit ?? 0));
    case VisitSort.nearest:
      if (origin == null) {
        list.sort((a, b) => date(b).compareTo(date(a)));
        break;
      }
      final dist = {
        for (final v in list) v.id: discoverDistanceMeters(v, origin)
      };
      list.sort((a, b) {
        final da = dist[a.id];
        final db = dist[b.id];
        if (da == null && db == null) return date(b).compareTo(date(a));
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    case VisitSort.alphaAsc:
      list.sort((a, b) =>
          discoverNormalize(name(a)).compareTo(discoverNormalize(name(b))));
  }
  return list;
}

/// Búsqueda + filtros + orden.
List<Visit> discoverApply(
  List<Visit> visits, {
  required String query,
  required VisitFilterValues filters,
  required VisitSort sort,
  DiscoverOrigin? origin,
}) =>
    discoverSort(
      [
        for (final v in visits)
          if (discoverMatches(v, query, filters)) v
      ],
      sort,
      origin: origin,
    );

// ── Estado vacío ───────────────────────────────────────────────────────────

/// Otra isla donde la búsqueda/filtros sí encuentran algo.
class DiscoverSuggestion {
  final String islandKey;
  final int count;
  const DiscoverSuggestion({required this.islandKey, required this.count});
}

/// La isla (distinta de [currentKey]) con más visitas que pasan la búsqueda
/// y los filtros; `null` si en ninguna otra hay.
DiscoverSuggestion? discoverEmptySuggestion(
  List<Visit> allVisits, {
  required String currentKey,
  required String query,
  required VisitFilterValues filters,
  required Map<String, String> islandIdToKey,
}) {
  final matches = [
    for (final v in allVisits)
      if (discoverMatches(v, query, filters)) v
  ];
  final counts = discoverIslandCounts(matches, islandIdToKey);
  final best = discoverTopIsland(counts, currentKey);
  if (best == null) return null;
  return DiscoverSuggestion(islandKey: best, count: counts[best]!);
}

/// Título del estado vacío de búsqueda/filtros.
String discoverEmptyTitle(String query, String islandLabel) {
  final q = query.trim();
  return q.isEmpty
      ? 'Ninguna visita con estos filtros en $islandLabel'
      : 'Ninguna visita con «$q» en $islandLabel';
}

/// «En Tenerife hay 45 visitas con «pulpo».»
String discoverSuggestionText(
    String query, String otherIslandLabel, int count) {
  final q = query.trim();
  final what = q.isEmpty ? 'con estos filtros' : 'con «$q»';
  final verb = count == 1 ? 'hay 1 visita' : 'hay $count visitas';
  return 'En $otherIslandLabel $verb $what.';
}
