import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/components/vignettes/list_vignette.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaReelThumbs;

/// Lógica de la lista curada (tableros «Lista curada, bocadillos de cochino»,
/// «japoneses» y «ocasiones especiales»): tema de la cabecera, datos de cada
/// tarjeta cruzando el sitio con su visita de Jonay y Joana, búsqueda y orden.

/// Tema (banda, tinta y glifo) de la lista según su viñeta: los bocadillos
/// van con las tascas, los japoneses con el lounge, las ocasiones especiales
/// con las experiencias y el brunch con el bar. Sin viñeta, el de categoría.
ListThemeKind curatedThemeKind(ListVignetteKind? vignette) =>
    switch (vignette) {
      ListVignetteKind.bocadillo => ListThemeKind.tasca,
      ListVignetteKind.japones => ListThemeKind.lounge,
      ListVignetteKind.celebracion => ListThemeKind.experiencia,
      ListVignetteKind.brunch => ListThemeKind.bar,
      null => ListThemeKind.categoria,
    };

/// «TOP» → «Top», «GUÍA» → «Guía»; lo que ya viene en caja normal se respeta.
String curatedEyebrow(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t != t.toUpperCase()) return t;
  final lower = t.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Antetítulo de la cabecera: «Guía · 6 en Tenerife» (o «· 6 sitios» si no
/// se sabe la isla).
String curatedHeaderEyebrow(String eyebrow, int count, String? island) {
  final where = island == null || island.isEmpty
      ? '$count ${count == 1 ? 'sitio' : 'sitios'}'
      : '$count en $island';
  final e = curatedEyebrow(eyebrow);
  return e.isEmpty ? where : '$e · $where';
}

const _kShortMunicipio = {
  'san cristobal de la laguna': 'La Laguna',
  'santa cruz de tenerife': 'Santa Cruz',
  'las palmas de gran canaria': 'Las Palmas',
  'la victoria de acentejo': 'La Victoria',
  'la matanza de acentejo': 'La Matanza',
  'san bartolome de tirajana': 'San Bartolomé',
  'granadilla de abona': 'Granadilla',
  'san miguel de abona': 'San Miguel',
  'santiago del teide': 'Santiago del Teide',
};

/// Municipio en forma corta («Santa Cruz», «La Laguna») y en tipo título.
String shortMunicipio(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  return _kShortMunicipio[fold(t)] ?? gmDisplayName(t);
}

/// «≈ 11 €», «≈ 11,60 €»; `null` sin precio.
String? formatPriceApprox(double? price) {
  if (price == null || price <= 0) return null;
  final whole = price == price.roundToDouble();
  final n = whole
      ? price.toInt().toString()
      : price.toStringAsFixed(2).replaceAll('.', ',');
  return '≈ $n €';
}

/// Minúsculas sin tildes, para buscar.
String fold(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  var out = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

/// La visita más reciente de Jonay y Joana a ese sitio (por fecha del vídeo).
Visit? latestVisitFor(String restaurantId, Iterable<Visit> visits) {
  Visit? best;
  for (final v in visits) {
    if (v.restaurantId != restaurantId) continue;
    if (best == null || (v.sortDate ?? '').compareTo(best.sortDate ?? '') > 0) {
      best = v;
    }
  }
  return best;
}

/// Datos ya resueltos de una tarjeta de la lista.
class CuratedPlace {
  final CuratedListItem item;
  final Visit? visit;

  /// Puesto en la guía (1-based sobre la lista completa).
  final int rank;
  final String name;
  final String? note;
  final String? zone;
  final String? price;

  /// Foto principal y alternativas por si falla (portada del vídeo en S3,
  /// fotogramas de YouTube y, al final, la foto del local).
  final String? photo;
  final List<String> photoFallbacks;

  const CuratedPlace({
    required this.item,
    required this.visit,
    required this.rank,
    required this.name,
    required this.note,
    required this.zone,
    required this.price,
    required this.photo,
    required this.photoFallbacks,
  });

  bool get hasVideo => visit != null;
  String get restaurantId => item.restaurantId;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Une cada sitio de la lista con su visita. La nota de la guía manda; si no
/// hay, el primer plato que probaron y, si tampoco, lo mejor del vídeo.
List<CuratedPlace> curatedPlaces(
    List<CuratedListItem> items, Iterable<Visit> visits) {
  final ordered = [...items]..sort((a, b) => a.position.compareTo(b.position));
  return [
    for (final (i, it) in ordered.indexed)
      () {
        final v = latestVisitFor(it.restaurantId, visits);
        final r = it.restaurant;
        final note = (it.note ?? '').trim().isNotEmpty
            ? it.note!.trim()
            : (v?.dishes.isNotEmpty ?? false)
                ? _capitalize(v!.dishes.first.name.trim())
                : (v?.highlights.isNotEmpty ?? false)
                    ? _capitalize(v!.highlights.first.trim())
                    : null;
        final muni = r?.municipio ?? v?.zone;
        final photos = v != null
            ? fichaReelThumbs(v, venuePhoto: r?.mainFoto)
            : [if ((r?.mainFoto ?? '').isNotEmpty) r!.mainFoto!];
        return CuratedPlace(
          item: it,
          visit: v,
          rank: i + 1,
          name: gmDisplayName(r?.nombre ?? v?.name ?? ''),
          note: note,
          zone:
              muni == null || muni.trim().isEmpty ? null : shortMunicipio(muni),
          price: formatPriceApprox(v?.priceApprox),
          photo: photos.isEmpty ? null : photos.first,
          photoFallbacks: photos.skip(1).toList(),
        );
      }(),
  ];
}

enum CuratedSort { byRank, alphabetical }

/// Filtra por búsqueda (nombre, zona, nota y platos del vídeo; sin tildes,
/// todas las palabras) y por municipio, y ordena.
List<CuratedPlace> filterCuratedPlaces(
  List<CuratedPlace> places, {
  String query = '',
  String? zone,
  CuratedSort sort = CuratedSort.byRank,
}) {
  final tokens =
      fold(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final out = places.where((p) {
    if (zone != null && p.zone != zone) return false;
    if (tokens.isEmpty) return true;
    final hay = fold([
      p.name,
      p.zone ?? '',
      p.note ?? '',
      p.item.restaurant?.municipio ?? '',
      ...?p.visit?.dishes.map((d) => d.name),
    ].join(' '));
    return tokens.every(hay.contains);
  }).toList();
  switch (sort) {
    case CuratedSort.byRank:
      out.sort((a, b) => a.rank.compareTo(b.rank));
    case CuratedSort.alphabetical:
      out.sort((a, b) => fold(a.name).compareTo(fold(b.name)));
  }
  return out;
}

/// Zonas de la lista para el filtro (solo si hay más de una).
List<String> curatedZones(List<CuratedPlace> places) {
  final zones = {
    for (final p in places)
      if (p.zone != null) p.zone!
  }.toList()
    ..sort((a, b) => fold(a).compareTo(fold(b)));
  return zones.length > 1 ? zones : const [];
}
