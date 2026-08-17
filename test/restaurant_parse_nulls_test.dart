import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

/// Regresión: islas enteras salían vacías porque el backend manda `null` en
/// campos que el modelo declara como String NO nullable.
///
/// Medido en producción (agosto 2026):
///   Lanzarote      11/11 registros con `horarios` y `googleUrl` a null
///   Fuerteventura  10/10 idem
///   La Palma       10/14 con `horarios` a null
/// Todos reventaban al parsear y se descartaban → "Todavía no hay restaurantes
/// en esta isla", cuando la API sí los devolvía.

/// Forma real de un registro de Lanzarote (recortado a lo relevante).
Map<String, dynamic> lanzaroteRow({String id = 'r1', String nombre = 'Bodega Uga'}) => {
      'id': id,
      'nombre': nombre,
      'horarios': null, // ← el que rompía
      'googleUrl': null, // ← el que rompía
      'direccion': 'Uga, Lanzarote',
      'telefono': null,
      'enable': true,
      'lat': '28.9',
      'lon': '-13.7',
      'google_horarios': 'lunes: 12:00–16:00',
      'municipios': {'Nombre': 'Yaiza'},
      'fotos': [],
    };

void main() {
  group('Restaurant.fromJson con nulls del backend', () {
    test('un registro con horarios/googleUrl null NO lanza', () {
      expect(() => Restaurant.fromJson(lanzaroteRow()), returnsNormally);
    });

    test('los String no-nullable caen a cadena vacía, no a null', () {
      final r = Restaurant.fromJson(lanzaroteRow());
      expect(r.horarios, '');
      expect(r.googleUrl, '');
      expect(r.telefono, '');
      // Y lo que sí viene se conserva.
      expect(r.nombre, 'Bodega Uga');
      expect(r.direccion, 'Uga, Lanzarote');
      expect(r.municipio, 'Yaiza');
    });

    test('id ausente no rompe el parseo', () {
      final row = lanzaroteRow()..remove('id');
      expect(() => Restaurant.fromJson(row), returnsNormally);
    });
  });

  group('RestaurantResponse — la isla completa se carga', () {
    test('los 11 de Lanzarote se parsean (antes: 0)', () {
      final json = {
        'count': 11,
        'rows': [
          for (var i = 0; i < 11; i++)
            lanzaroteRow(id: 'lz-$i', nombre: 'Negocio $i'),
        ],
      };
      final res = RestaurantResponse.fromJson(json);
      expect(res.restaurants.length, 11,
          reason: 'una isla entera no puede perderse por campos null');
      expect(res.count, 11);
    });

    test('sigue siendo tolerante: un registro irrecuperable no tumba al resto',
        () {
      final json = {
        'count': 3,
        'rows': [
          lanzaroteRow(id: 'ok-1'),
          'esto no es un objeto', // basura → debe saltarse
          lanzaroteRow(id: 'ok-2'),
        ],
      };
      final res = RestaurantResponse.fromJson(json);
      expect(res.restaurants.length, 2);
    });

    test('rows vacío o ausente → lista vacía sin lanzar', () {
      expect(RestaurantResponse.fromJson({'count': 0, 'rows': []}).restaurants,
          isEmpty);
      expect(RestaurantResponse.fromJson({'count': 0}).restaurants, isEmpty);
    });
  });
}
