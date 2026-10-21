import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:http/http.dart' show Client;
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

  /// «Tradicional» / «Moderno» (segmentado del Inicio).
  String get singular => short[0].toUpperCase() + short.substring(1);

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
/// Avisos sobre la papeleta (Revisar) o al cargar. Vienen de los
/// `SurveyFailure` del presenter v3 (`docs/encuesta-antivoto.md` §3).
enum PremiosErrorKind {
  noSelection,
  tooFast,
  alreadyVoted,

  /// 403 `integrity_failed` o App Check rechazado en el móvil.
  deviceUnverified,

  /// 429 o Firebase limitando tokens.
  rateLimited,

  /// 503 o Firebase / Apple / Google sin servicio.
  verificationUnavailable,

  /// 422 `invalid_option`: la opción ya no es candidata.
  invalidOption,

  /// El pinning de `/surveys/v3` falla (proxy, CA instalada, portal
  /// cautivo): no se ha enviado nada.
  insecureConnection,

  /// `503 integrity_unavailable`: el backend de la encuesta no está listo.
  /// Reintentar no sirve.
  votingUnavailable,
  network,
  server,
}

/// Lo que impide votar (pantalla entera, no un aviso sobre la papeleta).
enum PremiosGate {
  /// La edición aún no ha abierto.
  upcoming,

  /// Votación cerrada (hora del servidor).
  closed,

  /// `403 device_blocked`.
  blocked,

  /// `426` o versión por debajo de `minAppVersion`.
  upgradeRequired,

