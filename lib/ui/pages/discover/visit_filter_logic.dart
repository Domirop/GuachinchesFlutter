import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Filtros de la pestaña Visitas (tablero VisitasOrdenFiltros): lo que les
/// pareció, tipo de sitio, con fotos de los platos, precio por persona y
/// municipio. Recuentos facetados, texto del botón y pista del vacío.
/// Funciones puras.

/// Precio por persona: € (< 15 €), €€ (15–30 €), €€€ (> 30 €). Sale de
/// `priceRange` («$$») o, si falta, de `priceApprox`.
enum VisitPrice { low, mid, high }

extension VisitPriceMeta on VisitPrice {
  String get label => '€' * (index + 1);
}

/// Filtros activos. Dentro de una sección se suman (O); entre secciones,
/// todas a la vez (Y).
class VisitFilterValues {
  final Set<VisitMood> moods;
  final Set<ListThemeKind> types;
  final bool withDishPhotos;
  final Set<VisitPrice> prices;

  /// Municipios en forma corta («La Laguna»), los mismos de las filas.
  final Set<String> municipios;

  const VisitFilterValues({
    this.moods = const {},
    this.types = const {},
    this.withDishPhotos = false,
    this.prices = const {},
    this.municipios = const {},
  });

  int get count =>
      moods.length +
      types.length +
      (withDishPhotos ? 1 : 0) +
      prices.length +
      municipios.length;

  VisitFilterValues copyWith({
    Set<VisitMood>? moods,
    Set<ListThemeKind>? types,
    bool? withDishPhotos,
    Set<VisitPrice>? prices,
    Set<String>? municipios,
  }) =>
      VisitFilterValues(
        moods: moods ?? this.moods,
        types: types ?? this.types,
        withDishPhotos: withDishPhotos ?? this.withDishPhotos,
        prices: prices ?? this.prices,
        municipios: municipios ?? this.municipios,
      );
}

// ── Atributos de una visita ────────────────────────────────────────────────

/// Tipo de sitio de la visita (tema de lista); `null` si no se conoce.
ListThemeKind? visitTypeKind(Visit v) {
  final id = v.restaurant?.type ?? '';
  return listThemeForType(id, restaurantTypeLabel(id));
}

/// ¿Trae foto de algún plato?
bool visitHasDishPhotos(Visit v) => v.dishes.any((d) => d.photoUrl != null);

/// Franja de precio; `null` si el vídeo no lo dice.
VisitPrice? visitPrice(Visit v) {
  final range = (v.priceRange ?? '').trim();
  final n = RegExp(r'[$€]').allMatches(range).length;
  if (n > 0) return VisitPrice.values[(n - 1).clamp(0, 2)];
  final p = v.priceApprox;
  if (p == null || p <= 0) return null;
  if (p < 15) return VisitPrice.low;
  if (p <= 30) return VisitPrice.mid;
  return VisitPrice.high;
}

// ── Coincidencia y recuentos ───────────────────────────────────────────────

enum VisitFacet { mood, type, photos, price, municipio }

bool _passes(Visit v, VisitFilterValues f, String? Function(Visit) muni,
    {VisitFacet? skip}) {
  if (skip != VisitFacet.mood &&
      f.moods.isNotEmpty &&
      !f.moods.contains(visitMoodOf(v.overallSentiment))) {
    return false;
  }
  if (skip != VisitFacet.type &&
      f.types.isNotEmpty &&
      !f.types.contains(visitTypeKind(v))) {
    return false;
  }
  if (skip != VisitFacet.photos && f.withDishPhotos && !visitHasDishPhotos(v)) {
    return false;
  }
  if (skip != VisitFacet.price &&
      f.prices.isNotEmpty &&
      !f.prices.contains(visitPrice(v))) {
    return false;
  }
  if (skip != VisitFacet.municipio &&
      f.municipios.isNotEmpty &&
      !f.municipios.contains(muni(v))) {
    return false;
  }
  return true;
}

/// ¿La visita pasa todos los filtros? [muni] da el municipio corto.
bool visitPassesFilters(
        Visit v, VisitFilterValues f, String? Function(Visit) muni) =>
    _passes(v, f, muni);

/// Recuentos al momento de cada opción: lo que saldría al marcarla, con el
/// resto de secciones como están (la propia sección no cuenta).
class VisitFacetCounts {
  final Map<VisitMood, int> moods;
  final Map<ListThemeKind, int> types;
  final int photos;
  final Map<VisitPrice, int> prices;

  /// Visitas con el precio sin decir (con los demás filtros).
  final int noPrice;

  /// Municipios con su recuento, de más a menos.
  final List<(String, int)> municipios;
  final int total;

  const VisitFacetCounts({
    required this.moods,
    required this.types,
    required this.photos,
    required this.prices,
    required this.noPrice,
    required this.municipios,
    required this.total,
  });
}

