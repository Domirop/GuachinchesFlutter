import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/map/label_placement.dart';

/// Santa Cruz de Tenerife como origen realista de las pruebas.
const _lat = 28.4636;
const _lon = -16.2518;

/// Metros → grados de longitud a esta latitud (aprox). Sirve para separar
/// candidatas por una distancia física entendible.
double _lonOffsetMeters(double m) => m / (111320.0 * 0.879); // cos(28.46°)≈0.879
double _latOffsetMeters(double m) => m / 110574.0;

LabelCandidate _c(
  String id, {
  double dxMeters = 0,
  double dyMeters = 0,
  double width = 120,
  double height = 18,
}) {
  return LabelCandidate(
    id: id,
    lat: _lat + _latOffsetMeters(dyMeters),
    lon: _lon + _lonOffsetMeters(dxMeters),
    width: width,
    height: height,
  );
}

void main() {
  group('proyección Web Mercator', () {
    test('el mundo dobla de tamaño por cada nivel de zoom', () {
      expect(worldSizeAtZoom(0), 256);
      expect(worldSizeAtZoom(1), 512);
      expect(worldSizeAtZoom(8), 65536);
    });

    test('lon -180..180 mapea a 0..worldSize', () {
      expect(lonToWorldX(-180, 0), closeTo(0, 0.001));
      expect(lonToWorldX(0, 0), closeTo(128, 0.001));
      expect(lonToWorldX(180, 0), closeTo(256, 0.001));
    });

    test('el ecuador cae en el centro vertical y el norte por encima', () {
      expect(latToWorldY(0, 0), closeTo(128, 0.001));
      expect(latToWorldY(45, 0), lessThan(128));
      expect(latToWorldY(-45, 0), greaterThan(128));
    });

    test('no diverge en los polos (clamp de Mercator)', () {
      expect(latToWorldY(90, 2).isFinite, isTrue);
      expect(latToWorldY(-90, 2).isFinite, isTrue);
    });
  });

  group('selectNonOverlappingLabels', () {
    test('dos sitios pegados: solo el primero se etiqueta', () {
      // ~15 m de separación a zoom 16 → las cajas se pisan.
      final picked = selectNonOverlappingLabels(
        candidates: [_c('a'), _c('b', dxMeters: 15)],
        zoom: 16,
        maxLabels: 10,
      );
      expect(picked, {'a'});
    });

    test('dos sitios lejanos: se etiquetan los dos', () {
      final picked = selectNonOverlappingLabels(
        candidates: [_c('a'), _c('b', dxMeters: 900)],
        zoom: 16,
        maxLabels: 10,
      );
      expect(picked, {'a', 'b'});
    });

    test('respeta la prioridad: gana el primero de la lista', () {
      final picked = selectNonOverlappingLabels(
        candidates: [_c('segundo', dxMeters: 15), _c('primero')],
        zoom: 16,
        maxLabels: 10,
      );
      expect(picked, {'segundo'});
    });

    test('más zoom separa: lo que se pisaba deja de pisarse', () {
      final pair = [_c('a'), _c('b', dxMeters: 60)];
      final lejos = selectNonOverlappingLabels(
          candidates: pair, zoom: 13, maxLabels: 10);
      final cerca = selectNonOverlappingLabels(
          candidates: pair, zoom: 19, maxLabels: 10);
      expect(lejos, {'a'}, reason: 'a zoom bajo las cajas se solapan');
      expect(cerca, {'a', 'b'}, reason: 'a zoom alto ya caben las dos');
    });

    test('nunca supera maxLabels', () {
      final many = [
        for (var i = 0; i < 40; i++) _c('r$i', dxMeters: i * 900.0),
      ];
      final picked = selectNonOverlappingLabels(
        candidates: many,
        zoom: 16,
        maxLabels: 8,
      );
      expect(picked.length, 8);
    });

    test('maxLabels 0 o lista vacía → sin etiquetas', () {
      expect(
        selectNonOverlappingLabels(
            candidates: [_c('a')], zoom: 16, maxLabels: 0),
        isEmpty,
      );
      expect(
        selectNonOverlappingLabels(
            candidates: const [], zoom: 16, maxLabels: 5),
        isEmpty,
      );
    });

    test('una etiqueta ancha desplaza más candidatas que una corta', () {
      final anchas = selectNonOverlappingLabels(
        candidates: [_c('a', width: 300), _c('b', dxMeters: 120)],
        zoom: 16,
        maxLabels: 10,
      );
      final cortas = selectNonOverlappingLabels(
        candidates: [_c('a', width: 20), _c('b', dxMeters: 120, width: 20)],
        zoom: 16,
        maxLabels: 10,
      );
      expect(anchas, {'a'});
      expect(cortas, {'a', 'b'});
    });

    test('determinista: misma entrada → misma salida', () {
      final input = [_c('a'), _c('b', dxMeters: 15), _c('c', dxMeters: 900)];
      final r1 = selectNonOverlappingLabels(
          candidates: input, zoom: 16, maxLabels: 10);
      final r2 = selectNonOverlappingLabels(
          candidates: input, zoom: 16, maxLabels: 10);
      expect(r1, r2);
    });

    test('el solape también se detecta en vertical', () {
      // Mismo x, separados solo unos metros en latitud → cajas se pisan.
      final picked = selectNonOverlappingLabels(
        candidates: [_c('a'), _c('b', dyMeters: 3)],
        zoom: 16,
        maxLabels: 10,
      );
      expect(picked, {'a'});
    });
  });
}
