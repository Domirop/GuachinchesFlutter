import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show listWeightedRating;

/// Lógica pura del onboarding (rediseño iOS 27 · tablero `Onboarding`,
/// pasos isla · gustos · ubicación · cuenta). Sin widgets.

/// Pasos con barra de progreso (la bienvenida no cuenta).
const int kOnbTotalSteps = 4;

/// Gustos mínimos para continuar.
const int kOnbMinTastes = 3;

/// Mismas páginas legales que abre Ajustes (`settings_screen.dart`).
const String kOnbTermsUrl = 'https://dondecomercanarias.com/terminos';
const String kOnbPrivacyUrl = 'https://dondecomercanarias.com/privacidad';

String onbStepEyebrow(int step) => 'Paso $step de $kOnbTotalSteps';

// ── Normalización ──────────────────────────────────────────────────────────

String onbNormalize(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final buf = StringBuffer();
  for (final rune in s.toLowerCase().trim().runes) {
    final ch = String.fromCharCode(rune);
    final idx = from.indexOf(ch);
    buf.write(idx >= 0 ? to[idx] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
}

String _cap(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  final lower = t == t.toUpperCase() ? t.toLowerCase() : t;
  return lower[0].toUpperCase() + lower.substring(1);
}

// ── Paso 1 · Isla ──────────────────────────────────────────────────────────

/// Islas en el orden del backend (`position`).
List<Island> onbSortedIslands(List<Island> islands) =>
    [...islands]..sort((a, b) => a.position.compareTo(b.position));

/// Clave de la isla para la insignia («TF», «GC»…, la `key` de `/islands`).
/// Si el backend no la trae: iniciales de las dos primeras palabras
/// («Gran Canaria» → «GC») o las dos primeras letras («Tenerife» → «TE»).
String onbIslandBadge(Island island) {
  final k = island.key?.trim() ?? '';
  if (k.isNotEmpty) return k.toUpperCase();
  final words = island.name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  if (words.length == 1) {
    final w = words.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return words.take(2).map((w) => w[0]).join().toUpperCase();
}

/// Texto del botón fijo del paso de la isla.
String onbIslandCta(
    {required bool loading, required bool failed, required bool selected}) {
  if (failed) return 'Elegir más tarde';
  if (loading || selected) return 'Continuar';
  return 'Elige una isla';
}

// ── Paso 2 · Gustos ────────────────────────────────────────────────────────

/// Grupos del tablero, en orden.
enum OnbTasteGroup {
  food('Me gusta comer'),
  plans('Planes que me tiran'),
  services('Servicios que valoro');

  final String title;
  const OnbTasteGroup(this.title);
}

/// Glifo propio de cada gusto (nunca emoji). Los de marca (cabra, cochino,
/// vieja, copa, volcán) son assets multicolor; el resto, trazo de 2.
enum OnbTasteGlyph {
  cabra,
  cochino,
  vieja,
  papas,
  puchero,
  copa,
  sinGluten,
  conV,
  terraza,
  vistas,
  cesta,
  volcan,
  datafono,
  accesible,
  pata,
  gallina,
  globo,
  plato,
}

class OnbTaste {
  /// Id real de la categoría (`/categorias`), lo que se guarda.
  final String id;
  final String label;
  final OnbTasteGroup group;
  final OnbTasteGlyph glyph;

  /// Orden dentro del grupo (el del tablero; desconocidas al final).
  final int order;

  const OnbTaste({
    required this.id,
    required this.label,
    required this.group,
    required this.glyph,
    required this.order,
  });
}

class _TasteDef {
  final String label;
  final OnbTasteGroup group;
  final OnbTasteGlyph glyph;
  final int order;
  const _TasteDef(this.label, this.group, this.glyph, this.order);
}

/// Categoría real → etiqueta limpia (DISENO-FINAL §5), grupo y glifo.
_TasteDef _tasteDef(String raw) {
  final k = onbNormalize(raw);
  const f = OnbTasteGroup.food;
  const p = OnbTasteGroup.plans;
  const s = OnbTasteGroup.services;
  if (k.contains('cabra')) {
    return const _TasteDef('Carne de cabra', f, OnbTasteGlyph.cabra, 0);
  }
  if (k.contains('cochino')) {
    return const _TasteDef('Cochino negro', f, OnbTasteGlyph.cochino, 1);
  }
  if (k.contains('pescado') || k.contains('marisco')) {
    return const _TasteDef('Pescado o marisco', f, OnbTasteGlyph.vieja, 2);
  }
  if (k.contains('papas') || k.contains('costillas')) {
    return const _TasteDef(
        'Papas, piña y costillas', f, OnbTasteGlyph.papas, 3);
  }
  if (k.contains('puchero')) {
    return const _TasteDef('Puchero', f, OnbTasteGlyph.puchero, 4);
  }
  if (k.contains('cosecha')) {
    return const _TasteDef('Cosecha propia', f, OnbTasteGlyph.copa, 5);
  }
  if (k.contains('gluten')) {
    return const _TasteDef('Sin gluten', f, OnbTasteGlyph.sinGluten, 6);
  }
  if (k == 'con v' || k.startsWith('con v ') || k == 'v') {
    return const _TasteDef('Con V', f, OnbTasteGlyph.conV, 7);
  }
  if (k.contains('terraza')) {
    return const _TasteDef('Terraza', p, OnbTasteGlyph.terraza, 0);
  }
  if (k.contains('vistas')) {
    return const _TasteDef('Con vistas', p, OnbTasteGlyph.vistas, 1);
  }
  if (k.contains('mercado')) {
    return const _TasteDef('Mercado', p, OnbTasteGlyph.cesta, 2);
  }
  if (k.contains('experiencia')) {
    return const _TasteDef('Experiencia', p, OnbTasteGlyph.volcan, 3);
  }
  if (k.contains('datafono')) {
    return const _TasteDef('Datáfono', s, OnbTasteGlyph.datafono, 0);
  }
  if (k.contains('pmr') || k.contains('accesib')) {
    return const _TasteDef('Accesible', s, OnbTasteGlyph.accesible, 1);
  }
  if (k.contains('mascota')) {
    return const _TasteDef('Admite mascotas', s, OnbTasteGlyph.pata, 2);
  }
  // «Animales» (granja, cabras…) no es «Admite mascotas».
  if (k.contains('animales')) {
    return const _TasteDef('Con animales', s, OnbTasteGlyph.gallina, 3);
  }
  if (k.contains('infantil') || k.contains('ninos')) {
    return const _TasteDef('Zona infantil', s, OnbTasteGlyph.globo, 4);
  }
  return _TasteDef(_cap(raw), f, OnbTasteGlyph.plato, 100);
}

OnbTaste onbTasteFor(ModelCategory c) {
  final d = _tasteDef(c.nombre);
  return OnbTaste(
      id: c.id, label: d.label, group: d.group, glyph: d.glyph, order: d.order);
}

/// Las categorías reales agrupadas como en el tablero. Sin duplicados de
/// etiqueta ni categorías vacías; grupos vacíos fuera.
Map<OnbTasteGroup, List<OnbTaste>> onbGroupTastes(List<ModelCategory> cats) {
  final seen = <String>{};
  final all = <OnbTaste>[];
  for (final c in cats) {
    if (c.id.isEmpty || c.nombre.trim().isEmpty) continue;
    final t = onbTasteFor(c);
    if (!seen.add(t.label)) continue;
    all.add(t);
  }
  final out = <OnbTasteGroup, List<OnbTaste>>{};
  for (final g in OnbTasteGroup.values) {
    final list = all.where((t) => t.group == g).toList()
      ..sort((a, b) {
        final o = a.order.compareTo(b.order);
        return o != 0 ? o : a.label.compareTo(b.label);
      });
    if (list.isNotEmpty) out[g] = list;
  }
  return out;
}

/// «Continuar» con el mínimo; si no, «Elige N más».
String onbTastesCta(int selected) => selected >= kOnbMinTastes
    ? 'Continuar'
    : 'Elige ${kOnbMinTastes - selected} más';

/// Contador junto al antetítulo; vacío sin selección.
String onbTastesCounter(int n) =>
    n <= 0 ? '' : (n == 1 ? '1 elegido' : '$n elegidos');

// ── Paso 3 · Ubicación ─────────────────────────────────────────────────────

/// ¿El usuario concedió el permiso? Tras `requestPermissionOnly` el cubit
/// queda en `LocationLoading` (fix en segundo plano) o en un `LocationDenied`
/// (denegado, denegado para siempre o servicio apagado).
bool onbLocationGranted(LocationState s) =>
    s is! LocationDenied && s is! LocationInitial;

String onbLocationTitle({required bool declined}) =>
    declined ? 'Sin ubicación, de momento' : 'Lo bueno, cerca de ti';

String onbLocationSubtitle({required bool declined, String? islandName}) {
  if (!declined) {
    return 'Activa tu ubicación y te enseñamos lo que está abierto a tu '
        'alrededor.';
  }
  final where = (islandName == null || islandName.trim().isEmpty)
      ? 'Canarias'
      : islandName.trim();
  return 'No pasa nada: te enseñamos lo mejor de $where sin saber dónde '
      'estás.';
}

// ── Paso 4 · Cuenta ────────────────────────────────────────────────────────

/// Dos sitios reales para las tarjetas que se abren en abanico: con foto y
/// los mejor valorados con el ranking ponderado.
List<Restaurant> onbAccountPlaces(List<Restaurant> rs) {
  final withPhoto = rs
      .where((r) => r.mainFoto.trim().isNotEmpty && r.nombre.trim().isNotEmpty)
      .toList()
    ..sort((a, b) {
      final w = listWeightedRating(b).compareTo(listWeightedRating(a));
      // Si el listado no trae reseñas, desempata la media del backend.
      return w != 0 ? w : b.avgRating.compareTo(a.avgRating);
    });
  return withPhoto.take(2).toList();
}

enum OnbAuthProvider { google, apple }

/// Resultado de entrar con Apple / Google (cancelar no es un error).
enum OnbSignInOutcome { success, error, cancelled }

String onbProviderName(OnbAuthProvider p) =>
    p == OnbAuthProvider.google ? 'Google' : 'Apple';

String onbAuthLoadingLabel(OnbAuthProvider p) =>
    'Conectando con ${onbProviderName(p)}…';

String onbAuthErrorTitle(OnbAuthProvider p) =>
    'No hemos podido conectar con ${onbProviderName(p)}';

const String kOnbAuthErrorText =
    'Puede que hayas cancelado o que falle la conexión. Inténtalo otra vez.';
