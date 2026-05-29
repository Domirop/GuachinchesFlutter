import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('5 invocations spaced 10ms execute callback once after 300ms', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int calls = 0;

        for (int i = 0; i < 5; i++) {
          debouncer(() => calls++);
          async.elapse(const Duration(milliseconds: 10));
        }

        // Timer fires 300ms after the last call (at t=40ms), so at t=350ms
        expect(calls, 0);
        async.elapse(const Duration(milliseconds: 300));
        expect(calls, 1);

        debouncer.dispose();
      });
    });

    test('cancel before delay does not execute callback', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int calls = 0;

        debouncer(() => calls++);
        debouncer.cancel();

        async.elapse(const Duration(milliseconds: 400));
        expect(calls, 0);

        debouncer.dispose();
      });
    });

    test('two invocations separated by more than delay execute twice', () {
      fakeAsync((async) {
        final debouncer = Debouncer();
        int calls = 0;

        debouncer(() => calls++);
        async.elapse(const Duration(milliseconds: 350));
        expect(calls, 1);

        debouncer(() => calls++);
        async.elapse(const Duration(milliseconds: 350));
        expect(calls, 2);

        debouncer.dispose();
      });
    });
  });
}
