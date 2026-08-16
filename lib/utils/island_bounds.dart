/// Geografía de las islas Canarias — capa PURA (sin Flutter ni Google Maps).
///
/// Sirve para saber SOBRE QUÉ ISLA está el mapa: al arrastrar hasta otra isla,
/// la app cambia sola de isla y carga sus restaurantes, en vez de dejar la
/// pantalla sin marcadores.
///
/// Las cajas son envolventes aproximadas (bounding boxes) de cada isla, con un
/// margen pequeño para cubrir la costa. NO se solapan entre sí: el canal más
/// estrecho del archipiélago (La Gomera–Tenerife) deja hueco de sobra. Se
/// indexan por `key` del backend (TF, GC, LZ, FV, LP, GO, EH), que es estable —
/// nunca por UUID, que puede cambiar entre entornos.
library;

/// Caja envolvente de una isla.
class IslandBounds {
  /// `key` del backend: TF, GC, LZ, FV, LP, GO, EH.
  final String key;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const IslandBounds(
    this.key, {
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  bool contains(double lat, double lon) =>
      lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;

  double get centerLat => (minLat + maxLat) / 2;
  double get centerLon => (minLon + maxLon) / 2;
}

/// Envolventes de las 7 islas (+ La Graciosa dentro de Lanzarote).
const List<IslandBounds> kIslandBounds = [
  IslandBounds('TF',
      minLat: 27.98, maxLat: 28.62, minLon: -16.96, maxLon: -16.09),
  IslandBounds('GC',
      minLat: 27.71, maxLat: 28.21, minLon: -15.86, maxLon: -15.33),
  // Incluye La Graciosa y el resto del archipiélago Chinijo por el norte.
  IslandBounds('LZ',
      minLat: 28.83, maxLat: 29.33, minLon: -13.90, maxLon: -13.38),
  IslandBounds('FV',
      minLat: 28.02, maxLat: 28.78, minLon: -14.58, maxLon: -13.76),
  IslandBounds('LP',
      minLat: 28.43, maxLat: 28.89, minLon: -18.02, maxLon: -17.70),
  IslandBounds('GO',
      minLat: 27.96, maxLat: 28.25, minLon: -17.40, maxLon: -17.08),
  IslandBounds('EH',
      minLat: 27.61, maxLat: 27.87, minLon: -18.19, maxLon: -17.86),
];

/// Devuelve la `key` de la isla que contiene el punto, o `null` si cae en el
/// mar (o fuera de Canarias).
///
/// Deliberadamente NO busca "la isla más cercana": si el usuario está mirando
/// mar abierto, lo correcto es no cambiar de isla — cambiarla obligaría a
/// adivinar y provocaría saltos molestos al arrastrar entre islas.
String? islandKeyAt(double lat, double lon,
    {List<IslandBounds> bounds = kIslandBounds}) {
  for (final b in bounds) {
    if (b.contains(lat, lon)) return b.key;
  }
  return null;
}

/// Envolvente de una isla por su `key` (TF, GC, …), o `null` si no se conoce.
/// La comparación ignora mayúsculas/minúsculas.
IslandBounds? islandBoundsForKey(String? key,
    {List<IslandBounds> bounds = kIslandBounds}) {
  if (key == null || key.isEmpty) return null;
  final k = key.toUpperCase();
  for (final b in bounds) {
    if (b.key == k) return b;
  }
  return null;
}
