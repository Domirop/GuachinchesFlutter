import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos_logic.dart';

RestaurantSQLLite _row(Object? id, String rid) =>
    RestaurantSQLLite.fromMap({'Id': id, 'restaurantId': rid});

void main() {
  test('el último guardado primero, sin duplicados', () {
    final ids = favoritosOrderedIds([
      _row(1, 'a'),
      _row(3, 'c'),
      _row(2, 'b'),
      _row(4, 'a'), // re-guardado: manda la fila más reciente
      _row(null, 'z'),
      _row(5, ''),
    ]);
    expect(ids, ['a', 'c', 'b', 'z']);
  });

  test('visibles: guardados, descargados y no pendientes de quitar', () {
    final v = favoritosVisible(
      ordered: ['a', 'b', 'c', 'd'],
      saved: {'a', 'b', 'c'},
      loaded: {'a', 'c', 'd'},
      pendingRemoval: 'c',
    );
    expect(v, ['a']);
  });

  test('subtítulo y textos', () {
    expect(favoritosSubtitle(5),
        '5 sitios. Se guardan en este móvil, sin cuenta.');
    expect(
        favoritosSubtitle(1), '1 sitio. Se guardan en este móvil, sin cuenta.');
    expect(favoritosSubtitle(null), 'Se guardan en este móvil, sin cuenta.');
    expect(favoritosOpenEyebrow(1), '1 abierto ahora');
    expect(favoritosOpenEyebrow(3), '3 abiertos ahora');
    expect(favoritosOpenEyebrow(0), 'Ninguno abierto ahora');
    expect(favoritosMapTitle(5), '5 guardados');
    expect(favoritosMapTitle(1), '1 guardado');
    expect(favoritosRemovedText('Dragón Kitchen'), 'Quitaste Dragón Kitchen');
  });

  test('meta: tipo y municipio, sin huecos', () {
    expect(favoritosMeta(Restaurant(municipio: 'LA LAGUNA')), 'La Laguna');
    expect(
        favoritosMeta(Restaurant(type: 'Restaurante', municipio: 'Santa Cruz')),
        'Restaurante · Santa Cruz');
    expect(favoritosMeta(Restaurant()), '');
  });

  test('ubicación', () {
    expect(favoritosHasLocation(Restaurant(lat: 28.4, lon: -16.3)), isTrue);
    expect(favoritosHasLocation(Restaurant()), isFalse);
  });
}
