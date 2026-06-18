import 'package:guachinches/domain/cravings/craving_context.dart';

/// Un "antojo" candidato a mostrarse en "¿Qué te apetece ahora?".
///
/// Dominio puro: el [Craving] describe QUÉ es (emoji, etiqueta, filtro) y CÓMO
/// de relevante es según el contexto ([weights]). No sabe nada de Flutter ni
/// de red.
class Craving {
  final String id;
  final String emoji;
  final String label;

  /// Etiqueta de familia para diversificar el ranking (que no salgan dos
  /// antojos "de lo mismo"). Ej: 'mar', 'cuchara', 'terraza'.
  final String family;

  /// Filtro destino: OR de tipos de local (IDs del backend).
  final Set<String> typeIds;

  /// Filtro destino: OR de categorías (IDs del backend).
  final Set<String> categoryIds;

  final CravingWeights weights;

  /// Empuje base del antojo (sube/baja su prior global frente a otros).
  final double base;

  const Craving({
    required this.id,
    required this.emoji,
    required this.label,
    required this.family,
    this.typeIds = const {},
    this.categoryIds = const {},
    required this.weights,
    this.base = 1.0,
  });
}

/// Pesos por dimensión de contexto. Cada dimensión es independiente y se
/// combina de forma MULTIPLICATIVA en el motor.
///
/// Semántica de la ausencia de una clave:
///  - [dayPart] ausente ⇒ [offHoursWeight] (gating fuerte: el antojo casi no
///    aplica fuera de su franja natural).
///  - [sky] / [temp] / [dayType] ausentes ⇒ 1.0 (neutro: ni suma ni resta).
///
/// Un peso > 1 sube el antojo en ese contexto; < 1 lo penaliza; 0 lo elimina.
class CravingWeights {
  final Map<DayPart, double> dayPart;
  final Map<Sky, double> sky;
  final Map<TempBand, double> temp;
  final Map<DayType, double> dayType;
  final double offHoursWeight;

  const CravingWeights({
    this.dayPart = const {},
    this.sky = const {},
    this.temp = const {},
    this.dayType = const {},
    this.offHoursWeight = 0.12,
  });

  double dayPartFactor(DayPart d) => dayPart[d] ?? offHoursWeight;
  double skyFactor(Sky s) => sky[s] ?? 1.0;
  double tempFactor(TempBand t) => temp[t] ?? 1.0;
  double dayTypeFactor(DayType d) => dayType[d] ?? 1.0;
}
