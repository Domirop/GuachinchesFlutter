import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show kPriorRating, kPriorWeight;
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';

/// Lógica pura de la pestaña Listas (tablero TabListas): qué guías se ven,
/// con qué tinta, qué textos llevan y qué entra en «Mejor valorados». Sin
/// widgets.

/// Minúsculas y sin tildes/diéresis, para búsquedas tolerantes.
String listasNormalize(String s) {
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

/// Guías visibles para la isla global: activas, de esa isla o de todas
/// (`islandId == null`), en el orden editorial (`position`). Sin isla, todas.
List<CuratedList> listasGuidesForIsland(
    List<CuratedList> all, String? islandId) {
  final r = all
      .where((l) => l.enabled)
      .where((l) =>
          islandId == null || l.islandId == null || l.islandId == islandId)
      .toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  return r;
}

/// Búsqueda por palabras (todas deben aparecer) sobre título, subtítulo,
/// antetítulo y zona, sin distinguir tildes: «jonay terrazas» encuentra una
/// lista con «Terrazas» en el título y «Jonay» en el antetítulo.
List<CuratedList> listasSearchGuides(List<CuratedList> guides, String query) {
  final tokens = listasNormalize(query)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return guides;
  return guides.where((l) {
    final haystack =
        listasNormalize('${l.title} ${l.subtitle} ${l.eyebrow} ${l.location}');
    return tokens.every(haystack.contains);
  }).toList();
}

/// Tema (tinta del antetítulo) de una guía por palabras clave de su id y
/// título, como las viñetas de cabecera: bocadillos → tasca, japoneses o
/// sushi → lounge, ocasiones especiales → experiencia, brunch → bar; el
/// resto, el tema neutro de categoría.
ListThemeKind listasThemeForGuide(CuratedList l) {
  final s = listasNormalize('${l.id} ${l.title}');
  if (s.contains('brunch')) return ListThemeKind.bar;
  if (s.contains('bocadillo')) return ListThemeKind.tasca;
  if (s.contains('japon') || s.contains('sushi')) return ListThemeKind.lounge;
  if (s.contains('especial') ||
      s.contains('aniversario') ||
      s.contains('celebra') ||
      s.contains('cumple')) {
    return ListThemeKind.experiencia;
  }
  return ListThemeKind.categoria;
}

/// «RUTA» → «Ruta»; lo que ya viene en caja mixta se respeta.
String listasSentence(String s) {
  final t = s.trim();
  if (t.isEmpty || t != t.toUpperCase() || t == t.toLowerCase()) return t;
  return t[0] + t.substring(1).toLowerCase();
}

/// «1 sitio» / «7 sitios».
String listasCountLabel(int n) => n == 1 ? '1 sitio' : '$n sitios';

/// Antetítulo de la guía destacada: «Top · Toda la isla».
String listasFeaturedEyebrow(CuratedList l) {
  final parts = [
    listasSentence(l.eyebrow),
    l.location.trim(),
  ].where((p) => p.isNotEmpty);
  return parts.join(' · ');
}

/// Antetítulo de una guía en fila: «Guía · 6 sitios».
String listasRowEyebrow(CuratedList l) {
  final parts = [
    listasSentence(l.eyebrow),
    if (l.count > 0) listasCountLabel(l.count),
  ].where((p) => p.isNotEmpty);
  return parts.join(' · ');
}

const _kDays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// «Para ahora · miércoles, 9:15».
String listasParaAhoraEyebrow(DateTime now) =>
    'Para ahora · ${_kDays[now.weekday - 1]}, '
    '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

/// Subtítulo de la tarjeta «Para ahora»: el del tema de la franja (el
/// desayuno cambia el fin de semana).
String listasParaAhoraSubtitle(ListThemeKind k, DateTime now) =>
    k == ListThemeKind.desayuno
        ? breakfastSubtitle(now)
        : (kListThemes[k] ?? kListThemes[ListThemeKind.buscar]!).subtitle;

/// «1 sitio guardado» / «5 sitios guardados».
String listasSavedTitle(int n) =>
    n == 1 ? '1 sitio guardado' : '$n sitios guardados';

/// Hasta [max] fotos de los guardados que ya están en los sitios cargados
/// (sin pedir nada a la red). Vacío si no hay ninguna.
List<String> listasSavedPhotos(Set<String> saved, List<Restaurant> pool,
    {int max = 3}) {
  final out = <String>[];
  for (final r in pool) {
    if (out.length >= max) break;
    if (saved.contains(r.id) && r.mainFoto.trim().isNotEmpty) {
      out.add(r.mainFoto);
    }
  }
  return out;
}

/// Mínimo de reseñas para entrar en un ranking (Sistema §8).
const int kListasMinReviews = 10;

/// Reseñas de un sitio del ranking del servidor: `counter` es
/// `count(reseñas) · media`, así que n = counter / media.
int listasTopReviewCount(TopRestaurants t) {
  final sum = double.tryParse(t.counter.trim()) ?? 0;
  if (t.avg <= 0 || sum <= 0) return 0;
  return (sum / t.avg).round();
}

/// «Mejor valorados de <isla>»: solo sitios con 10 reseñas o más, de la isla
/// (los que están en [islandIds], los sitios ya cargados de esa isla; si aún
/// no hay ninguno cargado no se filtra), ordenados con el mismo peso que las
/// listas: (10 · 4,3 + Σ notas) / (10 + n).
List<TopRestaurants> listasTopRated(
    List<TopRestaurants> top, Set<String> islandIds) {
  double weighted(TopRestaurants t) {
    final n = listasTopReviewCount(t);
    final sum = double.tryParse(t.counter.trim()) ?? 0;
    return (kPriorWeight * kPriorRating + sum) / (kPriorWeight + n);
  }

  final list = top
      .where((t) => islandIds.isEmpty || islandIds.contains(t.id))
      .where((t) => listasTopReviewCount(t) >= kListasMinReviews)
      .toList();
  list.sort((a, b) => weighted(b).compareTo(weighted(a)));
  return list;
}
