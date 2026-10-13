import 'package:flutter/foundation.dart';

/// Modelos del contrato `/surveys/v3` (ENCUESTA-SEGURIDAD.md §3).
///
/// Plan App Check: cada petición con identidad (`my-votes`, `votes`) lleva un
/// token de App Check de uso limitado en la cabecera [kAppCheckHeader] (el
/// servidor lo consume al votar); la identidad del móvil va en el cuerpo como
/// `{platform, localIdHash}`. Nada de esto se registra.

const kAppCheckHeader = 'X-Firebase-AppCheck';

enum SurveyEditionStatus { upcoming, open, closed }

@immutable
class SurveyEdition {
  final int editionId;
  final String label;
  final SurveyEditionStatus status;
  final DateTime? votingStartsAt;
  final DateTime? votingEndsAt;

  /// `legacy` | `attested`.
  final String integrityPolicy;

  /// `business` (un voto por negocio en cualquier categoría) |
  /// `category_business`.
  final String voteScope;

  /// `{ios: "4.7.0", android: "4.7.0"}`.
  final Map<String, String> minAppVersion;
  final List<String> categories;

  const SurveyEdition({
    required this.editionId,
    required this.label,
    required this.status,
    this.votingStartsAt,
    this.votingEndsAt,
    this.integrityPolicy = 'attested',
    this.voteScope = 'business',
    this.minAppVersion = const {},
    this.categories = const [],
  });

  bool get businessScope => voteScope != 'category_business';

  factory SurveyEdition.fromJson(Map<String, dynamic> j) {
    SurveyEditionStatus status;
    switch (j['status']) {
      case 'open':
        status = SurveyEditionStatus.open;
        break;
      case 'upcoming':
        status = SurveyEditionStatus.upcoming;
        break;
      default:
        status = SurveyEditionStatus.closed;
    }
    final min = j['minAppVersion'];
    return SurveyEdition(
      editionId: (j['editionId'] as num).toInt(),
      label: j['label']?.toString() ?? '',
      status: status,
      votingStartsAt: DateTime.tryParse(j['votingStartsAt']?.toString() ?? ''),
      votingEndsAt: DateTime.tryParse(j['votingEndsAt']?.toString() ?? ''),
      integrityPolicy: j['integrityPolicy']?.toString() ?? 'attested',
      voteScope: j['voteScope']?.toString() ?? 'business',
      minAppVersion: min is Map
          ? {
              for (final e in min.entries)
                if (e.value != null) e.key.toString(): e.value.toString()
            }
          : const {},
      categories: [
        for (final c in (j['categories'] as List? ?? const [])) c.toString()
      ],
    );
  }
}

/// Votos de este dispositivo por categoría (solo `value`s).
typedef SurveyVoted = Map<String, List<String>>;

SurveyVoted parseSurveyVoted(Object? raw) {
  if (raw is! Map) return {};
  return {
    for (final e in raw.entries)
      e.key.toString(): [
        for (final v in (e.value is List ? e.value as List : const []))
          v.toString()
      ],
  };
}

/// Estado de la identidad del móvil en el servidor (`my-votes`).
enum SurveyDeviceStatus {
  /// Aún no ha votado en ninguna edición atestada.
  fresh,
  active,
  blocked,
}

/// Respuesta de `POST editions/:id/my-votes`: lo que este móvil ya votó.
@immutable
class SurveyMyVotes {
  final SurveyDeviceStatus status;
  final SurveyVoted voted;

  const SurveyMyVotes({this.status = SurveyDeviceStatus.fresh, this.voted = const {}});

  factory SurveyMyVotes.fromJson(Map<String, dynamic> j) => SurveyMyVotes(
        status: switch (j['status']) {
          'active' => SurveyDeviceStatus.active,
          'blocked' => SurveyDeviceStatus.blocked,
          _ => SurveyDeviceStatus.fresh,
        },
        voted: parseSurveyVoted(j['voted']),
      );
}

/// Un voto: categoría y `value` (id del restaurante).
@immutable
class SurveyVoteSelection {
  final String category;
  final String value;
  const SurveyVoteSelection(this.category, this.value);

  factory SurveyVoteSelection.fromJson(Map<String, dynamic> j) =>
      SurveyVoteSelection(
          j['category']?.toString() ?? '', j['value']?.toString() ?? '');

  Map<String, String> toJson() => {'category': category, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is SurveyVoteSelection &&
      other.category == category &&
      other.value == value;

  @override
  int get hashCode => Object.hash(category, value);

  @override
  String toString() => 'SurveyVoteSelection($category)';
}

@immutable
class SurveyVoteReceipt {
  final List<SurveyVoteSelection> accepted;
  final SurveyVoted voted;
  const SurveyVoteReceipt({required this.accepted, required this.voted});

  factory SurveyVoteReceipt.fromJson(Map<String, dynamic> j) =>
      SurveyVoteReceipt(
        accepted: [
          for (final a in (j['accepted'] as List? ?? const []))
            if (a is Map) SurveyVoteSelection.fromJson(Map.from(a))
        ],
        voted: parseSurveyVoted(j['voted']),
      );
}

/// Error de la API v3: `{error, message, details}` + `Retry-After`.
///
/// `message` es para registros del servidor; aquí no se guarda.
class SurveyApiException implements Exception {
  final int status;
  final String code;
  final Map<String, dynamic> details;
  final Duration? retryAfter;

  const SurveyApiException(this.status, this.code,
      {this.details = const {}, this.retryAfter});

  /// 409 `already_voted_this_business`: opciones ya votadas.
  List<SurveyVoteSelection> get conflicts => [
        for (final c in (details['conflicts'] as List? ?? const []))
          if (c is Map) SurveyVoteSelection.fromJson(Map.from(c))
      ];

  /// 403 `integrity_failed`: motivo (`app_check_missing`, `app_check_invalid`,
  /// `app_check_replayed`, `app_unrecognized`).
  String? get reason => details['reason']?.toString();

  /// 426: versión mínima (`details.minAppVersion`, texto o mapa por plataforma).
  Object? get minAppVersion => details['minAppVersion'];

  @override
  String toString() => 'SurveyApiException($status $code'
      '${reason != null ? ' / $reason' : ''})';
}

/// Sin conexión, DNS, TLS o tiempo de espera agotado. [maybeDelivered]: el
/// fallo llegó después de enviar el cuerpo (el servidor pudo procesarlo).
class SurveyNetworkException implements Exception {
  final bool maybeDelivered;
  const SurveyNetworkException({this.maybeDelivered = false});

  @override
  String toString() => 'SurveyNetworkException';
}
