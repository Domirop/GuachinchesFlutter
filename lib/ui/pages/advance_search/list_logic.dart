import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaCategoryFeature;
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/open_state.dart';

/// Lógica pura de la lista de resultados (rediseño iOS 27 · tableros
/// ListaDesayuno / ListaTradicional / ListaPescado / ListaBuscar · Sistema
/// §08). Sin widgets: qué título, qué orden, qué etiqueta y qué recuento.

// ── Normalización ──────────────────────────────────────────────────────────

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[áà]'), 'a')
    .replaceAll(RegExp(r'[éè]'), 'e')
    .replaceAll(RegExp(r'[íì]'), 'i')
    .replaceAll(RegExp(r'[óò]'), 'o')
    .replaceAll(RegExp(r'[úùü]'), 'u')
    .trim();

/// Etiqueta limpia de una categoría («carne cabra» → «Carne de cabra»,
/// «TERRAZA» → «Terraza»), la misma que usa la ficha.
String listCategoryLabel(String raw) {
  // «Animales» (granja, cabras…) no es «Admite mascotas»: en el panel
  // saldrían dos etiquetas iguales.
  if (_norm(raw) == 'animales') return 'Con animales';
  return fichaCategoryFeature(raw).label;
}

// ── Valoración ─────────────────────────────────────────────────────────────

/// Media a priori del ranking bayesiano y su peso (reseñas «fantasma»).
const double kPriorRating = 4.3;
const int kPriorWeight = 10;

/// Reseñas con nota válida.
List<double> _ratings(Restaurant r) => [
      for (final v in r.valoraciones)
        if (double.tryParse(v.rating.replaceAll(',', '.')) case final x?)
          if (x > 0) x
    ];

int listReviewCount(Restaurant r) => _ratings(r).length;

/// Nota que se enseña: la media del backend o, si no la trae, la de las
/// reseñas. 0 si no hay ninguna.
double listDisplayRating(Restaurant r) {
  if (r.avgRating > 0) return r.avgRating;
  final rs = _ratings(r);
  if (rs.isEmpty) return 0;
  return rs.reduce((a, b) => a + b) / rs.length;
}

/// «Mejor valorados» con peso: (10 · 4,3 + Σ notas) / (10 + n). Un 5,0 con
/// una reseña no adelanta a un 4,8 con nueve.
double listWeightedRating(Restaurant r) {
  final rs = _ratings(r);
  final sum = rs.isEmpty ? 0.0 : rs.reduce((a, b) => a + b);
  return (kPriorWeight * kPriorRating + sum) / (kPriorWeight + rs.length);
}

// ── Orden ──────────────────────────────────────────────────────────────────

enum ListSort { nearby, topRated, openFirst, closesSoonest }

String listSortLabel(ListSort s) {
  switch (s) {
    case ListSort.nearby:
      return 'Cerca de ti';
    case ListSort.topRated:
      return 'Mejor valorados';
    case ListSort.openFirst:
      return 'Abiertos primero';
    case ListSort.closesSoonest:
      return 'Cierran antes';
  }
}

/// Opciones del botón de orden: sin ubicación, «Cerca de ti» deja su sitio
/// a «Cierran antes».
List<ListSort> listSortOptions({required bool hasLocation}) => hasLocation
    ? const [ListSort.nearby, ListSort.topRated, ListSort.openFirst]
    : const [ListSort.topRated, ListSort.openFirst, ListSort.closesSoonest];

/// Pie del título: solo cuando el orden no se explica solo (valoración).
String? listSortCaption(ListSort s) => s == ListSort.topRated
    ? 'Ordenados por valoración y número de reseñas.'
    : null;

/// Orden por defecto: desde «Hoy», lo cercano (o lo abierto si no hay
/// ubicación); listas de tipo, categoría o búsqueda, lo mejor valorado.
ListSort listDefaultSort(
    {required bool fromContext, required bool hasLocation}) {
  if (fromContext) return hasLocation ? ListSort.nearby : ListSort.openFirst;
  return ListSort.topRated;
}

int _openRank(OpenState s) {
  switch (s.kind) {
    case OpenKind.open:
      return 0;
    case OpenKind.closingSoon:
      return 1; // dentro de «abiertos», los que cierran pronto al final
    case OpenKind.closed:
      return 2;
    case OpenKind.unknown:
      return 3;
  }
}

