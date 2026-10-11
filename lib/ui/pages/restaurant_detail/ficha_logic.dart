import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/short_quote.dart';
import 'package:guachinches/utils/open_now_utils.dart';

/// Lógica de presentación de la ficha de negocio (rediseño iOS 27 · tablero
/// FichaCompleta / Sistema §07). Funciones puras y testeables: qué se pinta,
/// en qué orden y con qué texto, a partir de los datos reales.

// ── Visitas ────────────────────────────────────────────────────────────────

/// Visitas ordenadas de la más reciente a la más antigua por la fecha real
/// del vídeo (no fiarse del orden del backend).
List<Visit> fichaSortedVisits(List<Visit> visits) {
  DateTime key(Visit v) =>
      DateTime.tryParse(v.sortDate ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  return [...visits]..sort((a, b) => key(b).compareTo(key(a)));
}

Visit? fichaLatestVisit(List<Visit> visits) {
  final s = fichaSortedVisits(visits);
  return s.isEmpty ? null : s.first;
}

/// «Les encantó» solo cuando el análisis dice muy positivo.
bool fichaLoved(Visit v) => v.overallSentiment == 'muy_positivo';

// ── Precio ─────────────────────────────────────────────────────────────────

/// «≈ 36 € por persona» desde la visita más reciente con precio; si no, el
/// rango del local («15–25 € por persona»). `null` si no hay dato.
String? fichaPriceLabel(Restaurant r, List<Visit> visits) {
  for (final v in fichaSortedVisits(visits)) {
    final p = v.priceApprox;
    if (p != null && p > 0) return '≈ ${p.round()} € por persona';
  }
  final min = r.minPrice;
  final max = r.maxPrice;
  if (min != null && max != null && max > 0) {
    return min == max ? '≈ $min € por persona' : '$min–$max € por persona';
  }
  if (max != null && max > 0) return 'hasta $max € por persona';
  return null;
}

// ── Características (categorías + servicios de la visita) ──────────────────

/// Glifo de una característica (lo resuelve la UI).
enum FichaFeatureGlyph {
  terraza,
  conV,
  cabra,
  cochino,
  pescado,
  vino,
  aparcamiento,
  accesible,
  mascotas,
  datafono,
  infantil,
  sinGluten,
  vistas,
  ninguno,
}

class FichaFeature {
  final String label;
  final FichaFeatureGlyph glyph;
  const FichaFeature(this.label, this.glyph);

  @override
  bool operator ==(Object o) => o is FichaFeature && o.label == label;
  @override
  int get hashCode => label.hashCode;
  @override
  String toString() => label;
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[áà]'), 'a')
    .replaceAll(RegExp(r'[éè]'), 'e')
    .replaceAll(RegExp(r'[íì]'), 'i')
    .replaceAll(RegExp(r'[óò]'), 'o')
    .replaceAll(RegExp(r'[úùü]'), 'u')
    .replaceAll('_', ' ')
    .trim();

/// Servicio de la visita (clave del backend) → etiqueta legible. `null` si
/// la clave no se pinta como chip (reservas va en la fila del teléfono).
FichaFeature? fichaServiceFeature(String raw) {
  final k = _norm(raw);
  switch (k) {
    case 'aparcamiento':
    case 'parking':
      return const FichaFeature('Aparcamiento', FichaFeatureGlyph.aparcamiento);
    case 'acceso pmr':
    case 'accesible':
    case 'accesibilidad':
      return const FichaFeature('Accesible', FichaFeatureGlyph.accesible);
    case 'petfriendly':
    case 'pet friendly':
    case 'mascotas':
    case 'admite mascotas':
      return const FichaFeature('Admite mascotas', FichaFeatureGlyph.mascotas);
    case 'terraza':
      return const FichaFeature('Terraza', FichaFeatureGlyph.terraza);
    case 'datafono':
    case 'tarjeta':
      return const FichaFeature('Datáfono', FichaFeatureGlyph.datafono);
    case 'reservas':
    case 'reserva':
    case 'carta':
    case 'menu degustacion':
      return null;
  }
  if (k.isEmpty) return null;
  // Claves libres («permite mascotas», «zona infantil»…): misma
  // normalización que las categorías para no duplicar chips.
  return fichaCategoryFeature(k);
}

/// Categoría del local → característica con glifo y etiqueta corregida
/// («carne cabra» → «Carne de cabra»).
FichaFeature fichaCategoryFeature(String raw) {
  final k = _norm(raw);
  if (k.contains('terraza')) {
    return const FichaFeature('Terraza', FichaFeatureGlyph.terraza);
  }
  if (k == 'con v' || k.startsWith('con v ')) {
    return const FichaFeature('Con V', FichaFeatureGlyph.conV);
  }
  if (k.contains('cabra')) {
    return const FichaFeature('Carne de cabra', FichaFeatureGlyph.cabra);
  }
  if (k.contains('cochino')) {
    return const FichaFeature('Cochino negro', FichaFeatureGlyph.cochino);
  }
  if (k.contains('pescado') || k.contains('marisco')) {
    return FichaFeature(_cap(raw), FichaFeatureGlyph.pescado);
  }
  if (k.contains('cosecha') || k.contains('vino')) {
    return FichaFeature(_cap(raw), FichaFeatureGlyph.vino);
  }
  if (k.contains('mascota') || k.contains('animales')) {
    return const FichaFeature('Admite mascotas', FichaFeatureGlyph.mascotas);
  }
  if (k.contains('pmr') || k.contains('accesib')) {
    return const FichaFeature('Accesible', FichaFeatureGlyph.accesible);
  }
  if (k.contains('datafono')) {
    return const FichaFeature('Datáfono', FichaFeatureGlyph.datafono);
  }
  if (k.contains('infantil') || k.contains('ninos')) {
    return FichaFeature(_cap(raw), FichaFeatureGlyph.infantil);
  }
  if (k.contains('gluten')) {
    return FichaFeature(_cap(raw), FichaFeatureGlyph.sinGluten);
  }
  if (k.contains('vistas')) {
    return FichaFeature(_cap(raw), FichaFeatureGlyph.vistas);
  }
  return FichaFeature(_cap(raw), FichaFeatureGlyph.ninguno);
}

String _cap(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  final lower = t == t.toUpperCase() ? t.toLowerCase() : t;
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Chips de la ficha: categorías del local y, después, los servicios de la
/// visita más reciente. Sin duplicados («Terraza» de las dos fuentes).
List<FichaFeature> fichaFeatures(Restaurant r, List<Visit> visits) {
  final out = <FichaFeature>[];
  void add(FichaFeature? f) {
    if (f == null || f.label.isEmpty) return;
    if (out.any((x) => x.label == f.label)) return;
    out.add(f);
  }

  for (final c in r.categoriaRestaurantes) {
    add(fichaCategoryFeature(c.categorias.nombre));
  }
  final latest = fichaLatestVisit(visits);
  if (latest != null) {
    for (final s in latest.services) {
      add(fichaServiceFeature(s));
    }
  }
  return out;
}

/// ¿Se reserva? (servicio «reservas» en alguna visita).
bool fichaTakesReservations(List<Visit> visits) => visits.any((v) =>
    v.services.any((s) => _norm(s) == 'reservas' || _norm(s) == 'reserva'));

// ── Citas ──────────────────────────────────────────────────────────────────

/// Cita literal sin hablante: quita prefijos «Jonay:», «Joana -», etc. y
/// envuelve en comillas latinas.
String fichaQuote(String raw) {
  var t = raw.trim();
  t = t.replaceFirst(
      RegExp(r'^(jonay|joana|jonay y joana|ella|el|él)\s*[:\-–—]\s*',
          caseSensitive: false),
      '');
  t = t.replaceAll(RegExp(r'^[«"“]+|[»"”]+$'), '').trim();
  if (t.isEmpty) return '';
  // Las citas extraídas a veces empiezan en minúscula: mayúscula inicial
  // (también tras «¡» o «¿»).
  final m = RegExp(r'^([¡¿…\s]*)(\p{Ll})', unicode: true).firstMatch(t);
  if (m != null) {
    t = m.group(1)! + m.group(2)!.toUpperCase() + t.substring(m.end);
  }
  return '«$t»';
}

/// ¿Parece una frase completa? (empieza en mayúscula —o ¡/¿— en el
/// original). Las que empiezan en minúscula suelen ser fragmentos.
bool fichaLooksComplete(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'^[«"“]+'), '');
  if (t.isEmpty) return false;
  final first = t[0];
  return first == '¡' || first == '¿' || first != first.toLowerCase();
}

/// Cita del teaser de la visita: literal, positiva si la hay, distinta de
/// las del short (para no repetir la misma frase dos veces).
String? fichaTeaserQuote(Visit v, List<ShortQuote> shortQuotes) {
  final used = shortQuotes.map((q) => _norm(q.text)).toSet();
  final candidates = v.quotes
      .where((q) => q.text.trim().isNotEmpty && !used.contains(_norm(q.text)))
      .toList();
  if (candidates.isEmpty) return null;
  // Preferimos frases completas, positivas y cortas (caben en dos líneas).
  candidates.sort((a, b) {
    final ca = fichaLooksComplete(a.text) ? 0 : 1;
    final cb = fichaLooksComplete(b.text) ? 0 : 1;
    if (ca != cb) return ca.compareTo(cb);
    final pa = (a.sentiment ?? '').startsWith('pos') ? 0 : 1;
    final pb = (b.sentiment ?? '').startsWith('pos') ? 0 : 1;
    if (pa != pb) return pa.compareTo(pb);
    return a.text.length.compareTo(b.text.length);
  });
  return fichaQuote(candidates.first.text);
}

/// Una frase de «Lo que dicen» (citas literales con marca Positivo/Ojo).
class FichaSaying {
  final String text;
  final bool warning;
  const FichaSaying(this.text, {this.warning = false});
}

/// «Lo que dicen»: las citas del short; si no hay, las de la visita más
/// reciente (con su sentimiento). Siempre literales, sin hablante.
List<FichaSaying> fichaSayings(Restaurant r, List<Visit> visits) {
  final out = <FichaSaying>[];
  for (final q in r.shortQuotes) {
    final t = fichaQuote(q.text);
    if (t.isNotEmpty) out.add(FichaSaying(t, warning: q.isWarning));
  }
  if (out.isNotEmpty) return out;
  final latest = fichaLatestVisit(visits);
  if (latest == null) return out;
  for (final q in latest.quotes) {
    final t = fichaQuote(q.text);
    if (t.isEmpty) continue;
    final s = (q.sentiment ?? '').toLowerCase();
    out.add(FichaSaying(t, warning: s.startsWith('neg') || s == 'warning'));
  }
  return out;
}

// ── Resumen con IA (único sitio de «A favor» / «En contra») ─────────────────

String _dedupeKey(String s) => _norm(s)
    .replaceAll(RegExp(r'[^a-z0-9ñ ]'), '')
    .replaceAll(RegExp(r'\s+'), ' ');

List<String> _mergeUnique(Iterable<String> items) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in items) {
    final t = raw.trim();
    if (t.isEmpty) continue;
    final k = _dedupeKey(t);
    if (!seen.add(k)) continue;
    out.add(t[0].toUpperCase() + t.substring(1));
  }
  return out;
}

