import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/restaurant.dart';

/// La pestaña Visitas decía "LANZAROTE · 300 visitas" y listaba sitios de
/// Tenerife: el filtro comparaba `restaurant.island`, campo que el endpoint de
/// visitas NO manda (0 de 300 lo traían), y ante el vacío dejaba pasar todo.
///
/// `municipios.islandId` sí viene (293/300) y es la referencia fiable.
void main() {
  group('municipioIslandId', () {
    const gc = '6f91d60f-0996-4dde-9088-167aab83a21a';

    test('shape anidado: municipios.islandId', () {
      final r = Restaurant.fromJson({
        'id': 'r1',
        'nombre': 'Guachinche de Melo',
        'municipios': {
          'Id': 'm1',
          'Nombre': 'San Bartolomé de Tirajana',
          'islandId': gc,
        },
      });
      expect(r.municipioIslandId, gc);
      expect(r.municipio, 'San Bartolomé de Tirajana');
    });

    test('shape plano: "municipios.islandId"', () {
      final r = Restaurant.fromJson({
        'id': 'r2',
        'nombre': 'X',
        'municipios.Nombre': 'Arona',
        'municipios.islandId': gc,
      });
      expect(r.municipioIslandId, gc);
    });

    test('sin municipio → null (no rompe)', () {
      final r = Restaurant.fromJson({'id': 'r3', 'nombre': 'Y'});
      expect(r.municipioIslandId, isNull);
      expect(r.municipio, '');
    });

    test('municipio sin islandId → null pero conserva el nombre', () {
      final r = Restaurant.fromJson({
        'id': 'r4',
        'nombre': 'Z',
        'municipios': {'Nombre': 'Yaiza'},
      });
      expect(r.municipioIslandId, isNull);
      expect(r.municipio, 'Yaiza');
    });

    test('el payload real de visitas no trae `island`, sí el municipio', () {
      // Forma exacta observada en /video-ingestion/restaurant-videos/published
      final r = Restaurant.fromJson({
        'id': 'r5',
        'nombre': 'Restaurante Grill El Palmeral',
        'horarios': null,
        'googleUrl': null,
        'lat': 27.758051,
        'lon': -15.586604,
        'municipios': {'Nombre': 'San Bartolomé de Tirajana', 'islandId': gc},
      });
      expect(r.island, isNull, reason: 'el backend no manda `island` aquí');
      expect(r.municipioIslandId, gc);
      expect(r.lat, closeTo(27.758051, 0.0001));
    });
  });
}
