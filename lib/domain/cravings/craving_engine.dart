import 'package:guachinches/domain/cravings/craving.dart';
import 'package:guachinches/domain/cravings/craving_context.dart';

/// Motor de scoring de "¿Qué te apetece ahora?".
///
/// Es una FUNCIÓN PURA: mismo (catálogo, contexto) → misma salida. Sin estado,
/// sin I/O, 100% testeable. Esa determinación es deliberada: el antojo no debe
/// "bailar" en cada rebuild; cambia solo cuando cambia el contexto (hora,
/// clima, día).

class ScoredCraving {
  final Craving craving;
  final double score;
  const ScoredCraving(this.craving, this.score);
}

/// Puntúa un antojo en un contexto: producto de los cuatro factores.
///
/// Multiplicativo (no aditivo) a propósito: si una dimensión "mata" el antojo
/// (p. ej. terraza con tormenta → 0.1), debe arrastrar al conjunto aunque las
/// demás sean altas. Un AND suave, no un OR.
double scoreCraving(Craving c, CravingContext ctx) {
  return c.base *
      c.weights.dayPartFactor(ctx.dayPart) *
      c.weights.skyFactor(ctx.sky) *
      c.weights.tempFactor(ctx.tempBand) *
      c.weights.dayTypeFactor(ctx.dayType);
}

/// Rankea el [catalog] para [ctx] y devuelve hasta [max] antojos.
///
/// Dos pasadas:
///  1. **Diversa**: recorre por score desc y admite como máximo [perFamily] por
///     familia, para que los chips no sean "tres veces lo mismo".
///  2. **Relleno**: si la diversidad dejó huecos, completa con los mejores
///     restantes ignorando la familia (mejor llenar que mostrar menos).
///
/// Estable: empate de score se rompe por `id` (orden reproducible).
List<Craving> rankCravings(
  List<Craving> catalog,
  CravingContext ctx, {
  int max = 4,
  int perFamily = 1,
  double floor = 0.0,
}) {
  final scored = [
    for (final c in catalog) ScoredCraving(c, scoreCraving(c, ctx)),
  ]..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.craving.id.compareTo(b.craving.id);
    });

  final picked = <Craving>[];
  final familyCount = <String, int>{};

  void take(bool Function(ScoredCraving) accept) {
    for (final s in scored) {
      if (picked.length >= max) return;
      if (s.score <= floor) continue;
      if (picked.contains(s.craving)) continue;
      if (!accept(s)) continue;
      picked.add(s.craving);
      familyCount[s.craving.family] =
          (familyCount[s.craving.family] ?? 0) + 1;
    }
  }

  // 1ª pasada: diversa por familia.
  take((s) => (familyCount[s.craving.family] ?? 0) < perFamily);
  // 2ª pasada: relleno si faltan huecos.
  if (picked.length < max) take((_) => true);

  return picked;
}
