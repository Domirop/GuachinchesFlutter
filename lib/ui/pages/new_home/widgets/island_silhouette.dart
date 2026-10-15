import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Silueta propia de cada isla (glifo de rejilla 24, como `isla_glyph` del
/// tablero HojaIsla/HojaZona): costa simplificada (lon, lat), proyectada con
/// cos(28,3°) y encajada en 21 px centrada en 24.
///
/// Candidato a `lib/ui/theme/` (también lo usará la hoja de isla).
const Map<String, List<(double, double)>> kIslandCoast = {
  'tenerife': [
    (-16.92, 28.34),
    (-16.80, 28.38),
    (-16.68, 28.40),
    (-16.55, 28.42),
    (-16.42, 28.49),
    (-16.32, 28.58),
    (-16.22, 28.57),
    (-16.13, 28.58),
    (-16.17, 28.53),
    (-16.25, 28.47),
    (-16.37, 28.35),
    (-16.43, 28.16),
    (-16.54, 28.04),
    (-16.72, 28.05),
    (-16.75, 28.12),
    (-16.84, 28.25),
  ],
  'gran canaria': [
    (-15.71, 28.10),
    (-15.66, 28.15),
    (-15.52, 28.14),
    (-15.44, 28.15),
    (-15.41, 28.18),
    (-15.40, 28.15),
    (-15.42, 28.10),
    (-15.36, 28.00),
    (-15.39, 27.86),
    (-15.45, 27.79),
    (-15.58, 27.74),
    (-15.73, 27.80),
    (-15.80, 27.88),
    (-15.82, 27.99),
  ],
  'lanzarote': [
    (-13.45, 29.22),
    (-13.46, 29.13),
    (-13.53, 29.00),
    (-13.55, 28.96),
    (-13.63, 28.92),
    (-13.76, 28.86),
    (-13.83, 28.86),
    (-13.84, 28.91),
    (-13.83, 28.98),
    (-13.76, 29.03),
    (-13.62, 29.08),
    (-13.55, 29.12),
    (-13.50, 29.20),
  ],
  'fuerteventura': [
    (-13.87, 28.74),
    (-13.84, 28.54),
    (-13.86, 28.50),
    (-13.92, 28.32),
    (-14.02, 28.21),
    (-14.20, 28.10),
    (-14.35, 28.05),
    (-14.50, 28.07),
    (-14.40, 28.11),
    (-14.21, 28.21),
    (-14.15, 28.40),
    (-14.06, 28.55),
    (-14.01, 28.68),
    (-13.94, 28.75),
  ],
  'la palma': [
    (-17.80, 28.83),
    (-17.76, 28.68),
    (-17.77, 28.60),
    (-17.80, 28.52),
    (-17.84, 28.46),
    (-17.88, 28.53),
    (-17.92, 28.59),
    (-17.95, 28.64),
    (-17.96, 28.71),
    (-17.99, 28.78),
    (-17.92, 28.84),
    (-17.86, 28.86),
  ],
  'la gomera': [
    (-17.11, 28.09),
    (-17.13, 28.14),
    (-17.19, 28.17),
    (-17.20, 28.19),
    (-17.27, 28.19),
    (-17.32, 28.16),
    (-17.34, 28.10),
    (-17.28, 28.04),
    (-17.20, 28.02),
    (-17.14, 28.04),
  ],
  'el hierro': [
    (-17.98, 27.84),
    (-18.02, 27.79),
    (-18.08, 27.75),
    (-18.16, 27.72),
    (-18.11, 27.68),
    (-17.98, 27.64),
    (-17.92, 27.70),
    (-17.89, 27.78),
    (-17.88, 27.83),
    (-17.93, 27.85),
  ],
};

const Map<String, String> _kKeyToName = {
  'tf': 'tenerife',
  'gc': 'gran canaria',
  'lz': 'lanzarote',
  'fv': 'fuerteventura',
  'lp': 'la palma',
  'go': 'la gomera',
  'eh': 'el hierro',
};

/// Nombre canónico de la isla («Tenerife», «TF», «tenerife » → «tenerife»).
/// `null` si no es una de las siete.
String? islandCoastKey(String nameOrKey) {
  final n = nameOrKey.trim().toLowerCase();
  if (kIslandCoast.containsKey(n)) return n;
  return _kKeyToName[n];
}

/// Puntos de la silueta en la rejilla 24 (port de `_geo_path`). `null` si la
/// isla no se conoce.
List<Offset>? islandSilhouettePoints(String nameOrKey) {
  final k = islandCoastKey(nameOrKey);
  if (k == null) return null;
  final pts = kIslandCoast[k]!;
  final c = math.cos(28.3 * math.pi / 180);
  final xs = [for (final p in pts) p.$1 * c];
  final ys = [for (final p in pts) -p.$2];
  final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
  final w = maxX - minX, h = maxY - minY;
  final sc = 21 / math.max(w, h);
  final ox = (24 - w * sc) / 2 - minX * sc;
  final oy = (24 - h * sc) / 2 - minY * sc;
  return [
    for (var i = 0; i < xs.length; i++) Offset(xs[i] * sc + ox, ys[i] * sc + oy)
  ];
}

/// Silueta rellena de [color] (con filo de 0,8 del mismo color, juntas
/// redondas). Si la isla no se conoce pinta [fallback] (o nada).
class IslandSilhouette extends StatelessWidget {
  final String island;
  final double size;
  final Color color;
  final Widget? fallback;

  const IslandSilhouette({
    super.key,
    required this.island,
    required this.color,
    this.size = 34,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final pts = islandSilhouettePoints(island);
    if (pts == null) return fallback ?? SizedBox.square(dimension: size);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _IslandPainter(pts, color),
      ),
    );
  }
}

class _IslandPainter extends CustomPainter {
  final List<Offset> pts;
  final Color color;
  _IslandPainter(this.pts, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IslandPainter old) =>
      old.color != color || !identical(old.pts, pts);
}
