import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmPlaceName;

/// Encuesta «Premios Donde Comer Canarias 2026» (tableros Encuesta*): el
/// estado que pintan las vistas y la lógica pura que no depende del backend
/// (normalización del buscador, puestos compartidos, cuenta atrás, copy de
/// los errores). Las vistas solo leen estos tipos; quién los rellena (el
/// presenter de hoy o el del contrato nuevo) vive en `premios_controllers`.

// ── Categorías ─────────────────────────────────────────────────────────────

enum PremiosCategory {
  tradicional(
    apiName: 'Mejor-Guachinche-Tradicional',
    short: 'tradicional',
    title: 'Mejor guachinche tradicional',
    plural: 'Tradicionales',
  ),
  moderno(
    apiName: 'Mejor-Guachinche-Moderno',
    short: 'moderno',
    title: 'Mejor guachinche moderno',
    plural: 'Modernos',
  );

  final String apiName;
  final String short;
  final String title;
  final String plural;

  const PremiosCategory({
    required this.apiName,
    required this.short,
    required this.title,
    required this.plural,
  });

  /// «36 guachinches» / «154 sitios» (el tablero distingue los dos).
  String candidatesNoun(int n) => this == tradicional
      ? (n == 1 ? 'guachinche' : 'guachinches')
      : (n == 1 ? 'sitio' : 'sitios');
}

/// Una opción de la papeleta. El backend solo manda `value` y `text`; el
/// nombre se pinta en tipo título (los textos llegan casi siempre en
/// mayúsculas).
@immutable
class PremiosCandidate {
  final String value;
  final String name;

  const PremiosCandidate({required this.value, required this.name});

  factory PremiosCandidate.fromApi(String value, String text) =>
      PremiosCandidate(value: value, name: premiosDisplayName(text));

  @override
  bool operator ==(Object other) =>
      other is PremiosCandidate && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

const _kSmall = {'de', 'del', 'y', 'en', 'por', 'con'};
const _kArticles = {'el', 'la', 'los', 'las', 'a'};
final _kLetter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
final _kVowel = RegExp(r'[AEIOUÁÉÍÓÚÜaeiouáéíóúü]');

/// Nombres de la papeleta en tipo título, palabra a palabra (como los datos
/// del tablero): «GUACHINCHE LA CUADRA (Los Realejos)» → «Guachinche La
/// Cuadra (Los Realejos)», «BODEGON DE LA ERA» → «Bodegon de la Era». Las
/// palabras ya mixtas y las siglas sin vocales se respetan; no se inventan
/// tildes. Comillas rectas → «».
String premiosDisplayName(String raw) {
  final words =
      raw.replaceAll(RegExp('[“”]'), '"').trim().split(RegExp(r'\s+'));
  final out = <String>[];
  var prev = '';
  for (var i = 0; i < words.length; i++) {
    var w = words[i];
    final core = w.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]'), '');
    final low = core.toLowerCase();
    final opens = w.startsWith('(') || w.startsWith('"');
    final small = i > 0 &&
        !opens &&
        (_kSmall.contains(low) ||
            (_kArticles.contains(low) && _kSmall.contains(prev)));
    final caps = core.length > 1 && core == core.toUpperCase();
    if (small && (caps || core == low)) {
      w = w.toLowerCase();
    } else if (caps && _kVowel.hasMatch(core)) {
      final lw = w.toLowerCase();
      final k = lw.indexOf(_kLetter);
      w = k < 0
          ? lw
          : lw.substring(0, k) + lw[k].toUpperCase() + lw.substring(k + 1);
    } else if (core.isNotEmpty && core[0] == core[0].toLowerCase() && !small) {
      final k = w.indexOf(_kLetter);
      if (k >= 0)
        w = w.substring(0, k) + w[k].toUpperCase() + w.substring(k + 1);
    }
    out.add(w);
    prev = low;
  }
  return out
      .join(' ')
      .replaceAllMapped(RegExp(r'"\s*([^"]*?)\s*"'), (m) => '«${m[1]}»');
}

// ── Buscador ───────────────────────────────────────────────────────────────

