import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show kPriorRating, kPriorWeight;
import 'package:guachinches/ui/pages/listas/listas_logic.dart'
    show
        kListasMinReviews,
        listasNormalize,
        listasTopRated,
        listasTopReviewCount;
import 'package:guachinches/ui/theme/gm_widgets.dart' show GmRating;

/// Lógica pura de «Mejor valorados» (tablero MejorValorados): reparto entre
/// ranking (≥ 10 reseñas) y «Aún con pocas reseñas», qué sitios son de cada
/// isla y los textos. Sin widgets.

/// Puntuación ponderada `(10 · 4,3 + Σ notas) / (10 + n)`.
double topRatedScore(TopRestaurants t) {
  final n = listasTopReviewCount(t);
  final sum = double.tryParse(t.counter.trim()) ?? 0;
  return (kPriorWeight * kPriorRating + sum) / (kPriorWeight + n);
}

class TopRatedSplit {
  /// Con 10 reseñas o más, por puntuación ponderada (medalla / «Nº»).
  final List<TopRestaurants> ranked;

  /// Con 1–9 reseñas, mismo orden, sin número.
  final List<TopRestaurants> few;

  const TopRatedSplit({required this.ranked, required this.few});

  static const empty = TopRatedSplit(ranked: [], few: []);

  bool get isEmpty => ranked.isEmpty;
}

/// Reparte los sitios de una isla: el ranking reutiliza `listasTopRated`
/// (mismo filtro y orden que la pestaña Listas); los de 1–9 reseñas van
/// aparte con el mismo orden. Sin reseñas no entran en ningún lado.
TopRatedSplit topRatedSplit(List<TopRestaurants> island) {
  final ranked = listasTopRated(island, const {});
  final few = island.where((t) {
    final n = listasTopReviewCount(t);
    return n >= 1 && n < kListasMinReviews;
  }).toList()
    ..sort((a, b) => topRatedScore(b).compareTo(topRatedScore(a)));
  return TopRatedSplit(ranked: ranked, few: few);
}

// ─────────────────────────────────────────────────────────────────────
// ¿De qué isla es cada sitio?
// ─────────────────────────────────────────────────────────────────────

/// Municipios oficiales de cada isla (por clave `TF`, `GC`…). El ranking del
/// servidor no trae la isla, solo `municipio`, escrito de muchas maneras
/// («La Orotava», «OROTAVA», «San Cristóbal de La Laguna», «LA LAGUNA»…);
/// los barrios que vienen de `/areas/islands/:id` («LOS CRISTIANOS»,
/// «BAJAMAR»…) se suman a la isla pedida.
const Map<String, List<String>> kTopRatedIslandMunicipalities = {
  'TF': [
    'Adeje',
    'Arafo',
    'Arico',
    'Arona',
    'Buenavista del Norte',
    'Candelaria',
    'El Rosario',
    'El Sauzal',
    'El Tanque',
    'Fasnia',
    'Garachico',
    'Granadilla de Abona',
    'Guía de Isora',
    'Güímar',
    'Icod de los Vinos',
    'La Guancha',
    'La Matanza de Acentejo',
    'La Orotava',
    'La Victoria de Acentejo',
    'Los Realejos',
    'Los Silos',
    'Puerto de la Cruz',
    'San Cristóbal de La Laguna',
    'San Juan de la Rambla',
    'San Miguel de Abona',
    'Santa Cruz de Tenerife',
    'Santa Úrsula',
    'Santiago del Teide',
    'Tacoronte',
    'Tegueste',
    'Vilaflor de Chasna',
  ],
  'GC': [
    'Agaete',
    'Agüimes',
    'Artenara',
    'Arucas',
    'Firgas',
    'Gáldar',
    'Ingenio',
    'La Aldea de San Nicolás',
    'Las Palmas de Gran Canaria',
    'Mogán',
    'Moya',
    'San Bartolomé de Tirajana',
    'Santa Brígida',
    'Santa Lucía de Tirajana',
    'Santa María de Guía de Gran Canaria',
    'Tejeda',
    'Telde',
    'Teror',
    'Valsequillo de Gran Canaria',
    'Valleseco',
    'Vega de San Mateo',
  ],
  'LZ': [
    'Arrecife',
    'Haría',
    'San Bartolomé',
    'Teguise',
    'Tías',
    'Tinajo',
    'Yaiza',
  ],
  'FV': [
    'Antigua',
    'Betancuria',
    'La Oliva',
    'Pájara',
    'Puerto del Rosario',
    'Tuineje',
  ],
  'LP': [
    'Barlovento',
    'Breña Alta',
    'Breña Baja',
    'El Paso',
    'Fuencaliente de La Palma',
    'Garafía',
    'Los Llanos de Aridane',
    'Puntagorda',
    'Puntallana',
    'San Andrés y Sauces',
    'Santa Cruz de La Palma',
    'Tazacorte',
    'Tijarafe',
    'Villa de Mazo',
  ],
  'GO': [
    'Agulo',
    'Alajeró',
    'Hermigua',
    'San Sebastián de La Gomera',
    'Valle Gran Rey',
    'Vallehermoso',
  ],
  'EH': ['El Pinar de El Hierro', 'Frontera', 'Valverde'],
};

