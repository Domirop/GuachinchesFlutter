import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

/// Lógica pura del juego «Conquista Canarias» (tableros `Quiz*`): paleta y
/// orden de los quesitos, textos derivados de los datos y formatos. Sin
/// widgets: se prueba con `flutter_test` en `test/ui/pages/quiz/`.

// ── Quesitos ────────────────────────────────────────────────────────────────

/// Un quesito = una categoría. Paleta y orden EXACTOS de la tarjeta del quiz
/// del Inicio (`QuesitosWheel`): desde arriba, en sentido horario. El relleno
/// nunca se usa para texto; para texto y glifos están las tintas AA de día y
/// de noche.
@immutable
class QuizQuesito {
  final String slug;
  final String name;
  final String short;
  final Color fill;
  final Color inkDay;
  final Color inkNight;

  /// Clave del glifo en `quiz_glyphs.dart`.
  final String glyph;

  const QuizQuesito({
    required this.slug,
    required this.name,
    required this.short,
    required this.fill,
    required this.inkDay,
    required this.inkNight,
    required this.glyph,
  });

  Color ink(bool dark) => dark ? inkNight : inkDay;

  /// Fondo suave (chips pendientes, losetas de icono): relleno al 16 % de día
  /// y al 22 % de noche.
  Color soft(bool dark) => fill.withValues(alpha: dark ? 0.22 : 0.16);
}

const List<QuizQuesito> kQuizQuesitos = [
  QuizQuesito(
      slug: 'geografia',
      name: 'Geografía',
      short: 'Geografía',
      fill: Color(0xFF0085C4),
      inkDay: Color(0xFF005A85),
      inkNight: Color(0xFF7CC4E6),
      glyph: 'brujula'),
  QuizQuesito(
      slug: 'folclore',
      name: 'Folclore y Tradiciones',
      short: 'Folclore',
      fill: Color(0xFFFFC23D),
      inkDay: Color(0xFF8A5A00),
      inkNight: Color(0xFFFFD27A),
      glyph: 'timple'),
  QuizQuesito(
      slug: 'historia',
      name: 'Historia',
      short: 'Historia',
      fill: Color(0xFFFF5A4E),
      inkDay: Color(0xFFB8322A),
      inkNight: Color(0xFFFF8F85),
      glyph: 'torre'),
  QuizQuesito(
      slug: 'arte_literatura',
      name: 'Arte y Literatura',
      short: 'Arte',
      fill: Color(0xFFF39A2B),
      inkDay: Color(0xFF9A4E06),
      inkNight: Color(0xFFF7B567),
      glyph: 'pluma'),
  QuizQuesito(
      slug: 'ciencia_natura',
      name: 'Ciencia y Naturaleza',
      short: 'Ciencia',
      fill: Color(0xFF34B25A),
      inkDay: Color(0xFF1E7A42),
      inkNight: Color(0xFF72D493),
      glyph: 'drago'),
  QuizQuesito(
      slug: 'entretenimiento',
      name: 'Entretenimiento',
      short: 'Ocio',
      fill: Color(0xFF14A394),
      inkDay: Color(0xFF0B6B61),
      inkNight: Color(0xFF5ED3C4),
      glyph: 'antifaz'),
  QuizQuesito(
      slug: 'deporte',
      name: 'Deporte',
      short: 'Deporte',
      fill: Color(0xFF8B5CC7),
      inkDay: Color(0xFF5E3A96),
      inkNight: Color(0xFFBFA1EC),
      glyph: 'balon'),
];

/// Posición del quesito en la rueda (−1 si el backend trae un slug nuevo).
int quizQuesitoIndex(String slug) =>
    kQuizQuesitos.indexWhere((q) => q.slug == slug);

/// Quesito de un slug; uno neutro (Geografía) si el slug no se conoce, para
/// no romper la partida si el backend añade una categoría.
QuizQuesito quizQuesitoFor(String slug) {
  final i = quizQuesitoIndex(slug);
  return i < 0 ? kQuizQuesitos.first : kQuizQuesitos[i];
}

/// Ordena las categorías del backend en el orden de la rueda del Inicio; las
/// desconocidas van al final en su orden de `sortOrder`.
List<QuizCategory> quizOrderCategories(List<QuizCategory> cats) {
  final known = <QuizCategory>[];
  for (final q in kQuizQuesitos) {
    for (final c in cats) {
      if (c.slug == q.slug) known.add(c);
    }
  }
  final unknown = cats.where((c) => quizQuesitoIndex(c.slug) < 0).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return [...known, ...unknown];
}

/// Nombre a mostrar de una categoría (el del backend si llega; si no, el de la
/// paleta).
String quizCategoryName(String slug, List<QuizCategory> cats) {
  for (final c in cats) {
    if (c.slug == slug && c.name.trim().isNotEmpty) return c.name.trim();
  }
  return quizQuesitoFor(slug).name;
}

