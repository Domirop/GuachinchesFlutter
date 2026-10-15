import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_curated_list.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_nearby_minimap.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/distance_utils.dart';

Restaurant _r() => Restaurant(
      id: 'r1',
      nombre: 'Área de descanso Polígono de Güímar con nombre larguísimo',
      municipio: 'San Cristóbal de La Laguna',
      avgRating: 4.7,
    );

Widget _host(double scale, Widget child) => MaterialApp(
      theme: appLightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(402, 874),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

/// Escalado no lineal como el de Android 14+ (a más tamaño, menos escala):
/// 1,3× en letra pequeña y algo menos en la grande.
class _AndroidNonLinear extends TextScaler {
  const _AndroidNonLinear();
  @override
  double scale(double fontSize) =>
      fontSize * (1.3 - ((fontSize - 12).clamp(0, 20)) * 0.01);
  @override
  double get textScaleFactor => 1.3;
  @override
  TextScaler clamp(
          {double minScaleFactor = 0,
          double maxScaleFactor = double.infinity}) =>
      this;
  @override
  bool operator ==(Object other) => other is _AndroidNonLinear;
  @override
  int get hashCode => 1;
}

Widget _nonLinearHost(Widget child) => MaterialApp(
      theme: appLightTheme,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(402, 874),
          textScaler: _AndroidNonLinear(),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  // QA Android (I4): con el escalado no lineal de Android al 130 % el alto
  // calculado se quedaba corto (4,1 px en «Cerca de ti», 2,4 px en «Guías»).
  testWidgets('«Cerca de ti» no desborda con el escalado no lineal de Android',
      (tester) async {
    await tester.pumpWidget(_nonLinearHost(Builder(
      builder: (context) => SizedBox(
        height: CardNearbyMinimap.heightFor(context),
        child: CardNearbyMinimap(
          nearby: NearbyRestaurant(restaurant: _r(), distanceLabel: '1,2 km'),
          onTap: () {},
        ),
      ),
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('«Guías» no desborda con el escalado no lineal de Android',
      (tester) async {
    const list = CuratedList(
      id: 'l1',
      eyebrow: 'Guía',
      title: 'Japoneses en Tenerife con un título larguísimo',
      subtitle: 'Te presentamos un recorrido por los mejores japoneses de '
          'la isla. Nos encanta esta comida y esperamos que crezca.',
      heroEmoji: '🍣',
      count: 6,
      location: 'Todo Tenerife',
      accent: Color(0xFF5B4FA8),
    );
    await tester.pumpWidget(_nonLinearHost(Builder(
      builder: (context) => SizedBox(
        width: CardCuratedList.width,
        height: CardCuratedList.heightFor(context),
        child: CardCuratedList(list: list, onTap: () {}),
      ),
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.35, 2.0]) {
    testWidgets('«Cerca de ti» no desborda a ${scale}x', (tester) async {
      await tester.pumpWidget(_host(
        scale,
        // Igual que la home: el carrusel limita el texto a 1,3×.
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Builder(
            builder: (context) => SizedBox(
              height: CardNearbyMinimap.heightFor(context),
              child: CardNearbyMinimap(
                nearby:
                    NearbyRestaurant(restaurant: _r(), distanceLabel: '1,2 km'),
                onTap: () {},
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tarjeta de la rejilla Hoy no desborda a ${scale}x',
        (tester) async {
      await tester.pumpWidget(_host(
        scale,
        SizedBox(
          width: 179,
          child: GmPlaceCard(
            restaurant: _r(),
            onTap: () {},
            meta: GmMetaRow(
              leading: const GmOpenLabel(),
              rating: _r().avgRating,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('cápsula primaria crece con el texto a ${scale}x',
        (tester) async {
      await tester.pumpWidget(_host(
        scale,
        Align(
          alignment: Alignment.topLeft,
          child: GmCapsuleButton(
              label: 'Activar ubicación', icon: GmIcons.play, onTap: () {}),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final h = tester.getSize(find.byType(GmCapsuleButton)).height;
      expect(h, greaterThanOrEqualTo(44));
    });
  }
}