/// Nombre comparable: minúsculas, sin tildes ni signos, espacios simples
/// («ANAGA.» → «anaga», «La Esperanza -La Laguna» → «la esperanza la laguna»).
String topRatedNormalizePlace(String s) => listasNormalize(s)
    .replaceAll(RegExp(r'[^a-z0-9ñ]+'), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

bool _containsWords(String haystack, String needle) =>
    ' $haystack '.contains(' $needle ');

/// Parecido entre un `municipio` y una lista de nombres: exacto gana a todo;
/// si uno contiene al otro por palabras enteras («la orotava» ⊃ «orotava»)
/// cuenta el largo del más corto. 0 = nada que ver.
int _score(String place, Iterable<String> names) {
  var best = 0;
  for (final raw in names) {
    final m = topRatedNormalizePlace(raw);
    if (m.isEmpty) continue;
    if (m == place) return 100000;
    if (_containsWords(place, m) || _containsWords(m, place)) {
      final l = place.length < m.length ? place.length : m.length;
      if (l > best) best = l;
    }
  }
  return best;
}

/// Isla (clave) de un `municipio`, o `null` si no se reconoce o empata entre
/// islas. [extra] suma nombres por isla (barrios de `/areas/islands/:id`).
/// Se elige la isla con el parecido más fuerte, así «Santa Cruz de La Palma»
/// no cae en Tenerife por «SANTA CRUZ» ni «San Bartolomé de Tirajana» en
/// Lanzarote por «San Bartolomé».
String? topRatedIslandOf(String municipio,
    {Map<String, List<String>> extra = const {}}) {
  final place = topRatedNormalizePlace(municipio);
  if (place.isEmpty) return null;
  String? winner;
  var best = 0;
  var tie = false;
  for (final e in kTopRatedIslandMunicipalities.entries) {
    final s = _score(place, [...e.value, ...?extra[e.key]]);
    if (s > best) {
      best = s;
      winner = e.key;
      tie = false;
    } else if (s == best && s > 0) {
      tie = true;
    }
  }
  return tie ? null : winner;
}

/// Sitios del ranking global que son de la isla [islandKey].
List<TopRestaurants> topRatedForIsland(
  List<TopRestaurants> top,
  String islandKey, {
  List<String> areaNames = const [],
}) {
  final key = islandKey.trim().toUpperCase();
  final extra = {key: areaNames};
  return top
      .where((t) => topRatedIslandOf(t.municipio, extra: extra) == key)
      .toList();
}

/// Nombre para pintar. `TopRestaurants` llega con `capitalize()` del modelo
/// («Guachinche el fogon», «La huerta de ana y eva»): se pasa a tipo título
/// salvo los enlaces («de», «del», «y»…), que no sean la primera palabra.
/// Lo que ya trae mayúsculas internas («McDonald's») se respeta.
String topRatedDisplayName(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return s;
  const small = {'de', 'del', 'y', 'e', 'a', 'al', 'en', 'con'};
  final letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
  var first = true;
  return s.split(' ').map((w) {
    if (w.isEmpty) return w;
    final isFirst = first;
    first = false;
    final lower = w.toLowerCase();
    if (w != lower && w.substring(1) != w.substring(1).toLowerCase()) {
      return w; // mayúsculas internas: viene bien escrito
    }
    if (!isFirst && small.contains(lower)) return lower;
    final k = lower.indexOf(letter);
    if (k < 0) return lower;
    return lower.substring(0, k) +
        lower[k].toUpperCase() +
        lower.substring(k + 1);
  }).join(' ');
}

// ─────────────────────────────────────────────────────────────────────
// Textos
// ─────────────────────────────────────────────────────────────────────

const String kTopRatedEyebrow = 'Valoración media ponderada';
const String kTopRatedTitle = 'Mejor valorados';
const String kTopRatedSubtitle =
    'Entran los sitios con 10 reseñas o más. Así un 5,0 con 3 reseñas no '
    'adelanta a un 4,8 con 36.';
const String kTopRatedCaption =
    'Reseñas de usuarios de la app. La nota media cuenta como si cada sitio '
    'partiera con 10 reseñas de 4,3.';
const String kTopRatedFewTitle = 'Aún con pocas reseñas';
const String kTopRatedFewEyebrow = 'Menos de 10, todavía no entran';
const String kTopRatedFooter =
    '¿Has comido en alguno? Tu reseña cuenta para el ranking.';
const String kTopRatedErrorTitle = 'No pudimos cargar el ranking';
const String kTopRatedErrorText = 'Revisa tu conexión e inténtalo de nuevo.';

/// Sitios de 1–9 reseñas que se ven antes de «Ver los N…».
const int kTopRatedFewPreview = 3;

/// «1 reseña» / «18 reseñas».
String topRatedReviewsLabel(int n) => n == 1 ? '1 reseña' : '$n reseñas';

/// «4,8».
String topRatedRatingLabel(double avg) => GmRating.format(avg);

/// «Ver los 118 con pocas reseñas».
String topRatedFewMoreLabel(int total) => 'Ver los $total con pocas reseñas';

String topRatedEmptyTitle(String island) =>
    'Todavía nadie llega a 10 reseñas en $island';

String topRatedEmptyText(String island) =>
    'En cuanto un sitio de la isla tenga 10 reseñas, entra aquí. Mientras, '
    'mira todos los sitios de $island.';

String topRatedSeeIslandCta(String island) => 'Ver sitios de $island';

String topRatedBackToRankingCta(String island) => 'Ver el ranking de $island';

/// Etiqueta para lectores de pantalla de una fila: «Número 1, Rincón del
/// Marinero, Arico, 5,0 estrellas, 18 reseñas».
String topRatedRowSemantics({
  int? rank,
  required String name,
  required String place,
  required double avg,
  required int reviews,
}) {
  final parts = [
    if (rank != null) 'Número $rank',
    name,
    if (place.isNotEmpty) place,
    if (avg > 0) '${topRatedRatingLabel(avg)} estrellas',
    topRatedReviewsLabel(reviews),
  ];
  return parts.join(', ');
}
