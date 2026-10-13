import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;

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
      PremiosCandidate(value: value, name: gmDisplayName(text));

  @override
  bool operator ==(Object other) =>
      other is PremiosCandidate && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

// ── Buscador ───────────────────────────────────────────────────────────────

const _kFold = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// Sin tildes ni mayúsculas, con los espacios colapsados: «JOSÉ» y «jose»
/// son lo mismo (como el `normalize('NFD')` del tablero).
String premiosNormalize(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
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
        title: 'No hemos podido comprobar este móvil',
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
  final sorted = [...results]..sort((a, b) => b.votes.compareTo(a.votes));
  final ranks = premiosCompetitionRanks([for (final r in sorted) r.votes]);
  final count = <int, int>{};
  for (final r in ranks) {
    count[r] = (count[r] ?? 0) + 1;
  }
  return [
    for (var i = 0; i < sorted.length; i++)
      PremiosRankEntry(
        id: sorted[i].restaurantId,
        name: sorted[i].restaurant == null
            ? kPremiosMissingName
            : gmDisplayName(sorted[i].restaurant!.nombre),
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

enum PremiosPhase { open, lastDay, closed }

const _kMonths = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Fecha de cierre de la votación. La API aún no la manda (petición al
/// backend: `endsAt`/`status`); hasta entonces vive aquí. El código viejo
/// tenía `20/04/2026` mientras el texto decía «20 de marzo»: manda el texto
/// (y el tablero). En debug se puede probar otra fecha con
/// `PREMIOS_CLOSES_AT=2026-10-25T23:59` en `env_files/debug.env`.
@immutable
class PremiosEdition {
  final DateTime closesAt;

  const PremiosEdition(this.closesAt);

  static final PremiosEdition fallback =
      PremiosEdition(DateTime(2026, 3, 20, 23, 59));

  static PremiosEdition get current {
    // dotenv sin cargar (tests): fecha por defecto.
    final raw =
        dotenv.isInitialized ? dotenv.env['PREMIOS_CLOSES_AT'] : null;
    final parsed = raw == null ? null : DateTime.tryParse(raw.trim());
    return parsed == null ? fallback : PremiosEdition(parsed);
  }

  PremiosPhase phase(DateTime now) {
    if (!now.isBefore(closesAt)) return PremiosPhase.closed;
    return _daysLeft(now) == 0 ? PremiosPhase.lastDay : PremiosPhase.open;
  }

  int _daysLeft(DateTime now) {
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(closesAt.year, closesAt.month, closesAt.day);
    return b.difference(a).inDays;
  }

  /// Casilla de la cuenta atrás: días; el último día, horas. Sin minutos.
  (int, String) countdown(DateTime now) {
    if (phase(now) == PremiosPhase.lastDay) {
      final h = (closesAt.difference(now).inMinutes / 60).ceil().clamp(1, 24);
      return (h, h == 1 ? 'hora' : 'horas');
    }
    final d = _daysLeft(now).clamp(0, 9999);
    return (d, d == 1 ? 'día' : 'días');
  }

  /// «Quedan 12 días» / «Quedan 9 horas».
  String remainingLabel(DateTime now) {
    final (n, unit) = countdown(now);
    return n == 1 ? 'Queda 1 $unit' : 'Quedan $n $unit';
  }

  /// «Se vota hasta el 20 de marzo».
  String get untilLabel =>
      'Se vota hasta el ${closesAt.day} de ${_kMonths[closesAt.month - 1]}';
}
