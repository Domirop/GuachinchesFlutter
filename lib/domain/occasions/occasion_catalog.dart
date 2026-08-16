import 'package:guachinches/domain/occasions/occasion.dart';
import 'package:guachinches/domain/occasions/occasion_context.dart';
import 'package:guachinches/utils/contextual_pool.dart';

/// Catálogo de reglas del "Planificador por ocasión" (banner DESCUBRE PLANES).
///
/// Cada regla es (predicado + constructor de [Occasion]). El motor evalúa
/// todas, se queda con las ACTIVAS y muestra la de mayor `priority`. Tunear el
/// comportamiento = tocar solo este fichero.
///
/// Filosofía: el banner es de **anticipación** y focal — UN plan, no una lista.
/// Por eso hay prioridades claras: lo más perecedero y accionable (víspera de
/// festivo, finde) gana al copy genérico.
///
/// Campos por modo:
///  - [Occasion.eyebrow]  → antetítulo del banner ("ESTA SEMANA EN CANARIAS").
///  - [Occasion.headline] → titular grande ("Planes del finde"); el widget lo
///    pinta en mayúsculas.
///  - [Occasion.tagline]  → subcopy en cursiva ("Brunch, romerías y playa").
///  - [Occasion.body]     → copy largo, reservado para el push contextual.
///
/// Nota DB: aún no existe categoría "brunch" en el backend (ver taxonomía); el
/// finde mapea a tipos canarios + Bar/Cafetería como aproximación.

const _char = 'jonay_joana';

/// Una regla del planificador: cuándo aplica y qué ocasión emite.
class OccasionRule {
  final String id;
  final int priority;
  final bool Function(OccasionContext) active;
  final Occasion Function(OccasionContext) build;

  const OccasionRule({
    required this.id,
    required this.priority,
    required this.active,
    required this.build,
  });
}

const _findeTypes = {
  RestaurantTypeIds.restaurantes,
  RestaurantTypeIds.guachinchesModernos,
  RestaurantTypeIds.guachinchesTradicionales,
  RestaurantTypeIds.tascas,
  RestaurantTypeIds.barCafeteria,
};