const _kFold = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'ã': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Sin tildes ni mayúsculas, con los espacios colapsados: «JOSÉ» y «jose»
/// son lo mismo (como el `normalize('NFD')` del tablero).
String premiosNormalize(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final r in lower.runes) {
    // Diacríticos combinados (NFD, U+0300–U+036F): fuera.
    if (r >= 0x300 && r <= 0x36F) continue;
    final ch = String.fromCharCode(r);
    b.write(_kFold[ch] ?? ch);
  }
  return b.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Filtra la lista por el texto del buscador (normalizado en los dos lados).
List<PremiosCandidate> premiosFilter(
    List<PremiosCandidate> list, String query) {
  final q = premiosNormalize(query);
  if (q.isEmpty) return list;
  return [
    for (final c in list)
      if (premiosNormalize(c.name).contains(q)) c,
  ];
}

// ── Errores al enviar ──────────────────────────────────────────────────────

/// Errores que la UI sabe pintar. Los de hoy llegan del presenter actual;
/// [deviceUnverified] (403) y [rateLimited] (429) vendrán con el contrato
/// nuevo de identidad del dispositivo.
enum PremiosErrorKind {
  noSelection,
  tooFast,
  alreadyVoted,
  deviceUnverified,
  rateLimited,
  network,
  server,
}

@immutable
class PremiosError {
  final PremiosErrorKind kind;

  /// En un 409: la opción rechazada, si se sabe (hoy se averigua repitiendo
  /// `GET surveys/results/1/by-device`; el contrato nuevo la devolverá).
  final PremiosCategory? category;
  final String? value;

  const PremiosError(this.kind, {this.category, this.value});

  @override
  bool operator ==(Object other) =>
      other is PremiosError &&
      other.kind == kind &&
      other.category == category &&
      other.value == value;

  @override
  int get hashCode => Object.hash(kind, category, value);
}

enum PremiosTone { warn, closed }

enum PremiosAlertIcon { warn, clock, network, error }

/// Texto de cada aviso de Revisar (tablero EncuestaRevisar). Los mensajes
/// literales del backend/presenter se conservan en [message].
@immutable
class PremiosErrorCopy {
  final String title;
  final String message;
  final String help;
  final PremiosTone tone;
  final PremiosAlertIcon icon;

  /// Botón dentro del aviso (solo «Te falta elegir»).
  final String? action;

  /// El botón principal pasa a «Reintentar».
  final bool retry;

  const PremiosErrorCopy({
    required this.title,
    required this.message,
    required this.help,
    required this.tone,
    required this.icon,
    this.action,
    this.retry = false,
  });
}

/// [rowFlagged]: tras un 409 ya se sabe qué fila tenía el voto.
PremiosErrorCopy premiosErrorCopy(PremiosErrorKind kind,
    {bool rowFlagged = false}) {
  switch (kind) {
    case PremiosErrorKind.noSelection:
      return const PremiosErrorCopy(
        title: 'Te falta elegir',
        message: 'Debes seleccionar al menos una opción.',
        help: 'Con un guachinche en una de las dos categorías ya vale.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.warn,
        action: 'Elegir guachinche',
      );
    case PremiosErrorKind.tooFast:
      return const PremiosErrorCopy(
        title: 'Con calma, que no se enfría',
        message: 'Por favor, tómate tu tiempo para votar.',
        help: 'Echa un ojo a tus votos y vuelve a enviarlos.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
      );
    case PremiosErrorKind.alreadyVoted:
      return rowFlagged
          ? const PremiosErrorCopy(
              title: 'Ese ya tenía tu voto',
              message: 'Ya has votado a este negocio anteriormente.',
              help: 'Cámbialo por otro guachinche o quítalo, y envía el resto.',
              tone: PremiosTone.warn,
              icon: PremiosAlertIcon.warn,
            )
          : const PremiosErrorCopy(
              title: 'Uno de estos ya tenía tu voto',
              message: 'Ya has votado a este negocio anteriormente.',
              help: 'Cambia el que ya votaste y vuelve a enviar.',
              tone: PremiosTone.warn,
              icon: PremiosAlertIcon.warn,
            );
    // Copy provisional (pendiente del diseño): 403 del contrato nuevo de
    // identidad del dispositivo.
    case PremiosErrorKind.deviceUnverified:
      return const PremiosErrorCopy(
        title: 'No hemos podido comprobar este\u00A0móvil',
        message: 'Así evitamos votos repetidos. Actualiza la app o '
            'inténtalo más tarde.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.error,
        retry: true,
      );
    // Copy provisional (pendiente del diseño): 429.
    case PremiosErrorKind.rateLimited:
      return const PremiosErrorCopy(
        title: 'Un momentito, que hay cola',
        message: 'Has enviado muchas veces seguidas. Espera un poco y '
            'vuelve a probar.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
        retry: true,
      );
    case PremiosErrorKind.network:
      return const PremiosErrorCopy(
        title: 'Se nos fue la cobertura',
        message: 'Revisa tu conexión e inténtalo de nuevo.',
        help: 'Tus votos siguen aquí, no se pierden.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.network,
        retry: true,
      );
    case PremiosErrorKind.server:
      return const PremiosErrorCopy(
        title: 'No pudimos enviar tus votos',
        message: 'No se pudo enviar tu voto. Inténtalo de nuevo.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.error,
        retry: true,
      );
  }
}

