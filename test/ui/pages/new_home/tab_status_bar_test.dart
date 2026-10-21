import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';

class _Online extends ConnectivityCubit {
  _Online() : super() {
    emit(const ConnectivityOnline());
  }
}

/// QA multidispositivo (I3): al volver de la encuesta (barra de estado en
/// blanco) el Inicio y Listas no declaraban su estilo y se quedaba blanco.
/// Las pestañas declaran ahora el suyo: iconos oscuros de día, claros de
/// noche, y se vuelve a aplicar al cerrar la ruta de encima.
void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('es'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<MenuCubit>(create: (_) => MenuCubit()),
          BlocProvider<ConnectivityCubit>(create: (_) => _Online()),
        ],
        child: NewHomeTabScaffold(
          screens: List.generate(5, (i) => Center(child: Text('tab-$i'))),
        ),
      ),
    ));
    await tester.pump();
  }

  SystemUiOverlayStyle? top(WidgetTester tester) {
    final layer = tester.binding.renderViews.first.debugLayer!;
    return layer.find<SystemUiOverlayStyle>(const Offset(10, 10));
  }

  testWidgets('de día: iconos oscuros, también al volver de la encuesta',
      (tester) async {
    await pump(tester, appLightTheme);
    expect(top(tester)?.statusBarIconBrightness, Brightness.dark);

    // Una ruta encima con la barra en blanco (como la cabecera de Premios).
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(
      builder: (_) => const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ColoredBox(color: Colors.black, child: SizedBox.expand()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(top(tester)?.statusBarIconBrightness, Brightness.light);
    nav.pop();
    await tester.pumpAndSettle();
    expect(top(tester)?.statusBarIconBrightness, Brightness.dark);
  });

  testWidgets('de noche: iconos claros', (tester) async {
    await pump(tester, appDarkTheme);
    expect(top(tester)?.statusBarIconBrightness, Brightness.light);
  });
}
