import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmPlaceName;
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Lógica pura de Guardados (tablero Guardados).

/// Ids de la tabla local `fav`, el último guardado primero (el `Id` es
/// autoincremental). Sin duplicados: si un sitio aparece dos veces manda la
/// fila más reciente. Filas con `Id` no numérico van al final, en su orden.
List<String> favoritosOrderedIds(List<RestaurantSQLLite> rows) {
  final indexed = [
    for (var i = 0; i < rows.length; i++) (i, int.tryParse(rows[i].id), rows[i])
  ];
  indexed.sort((a, b) {
    final x = a.$2, y = b.$2;
    if (x != null && y != null) return y.compareTo(x);
    if (x != null) return -1;
    if (y != null) return 1;
    return a.$1.compareTo(b.$1);
  });
  final seen = <String>{};
  return [
    for (final r in indexed)
      if (r.$3.restaurantId.isNotEmpty && seen.add(r.$3.restaurantId))
        r.$3.restaurantId
  ];
}

/// Lo que se pinta: en orden, guardado de verdad, no pendiente de quitar y
/// con la ficha ya descargada.
List<String> favoritosVisible({
  required List<String> ordered,
  required Set<String> saved,
  required Set<String> loaded,
  String? pendingRemoval,
}) =>
    [
      for (final id in ordered)
        if (id != pendingRemoval && saved.contains(id) && loaded.contains(id))
          id
    ];

/// «5 sitios. Se guardan en este móvil, sin cuenta.»
String favoritosSubtitle(int? count) {
  const tail = 'Se guardan en este móvil, sin cuenta.';
  if (count == null) return tail;
  return '${count == 1 ? '1 sitio' : '$count sitios'}. $tail';
}

/// «Guachinche moderno · La Victoria» (lo que haya; nunca un hueco).
String favoritosMeta(Restaurant r) {
  final type = restaurantTypeLabel(r.type);
  final muni = gmPlaceName(r.municipio);
  return [
    if (type.isNotEmpty) type,
    if (muni.isNotEmpty) muni,
  ].join(' · ');
}

/// Antetítulo del mapa: «1 abierto ahora» / «3 abiertos ahora» / «Ninguno
/// abierto ahora».
String favoritosOpenEyebrow(int open) {
  if (open <= 0) return 'Ninguno abierto ahora';
  return open == 1 ? '1 abierto ahora' : '$open abiertos ahora';
}

/// «5 guardados» / «1 guardado».
String favoritosMapTitle(int n) => n == 1 ? '1 guardado' : '$n guardados';

/// «Quitaste Dragón Kitchen».
String favoritosRemovedText(String name) => 'Quitaste $name';

/// Tiene coordenadas para el mapa.
bool favoritosHasLocation(Restaurant r) => r.lat != 0 || r.lon != 0;