/// Nombres de los quesitos que faltan, en el orden de la rueda.
List<String> quizMissingNames(Iterable<String> owned, List<QuizCategory> cats) {
  final own = owned.toSet();
  final order = cats.isEmpty
      ? kQuizQuesitos.map((q) => q.slug).toList()
      : quizOrderCategories(cats).map((c) => c.slug).toList();
  return [
    for (final slug in order)
      if (!own.contains(slug)) quizCategoryName(slug, cats)
  ];
}

/// «A», «A y B», «A, B y C».
String quizJoin(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
}

/// Subtítulo de la ruleta: qué quesitos faltan.
String quizWheelSubtitle(Iterable<String> owned, List<QuizCategory> cats) {
  final missing = quizMissingNames(owned, cats);
  if (missing.isEmpty) return 'Ya tienes los 7 quesitos.';
  if (missing.length >= 7) return 'Acierta una pregunta de cada categoría.';
  if (missing.length == 1) return 'Te falta ${missing.first}.';
  return 'Te faltan ${quizJoin(missing)}.';
}

// ── Formatos ────────────────────────────────────────────────────────────────

/// Entero con punto de millares: 41804 → «41.804».
String quizFormatInt(int n) {
  final neg = n < 0;
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${neg ? '-' : ''}$buf';
}

/// «1 pleno», «3 plenos».
String quizCount(int n, String one, String many) =>
    '${quizFormatInt(n)} ${n == 1 ? one : many}';

/// Dificultad del backend → texto («facil» → «fácil»).
String quizDifficultyLabel(String d) {
  switch (d.toLowerCase()) {
    case 'facil':
    case 'fácil':
      return 'fácil';
    case 'dificil':
    case 'difícil':
      return 'difícil';
    default:
      return 'media';
  }
}

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic'
];

/// Fecha corta del historial: «12 oct» (con año si no es el actual). `null`
/// si no hay fecha válida.
String? quizShortDate(String? iso, {DateTime? now}) {
  if (iso == null || iso.isEmpty) return null;
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return null;
  final n = now ?? DateTime.now();
  final base = '${d.day} ${_months[d.month - 1]}';
  return d.year == n.year ? base : '$base ${d.year}';
}

