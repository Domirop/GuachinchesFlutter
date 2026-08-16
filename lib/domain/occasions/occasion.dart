/// Modelo de una "ocasión" — un plan anticipado que Jonay & Joana (u otro
/// personaje) recomiendan en el home. Dominio puro: describe QUÉ se muestra y a
/// dónde lleva la CTA, sin saber nada de Flutter ni de red.
library;

/// Qué hace la CTA de la card. Hoy solo [explore] está operativa (abre la
/// búsqueda filtrada). [reserve] y [sponsored] quedan DEFINIDAS para el
/// roadmap de monetización (reserva con comisión tipo TheFork / slot
/// patrocinado por un restaurante que quiere llenar un hueco) — cuando exista
/// el partner de reservas será un cambio de datos, no de arquitectura.
enum OccasionCtaKind { explore, reserve, sponsored }

/// Una ocasión resuelta, lista para pintar.
class Occasion {
  /// Estable, para tests/analytics y como anchor de a11y.
  final String id;

  /// Mayor gana cuando varias reglas están activas a la vez (p. ej. víspera de
  /// festivo > viernes-brunch). Lo fija la regla del catálogo.
  final int priority;

  /// Clave de personaje que "firma" la recomendación. Hoy `jonay_joana`; el
  /// modelo deja la puerta abierta a otros personajes por tipo de plan.
  final String character;

  /// Antetítulo corto en mayúsculas ("FINDE A LA VISTA").
  final String eyebrow;

  /// Titular de la recomendación ("Reserva ya tu brunch del domingo"). Se usa
  /// en el modo genérico (sin sitio concreto que destacar).
  final String headline;

  /// Coletilla corta para el modo "sitio concreto": acompaña al nombre del
  /// local ("Bistró X · para tu brunch del domingo"). Minúsculas, sin punto.
  final String tagline;

  /// Subcopy de apoyo (una frase).
  final String body;

  /// Texto del botón ("Ver brunchs").
  final String ctaLabel;

  /// Clave de tinte de acento (se mapea a Color en la capa UI, igual que el
  /// catálogo de antojos) para no meter Flutter en el dominio.
  final String accentKey;

  /// Filtro destino (OR de tipos de local, IDs del backend).
  final Set<String> typeIds;

  /// Filtro destino (OR de categorías, IDs del backend).
  final Set<String> categoryIds;

  /// Si la CTA debe forzar "abierto ahora" al abrir la búsqueda.
  final bool openOnly;

  final OccasionCtaKind ctaKind;

  /// Monetización: si una marca patrocina este hueco, el id del restaurante a
  /// destacar. Hoy siempre `null`; se inyectará desde backend/Remote Config.
  final String? sponsoredRestaurantId;

  const Occasion({
    required this.id,
    required this.priority,
    required this.character,
    required this.eyebrow,
    required this.headline,
    this.tagline = '',
    required this.body,
    this.ctaLabel = '',
    required this.accentKey,
    this.typeIds = const {},
    this.categoryIds = const {},
    this.openOnly = false,
    this.ctaKind = OccasionCtaKind.explore,
    this.sponsoredRestaurantId,
  });
}
