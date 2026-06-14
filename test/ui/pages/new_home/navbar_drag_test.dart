import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/core/connectivity/connectivity_cubit.dart';
import 'package:guachinches/core/connectivity/connectivity_state.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';

/// Verifica el navbar liquid-glass: tap cambia de tab y, sobre todo, que se
/// pueda **arrastrar** el dedo por la barra para cambiar de opción (al soltar
/// engancha al tab bajo el dedo).
class _OnlineConnectivityCubit extends ConnectivityCubit {
  _OnlineConnectivityCubit() : super() {
    emit(const ConnectivityOnline());
  }
}

void main() {
  Finder bySemanticsId(String id) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == id,
      );

  Widget wrap(MenuCubit menu) {
    final screens = List<Widget>.generate(
      5,
      (i) => Center(child: Text('screen-$i')),
    );
    return MaterialApp(
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
        child: NewHomeTabScaffold(screens: screens),
      ),
    );
  }

  void useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone-like
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('tap en un tab cambia el índice seleccionado', (tester) async {
    useMobileViewport(tester);
    final menu = MenuCubit();
    await tester.pumpWidget(wrap(menu));
    await tester.pumpAndSettle();

    expect(menu.state.selectedIndex, 0);

    await tester.tap(bySemanticsId('tab-mapa'));
    await tester.pumpAndSettle();

    expect(menu.state.selectedIndex, 2);
  });

  testWidgets('arrastrar por la barra cambia de tab (engancha al soltar)',
      (tester) async {
    useMobileViewport(tester);
    final menu = MenuCubit();
    await tester.pumpWidget(wrap(menu));
    await tester.pumpAndSettle();

    expect(menu.state.selectedIndex, 0);

    // Arrastre horizontal desde el primer tab hacia la derecha del todo:
    // debe enganchar al último tab (perfil, índice 4).
    final start = tester.getCenter(bySemanticsId('tab-explora'));
    await tester.dragFrom(start, const Offset(700, 0));
    await tester.pumpAndSettle();

    expect(menu.state.selectedIndex, greaterThan(0),
        reason: 'el arrastre debe cambiar de tab');
    expect(menu.state.selectedIndex, 4,
        reason: 'arrastrar al extremo derecho engancha al último tab');
  });
}
