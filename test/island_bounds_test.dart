import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/utils/island_bounds.dart';

void main() {
  group('islandKeyAt — capitales y puntos reales', () {
    // (lat, lon, key esperada, descripción)
    const casos = <(double, double, String, String)>[
      (28.4636, -16.2518, 'TF', 'Santa Cruz de Tenerife'),
      (28.0916, -16.7400, 'TF', 'Los Cristianos (sur de Tenerife)'),
      (28.2716, -16.6060, 'TF', 'Teide'),
      (28.1235, -15.4363, 'GC', 'Las Palmas de Gran Canaria'),
      (27.7606, -15.5860, 'GC', 'Maspalomas'),
      (28.9630, -13.5500, 'LZ', 'Arrecife'),
      (29.2320, -13.5030, 'LZ', 'Órzola (norte de Lanzarote)'),
      (29.2300, -13.5030, 'LZ', 'La Graciosa'),
      (28.5004, -13.8627, 'FV', 'Puerto del Rosario'),
      (28.7400, -13.8600, 'FV', 'Corralejo'),
      (28.6835, -17.7642, 'LP', 'Santa Cruz de La Palma'),
      (28.1120, -17.1100, 'GO', 'San Sebastián de La Gomera'),
      (27.8060, -17.9160, 'EH', 'Valverde (El Hierro)'),
    ];

    for (final (lat, lon, key, desc) in casos) {
      test('$desc → $key', () {
        expect(islandKeyAt(lat, lon), key);
      });
    }
  });

  group('mar abierto → null (no cambiar de isla)', () {
    test('canal entre Tenerife y Gran Canaria', () {
      expect(islandKeyAt(28.10, -15.95), isNull);
    });

    test('canal entre Lanzarote y Fuerteventura', () {
      expect(islandKeyAt(28.80, -13.83), isNull);
    });

    test('Atlántico al norte del archipiélago', () {
      expect(islandKeyAt(30.50, -16.00), isNull);
    });

    test('fuera de Canarias (Madrid)', () {
      expect(islandKeyAt(40.4168, -3.7038), isNull);
    });

    test('costa africana (al este de Fuerteventura)', () {
      expect(islandKeyAt(28.50, -12.50), isNull);
    });
  });

  group('invariantes de las envolventes', () {
    test('están las 7 islas y sin keys repetidas', () {
      final keys = kIslandBounds.map((b) => b.key).toSet();
      expect(keys, {'TF', 'GC', 'LZ', 'FV', 'LP', 'GO', 'EH'});
      expect(kIslandBounds.length, 7);
    });

    test('ninguna caja se solapa con otra', () {
      for (var i = 0; i < kIslandBounds.length; i++) {
        for (var j = i + 1; j < kIslandBounds.length; j++) {
          final a = kIslandBounds[i];
          final b = kIslandBounds[j];
          final solapa = a.minLat < b.maxLat &&
              a.maxLat > b.minLat &&
              a.minLon < b.maxLon &&
              a.maxLon > b.minLon;
          expect(solapa, isFalse,
              reason: '${a.key} y ${b.key} se solapan: un punto daría '
                  'dos islas y el mapa saltaría entre ellas');
        }
      }
    });

    test('cada caja está bien formada y su centro cae dentro', () {
      for (final b in kIslandBounds) {
        expect(b.minLat, lessThan(b.maxLat), reason: b.key);
        expect(b.minLon, lessThan(b.maxLon), reason: b.key);
        expect(islandKeyAt(b.centerLat, b.centerLon), b.key);
      }
    });
  });
}