class FichaAiSummary {
  final List<String> pros;
  final List<String> cons;
  final int visitCount;
  const FichaAiSummary(this.pros, this.cons, this.visitCount);
  bool get isEmpty => pros.isEmpty && cons.isEmpty;
}

/// Junta los «a favor / en contra» de todas las visitas, sin duplicados.
FichaAiSummary fichaAiSummary(List<Visit> visits) {
  final sorted = fichaSortedVisits(visits);
  return FichaAiSummary(
    _mergeUnique(sorted.expand((v) => v.highlights)),
    _mergeUnique(sorted.expand((v) => v.lowlights)),
    sorted.where((v) => v.highlights.isNotEmpty || v.lowlights.isNotEmpty).length,
  );
}

// ── Reseñas y ranking ──────────────────────────────────────────────────────

/// «Ver todas las reseñas» solo con más de 3.
bool fichaShowAllReviews(int count) => count > 3;

/// El «Nº X» solo con 10 reseñas o más (y si el backend da el puesto).
bool fichaShowRank(Restaurant r) =>
    r.rankNumber != null && r.rankNumber! > 0 && r.valoraciones.length >= 10;

/// Nombre de pila de quien reseña (nunca apellidos).
String fichaFirstName(String? full) {
  final t = (full ?? '').trim();
  if (t.isEmpty) return 'Anónimo';
  final first = t.split(RegExp(r'\s+')).first;
  final lower = first.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Texto de una reseña tal cual, salvo los rellenos que mete el backend
/// cuando la persona no escribió nada («Sin descripción»).
String fichaReviewText(String raw) {
  final t = raw.trim();
  if (_norm(t) == 'sin descripcion') return '';
  return t;
}

/// «@casaangela» desde un enlace o un nombre de usuario de Instagram.
String fichaInstagramHandle(String raw) {
  var t = raw.trim();
  final m = RegExp(r'instagram\.com/([A-Za-z0-9._]+)').firstMatch(t);
  if (m != null) t = m.group(1)!;
  t = t.replaceAll(RegExp(r'^@+'), '').replaceAll('/', '');
  return t.isEmpty ? '' : '@$t';
}

// ── Dirección ──────────────────────────────────────────────────────────────

/// Quita emojis/pictogramas iniciales que vienen en la BD («📍Calle…»).
String fichaCleanAddress(String raw) {
  var t = raw.trim();
  t = t.replaceFirst(
      RegExp(r'^[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}\s]+',
          unicode: true),
      '');
  return t.trim();
}

/// Dirección en dos líneas («Calle…, 84» / «38389 Municipio») cuando trae
/// código postal; quita la provincia final.
String fichaAddressLines(String raw) {
  final t = fichaCleanAddress(raw);
  final parts = t.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 3) {
    final cpIdx = parts.indexWhere((p) => RegExp(r'^\d{5}\b').hasMatch(p));
    if (cpIdx > 0) {
      return '${parts.sublist(0, cpIdx).join(', ')}\n${parts[cpIdx]}';
    }
  }
  return t;
}

