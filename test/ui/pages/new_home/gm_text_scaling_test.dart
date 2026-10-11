import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/restaurant.dart';
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

void main() {
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
                nearby: NearbyRestaurant(
                    restaurant: _r(), distanceLabel: '1,2 km'),
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
