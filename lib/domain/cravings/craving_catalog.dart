import 'package:guachinches/domain/cravings/craving.dart';
import 'package:guachinches/domain/cravings/craving_context.dart';
import 'package:guachinches/utils/contextual_pool.dart';

/// Catálogo de antojos de "¿Qué te apetece ahora?".
///
/// Fuente única de los pesos del motor. Cada antojo mapea a tipos/categorías
/// REALES del backend (vía [RestaurantTypeIds] / [CategoryIds]). Tunear el
/// comportamiento del feature = tocar solo este fichero.
///
/// Reglas de pulgar para los pesos:
///  - `dayPart`: marca SOLO las franjas donde el antojo tiene sentido (fuera de
///    ahí cae al `offHoursWeight` y casi no aparece).
///  - `sky` / `temp`: modulan (>1 sube, <1 baja). Deja neutro lo que no aplica.
///  - `dayType`: viernes/finde para planes y caprichos.
const List<Craving> kCravingCatalog = [
  // ── Desayuno ────────────────────────────────────────────────────────────
  Craving(
    id: 'desayuno',
    emoji: '☕',
    label: 'Desayunar',
    family: 'cafe',
    typeIds: {RestaurantTypeIds.barCafeteria},
    weights: CravingWeights(
      dayPart: {DayPart.desayuno: 1.7, DayPart.madrugada: 0.5},
      sky: {Sky.rain: 1.1},
      offHoursWeight: 0.05,
    ),
  ),

  // ── Terraza / cervecita ───────────────────────────────────────────────────
  Craving(
    id: 'terraza',
    emoji: '🍺',
    label: 'Terraza',
    family: 'terraza',
    categoryIds: {CategoryIds.terraza, CategoryIds.conVistas},
    weights: CravingWeights(
      dayPart: {
        DayPart.mediodia: 1.0,
        DayPart.sobremesa: 1.1,
        DayPart.tarde: 1.3,
        DayPart.noche: 0.9,
      },
      sky: {Sky.clear: 1.6, Sky.clouds: 1.0, Sky.fog: 0.5, Sky.rain: 0.15, Sky.storm: 0.1},
      temp: {TempBand.cold: 0.4, TempBand.mild: 1.0, TempBand.warm: 1.4, TempBand.hot: 1.5},
      dayType: {DayType.friday: 1.15, DayType.weekend: 1.2},
    ),
  ),

  // ── Pescado fresco / mar ──────────────────────────────────────────────────
  Craving(
    id: 'pescado',
    emoji: '🐟',
    label: 'Pescado fresco',
    family: 'mar',
    categoryIds: {CategoryIds.pescadoMarisco},
    weights: CravingWeights(
      dayPart: {DayPart.mediodia: 1.4, DayPart.sobremesa: 1.0, DayPart.noche: 1.2},
      sky: {Sky.clear: 1.2, Sky.rain: 0.8},
      temp: {TempBand.warm: 1.2, TempBand.hot: 1.2},
      dayType: {DayType.weekend: 1.15},
    ),
  ),

  // ── Cuchara / puchero (comfort) ───────────────────────────────────────────
  Craving(
    id: 'cuchara',
    emoji: '🍲',
    label: 'De cuchara',
    family: 'cuchara',
    categoryIds: {CategoryIds.puchero},
    weights: CravingWeights(
      dayPart: {DayPart.mediodia: 1.4, DayPart.sobremesa: 1.2, DayPart.noche: 0.6},
      sky: {Sky.rain: 1.7, Sky.storm: 1.6, Sky.fog: 1.4, Sky.clouds: 1.15, Sky.clear: 0.7},
      temp: {TempBand.cold: 1.7, TempBand.mild: 1.1, TempBand.warm: 0.6, TempBand.hot: 0.3},
      dayType: {DayType.weekend: 1.1},
    ),
  ),

  // ── Guachinche (plan canario) ─────────────────────────────────────────────
  Craving(
    id: 'guachinche',
    emoji: '🍷',
    label: 'Guachinche',
    family: 'tradicion',
    typeIds: {
      RestaurantTypeIds.guachinchesTradicionales,
      RestaurantTypeIds.guachinchesModernos,
    },
    weights: CravingWeights(
      dayPart: {
        DayPart.mediodia: 1.2,
        DayPart.sobremesa: 1.3,
        DayPart.tarde: 1.0,
        DayPart.noche: 1.0,
      },
      dayType: {DayType.friday: 1.2, DayType.weekend: 1.4},
    ),
  ),

  // ── Tapeo / papas & costillas ─────────────────────────────────────────────
  Craving(
    id: 'tapeo',
    emoji: '🍢',
    label: 'Picoteo',
    family: 'tapeo',
    categoryIds: {CategoryIds.papasPinasCostillas},
    weights: CravingWeights(
      dayPart: {DayPart.sobremesa: 0.9, DayPart.tarde: 1.2, DayPart.noche: 1.3},
      dayType: {DayType.friday: 1.2, DayType.weekend: 1.15},
    ),
  ),

  // ── Atardecer / con vistas ────────────────────────────────────────────────
  Craving(
    id: 'atardecer',
    emoji: '🌅',
    label: 'Con vistas',
    family: 'vistas',
    categoryIds: {CategoryIds.conVistas},
    weights: CravingWeights(
      dayPart: {DayPart.mediodia: 0.5, DayPart.tarde: 1.6, DayPart.noche: 0.7},
      sky: {Sky.clear: 1.5, Sky.clouds: 0.9, Sky.rain: 0.2, Sky.storm: 0.1},
      temp: {TempBand.warm: 1.2, TempBand.hot: 1.2},
    ),
  ),

  // ── Cena / restaurante ────────────────────────────────────────────────────
  Craving(
    id: 'cena',
    emoji: '🍽️',
    label: 'Cenar',
    family: 'cena',
    typeIds: {RestaurantTypeIds.restaurantes, RestaurantTypeIds.loungeTenerife},
    weights: CravingWeights(
      dayPart: {DayPart.tarde: 0.7, DayPart.noche: 1.5},
      dayType: {DayType.friday: 1.2, DayType.weekend: 1.2},
    ),
  ),

  // ── Tasca / bodegón (vinos, cozy) ─────────────────────────────────────────
  Craving(
    id: 'tasca',
    emoji: '🧀',
    label: 'Tasca',
    family: 'tasca',
    typeIds: {RestaurantTypeIds.tascas, RestaurantTypeIds.bodegones},
    weights: CravingWeights(
      dayPart: {DayPart.sobremesa: 1.0, DayPart.tarde: 1.1, DayPart.noche: 1.2},
      temp: {TempBand.cold: 1.15},
      sky: {Sky.rain: 1.1, Sky.clouds: 1.05},
      dayType: {DayType.friday: 1.25, DayType.weekend: 1.15},
    ),
  ),

  // ── Merienda / café de tarde ──────────────────────────────────────────────
  Craving(
    id: 'merienda',
    emoji: '🥐',
    label: 'Merienda',
    family: 'cafe',
    typeIds: {RestaurantTypeIds.barCafeteria},
    weights: CravingWeights(
      dayPart: {DayPart.tarde: 1.25, DayPart.sobremesa: 0.8},
      sky: {Sky.rain: 1.1, Sky.clouds: 1.05},
      offHoursWeight: 0.05,
    ),
  ),
];