// ── Horario ────────────────────────────────────────────────────────────────

const _dayNames = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
];
const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String fichaDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String? fichaDateFromIso(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  return d == null ? null : fichaDate(d.toLocal());
}

String _hhmm(String t) => '${t.substring(0, 2)}:${t.substring(2, 4)}';

class FichaStatus {
  final bool open;

  /// «hasta las 22:00» / «abre el miércoles a las 12:00» (puede ser null).
  final String? rest;
  const FichaStatus(this.open, this.rest);
}

/// Estado de apertura. Con `horariosJson` (periodos de Google) calcula la
/// hora de cierre o la próxima apertura; sin él cae a `open` (texto de
/// Google). `null` si no hay ningún dato de horario.
FichaStatus? fichaStatus(Restaurant r, DateTime now) {
  final json = r.horariosJson;
  final periods = json == null ? null : json['periods'];
  if (periods is List && periods.isNotEmpty) {
    try {
      final open = isOpenNow(json, now);
      final nowMin = (now.weekday % 7) * 1440 + now.hour * 60 + now.minute;
      int abs(Map p) {
        final t = p['time'] as String;
        return (p['day'] as int) * 1440 +
            int.parse(t.substring(0, 2)) * 60 +
            int.parse(t.substring(2, 4));
      }

      if (open) {
        for (final p in periods) {
          final o = p['open'];
          final c = p['close'];
          if (o == null) continue;
          if (c == null) return const FichaStatus(true, 'abierto 24 h');
          var om = abs(o);
          var cm = abs(c);
          if (cm <= om) cm += 7 * 1440;
          var n = nowMin;
          if (n < om) n += 7 * 1440;
          if (n >= om && n < cm) {
            return FichaStatus(true, 'hasta las ${_hhmm(c['time'] as String)}');
          }
        }
        return const FichaStatus(true, null);
      }
      // Cerrado: próxima apertura en la semana.
      int? best;
      Map? bestOpen;
      for (final p in periods) {
        final o = p['open'];
        if (o == null) continue;
        var om = abs(o);
        if (om <= nowMin) om += 7 * 1440;
        if (best == null || om < best) {
          best = om;
          bestOpen = o;
        }
      }
      if (best == null || bestOpen == null) return const FichaStatus(false, null);
      final at = _hhmm(bestOpen['time'] as String);
      final daysAhead = (best ~/ 1440) - (nowMin ~/ 1440);
      if (daysAhead == 0) return FichaStatus(false, 'abre hoy a las $at');
      if (daysAhead == 1) return FichaStatus(false, 'abre mañana a las $at');
      final gDay = bestOpen['day'] as int; // 0 = domingo
      final name = _dayNames[(gDay + 6) % 7];
      return FichaStatus(false, 'abre el $name a las $at');
    } catch (_) {
      // Formato inesperado: seguimos con el texto de Google.
    }
  }
  if (r.googleHorarios.trim().isNotEmpty &&
      r.googleHorarios.toLowerCase() != 'sin horario') {
    return FichaStatus(r.open, null);
  }
  return null;
}

