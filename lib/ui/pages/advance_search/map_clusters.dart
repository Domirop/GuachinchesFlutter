import 'dart:math' as math;

/// Agrupación sencilla de chinchetas por distancia en pantalla (Web
/// Mercator, 256 px por tesela): las que quedan a menos de [radius] px a
/// este [zoom] se juntan en una burbuja con el número. Voraz, en el orden
/// de entrada (el primero de cada grupo es su ancla).
class MapCluster {
  /// Índices de los puntos del grupo (en el orden de entrada).
  final List<int> members;
  final double lat;
  final double lon;
  const MapCluster(this.members, this.lat, this.lon);

  bool get single => members.length == 1;
}

/// Píxeles del mundo a ese zoom (lógicos, sin densidad).
math.Point<double> mapWorldPixel(double lat, double lon, double zoom) {
  final scale = 256 * math.pow(2, zoom);
  final x = (lon + 180) / 360 * scale;
  final s = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
  final y = (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale;
  return math.Point(x, y.toDouble());
}

List<MapCluster> mapClusters(
  List<(double lat, double lon)> points,
  double zoom, {
  double radius = 28,
}) {
  final px = [for (final p in points) mapWorldPixel(p.$1, p.$2, zoom)];
  final used = List<bool>.filled(points.length, false);
  final out = <MapCluster>[];
  for (var i = 0; i < points.length; i++) {
    if (used[i]) continue;
    used[i] = true;
    final members = [i];
    for (var j = i + 1; j < points.length; j++) {
      if (used[j]) continue;
      if (px[i].distanceTo(px[j]) < radius) {
        used[j] = true;
        members.add(j);
      }
    }
    final lat = members.map((m) => points[m].$1).reduce((a, b) => a + b) /
        members.length;
    final lon = members.map((m) => points[m].$2).reduce((a, b) => a + b) /
        members.length;
    out.add(MapCluster(members, lat, lon));
  }
  return out;
}