// ── Estado del flujo de votación ───────────────────────────────────────────

enum PremiosLoad { loading, ready, error }

@immutable
class PremiosFlowState {
  final PremiosLoad load;
  final Map<PremiosCategory, List<PremiosCandidate>> candidates;
  final Map<PremiosCategory, PremiosCandidate> picks;
  final bool submitting;
  final PremiosError? error;

  /// Opciones elegidas que este móvil ya había votado (tras un 409).
  final Set<String> flagged;

  /// Votos enviados con éxito (Gracias). `null` mientras no se envía.
  final Map<PremiosCategory, PremiosCandidate>? sent;

  const PremiosFlowState({
    this.load = PremiosLoad.loading,
    this.candidates = const {},
    this.picks = const {},
    this.submitting = false,
    this.error,
    this.flagged = const {},
    this.sent,
  });

  List<PremiosCandidate> candidatesOf(PremiosCategory c) =>
      candidates[c] ?? const [];

  int get pickCount => picks.length;

  PremiosFlowState copyWith({
    PremiosLoad? load,
    Map<PremiosCategory, List<PremiosCandidate>>? candidates,
    Map<PremiosCategory, PremiosCandidate>? picks,
    bool? submitting,
    PremiosError? Function()? error,
    Set<String>? flagged,
    Map<PremiosCategory, PremiosCandidate>? Function()? sent,
  }) =>
      PremiosFlowState(
        load: load ?? this.load,
        candidates: candidates ?? this.candidates,
        picks: picks ?? this.picks,
        submitting: submitting ?? this.submitting,
        error: error != null ? error() : this.error,
        flagged: flagged ?? this.flagged,
        sent: sent != null ? sent() : this.sent,
      );
}

/// Resumen de la barra de Revisar: (título, subtítulo).
(String, String) premiosPickSummary(
    Map<PremiosCategory, PremiosCandidate> picks) {
  final t = picks.containsKey(PremiosCategory.tradicional);
  final m = picks.containsKey(PremiosCategory.moderno);
  if (t && m) return ('2 votos', 'Tradicional y moderno');
  if (t) return ('1 voto', 'Solo tradicional');
  if (m) return ('1 voto', 'Solo moderno');
  return ('Ningún voto', 'Elige al menos uno');
}

// ── Ranking ────────────────────────────────────────────────────────────────

String premiosVotes(int v) => v == 1 ? '1 voto' : '$v votos';

/// Puestos compartidos (competición): votos 7 · 6 · 6 · 5 → 1, 2, 2, 4.
/// [votes] debe venir ordenado de mayor a menor.
List<int> premiosCompetitionRanks(List<int> votes) {
  final out = <int>[];
  for (var i = 0; i < votes.length; i++) {
    out.add(i > 0 && votes[i] == votes[i - 1] ? out[i - 1] : i + 1);
  }
  return out;
}

@immutable
class PremiosRankEntry {
  final String id;
  final String name;
  final String municipio;
  final String? photoUrl;
  final int votes;
  final int rank;

  /// Comparte puesto con otro.
  final bool tied;

  /// Votado desde este móvil.
  final bool mine;