/// Horario de la semana (lunes→domingo) y el índice de hoy. Usa
/// `weekday_text` de Google o, si no, el texto plano de Google. `null` si no
/// hay 7 líneas.
({List<String> hours, int today})? fichaWeek(Restaurant r, DateTime now) {
  final today = (now.weekday + 6) % 7;
  String strip(String line) {
    final i = line.indexOf(':');
    return (i != -1 && i + 1 < line.length) ? line.substring(i + 1).trim() : line;
  }

  String pretty(String h) {
    final t = h.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  final json = r.horariosJson;
  final wt = json == null ? null : json['weekday_text'];
  if (wt is List && wt.length >= 7) {
    return (hours: [for (var i = 0; i < 7; i++) pretty(strip(wt[i].toString()))], today: today);
  }
  final raw = r.googleHorarios;
  if (raw.isNotEmpty && raw.toLowerCase() != 'sin horario') {
    final lines =
        raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length >= 7) {
      return (hours: [for (final l in lines.take(7)) pretty(strip(l))], today: today);
    }
  }
  return null;
}

/// «Horario de Google, sincronizado el 11 oct 2026».
String? fichaScheduleFootnote(Restaurant r) {
  final d = fichaDateFromIso(r.googleHorariosSyncedAt);
  return d == null ? null : 'Horario de Google, sincronizado el $d';
}

