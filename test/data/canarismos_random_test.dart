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
}
