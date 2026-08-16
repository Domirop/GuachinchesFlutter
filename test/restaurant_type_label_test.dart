import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

void main() {
  test('UUID conocido → nombre en singular', () {
    expect(restaurantTypeLabel(RestaurantTypeIds.tascas), 'Tasca');
    expect(restaurantTypeLabel(RestaurantTypeIds.restaurantes), 'Restaurante');
    expect(restaurantTypeLabel(RestaurantTypeIds.barCafeteria), 'Bar/Cafetería');
    expect(restaurantTypeLabel(RestaurantTypeIds.guachinchesTradicionales),
        'Guachinche tradicional');
  });

  test('el UUID en mayúsculas también se reconoce', () {
    // La ficha mostraba "CE25663D-4916-43E9-9918-C2A07B32347F" tal cual.
    expect(
      restaurantTypeLabel(RestaurantTypeIds.tascas.toUpperCase()),
      'Tasca',
    );
  });

  test('UUID desconocido → vacío (nunca se pinta un identificador)', () {
    expect(restaurantTypeLabel('11111111-2222-3333-4444-555555555555'), '');
  });

  test("'vacio', null y cadena vacía → vacío", () {
    expect(restaurantTypeLabel('vacio'), '');
    expect(restaurantTypeLabel('VACIO'), '');
    expect(restaurantTypeLabel(null), '');
    expect(restaurantTypeLabel('   '), '');
  });

  test('si el backend manda un nombre, se respeta', () {
    expect(restaurantTypeLabel('Tasca de barrio'), 'Tasca de barrio');
  });

  test('ningún nombre del catálogo parece un UUID', () {
    for (final name in kRestaurantTypeNames.values) {
      expect(restaurantTypeLabel(name), name);
    }
  });
}