const fichaWeekDays = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];

// ── Listas y fotos ─────────────────────────────────────────────────────────

/// Lista curada en la que aparece el local y su puesto en ella.
class ListAppearance {
  final CuratedList list;

  /// Puesto 1-based dentro de la lista.
  final int position;

  /// Sitios de la lista (para «Parada 2 de 12»); 0 si no se conoce.
  final int total;
  const ListAppearance(
      {required this.list, required this.position, this.total = 0});
}

/// Puesto 1-based del local en una lista a partir de `(restaurantId,
/// position)` de sus elementos. El backend numera desde 0 en unas listas y
/// desde 1 en otras: se ordena por `position` y se cuenta. `null` si no está.
int? fichaListRank(List<(String, int)> items, String restaurantId) {
  final sorted = [...items]..sort((a, b) => a.$2.compareTo(b.$2));
  final i = sorted.indexWhere((e) => e.$1 == restaurantId);
  return i < 0 ? null : i + 1;
}

/// «Ruta · Parada 2 de 12» / «Top · Puesto nº 1» (sin ceros a la izquierda).
String fichaListLabel(String eyebrow, int position, int count) {
  final e = eyebrow.trim();
  final pretty = e.isEmpty
      ? ''
      : (e == e.toUpperCase() ? e[0] + e.substring(1).toLowerCase() : e);
  final isRoute = _norm(e).contains('ruta');
  final slot = isRoute
      ? (count > 0 ? 'Parada $position de $count' : 'Parada $position')
      : 'Puesto nº $position';
  return pretty.isEmpty ? slot : '$pretty · $slot';
}

/// URLs de fotos del local (o la principal si no hay galería).
List<String> fichaPhotoUrls(Restaurant r) {
  final urls = r.fotos
      .map((f) => f.photoUrl ?? '')
      .where((u) => u.isNotEmpty)
      .toList();
  if (urls.isEmpty && r.mainFoto.isNotEmpty) return [r.mainFoto];
  return urls;
}

/// Miniaturas de una visita de mejor a peor: maxres de YouTube, la
/// original (hq) y la foto del local. Para usar con `GmPhoto.fallbacks`.
List<String> fichaVisitThumbs(Visit v) {
  final out = <String>[];
  final best = fichaVisitThumb(v);
  if (best != null) out.add(best);
  final t = v.thumbnail;
  if (t != null && t.isNotEmpty && !out.contains(t)) out.add(t);
  final id = v.youtubeVideoId;
  if (id != null && id.isNotEmpty && !id.contains('-')) {
    final hq = 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
    if (!out.contains(hq)) out.add(hq);
  }
  final m = v.restaurant?.mainFoto;
  if (m != null && m.isNotEmpty && !out.contains(m)) out.add(m);
  return out;
}

/// Miniatura de YouTube de una visita: maxres si es posible.
String? fichaVisitThumb(Visit v) {
  final t = v.thumbnail;
  if (t != null && t.isNotEmpty) {
    return t.contains('i.ytimg.com') && t.contains('/hqdefault.')
        ? t.replaceAll('/hqdefault.', '/maxresdefault.')
        : t;
  }
  final id = v.youtubeVideoId;
  if (id != null && id.isNotEmpty && !id.contains('-')) {
    return 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';
  }
  final m = v.restaurant?.mainFoto;
  return (m != null && m.isNotEmpty) ? m : null;
}

/// «1:35» desde segundos o desde el texto del backend («PT1M35S», «1:35»).
String? fichaDuration({int? seconds, String? raw}) {
  if (seconds != null && seconds > 0) {
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  final iso = RegExp(r'^PT(?:(\d+)M)?(?:(\d+)S)?$').firstMatch(t);
  if (iso != null) {
    final m = int.tryParse(iso.group(1) ?? '0') ?? 0;
    final s = int.tryParse(iso.group(2) ?? '0') ?? 0;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
  return t;
}