/// Ordena [list]. [distance] da los metros al usuario (o `null`).
List<Restaurant> listSorted(
  List<Restaurant> list,
  ListSort sort,
  DateTime now, {
  double? Function(Restaurant r)? distance,
}) {
  final states = {for (final r in list) r.id: restaurantOpenState(r, now)};
  final weighted = {for (final r in list) r.id: listWeightedRating(r)};
  int byRating(Restaurant a, Restaurant b) {
    final c = weighted[b.id]!.compareTo(weighted[a.id]!);
    if (c != 0) return c;
    return listReviewCount(b).compareTo(listReviewCount(a));
  }

  final out = [...list];
  switch (sort) {
    case ListSort.topRated:
      out.sort(byRating);
    case ListSort.nearby:
      out.sort((a, b) {
        final da = distance?.call(a);
        final db = distance?.call(b);
        if (da == null && db == null) return byRating(a, b);
        if (da == null) return 1;
        if (db == null) return -1;
        final c = da.compareTo(db);
        return c != 0 ? c : byRating(a, b);
      });
    case ListSort.openFirst:
      out.sort((a, b) {
        final sa = states[a.id]!;
        final sb = states[b.id]!;
        final c = _openRank(sa).compareTo(_openRank(sb));
        if (c != 0) return c;
        if (sa.kind == OpenKind.closed) {
          final ma = sa.minutesToOpen ?? 1 << 30;
          final mb = sb.minutesToOpen ?? 1 << 30;
          if (ma != mb) return ma.compareTo(mb);
        }
        return byRating(a, b);
      });
    case ListSort.closesSoonest:
      out.sort((a, b) {
        final sa = states[a.id]!;
        final sb = states[b.id]!;
        final oa = sa.isOpen ? 0 : (sa.kind == OpenKind.closed ? 1 : 2);
        final ob = sb.isOpen ? 0 : (sb.kind == OpenKind.closed ? 1 : 2);
        if (oa != ob) return oa.compareTo(ob);
        if (oa == 0) {
          // 24 h (sin hora de cierre) al final de los abiertos.
          final ma = sa.minutesToClose ?? 1 << 30;
          final mb = sb.minutesToClose ?? 1 << 30;
          if (ma != mb) return ma.compareTo(mb);
        }
        return byRating(a, b);
      });
  }
  return out;
}

// ── Etiqueta de apertura ───────────────────────────────────────────────────

/// Días abreviados (la etiqueta cabe en una línea de la rejilla).
const _days = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];

String _clock(int minuteOfDay) =>
    '${minuteOfDay ~/ 60}:${(minuteOfDay % 60).toString().padLeft(2, '0')}';

/// Partes de la etiqueta de apertura: la palabra con color («Abierto»,
/// «Cierra en 20 min», «Cerrado», «Horario sin confirmar») y el resto en
/// gris («hasta 13:00», «· abre mañana a las 7:00»).
class OpenLabel {
  final OpenKind kind;
  final String lead;
  final String rest;
  const OpenLabel(this.kind, this.lead, [this.rest = '']);

  String get text => rest.isEmpty ? lead : '$lead$rest';
}

OpenLabel listOpenLabel(OpenState s) {
  switch (s.kind) {
    case OpenKind.open:
      final at = s.closesAtMinute;
      // Sin hora de cierre (24 h o solo el texto de Google): «Abierto».
      if (at == null) return const OpenLabel(OpenKind.open, 'Abierto');
      return OpenLabel(OpenKind.open, 'Abierto', ' hasta ${_clock(at)}');
    case OpenKind.closingSoon:
      return OpenLabel(
          OpenKind.closingSoon, 'Cierra en ${s.minutesToClose} min');
    case OpenKind.closed:
      final at = s.opensAtMinute;
      final days = s.opensInDays;
      if (at == null || days == null) {
        return const OpenLabel(OpenKind.closed, 'Cerrado');
      }
      final when = days == 0
          ? 'hoy'
          : days == 1
              ? 'mañana'
              : _days[s.opensGoogleDay ?? 0];
      return OpenLabel(
          OpenKind.closed, 'Cerrado', ' · abre $when ${_clock(at)}');
    case OpenKind.unknown:
      return const OpenLabel(OpenKind.unknown, 'Horario sin confirmar');
  }
}

// ── «N más» ────────────────────────────────────────────────────────────────

class LaterBreakdown {
  final int laterToday;
  final int notToday;
  final int noHours;
  const LaterBreakdown(this.laterToday, this.notToday, this.noHours);
  int get total => laterToday + notToday + noHours;
}

