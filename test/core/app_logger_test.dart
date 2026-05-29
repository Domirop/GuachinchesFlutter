import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/logging/app_logger.dart';

void main() {
  group('AppLogger in debug mode', () {
    test('info does not throw', () {
      expect(() => AppLogger.info('test-tag', 'test message'), returnsNormally);
    });

    test('error does not throw', () {
      expect(
        () => AppLogger.error('test-tag', Exception('x'), StackTrace.current),
        returnsNormally,
      );
    });

    test('debug output contains tag', () {
      final captured = <String>[];
      final prev = debugPrint;
      debugPrint = (String? msg, {int? wrapWidth}) {
        if (msg != null) captured.add(msg);
      };
      AppLogger.info('my-tag', 'hello');
      debugPrint = prev;
      expect(captured.any((line) => line.contains('my-tag')), isTrue);
    });
  });
}