  const PremiosRankEntry({
    required this.id,
    required this.name,
    required this.municipio,
    required this.photoUrl,
    required this.votes,
    required this.rank,
    required this.tied,
    required this.mine,
  });
}

/// Nombre cuando el resultado no casa con ningún restaurante de la encuesta
/// (antes `firstWhere` sin `orElse` tumbaba la pantalla).
const kPremiosMissingName = 'Sitio sin ficha';

/// Resultados del backend → filas con puesto real (empates incluidos).
List<PremiosRankEntry> premiosRank(List<SurveyResult> results) {
  String name(SurveyResult r) => r.restaurant == null
      ? kPremiosMissingName
      : premiosDisplayName(r.restaurant!.nombre);
  // Más votos primero; con los mismos votos, por nombre (orden estable).
  final sorted = [...results]..sort((a, b) {
      final v = b.votes.compareTo(a.votes);
      return v != 0
          ? v
          : premiosNormalize(name(a)).compareTo(premiosNormalize(name(b)));
    });
  final ranks = premiosCompetitionRanks([for (final r in sorted) r.votes]);
  final count = <int, int>{};
  for (final r in ranks) {
    count[r] = (count[r] ?? 0) + 1;
  }
  return [
    for (var i = 0; i < sorted.length; i++)
      PremiosRankEntry(
        id: sorted[i].restaurantId,
        name: name(sorted[i]),
        municipio: gmPlaceName(sorted[i].restaurant?.municipio ?? ''),
        photoUrl: (sorted[i].restaurant?.mainFoto.isNotEmpty ?? false)
            ? sorted[i].restaurant!.mainFoto
            : null,
        votes: sorted[i].votes,
        rank: ranks[i],
        tied: (count[ranks[i]] ?? 0) > 1,
        mine: sorted[i].isVotedByUser,
      ),
  ];
}

/// «Bodega Zacatín (Guachinche El Churrasco)» → nombre y paréntesis en
/// línea aparte (podio).
(String, String) premiosSplitName(String name) {
  final m = RegExp(r'^(.*?)\s*(\(.*\))\s*$').firstMatch(name);
  if (m == null || m.group(1)!.isEmpty) return (name, '');
  return (m.group(1)!, m.group(2)!);
}

@immutable
class PremiosRankingState {
  final PremiosLoad load;
  final List<PremiosRankEntry> tradicional;
  final List<PremiosRankEntry> moderno;

  const PremiosRankingState({
    this.load = PremiosLoad.loading,
    this.tradicional = const [],
    this.moderno = const [],
  });

  List<PremiosRankEntry> of(PremiosCategory c) =>
      c == PremiosCategory.tradicional ? tradicional : moderno;

  bool get hasMine =>
      tradicional.any((e) => e.mine) || moderno.any((e) => e.mine);
}

// ── Edición y cuenta atrás ─────────────────────────────────────────────────

/// Estado de la votación. [unknown]: no hay fecha de cierre configurada →
/// estado neutro (ni cuenta atrás ni «cerrada»; la campaña no se anuncia).
enum PremiosPhase {
  unknown,
  upcoming,
  open,
  lastDay,
  closed;

  /// Se puede votar (sin fecha manda el servidor: no se bloquea).
  bool get canVote => this != closed && this != upcoming;

  /// Hay cuenta atrás que enseñar.
  bool get counting => this == open || this == lastDay;
}