VisitFacetCounts visitFacetCounts(
  List<Visit> visits,
  VisitFilterValues f,
  String? Function(Visit) muni,
) {
  final moods = {for (final m in VisitMood.values) m: 0};
  final types = <ListThemeKind, int>{};
  final prices = {for (final p in VisitPrice.values) p: 0};
  final munis = <String, int>{};
  var photos = 0;
  var noPrice = 0;
  var total = 0;
  for (final v in visits) {
    if (_passes(v, f, muni)) total++;
    if (_passes(v, f, muni, skip: VisitFacet.mood)) {
      final m = visitMoodOf(v.overallSentiment);
      if (m != null) moods[m] = moods[m]! + 1;
    }
    if (_passes(v, f, muni, skip: VisitFacet.type)) {
      final t = visitTypeKind(v);
      if (t != null) types[t] = (types[t] ?? 0) + 1;
    }
    if (_passes(v, f, muni, skip: VisitFacet.photos) && visitHasDishPhotos(v)) {
      photos++;
    }
    if (_passes(v, f, muni, skip: VisitFacet.price)) {
      final p = visitPrice(v);
      if (p == null) {
        noPrice++;
      } else {
        prices[p] = prices[p]! + 1;
      }
    }
    if (_passes(v, f, muni, skip: VisitFacet.municipio)) {
      final m = muni(v);
      if (m != null && m.isNotEmpty) munis[m] = (munis[m] ?? 0) + 1;
    }
  }
  final muniList = munis.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  return VisitFacetCounts(
    moods: moods,
    types: types,
    photos: photos,
    prices: prices,
    noPrice: noPrice,
    municipios: muniList,
    total: total,
  );
}

/// Tipos que se ofrecen: los que hay entre las visitas (más los elegidos),
/// en el orden de la hoja de filtros de las listas.
List<ListThemeKind> visitTypeOptions(List<Visit> visits, VisitFilterValues f) {
  const order = [
    ListThemeKind.tradicional,
    ListThemeKind.restaurante,
    ListThemeKind.bar,
    ListThemeKind.moderno,
    ListThemeKind.tasca,
    ListThemeKind.bodegon,
    ListThemeKind.mercado,
    ListThemeKind.lounge,
    ListThemeKind.cofradia,
    ListThemeKind.experiencia,
  ];
  final present = {for (final v in visits) visitTypeKind(v)};
  return [
    for (final k in order)
      if (present.contains(k) || f.types.contains(k)) k
  ];
}

// ── Textos ─────────────────────────────────────────────────────────────────

/// «Filtrar visitas» / «Filtrar visitas · 2».
String visitFilterTitle(int count) =>
    count == 0 ? 'Filtrar visitas' : 'Filtrar visitas · $count';

/// Botón fijo: «Mostrar 82 visitas» / «Ninguna visita con estos filtros».
String visitFilterCta(int n) {
  if (n <= 0) return 'Ninguna visita con estos filtros';
  return n == 1 ? 'Mostrar 1 visita' : 'Mostrar $n visitas';
}

/// «29 de estas visitas no lo mencionan.»
String visitPriceCaption(int noPrice) {
  const base = 'El que dicen en el vídeo.';
  if (noPrice <= 0) return base;
  return noPrice == 1
      ? '$base 1 de estas visitas no lo menciona.'
      : '$base $noPrice de estas visitas no lo mencionan.';
}

/// Un filtro concreto que se puede quitar.
class VisitFilterChip {
  final String label;
  final VisitFilterValues without;
  const VisitFilterChip(this.label, this.without);
}

/// Cada filtro activo por separado, con los valores que quedan al quitarlo.
List<VisitFilterChip> visitActiveFilters(VisitFilterValues f) => [
      for (final m in f.moods)
        VisitFilterChip(m.label, f.copyWith(moods: {...f.moods}..remove(m))),
      for (final t in f.types)
        VisitFilterChip(kListThemes[t]?.title ?? t.name,
            f.copyWith(types: {...f.types}..remove(t))),
      if (f.withDishPhotos)
        VisitFilterChip(
            'Con fotos de los platos', f.copyWith(withDishPhotos: false)),
      for (final p in f.prices)
        VisitFilterChip(p.label, f.copyWith(prices: {...f.prices}..remove(p))),
      for (final m in f.municipios)
        VisitFilterChip(
            m, f.copyWith(municipios: {...f.municipios}..remove(m))),
    ];

/// Pista del estado sin resultados: el filtro que, al quitarlo, devuelve
/// más visitas. `null` si quitar uno solo no basta.
({String label, int count, VisitFilterValues without})? visitEmptyHint(
  List<Visit> visits,
  VisitFilterValues f,
  String? Function(Visit) muni,
) {
  ({String label, int count, VisitFilterValues without})? best;
  for (final c in visitActiveFilters(f)) {
    final n = visits.where((v) => _passes(v, c.without, muni)).length;
    if (n > 0 && (best == null || n > best.count)) {
      best = (label: c.label, count: n, without: c.without);
    }
  }
  return best;
}

/// «Ninguna visita cumple todos los filtros. Quita «Regular» y verás 13
/// visitas.»
String visitEmptyHintText(String label, int count) {
  final seen = count == 1 ? 'verás 1 visita' : 'verás $count visitas';
  return 'Ninguna visita cumple todos los filtros. Quita «$label» y $seen.';
}
