/// Colocación de etiquetas del mapa sin solapes.
///
/// Capa PURA (sin Flutter ni Google Maps): se puede testear en aislamiento.
///
/// Problema que resuelve: el tope de etiquetas por viewport se aplicaba **por
/// orden de lista**, así que dos restaurantes a 20 m uno del otro recibían
/// ambos su etiqueta y los nombres se pisaban ("La cueva de madera" encima de
/// "Dragón Kitchen"), tapando además el nombre de la ciudad. Aquí elegimos las
/// etiquetas por SEPARACIÓN REAL EN PANTALLA: recorremos por prioridad y
/// descartamos toda candidata cuya caja se solape con una ya colocada.
///
/// Es el algoritmo clásico voraz de *label placement*: no busca el óptimo
/// global (NP-duro), pero es estable, O(n·k) y visualmente correcto.
library;

import 'dart:math' as math;

/// Candidata a etiqueta. [priority] la fija quien llama (orden de la lista):
/// las primeras ganan el sitio.
class LabelCandidate {
  final String id;
  final double lat;
  final double lon;

  /// Ancho de la etiqueta en píxeles lógicos (dot + hueco + nombre).
  final double width;

  /// Alto de la etiqueta en píxeles lógicos.
  final double height;

  const LabelCandidate({
    required this.id,
    required this.lat,
    required this.lon,
    required this.width,
    required this.height,
  });
}

/// Caja en píxeles de mundo (Web Mercator) para el test de solape.
class _Box {
  final double left, top, right, bottom;
  const _Box(this.left, this.top, this.right, this.bottom);

  bool overlaps(_Box o) =>
      left < o.right && right > o.left && top < o.bottom && bottom > o.top;
}

/// Tamaño del mundo en píxeles a un [zoom] dado (tile de 256 px).
double worldSizeAtZoom(double zoom) => 256.0 * math.pow(2.0, zoom);

/// Longitud → X en píxeles de mundo.
double lonToWorldX(double lon, double zoom) =>
    (lon + 180.0) / 360.0 * worldSizeAtZoom(zoom);

/// Latitud → Y en píxeles de mundo (proyección Web Mercator).
double latToWorldY(double lat, double zoom) {
  // Clamp a los límites de Mercator para no divergir en los polos.
  final clamped = lat.clamp(-85.05112878, 85.05112878);
  final rad = clamped * math.pi / 180.0;
  final y = math.log(math.tan(math.pi / 4 + rad / 2));
  return (1.0 - y / math.pi) / 2.0 * worldSizeAtZoom(zoom);
}

/// Devuelve los ids que SÍ deben pintar etiqueta.
///
/// Recorre [candidates] en orden (= prioridad) y acepta una etiqueta solo si su
/// caja no pisa ninguna ya aceptada. Para al llegar a [maxLabels].
///
/// La etiqueta se dibuja a la DERECHA del punto y centrada en vertical, así que
/// la caja va de `x` a `x + width` y de `y - height/2` a `y + height/2`.
/// [padding] añade aire alrededor para que no queden pegadas.
Set<String> selectNonOverlappingLabels({
  required List<LabelCandidate> candidates,
  required double zoom,
  required int maxLabels,
  double padding = 3.0,
}) {
  final accepted = <String>{};
  if (maxLabels <= 0) return accepted;

  final placed = <_Box>[];
  for (final c in candidates) {
    if (accepted.length >= maxLabels) break;

    final x = lonToWorldX(c.lon, zoom);
    final y = latToWorldY(c.lat, zoom);
    final box = _Box(
      x - padding,
      y - c.height / 2 - padding,
      x + c.width + padding,
      y + c.height / 2 + padding,
    );

    var collides = false;
    for (final p in placed) {
      if (box.overlaps(p)) {
        collides = true;
        break;
      }
    }
    if (collides) continue;

    placed.add(box);
    accepted.add(c.id);
  }
  return accepted;
}
