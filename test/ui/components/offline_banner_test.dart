import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';
import 'package:guachinches/ui/components/offline_banner.dart';

class _FixedConnectivityCubit extends ConnectivityCubit {
  _FixedConnectivityCubit(ConnectivityState initial) : super() {
    emit(initial);
  }
}

Widget _wrap(ConnectivityState state) {
  return MaterialApp(
    home: BlocProvider<ConnectivityCubit>(
      create: (_) => _FixedConnectivityCubit(state),
      child: const Scaffold(
        body: Column(
          children: [OfflineBanner()],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('(a) ConnectivityOnline: no renderiza el texto de sin conexión',
      (tester) async {
    await tester.pumpWidget(_wrap(const ConnectivityOnline()));
    await tester.pump();

    expect(
      find.text('Sin conexión — mostrando datos guardados'),
      findsNothing,
    );
  });

  testWidgets(
      '(b) ConnectivityOffline: renderiza texto, icono y nodo semantics',
      (tester) async {
    await tester.pumpWidget(_wrap(const ConnectivityOffline()));
    await tester.pump();

    expect(
      find.text('Sin conexión — mostrando datos guardados'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'offline-banner',
      ),
      findsOneWidget,
    );
  });
}
