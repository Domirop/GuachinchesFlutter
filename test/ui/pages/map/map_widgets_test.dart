import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/widgets/map_chrome.dart';
import 'package:guachinches/ui/pages/map/widgets/map_drive.dart';
import 'package:guachinches/ui/pages/map/widgets/map_nearby.dart';
import 'package:guachinches/ui/pages/map/widgets/map_peek_sheet.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/open_state.dart';

import 'map_test_utils.dart';

void main() {
  group('hoja del sitio elegido', () {
    Future<Map<String, int>> pumpSheet(WidgetTester tester,
        {bool dark = false, VoidCallback? onCall, GmFavorites? favs}) async {
      final taps = <String, int>{};
      void hit(String k) => taps[k] = (taps[k] ?? 0) + 1;
      await tester.pumpWidget(wrapMap(
        Align(
          alignment: Alignment.bottomCenter,
          child: MapPeekSheet(
            site: site('angela', type: RestaurantTypeIds.guachinchesModernos),
            positionLabel: zonePosition(20, 37, byDistance: true),
            onPrev: () => hit('prev'),
            onNext: () => hit('next'),
            onClose: () => hit('close'),
            onOpenDetail: () => hit('detail'),
            onDirections: () => hit('directions'),
            onCall: onCall,
            favorites: favs ?? GmFavorites.withRepository(MemFavs()),
          ),
        ),
        dark: dark,
      ));
      await tester.pump();
      return taps;
    }

    testWidgets('pinta tipo, municipio, nombre, estado y posición',
        (tester) async {
      await pumpSheet(tester);
      expect(find.text('Guachinche moderno · La Victoria'), findsOneWidget);
      expect(find.text('Casa Ángela'), findsOneWidget);
      expect(find.text('21 de 37 en esta zona · por cercanía'), findsOneWidget);
      expect(find.textContaining('Abierto'), findsWidgets);
      expect(find.text('3,4 km'), findsOneWidget);
      for (final l in ['Cómo llegar', 'Llamar', 'Guardar', 'Ver ficha']) {
        expect(find.text(l), findsOneWidget);
      }
    });

    testWidgets('acciones y navegación', (tester) async {
      var called = 0;
      final taps = await pumpSheet(tester, onCall: () => called++);
      await tester.tap(byIdentifier('mapa-peek-prev'));
      await tester.tap(byIdentifier('mapa-peek-next'));
      await tester.tap(byIdentifier('mapa-peek-close'));
      await tester.tap(byIdentifier('mapa-peek-detail'));
      await tester.tap(byIdentifier('mapa-peek-directions'));
      await tester.tap(byIdentifier('mapa-peek-call'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, {
        'prev': 1,
        'next': 1,
        'close': 1,
        'detail': 1,
        'directions': 1,
      });
      expect(called, 1);
    });

    testWidgets('Guardar ↔ Guardado con los guardados locales', (tester) async {
      final favs = GmFavorites.withRepository(MemFavs());
      await pumpSheet(tester, favs: favs);
      await tester.tap(byIdentifier('mapa-peek-save'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Guardado'), findsOneWidget);
      expect(favs.isSaved('angela'), isTrue);
    });

    testWidgets('sin teléfono «Llamar» queda deshabilitado; de noche pinta',
        (tester) async {
      await pumpSheet(tester, dark: true);
      final sem = tester.getSemantics(byIdentifier('mapa-peek-call'));
      expect(sem.flagsCollection.isEnabled, isNot(true));
      expect(tester.takeException(), isNull);
    });
  });

  group('fila de chips', () {
    testWidgets('activos primero con aspa; los toques llegan', (tester) async {
      var open = 0;
      final typeTaps = <String>[];
      final chips = mapTypeChips(const [], active: const {});
      expect(chips, isEmpty);
      await tester.pumpWidget(wrapMap(MapChipRow(
        openNow: true,
        types: const [
          MapTypeChip('t1', 'Tascas', null),
          MapTypeChip('t2', 'Cofradías', null),
        ],
        activeTypes: const {'t2'},
        onToggleOpen: () => open++,
        onToggleType: typeTaps.add,
      )));
      final xOpen = tester.getTopLeft(find.text('Abierto ahora')).dx;
      final xCof = tester.getTopLeft(find.text('Cofradías')).dx;
      final xTas = tester.getTopLeft(find.text('Tascas')).dx;
      expect(xOpen < xCof && xCof < xTas, isTrue,
          reason: 'activos («Abierto ahora», Cofradías) primero');
      await tester.tap(byIdentifier('mapa-pill-abierto'));
      await tester.tap(byIdentifier('mapa-pill-t1'));
      expect(open, 1);
      expect(typeTaps, ['t1']);
    });

    testWidgets('esqueleto mientras carga', (tester) async {
      await tester.pumpWidget(wrapMap(MapChipRow(
        skeleton: true,
        openNow: false,
        types: const [],
        activeTypes: const {},
        onToggleOpen: () {},
        onToggleType: (_) {},
      )));
      expect(find.text('Abierto ahora'), findsNothing);
    });
  });

  group('estados', () {
    testWidgets('error con «Reintentar»', (tester) async {
      var retry = 0;
      await tester.pumpWidget(wrapMap(MapStateCard(
        identifier: 'mapa-error-state',
        alert: true,
        art: const SizedBox(),
        title: 'No pudimos cargar los sitios',
        text: 'Revisa tu conexión e inténtalo de nuevo. El mapa sigue aquí.',
        actions: [
          TextButton(onPressed: () => retry++, child: const Text('Reintentar'))
        ],
      )));
      await tester.tap(find.text('Reintentar'));
      expect(retry, 1);
    });

    testWidgets('aviso sin ubicación con «Activar»', (tester) async {
      var n = 0;
      await tester
          .pumpWidget(wrapMap(MapNoLocationBanner(onActivate: () => n++)));
      expect(find.text('Sin ubicación, el mapa no sabe qué te queda cerca.'),
          findsOneWidget);
      await tester.tap(byIdentifier('mapa-noloc-activate'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(n, 1);
    });

    testWidgets('cápsula de carga', (tester) async {
      await tester.pumpWidget(
          wrapMap(MapLoadingCapsule(text: loadingCopy('Tenerife'))));
      expect(find.text('Cargando sitios de Tenerife…'), findsOneWidget);
    });
  });

  group('modo coche', () {
    testWidgets('«Estará cerrado al llegar» con la hora de cierre',
        (tester) async {
      await tester.pumpWidget(wrapMap(Center(
        child: SizedBox(
          width: 330,
          height: 196,
          child: MapDriveCard(
            site: site('parralito',
                name: 'El Parralito',
                type: RestaurantTypeIds.guachinchesTradicionales,
                meters: 1700,
                open: const OpenState(OpenKind.closingSoon,
                    minutesToClose: 3, closesAtMinute: 16 * 60)),
            eyebrow: driveCardEyebrow(11, 31),
            onGo: () {},
          ),
        ),
      )));
      expect(find.text('Estará cerrado al llegar'), findsOneWidget);
      expect(find.text('Cierra a las 16:00'), findsOneWidget);
      expect(find.text('12 de 31 · Guachinche tradicional'), findsOneWidget);
      expect(find.textContaining('4 min', findRichText: true), findsOneWidget);
      expect(find.text('Ir'), findsOneWidget);
    });

    testWidgets('sugerencia «¿Vas en coche?»', (tester) async {
      var yes = 0, no = 0;
      await tester.pumpWidget(wrapMap(Align(
        alignment: Alignment.bottomCenter,
        child: MapDriveSuggestionSheet(
            onConfirm: () => yes++, onDismiss: () => no++),
      )));
      expect(find.text('¿Vas en coche?'), findsOneWidget);
      await tester.tap(byIdentifier('mapa-drive-suggest-accept'));
      await tester.tap(byIdentifier('mapa-drive-suggest-dismiss'));
      await tester.pump(const Duration(milliseconds: 300));
      expect((yes, no), (1, 1));
    });
  });

  group('«Cerca de ti»', () {
    Widget sheet(NearbyPhase phase, List<MapSite> near,
            {VoidCallback? onActivate, VoidCallback? onIsland}) =>
        wrapMap(Align(
          alignment: Alignment.bottomCenter,
          child: MapNearbySheet(
            phase: phase,
            near: near,
            carousel: ScrollController(),
            onOpen: (_) {},
            onActivateLocation: onActivate ?? () {},
            onShowIsland: onIsland ?? () {},
            onRetry: () {},
          ),
        ));

    testWidgets('listo: «N abiertos ahora · Abiertos y cerca»', (tester) async {
      await tester.pumpWidget(sheet(NearbyPhase.ready, [
        site('a', name: 'Guachinche Pa Picar', meters: 560),
        site('b', meters: 900, open: const OpenState(OpenKind.closed)),
      ]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1 abierto ahora'), findsOneWidget);
      expect(find.text('Abiertos y cerca'), findsOneWidget);
      expect(find.text('Guachinche Pa Picar'), findsOneWidget);
    });

    testWidgets('sin ubicación: activar o ver toda la isla', (tester) async {
      var act = 0, isl = 0;
      await tester.pumpWidget(sheet(NearbyPhase.noLocation, const [],
          onActivate: () => act++, onIsland: () => isl++));
      expect(find.text('Activa la ubicación'), findsOneWidget);
      await tester.tap(byIdentifier('mapa-nearby-activate'));
      await tester.tap(byIdentifier('mapa-nearby-island'));
      await tester.pump(const Duration(milliseconds: 300));
      expect((act, isl), (1, 1));
    });

    testWidgets('error y nada cerca', (tester) async {
      await tester.pumpWidget(sheet(NearbyPhase.error, const []));
      expect(
          find.text('No pudimos cargar lo que tienes cerca'), findsOneWidget);
      await tester.pumpWidget(sheet(NearbyPhase.ready, const []));
      expect(find.text('Nada a menos de 3 km'), findsOneWidget);
    });

    testWidgets('lista agrupada con título y subtítulo', (tester) async {
      await tester.pumpWidget(wrapMap(MapNearbyList(
        phase: NearbyPhase.ready,
        near: [
          site('a', name: 'Los Muchachos', type: RestaurantTypeIds.bodegones),
          site('b', name: 'La Espetada', type: RestaurantTypeIds.tascas),
        ],
        topInset: 0,
        onOpen: (_) {},
        onActivateLocation: () {},
        onShowIsland: () {},
        onRetry: () {},
      )));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Cerca de ti'), findsOneWidget);
      expect(find.text('2 sitios a menos de 3 km · abiertos primero'),
          findsOneWidget);
      expect(find.text('Los Muchachos'), findsOneWidget);
      expect(byIdentifier('mapa-nearby-row-b'), findsOneWidget);
    });

    testWidgets('segmentado Lista/Mapa', (tester) async {
      bool? picked;
      await tester.pumpWidget(wrapMap(Center(
          child: MapSegmented(
              listSelected: false, onChanged: (v) => picked = v))));
      await tester.tap(byIdentifier('mapa-nearby-list'));
      expect(picked, isTrue);
    });
  });
}
