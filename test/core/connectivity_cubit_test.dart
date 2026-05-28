import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  ConnectivityResult initialResult;
  final StreamController<ConnectivityResult> controller =
      StreamController<ConnectivityResult>.broadcast();

  _FakeConnectivity({this.initialResult = ConnectivityResult.wifi});

  @override
  Future<ConnectivityResult> checkConnectivity() async => initialResult;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => controller.stream;
}

void main() {
  group('ConnectivityCubit', () {
    test('(a) init() con wifi resulta en ConnectivityOnline', () async {
      final fake = _FakeConnectivity(initialResult: ConnectivityResult.wifi);
      final cubit = ConnectivityCubit(connectivity: fake);

      await cubit.init();

      expect(cubit.state, isA<ConnectivityOnline>());
      await cubit.close();
    });

    test('(b) init() con none resulta en ConnectivityOffline', () async {
      final fake = _FakeConnectivity(initialResult: ConnectivityResult.none);
      final cubit = ConnectivityCubit(connectivity: fake);

      await cubit.init();

      expect(cubit.state, isA<ConnectivityOffline>());
      await cubit.close();
    });

    test('(c) secuencia [none, wifi] produce [offline, online]', () async {
      final fake = _FakeConnectivity(initialResult: ConnectivityResult.wifi);
      final cubit = ConnectivityCubit(connectivity: fake);

      await cubit.init();

      final states = <ConnectivityState>[];
      final sub = cubit.stream.listen(states.add);

      fake.controller.add(ConnectivityResult.none);
      fake.controller.add(ConnectivityResult.wifi);

      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ConnectivityOffline>());
      expect(states[1], isA<ConnectivityOnline>());

      await sub.cancel();
      await cubit.close();
    });
  });
}
