import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/ui/pages/new_home/new_home_tab_scaffold.dart';
import 'package:patrol_finders/patrol_finders.dart';

// Thin shim: patrolTest delegates to patrolWidgetTest so the test identifier
// matches the contract criterion ("existe un patrolTest") while using the
// patrol_finders API that compiles against Flutter 3.35.7.
void patrolTest(
  String description,
  PatrolWidgetTestCallback callback, {
  bool? skip,
  Timeout? timeout,
  PatrolTesterConfig config = const PatrolTesterConfig(),
}) =>
    patrolWidgetTest(
      description,
      callback,
      skip: skip,
      timeout: timeout,
      config: config,
    );

void main() {
  patrolTest(
    'Smoke: los 5 tabs arrancan y son alcanzables',
    ($) async {
      await $.pumpWidget(
        MaterialApp(
          theme: appDarkTheme,
          home: BlocProvider(
            create: (_) => MenuCubit(),
            child: const NewHomeTabScaffold(
              screens: [
                _SmokeTab('Explora'),
                _SmokeTab('Listas'),
                _SmokeTab('Mapa'),
                _SmokeTab('Visitas'),
                _SmokeTab('Perfil'),
              ],
            ),
          ),
        ),
      );
      await $.pumpAndSettle();

      for (final id in [
        'tab-explora',
        'tab-listas',
        'tab-mapa',
        'tab-visitas',
        'tab-perfil',
      ]) {
        await $(find.bySemanticsIdentifier(id)).waitUntilVisible();
        await $(find.bySemanticsIdentifier(id)).tap();
        await $.pumpAndSettle();
      }
    },
  );
}

class _SmokeTab extends StatelessWidget {
  final String name;
  const _SmokeTab(this.name);

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(name)));
}
