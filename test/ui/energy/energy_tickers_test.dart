import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:guachinches/ui/pages/new_home/widgets/starfield_painter.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';

/// Energía: nada debe pedir fotogramas cuando no se ve. Cada fotograma es
/// CPU + GPU de pantalla completa (a 120 Hz en los iPhone ProMotion).
class _OnlineConnectivityCubit extends ConnectivityCubit {
  _OnlineConnectivityCubit() : super() {
    emit(const ConnectivityOnline());
  }
}

/// Apunta si su subárbol tiene los tickers encendidos.
class _TickerProbe extends StatelessWidget {
  final int index;
  final Map<int, bool> seen;
  const _TickerProbe(this.index, this.seen);

  @override
  Widget build(BuildContext context) {
    seen[index] = TickerMode.valuesOf(context).enabled;
    return Center(child: Text('screen-$index'));
  }
}

bool _running(WidgetTester tester) =>
    (tester.state(find.byType(GmLoop)) as dynamic).isRunning as bool;

void main() {
  group('GmLoop', () {
    Widget loopInList(ScrollController ctrl) => MaterialApp(
          home: Scaffold(
            // Como un SliverToBoxAdapter: el hijo sigue montado fuera de
            // la vista.
            body: SingleChildScrollView(
              controller: ctrl,
              child: Column(children: [
                SizedBox(
                  height: 40,
                  child: GmLoop(
                    period: const Duration(seconds: 3),
                    builder: (_, t, __) => Opacity(opacity: t),
                  ),
                ),
                const SizedBox(height: 4000),
              ]),
            ),
          ),
        );

    testWidgets('se para fuera de pantalla y vuelve al regresar',
        (tester) async {
      final ctrl = ScrollController();
      await tester.pumpWidget(loopInList(ctrl));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_running(tester), isTrue);

      ctrl.jumpTo(2000);
      await tester.pump();
      expect(_running(tester), isFalse);
      // Sin bucle activo no queda ningún fotograma pendiente.
      expect(tester.binding.hasScheduledFrame, isFalse);

      ctrl.jumpTo(0);
      await tester.pump();
      expect(_running(tester), isTrue);
    });

    testWidgets('con «reducir movimiento» no corre', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: GmLoop(
          period: const Duration(seconds: 3),
          builder: (_, t, __) => const SizedBox(),
        ),
      ));
      await tester.pump();
      expect(_running(tester), isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('el cielo de estrellas no pide fotogramas', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: StarfieldWidget(opacity: 1, heroSize: Size(400, 340)),
    ));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('las pestañas ocultas tienen los tickers apagados',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seen = <int, bool>{};
    final menu = MenuCubit();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: ThemeData.dark().copyWith(extensions: const [BrandColors.dark]),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<MenuCubit>.value(value: menu),
          BlocProvider<ConnectivityCubit>(
            create: (_) => _OnlineConnectivityCubit(),
          ),
        ],
        child: NewHomeTabScaffold(
          screens: [for (var i = 0; i < 5; i++) _TickerProbe(i, seen)],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(seen, {0: true, 1: false, 2: false, 3: false, 4: false});

    await tester.tap(find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'tab-mapa'));
    await tester.pumpAndSettle();
    expect(seen, {0: false, 1: false, 2: true, 3: false, 4: false});
  });
}
