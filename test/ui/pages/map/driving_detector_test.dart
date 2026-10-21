import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/ui/pages/map/driving_detector.dart';

Position _pos(double speed, int second) => Position(
      latitude: 28.45,
      longitude: -16.44,
      timestamp: DateTime(2026, 10, 18, 15, 52, second),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 0,
    );

void main() {
  test('pregunta al ir a velocidad de coche, no entra solo', () {
    final d = MapDrivingDetector(clock: () => DateTime(2026, 10, 18, 15, 52));
    for (var i = 0; i < 4; i++) {
      d.onPosition(_pos(12, i));
    }
    expect(d.shouldSuggest.value, isFalse, reason: 'menos de 5 muestras');
    d.onPosition(_pos(12, 5));
    expect(d.shouldSuggest.value, isTrue);
    expect(d.isDriving.value, isFalse);
    d.confirmDrive();
    expect(d.isDriving.value, isTrue);
    expect(d.shouldSuggest.value, isFalse);
  });

  test('sale del modo coche al pararse', () {
    final d = MapDrivingDetector();
    d.confirmDrive();
    for (var i = 0; i < 8; i++) {
      d.onPosition(_pos(0.5, i));
    }
    expect(d.isDriving.value, isFalse);
  });

  test('«Ahora no» no vuelve a preguntar durante el enfriamiento', () {
    var now = DateTime(2026, 10, 18, 15, 52);
    final d = MapDrivingDetector(clock: () => now);
    for (var i = 0; i < 5; i++) {
      d.onPosition(_pos(12, i));
    }
    d.dismissSuggestion();
    d.onPosition(_pos(12, 6));
    expect(d.shouldSuggest.value, isFalse);
    now = now.add(const Duration(minutes: 6));
    d.onPosition(_pos(12, 7));
    expect(d.shouldSuggest.value, isTrue);
  });

  test('mediana', () {
    expect(MapDrivingDetector.median([3, 1, 2]), 2);
    expect(MapDrivingDetector.median([4, 1, 2, 3]), 2.5);
    expect(MapDrivingDetector.median([]), 0);
  });
}