  /// Sin App Attest / Google Play: no puede dar token de App Check.
  unsupported,
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
    {bool rowFlagged = false, String store = 'la tienda'}) {
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
    // Textos de `docs/encuesta-antivoto.md` §3 en el tono de la app.
    case PremiosErrorKind.deviceUnverified:
      return PremiosErrorCopy(
        title: 'No hemos podido comprobar este\u00A0móvil',
        // Actualizar la app no arregla un fallo de Play Integrity / App
        // Attest: lo que suele fallar es la tienda, la hora o la conexión.
        message: store == 'Google Play'
            ? 'Mira que Google Play esté al día y la hora del móvil en '
                'automático, y vuelve a probar.'
            : 'Mira que tengas conexión y la hora del móvil en automático, '
                'y vuelve a probar. Si sigue igual, actualiza la app desde '
                '$store.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.error,
        retry: true,
      );
    case PremiosErrorKind.rateLimited:
      return const PremiosErrorCopy(
        title: 'Un momentito, que hay cola',
        message: 'Demasiados intentos, prueba en un minuto.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
        retry: true,
      );
    case PremiosErrorKind.verificationUnavailable:
      return const PremiosErrorCopy(
        title: 'Ahora mismo no podemos comprobarlo',
        message: 'No podemos verificar ahora mismo, inténtalo en unos minutos.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
        retry: true,
      );
    case PremiosErrorKind.invalidOption:
      return const PremiosErrorCopy(
        title: 'Ese sitio ya no está en la lista',
        message: 'Uno de tus votos ya no es candidato.',
        help: 'Elige otro y vuelve a enviar.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.warn,
      );
    case PremiosErrorKind.insecureConnection:
      return const PremiosErrorCopy(
        title: 'No podemos conectar de forma segura',
        message: 'Prueba con otra red, por ejemplo con datos móviles.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.network,
        retry: true,
      );
    case PremiosErrorKind.votingUnavailable:
      return const PremiosErrorCopy(
        title: 'La votación no está disponible ahora\u00A0mismo',
        message: 'Vuelve más tarde.',
        help: 'Tus votos siguen aquí.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
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

/// Pantalla de bloqueo de cada [PremiosGate], con la estética de los avisos.
/// [action] es el botón (tienda, ranking…).
PremiosErrorCopy premiosGateCopy(PremiosGate gate,
    {String store = 'la tienda', String? minVersion, String opensLabel = ''}) {
  switch (gate) {
    case PremiosGate.upcoming:
      return PremiosErrorCopy(
        title: 'La votación aún no ha empezado',
        message: opensLabel.isEmpty
            ? 'Te avisamos en cuanto abra.'
            : 'Abre $opensLabel.',
        help: 'Mientras tanto, mira quién va delante.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
        action: 'Ver el ranking',
      );
    case PremiosGate.closed:
      return const PremiosErrorCopy(
        title: 'La votación ya está cerrada',
        message: 'Gracias a todos los que votaron.',
        help: 'Ya tenemos ganadores.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.clock,
        action: 'Ver ganadores',
      );
    case PremiosGate.blocked:
      return const PremiosErrorCopy(
        title: 'Este móvil no puede votar',
        message: 'Hemos visto algo raro con los votos desde este móvil.',
        help: 'Si crees que es un error, escríbenos.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.error,
        action: 'Ver el ranking',
      );
    case PremiosGate.upgradeRequired:
      return PremiosErrorCopy(
        title: 'Actualiza la app para votar',
        message: minVersion == null
            ? 'Esta versión ya no puede votar.'
            : 'Hace falta la versión $minVersion o una más nueva.',
        help: 'Es un momento y tu voto te espera.',
        tone: PremiosTone.warn,
        icon: PremiosAlertIcon.warn,
        action: 'Abrir $store',
      );
    case PremiosGate.unsupported:
      return const PremiosErrorCopy(
        title: 'Este móvil no puede verificarse para\u00A0votar',
        message: 'Para votar hace falta un iPhone con iOS 15 o un Android con '
            'Google Play.',
        help: 'El ranking sí lo puedes seguir.',
        tone: PremiosTone.closed,
        icon: PremiosAlertIcon.error,
        action: 'Ver el ranking',
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

  /// Tras un 409: el sitio que ya tenía voto, por categoría (el presenter ya
  /// lo quitó de [picks]; la fila lo enseña marcado).
  final Map<PremiosCategory, PremiosCandidate> conflicts;

  /// Lo que impide votar (pantalla entera).
  final PremiosGate? gate;

  /// Por qué no cargó ([load] == error).
  final PremiosErrorKind? loadError;

  /// Versión mínima con [PremiosGate.upgradeRequired].
  final String? minAppVersion;

  const PremiosFlowState({
    this.load = PremiosLoad.loading,
    this.candidates = const {},
    this.picks = const {},
    this.submitting = false,
    this.error,
    this.flagged = const {},
    this.sent,
    this.conflicts = const {},
    this.gate,
    this.loadError,
    this.minAppVersion,
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
    Map<PremiosCategory, PremiosCandidate>? conflicts,
    PremiosGate? Function()? gate,
    PremiosErrorKind? Function()? loadError,
    String? Function()? minAppVersion,
  }) =>
      PremiosFlowState(
        load: load ?? this.load,
        candidates: candidates ?? this.candidates,
        picks: picks ?? this.picks,
        submitting: submitting ?? this.submitting,
        error: error != null ? error() : this.error,
        flagged: flagged ?? this.flagged,
        sent: sent != null ? sent() : this.sent,
        conflicts: conflicts ?? this.conflicts,
        gate: gate != null ? gate() : this.gate,
        loadError: loadError != null ? loadError() : this.loadError,
        minAppVersion:
            minAppVersion != null ? minAppVersion() : this.minAppVersion,
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

/// Nombre de un candidato que llega sin nombre.
const kPremiosMissingName = 'Sitio sin ficha';

/// Filas de `GET editions/:id/results` → entradas del ranking. El puesto
/// ([SurveyResultRow.rank]) viene del servidor con los puestos compartidos y
/// el desempate; solo si falta se calcula aquí. Los candidatos con 0 votos
/// no entran (ni podio ni «El resto»: una lista de ceros no dice nada).
List<PremiosRankEntry> premiosRankFromRows(List<SurveyResultRow> rows,
    {bool Function(String value)? isMine}) {
  final voted = [
    for (final r in rows)
      if (r.votes > 0) r
  ];
  final serverRanks = voted.every((r) => r.rank > 0);
  final sorted = serverRanks
      ? ([...voted]..sort((a, b) => a.rank.compareTo(b.rank)))
      : ([...voted]..sort((a, b) => b.votes.compareTo(a.votes)));
  final ranks = serverRanks
      ? [for (final r in sorted) r.rank]
      : premiosCompetitionRanks([for (final r in sorted) r.votes]);
  final count = <int, int>{};
  for (final r in ranks) {
    count[r] = (count[r] ?? 0) + 1;
  }
  return [
    for (var i = 0; i < sorted.length; i++)
      PremiosRankEntry(
        id: sorted[i].value,
        name: sorted[i].name.trim().isEmpty
            ? kPremiosMissingName
            : premiosDisplayName(sorted[i].name),
        municipio: gmPlaceName(sorted[i].municipality ?? ''),
        photoUrl: sorted[i].photoUrl,
        votes: sorted[i].votes,
        rank: ranks[i],
        tied: (count[ranks[i]] ?? 0) > 1,
        mine: isMine?.call(sorted[i].value) ?? false,
      ),
  ];
}

/// Nombre corto para el podio compacto de la card del Inicio: sin el
/// genérico «Guachinche» delante («Guachinche Don Trino» → «Don Trino»). El
/// nombre completo va en el texto accesible.
String premiosShortName(String name) {
  const prefix = 'Guachinche ';
  final n = name.trim();
  if (n.length > prefix.length &&
      n.toLowerCase().startsWith(prefix.toLowerCase())) {
    return n.substring(prefix.length).trim();
  }
  return n;
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

  /// `hidden: true` (modo `after_close`): el ranking se desvela al cierre.
  final bool hidden;

  /// Votos totales de cada categoría (del servidor).
  final Map<PremiosCategory, int> totals;

  const PremiosRankingState({
    this.load = PremiosLoad.loading,
    this.tradicional = const [],
    this.moderno = const [],
    this.hidden = false,
    this.totals = const {},
  });

  /// Votos de las dos categorías.
  int get totalVotes => totals.values.fold(0, (a, b) => a + b);

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

/// Una edición de los premios: estado, apertura y cierre de la votación.
/// Sale solo de `GET /surveys/v3/editions/current`
/// ([PremiosEdition.fromSurvey]): el estado (`upcoming`/`open`/`closed`) lo
/// calcula el servidor con su hora y manda sobre el reloj del móvil; las
/// fechas (UTC) dan la cuenta atrás, con la hora del servidor ([skew]). Sin
/// respuesta (404 o red) no hay edición: [PremiosEdition.none].
@immutable
class PremiosEdition {
  final DateTime? votingStartsAt;
  final DateTime? votingEndsAt;

  /// Estado según el servidor (`null` sin edición).
  final SurveyEditionStatus? status;

  /// `editionId` de la API v3 (`null` sin edición).
  final int? id;

  /// `label` de la API v3 («Premios Donde Comer Canarias 2027»).
  final String label;

  /// Hora del servidor menos la del móvil (cabecera `Date` de la respuesta).
  final Duration skew;

  PremiosEdition(
      {DateTime? votingStartsAt,
      DateTime? votingEndsAt,
      this.status,
      this.id,
      this.label = '',
      this.skew = Duration.zero})
      : votingStartsAt = votingStartsAt?.toUtc(),
        votingEndsAt = votingEndsAt?.toUtc();

  /// [now] del móvil llevado a la hora del servidor.
  DateTime _server(DateTime now) => now.toUtc().add(skew);

  /// Año de la edición: el del `label` si lo trae y, si no, el del cierre.
  /// Sin edición, `null`: nunca un año inventado.
  int? get year {
    final m = RegExp(r'(?<!\d)(20\d\d)(?!\d)').firstMatch(label);
    if (m != null) return int.parse(m.group(1)!);
    return votingEndsAt?.year;
  }

  /// « 2027» o vacío, para pegar detrás de un título.
  String get _yearSuffix => year == null ? '' : ' $year';

  /// «Premios Donde Comer Canarias 2027» (sin año si no hay edición).
  String get awardsTitle => 'Premios Donde Comer Canarias$_yearSuffix';

  /// «Premios 2027».
  String get shortTitle => 'Premios$_yearSuffix';

  /// «Ganadores 2027».
  String get winnersTitle => 'Ganadores$_yearSuffix';

  /// Sin fechas: estado neutro.
  static final PremiosEdition none = PremiosEdition();

  factory PremiosEdition.fromSurvey(SurveyEdition e) => PremiosEdition(
        votingStartsAt: e.votingStartsAt,
        votingEndsAt: e.votingEndsAt,
        status: e.status,
        id: e.editionId,
        label: e.label,
        skew: e.clockSkew,
      );

  /// La caché local de `editions/current` ([toJson]). `null` si no se
  /// entiende.
  static PremiosEdition? fromJson(Object? json) {
    if (json is! Map) return null;
    DateTime? d(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toUtc() : null;
    final status = switch (json['status']) {
      'open' => SurveyEditionStatus.open,
      'upcoming' => SurveyEditionStatus.upcoming,
      'closed' => SurveyEditionStatus.closed,
      _ => null,
    };
    final id = json['editionId'];
    if (status == null || id is! num) return null;
    final skew = json['skewMs'];
    return PremiosEdition(
      votingStartsAt: d(json['votingStartsAt']),
      votingEndsAt: d(json['votingEndsAt']),
      status: status,
      id: id.toInt(),
      label: json['label']?.toString() ?? '',
      skew: Duration(milliseconds: skew is num ? skew.toInt() : 0),
    );
  }

  Map<String, Object?> toJson() => {
        'editionId': id,
        'label': label,
        'status': status?.name,
        'votingStartsAt': votingStartsAt?.toIso8601String(),
        'votingEndsAt': votingEndsAt?.toIso8601String(),
        'skewMs': skew.inMilliseconds,
      };

  /// Días que el Inicio sigue enseñando a los ganadores tras el cierre.
  static const winnersFor = Duration(days: 15);

  /// ¿Se anuncia la campaña en el Inicio? Solo con edición del servidor:
  /// abierta (card y hoja) o cerrada hace [winnersFor] o menos
  /// («Ganadores»). `upcoming`, más de 15 días cerrada o sin edición (404,
  /// red): nada. `upcoming` no se anuncia porque aún no se puede votar ni
  /// hay ranking; las pantallas de la encuesta ya enseñan «Abre el …».
  bool showOnHome(DateTime now) {
    if (status == null) return false;
    final p = phase(now);
    if (p.counting) return true;
    if (p != PremiosPhase.closed) return false;
    final end = votingEndsAt;
    return end != null && _server(now).difference(end) <= winnersFor;
  }

  bool get known => votingEndsAt != null;

  PremiosPhase phase(DateTime now) {
    // El servidor manda: su estado va por delante del reloj del móvil.
    switch (status) {
      case SurveyEditionStatus.upcoming:
        return PremiosPhase.upcoming;
      case SurveyEditionStatus.closed:
        return PremiosPhase.closed;
      case SurveyEditionStatus.open:
      case null:
        break;
    }
    final end = votingEndsAt;
    if (end == null) {
      return status == SurveyEditionStatus.open
          ? PremiosPhase.open
          : PremiosPhase.unknown;
    }
    final n = _server(now);
    final start = votingStartsAt;
    if (status == null) {
      if (start != null && n.isBefore(start)) return PremiosPhase.upcoming;
      if (!n.isBefore(end)) return PremiosPhase.closed;
    } else if (!n.isBefore(end)) {
      // Abierta según el servidor pero ya pasada la hora en este móvil
      // (reloj adelantado): último día, sin cuenta negativa.
      return PremiosPhase.lastDay;
    }
    return daysLeft(n) <= 0 ? PremiosPhase.lastDay : PremiosPhase.open;
  }

  /// Días de calendario hasta el día del cierre, comparando fechas UTC (el
  /// cambio de hora no resta un día).
  int daysLeft(DateTime now) {
    final end = votingEndsAt;
    if (end == null) return 0;
    final n = _server(now);
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
          (end.difference(_server(now)).inMinutes / 60).ceil().clamp(1, 24);
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

  /// «el 1 de febrero» (apertura, fecha UTC). Vacío sin fecha.
  String get opensLabel {
    final start = votingStartsAt;
    if (start == null) return '';
    return 'el ${start.day} de ${_kMonths[start.month - 1]}';
  }

  /// «Se vota hasta el 20 de marzo».
  String get untilLabel => known ? 'Se vota $untilShort' : '';

  @override
  bool operator ==(Object other) =>
      other is PremiosEdition &&
      other.votingStartsAt == votingStartsAt &&
      other.votingEndsAt == votingEndsAt &&
      other.status == status &&
      other.id == id &&
      other.label == label;

  @override
  int get hashCode =>
      Object.hash(votingStartsAt, votingEndsAt, status, id, label);
}

/// La edición en curso, compartida por las pantallas. Solo la decide el
/// servidor (`GET /surveys/v3/editions/current`, público: sin App Check ni
/// identidad). Para no hacer esperar al Inicio, la última respuesta queda en
/// caché local con un TTL corto ([cacheTtl]) y se enseña mientras llega la
/// del servidor, que siempre manda: 404 o error → sin edición.
class PremiosEditionStore extends ValueNotifier<PremiosEdition> {
  PremiosEditionStore._() : super(PremiosEdition.none);

  static final PremiosEditionStore instance = PremiosEditionStore._();

  /// Vida de la caché de `editions/current`.
  static const cacheTtl = Duration(hours: 1);
  static const _kCache = 'premiosEditionCache';

  PremiosEdition get current => value;

  bool _loaded = false;
  bool _fromServer = false;
  DateTime? _fetchedAt;
  Future<void>? _loading;
  Future<void>? _cached;

  /// ¿La edición ya la ha confirmado el servidor en este arranque? (La hoja
  /// del Inicio no sale con la caché.)
  bool get fromServer => _fromServer;

  /// Al abrir la app (Inicio) y las pantallas de la encuesta: una vez por
  /// sesión lee la caché y pide la edición al servidor.
  void ensureLoaded([RemoteRepository? repository]) {
    if (_loaded) return;
    _loaded = true;
    _cached = _readCache();
    _loading = _cached!
        .then((_) => refresh(repository ?? HttpRemoteRepository(Client())));
  }

  /// La caché ya leída (rápido): el Inicio pinta con ella sin esperar.
  Future<void> get cacheRead => _cached ?? Future.value();

  /// Espera a la respuesta del servidor (tests y pull-to-refresh).
  Future<void> get loading => _loading ?? Future.value();

  /// Al volver la app a primer plano: pide otra vez la edición si la última
  /// respuesta tiene más de [cacheTtl].
  Future<void> refreshIfStale(RemoteRepository repository, DateTime now) {
    final at = _fetchedAt;
    if (at != null && now.difference(at) < cacheTtl) {
      return Future.value();
    }
    _loaded = true;
    return _loading = refresh(repository);
  }

  /// `GET /surveys/v3/editions/current`. 404 o error: sin edición.
  Future<void> refresh(RemoteRepository repository) async {
    _fetchedAt = DateTime.now();
    try {
      final e = await repository.getCurrentSurveyEdition();
      _fromServer = true;
      value = PremiosEdition.fromSurvey(e);
      _writeCache(value);
    } on SurveyApiException catch (e) {
      // `edition_not_found`: no hay edición → sin campaña.
      AppLogger.warn('premios', 'edición: ${e.code}');
      _fromServer = true;
      value = PremiosEdition.none;
      if (e.status == 404) _clearCache();
    } catch (e) {
      AppLogger.warn('premios', 'edición no disponible: ${e.runtimeType}');
      value = PremiosEdition.none;
    }
  }

  /// La edición que trae el presenter de la votación (misma fuente).
  void publish(SurveyEdition edition) {
    _loaded = true;
    _fromServer = true;
    value = PremiosEdition.fromSurvey(edition);
    _writeCache(value);
  }

  Future<void> _readCache() async {
    try {
      final raw = await AppStorage.instance.read(key: _kCache);
      if (raw == null || raw.isEmpty || _fromServer) return;
      final m = json.decode(raw);
      final at = m is Map ? DateTime.tryParse('${m['at']}') : null;
      final e = m is Map ? PremiosEdition.fromJson(m['edition']) : null;
      if (at == null || e == null) return;
      final age = DateTime.now().toUtc().difference(at);
      if (age.isNegative || age > cacheTtl) return;
      value = e;
    } catch (e) {
      AppLogger.warn('premios', 'leer edición en caché: ${e.runtimeType}');
    }
  }

  Future<void> _writeCache(PremiosEdition e) async {
    try {
      await AppStorage.instance.write(
          key: _kCache,
          value: json.encode({
            'at': DateTime.now().toUtc().toIso8601String(),
            'edition': e.toJson(),
          }));
    } catch (e) {
      AppLogger.warn('premios', 'guardar edición: ${e.runtimeType}');
    }
  }

  Future<void> _clearCache() async {
    try {
      await AppStorage.instance.delete(key: _kCache);
    } catch (e) {
      AppLogger.warn('premios', 'borrar edición: ${e.runtimeType}');
    }
  }

  @visibleForTesting
  void reset() {
    _loaded = false;
    _fromServer = false;
    _fetchedAt = null;
    _loading = null;
    _cached = null;
    value = PremiosEdition.none;
  }

  /// Para tests y la galería de desarrollo.
  @visibleForTesting
  void set(PremiosEdition edition) {
    _loaded = true;
    value = edition;
  }
}
