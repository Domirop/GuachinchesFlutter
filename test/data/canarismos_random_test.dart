import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/canarismos.dart';

void main() {
  test('canarismoRandom returns an entry present in kCanarismos', () {
    final result = canarismoRandom(42);
    expect(kCanarismos.any((c) => c.palabra == result.palabra), isTrue);
  });

  test('canarismoRandom with actual returns a different word for multiple seeds', () {
    final base = kCanarismos.first;
    for (final seed in [0, 1, 2, 10, 42, 100, 999, 365, 730]) {
      final result = canarismoRandom(seed, actual: base);
      expect(
        result.palabra,
        isNot(equals(base.palabra)),
        reason: 'seed $seed should not return "${base.palabra}"',
      );
    }
  });

  group('orden diario anclado al lanzamiento', () {
    final launch = kCanarismoLaunchDate;
    // Día de calendario relativo al lanzamiento (sin drift de DST: usamos
    // aritmética de calendario, no `add(Duration)`).
    DateTime day(int i) => DateTime(launch.year, launch.month, launch.day + i);

    test('day index = 0 el día de lanzamiento, crece 1 por día', () {
      expect(canarismoDayIndex(day(0)), 0);
      expect(canarismoDayIndex(day(1)), 1);
      expect(canarismoDayIndex(day(30)), 30);
      // Antes del lanzamiento es negativo.
      expect(canarismoDayIndex(day(-1)), -1);
    });

    test('no repite hasta agotar el diccionario (permutación completa)', () {
      final seen = <String>{};
      for (int i = 0; i < kCanarismos.length; i++) {
        seen.add(canarismoOfDay(day(i)).palabra);
      }
      expect(seen.length, kCanarismos.length);
    });

    test('días consecutivos no comparten inicial (gracias al stride)', () {
      // Comprobación del motivo del stride: variedad en "anteriores".
      var distintos = 0;
      for (int i = 0; i < 20; i++) {
        final a = canarismoOfDay(day(i));
        final b = canarismoOfDay(day(i + 1));
        if (a.palabra[0].toLowerCase() != b.palabra[0].toLowerCase()) {
          distintos++;
        }
      }
      expect(distintos, greaterThanOrEqualTo(18));
    });
  });
}