/// Solo el nombre de pila, en tipo título: «MARIA JOSE perez» → «Maria».
/// (El backend debería mandarlo ya así; esto es la red de seguridad.)
String quizFirstName(String raw) {
  final first = raw.trim().split(RegExp(r'\s+')).first;
  if (first.isEmpty) return 'Jugador';
  return first
      .split('-')
      .map((p) =>
          p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join('-');
}

/// Inicial del avatar.
String quizInitial(String name) =>
    name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

/// Rango permanente: «Mago/a» → «Mago o Maga».
String quizRankName(String name) {
  final m =
      RegExp(r'^(.*?)(\p{L}+)o/a$', unicode: true).firstMatch(name.trim());
  if (m == null) return name.trim();
  final stem = m.group(2)!;
  return '${m.group(1)}${stem}o o ${stem}a';
}

/// «2 plenos más para ser Mago o Maga»; `null` si ya es el rango máximo.
String? quizRankProgress(QuizStats stats) {
  final next = stats.rank.next;
  if (next == null) return null;
  final left = (next.at - stats.gamesWon).clamp(1, 1 << 30);
  return '${quizCount(left, 'pleno', 'plenos')} más para ser ${quizRankName(next.name)}';
}

// ── Arenas (tiers) ──────────────────────────────────────────────────────────

const kQuizTierNames = ['Marea', 'Volcán', 'Leyenda'];

/// Nombre de la arena por número (1..3).
String quizTierName(int tier) =>
    kQuizTierNames[(tier - 1).clamp(0, kQuizTierNames.length - 1)];

/// Segundos por pregunta en una arena (los del cubit: 20 · 18 · 15).
int quizTierSeconds(int tier) => QuizGameCubit.secondsForTier(tier);

/// Medalla de la arena: Marea bronce · Volcán plata · Leyenda oro.
enum QuizMedalKind { bronze, silver, gold }

QuizMedalKind quizTierMedal(int tier) => switch (tier.clamp(1, 3)) {
      1 => QuizMedalKind.bronze,
      2 => QuizMedalKind.silver,
      _ => QuizMedalKind.gold,
    };

/// Estado de cada peldaño de la escalera de arenas.
String quizLadderStatus(int index, int currentTier) {
  final ci = currentTier - 1;
  if (index == ci) return 'tu arena';
  if (index < ci) return 'completada';
  if (index == ci + 1) return 'siguiente';
  return 'después';
}

/// Pie de la tarjeta de conquista: «Conquista 6 islas más para subir a la
/// arena Volcán.» Devuelve (antes, negrita, después) para pintar la negrita.
(String, String, String) quizConquestFoot(QuizConquest c) {
  final total = c.total == 0 ? 7 : c.total;
  final left = (total - c.conqueredCount).clamp(0, total);
  final islas = left == 1 ? '1 isla más' : '$left islas más';
  if (c.tier >= c.maxTier) {
    return (
      'Conquista ',
      islas,
      ' para completar la arena ${quizTierName(c.tier)}.'
    );
  }
  return (
    'Conquista ',
    islas,
    ' para subir a la arena ${quizTierName(c.tier + 1)}.'
  );
}

/// Subtítulo tras conquistar: «2 de 7 islas. Te quedan 5 para subir a la
/// arena Volcán.»
String quizConqueredSubtitle(QuizConquest c) {
  final total = c.total == 0 ? 7 : c.total;
  final left = (total - c.conqueredCount).clamp(0, total);
  final head = '${c.conqueredCount} de $total islas.';
  if (left == 0) return head;
  final goal = c.tier >= c.maxTier
      ? 'completar la arena ${quizTierName(c.tier)}'
      : 'subir a la arena ${quizTierName(c.tier + 1)}';
  return '$head Te ${left == 1 ? 'queda 1' : 'quedan $left'} para $goal.';
}

// ── Partida ─────────────────────────────────────────────────────────────────

/// Pie del fallo: «Pierdes una vida: te queda 1.»
String quizLivesLeftText(int lives) {
  if (lives <= 0) return 'Te has quedado sin vidas.';
  if (lives == 1) return 'Pierdes una vida: te queda 1.';
  return 'Pierdes una vida: te quedan $lives.';
}

/// Subtítulo del acierto.
String quizCorrectSubtitle(QuizAnswerResult r) {
  final n = r.session.wedges.length;
  if (r.session.isWon) return '¡Tienes los 7 quesitos!';
  if (r.newWedge) return 'Ya llevas $n de 7 quesitos.';
  return 'Ese quesito ya era tuyo: suma puntos.';
}

/// Qué botón principal lleva el lobby.
enum QuizLobbyCta { firstGame, resume, play }

QuizLobbyCta quizLobbyCta({QuizStats? stats, QuizSession? active}) {
  if (active != null && active.isActive) return QuizLobbyCta.resume;
  if (stats != null && stats.gamesPlayed == 0) return QuizLobbyCta.firstGame;
  return QuizLobbyCta.play;
}

/// Primera vez: sin partidas jugadas ni partida en curso.
bool quizIsFirstTime({QuizStats? stats, QuizSession? active}) =>
    quizLobbyCta(stats: stats, active: active) == QuizLobbyCta.firstGame;

// ── Ranking ─────────────────────────────────────────────────────────────────

/// Tarjeta fija «Tu puesto».
@immutable
class QuizMyPlace {
  /// Puesto (null si no aparece en el top cargado).
  final int? position;
  final int? points;
  final String subtitle;
  const QuizMyPlace(this.position, this.points, this.subtitle);
}

QuizMyPlace quizMyPlace(List<QuizRankingEntry> ranking, QuizStats? stats) {
  final i = ranking.indexWhere((e) => e.isMe);
  if (i >= 0) {
    final me = ranking[i];
    final plenos = me.gamesWon == 0
        ? 'Sin plenos aún'
        : quizCount(me.gamesWon, 'pleno', 'plenos');
    if (i == 0)
      return QuizMyPlace(me.position, me.totalPoints, '$plenos · vas primero');
    final above = ranking[i - 1];
    final gap = (above.totalPoints - me.totalPoints).clamp(0, 1 << 30);
    return QuizMyPlace(me.position, me.totalPoints,
        '$plenos · a ${quizCount(gap, 'punto', 'puntos')} del ${above.position}.º');
  }
  if (stats == null || stats.gamesPlayed == 0) {
    return const QuizMyPlace(
        null, null, 'Juega una partida y tu nombre aparecerá aquí.');
  }
  return QuizMyPlace(null, stats.totalPoints,
      'Sigue sumando puntos y tu nombre aparecerá aquí.');
}

/// Pie de la fila del ranking: «11 plenos» / «sin plenos aún».
String quizRankingSub(QuizRankingEntry e) => e.gamesWon == 0
    ? 'sin plenos aún'
    : quizCount(e.gamesWon, 'pleno', 'plenos');

// ── Historial ───────────────────────────────────────────────────────────────

/// Cabecera del historial: «3 partidas · 1 pleno». Prefiere las stats (el
/// historial viene limitado a las últimas 10).
String quizHistoryHeader(List<QuizSessionSummary> history, QuizStats? stats) {
  final played = stats?.gamesPlayed ?? history.length;
  final won = stats?.gamesWon ?? history.where((h) => h.isWon).length;
  final p = played < history.length ? history.length : played;
  return '${quizCount(p, 'partida', 'partidas')} · ${quizCount(won, 'pleno', 'plenos')}';
}

/// Pie de la fila: «12 oct · mejor racha 7».
String quizHistorySub(QuizSessionSummary h, {DateTime? now}) {
  final d = quizShortDate(h.endedAt, now: now);
  final racha = 'mejor racha ${h.bestStreak}';
  return d == null ? racha : '$d · $racha';
}
