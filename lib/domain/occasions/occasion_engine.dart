import 'package:guachinches/domain/occasions/occasion.dart';
import 'package:guachinches/domain/occasions/occasion_catalog.dart';
import 'package:guachinches/domain/occasions/occasion_context.dart';

/// Motor del "Planificador por ocasión".
///
/// FUNCIÓN PURA: mismo (catálogo, contexto) → misma ocasión. Sin estado, sin
/// I/O, 100% testeable. Devuelve UNA sola ocasión (la de mayor prioridad entre
/// las activas) porque la card es focal por diseño: anticipar un plan, no
/// ofrecer una lista.
///
/// Empate de prioridad → se rompe por `id` (orden reproducible). Con el comodín
/// `weekday_lowkey` (prioridad 10, siempre activo) el resultado nunca es null;
/// aun así la firma lo contempla por si algún día se quita ese comodín.
Occasion? activeOccasion(
  List<OccasionRule> catalog,
  OccasionContext ctx,
) {
  OccasionRule? best;
  for (final rule in catalog) {
    if (!rule.active(ctx)) continue;
    if (best == null ||
        rule.priority > best.priority ||
        (rule.priority == best.priority && rule.id.compareTo(best.id) < 0)) {
      best = rule;
    }
  }
  return best?.build(ctx);
}