final List<OccasionRule> kOccasionCatalog = [
  // ── Víspera de festivo (lo más accionable: mañana no se trabaja) ───────────
  OccasionRule(
    id: 'eve_holiday',
    priority: 100,
    active: (c) => c.tomorrowHoliday != null,
    build: (c) => Occasion(
      id: 'eve_holiday',
      priority: 100,
      character: _char,
      eyebrow: 'MAÑANA ES ${c.tomorrowHoliday!.name.toUpperCase()}',
      headline: 'Planes de festivo',
      tagline: 'Menús especiales y mesa asegurada',
      body:
          'Mañana es festivo y los sitios buenos sacan menú especial — y se '
          'llenan. Adelántate y reserva.',
      accentKey: 'festivo',
      ctaKind: OccasionCtaKind.reserve,
      typeIds: {
        RestaurantTypeIds.restaurantes,
        RestaurantTypeIds.tascas,
        RestaurantTypeIds.guachinchesTradicionales,
        RestaurantTypeIds.guachinchesModernos,
      },
    ),
  ),

  // ── Hoy es festivo ─────────────────────────────────────────────────────────
  OccasionRule(
    id: 'today_holiday',
    priority: 92,
    active: (c) => c.todayHoliday != null,
    build: (c) {
      final canario = c.todayHoliday!.canarian;
      return Occasion(
        id: 'today_holiday',
        priority: 92,
        character: _char,
        eyebrow: canario ? 'HOY, DÍA DE CANARIAS' : 'HOY ES FESTIVO',
        headline: canario ? 'Planes canariones' : 'Planes de hoy',
        tagline: canario
            ? 'Guachinche, vino del país y tradición'
            : 'Lo que abre hoy cerca de ti',
        body: canario
            ? 'Feliz Día de Canarias. Hoy toca guachinche, vino del país y '
                'comida de la tierra.'
            : 'Hoy es festivo: mira lo que abre cerca y no te quedes sin sitio.',
        accentKey: 'festivo',
        openOnly: true,
        typeIds: canario
            ? {
                RestaurantTypeIds.guachinchesTradicionales,
                RestaurantTypeIds.guachinchesModernos,
              }
            : const {},
      );
    },
  ),

  // ── Viernes tarde/noche → el finde ya ha empezado ──────────────────────────
  OccasionRule(
    id: 'friday_brunch',
    priority: 80,
    active: (c) =>
        c.weekday == DateTime.friday &&
        (c.dayPart == OccasionDayPart.afternoon ||
            c.dayPart == OccasionDayPart.evening ||
            c.dayPart == OccasionDayPart.night),
    build: (c) => const Occasion(
      id: 'friday_brunch',
      priority: 80,
      character: _char,
      eyebrow: 'ESTA SEMANA EN CANARIAS',
      headline: 'Planes del finde',
      tagline: 'Brunch, romerías y playa',
      body:
          'El finde ya está aquí. Reserva tu brunch del domingo antes de que '
          'vuelen las mesas.',
      accentKey: 'finde',
      ctaKind: OccasionCtaKind.reserve,
      typeIds: _findeTypes,
    ),
  ),

  // ── Jueves → el finde a la vista ───────────────────────────────────────────
  OccasionRule(
    id: 'thursday_weekend',
    priority: 65,
    active: (c) => c.weekday == DateTime.thursday,
    build: (c) => const Occasion(
      id: 'thursday_weekend',
      priority: 65,
      character: _char,
      eyebrow: 'ESTA SEMANA EN CANARIAS',
      headline: 'Planes del finde',
      tagline: 'Brunch, romerías y playa',
      body:
          'Finde a la vista. Adelántate: los sitios top se reservan con días.',
      accentKey: 'finde',
      typeIds: _findeTypes,
    ),
  ),

  // ── Domingo de sobremesa ───────────────────────────────────────────────────
  OccasionRule(
    id: 'sunday_sobremesa',
    priority: 56,
    active: (c) => c.weekday == DateTime.sunday && _isPlanningHour(c.dayPart),
    build: (c) => const Occasion(
      id: 'sunday_sobremesa',
      priority: 56,
      character: _char,
      eyebrow: 'ES DOMINGO',
      headline: 'Planes de domingo',
      tagline: 'Guachinche y sobremesa larga',
      body: 'Domingo de guachinche, vino del país y sin prisa.',
      accentKey: 'tradicion',
      typeIds: {
        RestaurantTypeIds.guachinchesTradicionales,
        RestaurantTypeIds.guachinchesModernos,
      },
    ),
  ),

  // ── Sábado mediodía → ¿dónde caemos hoy? ───────────────────────────────────
  OccasionRule(
    id: 'saturday_plan',
    priority: 55,
    active: (c) =>
        c.weekday == DateTime.saturday &&
        (c.dayPart == OccasionDayPart.morning ||
            c.dayPart == OccasionDayPart.midday),
    build: (c) => const Occasion(
      id: 'saturday_plan',
      priority: 55,
      character: _char,
      eyebrow: 'ES SÁBADO',
      headline: 'Planes de hoy',
      tagline: 'Comida, playa y planazo',
      body: 'Sábado resuelto en dos toques. Mira lo que más mola hoy.',
      accentKey: 'finde',
      openOnly: true,
      typeIds: _findeTypes,
    ),
  ),

  // ── Comodín entre semana (prioridad mínima: solo si nada más aplica) ───────
  OccasionRule(
    id: 'weekday_lowkey',
    priority: 10,
    active: (_) => true,
    build: (c) => const Occasion(
      id: 'weekday_lowkey',
      priority: 10,
      character: _char,
      eyebrow: 'ESTA SEMANA',
      headline: 'Planes entre semana',
      tagline: 'Sitios que merecen el viaje',
      body: 'Te guardamos sitios que merecen la pena, para cuando te apetezca.',
      accentKey: 'finde',
      typeIds: _findeTypes,
    ),
  ),
];

bool _isPlanningHour(OccasionDayPart p) =>
    p == OccasionDayPart.morning ||
    p == OccasionDayPart.midday ||
    p == OccasionDayPart.afternoon;
