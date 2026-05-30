import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/utils/eyebrow_format.dart';

void main() {
  group('eyebrowJoin', () {
    test('joins two parts with canonical separator', () {
      expect(
        eyebrowJoin(['12:00 · MEDIODÍA', 'HOY EN TENERIFE']),
        '12:00 · MEDIODÍA · HOY EN TENERIFE',
      );
    });

    test('joins abiertos ahora + island', () {
      expect(
        eyebrowJoin(['ABIERTOS AHORA', 'TENERIFE']),
        'ABIERTOS AHORA · TENERIFE',
      );
    });

    test('ignores empty strings', () {
      expect(eyebrowJoin(['A', '', '  ', 'B']), 'A · B');
    });

    test('trims whitespace from each segment', () {
      expect(eyebrowJoin(['  A ', 'B ']), 'A · B');
    });

    test('output never contains double-space adjacent to separator', () {
      final result = eyebrowJoin(['ABIERTOS AHORA', 'TENERIFE']);
      expect(result.contains('  ·'), isFalse);
      expect(result.contains('·  '), isFalse);
    });

    test('single non-empty part returns it without trailing separator', () {
      expect(eyebrowJoin(['SOLO']), 'SOLO');
    });

    test('all empty parts returns empty string', () {
      expect(eyebrowJoin(['', '  ']), '');
    });
  });
}