/// Desglose honesto de los que NO están abiertos ahora.
LaterBreakdown listLaterBreakdown(List<Restaurant> notOpen, DateTime now) {
  var later = 0, notToday = 0, noHours = 0;
  for (final r in notOpen) {
    final s = restaurantOpenState(r, now);
    if (s.isOpen) continue;
    if (s.kind == OpenKind.unknown) {
      noHours++;
    } else if (s.opensLaterToday) {
      later++;
    } else {
      notToday++;
    }
  }
  return LaterBreakdown(later, notToday, noHours);
}

String _joinEs(List<String> parts) {
  if (parts.length <= 1) return parts.join();
  return '${parts.sublist(0, parts.length - 1).join(', ')} y ${parts.last}';
}

/// («15 cafeterías más:», «8 abren más tarde, 4 ya no abren hoy y 3 sin
/// horario confirmado.»). `null` si no hay nada que contar.
(String, String)? listLaterText(LaterBreakdown b, {required String noun}) {
  if (b.total == 0) return null;
  final parts = <String>[
    if (b.laterToday > 0)
      b.laterToday == 1 ? '1 abre más tarde' : '${b.laterToday} abren más tarde',
    if (b.notToday > 0)
      b.notToday == 1 ? '1 ya no abre hoy' : '${b.notToday} ya no abren hoy',
    if (b.noHours > 0) '${b.noHours} sin horario confirmado',
  ];
  final lead = b.total == 1 ? '1 sitio más:' : '${b.total} $noun más:';
  return (lead, '${_joinEs(parts)}.');
}

// ── Filtros locales ────────────────────────────────────────────────────────

/// Filtros que se aplican en el dispositivo sobre lo que devuelve el
/// servidor (texto + tipos): así el recuento «Mostrar N resultados» es
/// inmediato y las categorías de un mismo panel suman (O), no restan (Y).
class LocalFilters {
  final Set<String> categoryIds;

  /// Municipios elegidos: claves de [listMunicipalityKey].
  final Set<String> municipalityKeys;
  final bool openOnly;

  const LocalFilters({
    this.categoryIds = const {},
    this.municipalityKeys = const {},
    this.openOnly = false,
  });
}

String listNormMunicipality(String name) => _norm(name);

/// Clave del municipio de un sitio: su id (NegocioMunicipioId o
/// `municipios.Id`) y, solo si no lo trae, el nombre normalizado. Con el id
/// no importa que se llame «La Laguna» o «San Cristóbal de La Laguna».
String listMunicipalityKey(Restaurant r) {
  final id = r.negocioMunicipioId.trim();
  if (id.isNotEmpty) return id;
  final n = _norm(r.municipio);
  return n.isEmpty ? '' : 'name:$n';
}

bool listMatches(Restaurant r, LocalFilters f, DateTime now) {
  if (f.categoryIds.isNotEmpty &&
      !r.categoriaRestaurantes.any((c) => f.categoryIds.contains(c.categoriaId))) {
    return false;
  }
  if (f.municipalityKeys.isNotEmpty &&
      !f.municipalityKeys.contains(listMunicipalityKey(r))) {
    return false;
  }
  if (f.openOnly && !restaurantOpenState(r, now).isOpen) return false;
  return true;
}

/// Filas de «Dónde»: (clave, nombre, recuento) de los municipios de
/// [base], más los ya elegidos aunque no tengan resultados. Ordenadas por
/// nombre.
List<(String, String, int)> listMunicipalityRows(
  List<Restaurant> base, {
  List<String> selected = const [],
  Map<String, String> names = const {},
}) {
  final counts = <String, int>{};
  final nameOf = <String, String>{};
  for (final r in base) {
    final k = listMunicipalityKey(r);
    if (k.isEmpty) continue;
    counts[k] = (counts[k] ?? 0) + 1;
    nameOf.putIfAbsent(k, () => listMunicipalityName(r.municipio));
  }
  for (final k in selected) {
    nameOf.putIfAbsent(k, () => names[k] ?? 'Municipio');
  }
  final rows = [
    for (final e in nameOf.entries) (e.key, e.value, counts[e.key] ?? 0)
  ]..sort((a, b) => _norm(a.$2).compareTo(_norm(b.$2)));
  return rows;
}