const _kMonths = [
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

/// Una edición de los premios: apertura y cierre de la votación en UTC.
/// Hoy llega de Remote Config (`premios_closes_at`); el repositorio del
/// contrato v3 la rellenará con `GET /surveys/v3/editions/current`
/// ([PremiosEdition.fromApi]) y la publicará en [PremiosEditionStore].
/// Todos los cálculos van en UTC (hora del servidor), nunca en la local.
@immutable
class PremiosEdition {
  final DateTime? votingStartsAt;
  final DateTime? votingEndsAt;

  PremiosEdition({DateTime? votingStartsAt, DateTime? votingEndsAt})
      : votingStartsAt = votingStartsAt?.toUtc(),
        votingEndsAt = votingEndsAt?.toUtc();

  /// Sin fechas: estado neutro.
  static final PremiosEdition none = PremiosEdition();

  /// `{"votingStartsAt": "…Z", "votingEndsAt": "…Z"}` de
  /// `GET /surveys/v3/editions/current`.
  factory PremiosEdition.fromApi(Map<String, dynamic> json) {
    DateTime? d(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toUtc() : null;
    return PremiosEdition(
      votingStartsAt: d(json['votingStartsAt']),
      votingEndsAt: d(json['votingEndsAt']),
    );
  }

  bool get known => votingEndsAt != null;

  PremiosPhase phase(DateTime now) {
    final end = votingEndsAt;
    if (end == null) return PremiosPhase.unknown;
    final n = now.toUtc();
    final start = votingStartsAt;
    if (start != null && n.isBefore(start)) return PremiosPhase.upcoming;
    if (!n.isBefore(end)) return PremiosPhase.closed;
    return daysLeft(n) == 0 ? PremiosPhase.lastDay : PremiosPhase.open;
  }

  /// Días de calendario hasta el día del cierre, comparando fechas UTC (el
  /// cambio de hora no resta un día).
  int daysLeft(DateTime now) {
    final end = votingEndsAt;
    if (end == null) return 0;
    final n = now.toUtc();
    final a = DateTime.utc(n.year, n.month, n.day);
    final b = DateTime.utc(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }

  /// Casilla de la cuenta atrás: días; el último día, horas. Sin minutos.
  (int, String) countdown(DateTime now) {
    final end = votingEndsAt;
    if (end == null) return (0, 'días');
    if (phase(now) == PremiosPhase.lastDay) {
      final h =
          (end.difference(now.toUtc()).inMinutes / 60).ceil().clamp(1, 24);
      return (h, h == 1 ? 'hora' : 'horas');
    }
    final d = daysLeft(now).clamp(0, 9999);
    return (d, d == 1 ? 'día' : 'días');
  }

  /// «Quedan 12 días» / «Quedan 9 horas».
  String remainingLabel(DateTime now) {
    final (n, unit) = countdown(now);
    return n == 1 ? 'Queda 1 $unit' : 'Quedan $n $unit';
  }

  /// «hasta el 20 de marzo» (fecha UTC del cierre). Vacío sin fecha.
  String get untilShort {
    final end = votingEndsAt;
    if (end == null) return '';
    return 'hasta el ${end.day} de ${_kMonths[end.month - 1]}';
  }

  /// «Se vota hasta el 20 de marzo».
  String get untilLabel => known ? 'Se vota $untilShort' : '';

  @override
  bool operator ==(Object other) =>
      other is PremiosEdition &&
      other.votingStartsAt == votingStartsAt &&
      other.votingEndsAt == votingEndsAt;

  @override
  int get hashCode => Object.hash(votingStartsAt, votingEndsAt);
}

/// La edición en curso, compartida por las pantallas. Arranca vacía (estado
/// neutro); [PremiosEditionStore.loadFromRemoteConfig] la rellena y el
/// repositorio v3 la sustituirá por la de la API.
class PremiosEditionStore extends ValueNotifier<PremiosEdition> {
  PremiosEditionStore._() : super(PremiosEdition.none);

  static final PremiosEditionStore instance = PremiosEditionStore._();

  PremiosEdition get current => value;

  bool _loaded = false;

  /// Lee Remote Config una vez (las pantallas lo llaman al abrirse).
  void ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    DateTime? closes;
    try {
      closes = DccRemoteConfig.instance.premiosClosesAt;
    } catch (e) {
      // Sin Firebase (tests): sin fecha → estado neutro.
      AppLogger.warn('premios', 'remote config no disponible: $e');
    }
    loadFromRemoteConfig(closes);
  }

  @visibleForTesting
  void reset() {
    _loaded = false;
    value = PremiosEdition.none;
  }

  /// [closesAt] viene de Remote Config `premios_closes_at` (ISO UTC). En
  /// debug, `PREMIOS_CLOSES_AT` en `env_files/debug.env` manda.
  void loadFromRemoteConfig(DateTime? closesAt) {
    final raw = dotenv.isInitialized ? dotenv.env['PREMIOS_CLOSES_AT'] : null;
    final debug = raw == null ? null : DateTime.tryParse(raw.trim());
    _loaded = true;
    value = PremiosEdition(votingEndsAt: debug ?? closesAt);
  }
}