/// «SANTA CRUZ» → «Santa Cruz»; los nombres bien escritos se respetan.
String listMunicipalityName(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t != t.toUpperCase()) return t;
  const small = {'de', 'del', 'la', 'las', 'los', 'el', 'y'};
  var first = true;
  return t.toLowerCase().split(RegExp(r'\s+')).map((w) {
    final keep = !first && small.contains(w);
    first = false;
    return keep || w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

/// Filtros activos (botón «Filtros · N»): tipos + categorías + municipios +
/// «Abierto ahora».
int listActiveFilterCount({
  required int types,
  required int categories,
  required int municipalities,
  required bool openOnly,
}) =>
    types + categories + municipalities + (openOnly ? 1 : 0);

// ── Chip de texto de la tarjeta ────────────────────────────────────────────

/// Como mucho un chip con texto arriba a la izquierda: «Terraza» o «Admite
/// mascotas». `null` si no aplica.
String? listCardChip(Restaurant r) {
  final ids = r.categoriaRestaurantes.map((c) => c.categoriaId).toSet();
  if (ids.contains(CategoryIds.terraza)) return 'Terraza';
  if (ids.contains(CategoryIds.permiteMascotas)) return 'Admite mascotas';
  return null;
}

// ── Cabecera ───────────────────────────────────────────────────────────────

class ListHeader {
  final ListTheme theme;
  final String eyebrow;
  final String title;
  final String subtitle;
  const ListHeader(this.theme, this.eyebrow, this.title, this.subtitle);
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Qué cabecera pinta la lista. El contexto horario manda cuando se abre
/// desde «Hoy» y los filtros siguen siendo los del preset; si el usuario los
/// cambia, el título pasa al tipo, a la categoría o a «N resultados». Nunca
/// «5 TIPOS».
ListHeader resolveListHeader({
  ListThemeKind? context,
  required bool filtersArePreset,
  required List<(String id, String name)> types,
  required List<String> categoryLabels,
  required String query,
  required int? resultCount,
  int? typeTotal,
  String? islandLabel,
  required DateTime now,
}) {
  final where = (islandLabel != null && islandLabel.trim().isNotEmpty)
      ? ' en ${islandLabel.trim()}'
      : '';
  String count(int n, {String noun = 'sitios'}) =>
      n == 1 ? '1 ${noun == 'sitios' ? 'sitio' : noun}' : '$n $noun';

  if (context != null && filtersArePreset && query.trim().isEmpty) {
    final t = kListThemes[context]!;
    final sub =
        context == ListThemeKind.desayuno ? breakfastSubtitle(now) : t.subtitle;
    return ListHeader(t, contextEyebrow(context), t.title, sub);
  }

  final q = query.trim();
  // Un tipo (con o sin «Qué buscas»): manda el tipo; los extras van en los
  // chips.
  if (types.length == 1 && q.isEmpty) {
    final kind = listThemeForType(types.first.$1, types.first.$2);
    final t = kListThemes[kind ?? ListThemeKind.buscar]!;
    final n = categoryLabels.isEmpty ? (typeTotal ?? resultCount) : resultCount;
    final eyebrow = n == null ? 'Tipo' : 'Tipo · $n$where';
    return ListHeader(t, eyebrow, kind == null ? _cap(types.first.$2) : t.title,
        kind == null ? 'Nombre, zona o plato.' : t.subtitle);
  }

  if (types.isEmpty && categoryLabels.length == 1 && q.isEmpty) {
    final t = kListThemes[ListThemeKind.categoria]!;
    final label = categoryLabels.first;
    final n = resultCount;
    return ListHeader(
      t,
      n == null ? 'Qué buscas' : 'Qué buscas · ${count(n)}$where',
      label,
      'Dónde comer ${label.toLowerCase()}.',
    );
  }

  final t = kListThemes[ListThemeKind.buscar]!;
  if (types.isEmpty && categoryLabels.isEmpty) {
    return ListHeader(t, '', 'Buscar', '');
  }
  // Mezcla de filtros: el título es el recuento.
  final n = resultCount;
  return ListHeader(t, 'Con tus filtros',
      n == null ? 'Resultados' : (n == 1 ? '1 resultado' : '$n resultados'),
      '');
}

/// Antetítulo de la sección de resultados.
String listSectionEyebrow({
  ListThemeKind? context,
  required int openCount,
  required int total,
  required bool openOnly,
  String? query,
}) {
  final q = query?.trim() ?? '';
  if (q.isNotEmpty) {
    final n = total == 1 ? '1 sitio' : '$total sitios';
    return '$n · coincide «$q»';
  }
  final open = openCount == 1 ? '1 abierto ahora' : '$openCount abiertos ahora';
  if (context != null) {
    const lead = {
      ListThemeKind.desayuno: 'Hora del desayuno',
      ListThemeKind.almuerzo: 'Hora del almuerzo',
      ListThemeKind.golden: 'Golden hour',
      ListThemeKind.cena: 'Hora de la cena',
      ListThemeKind.madrugada: 'De madrugada',
    };
    return '${lead[context] ?? ''} · $open';
  }
  if (openOnly) return open;
  return '$open · $total en total';
}
