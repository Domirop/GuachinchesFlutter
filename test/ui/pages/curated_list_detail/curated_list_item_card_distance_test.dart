import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/pages/curated_list_detail/widgets/curated_list_item_card.dart';

const _item = CuratedListItem(
  restaurantId: 'r1',
  position: 1,
  restaurant: CuratedListItemRestaurant(
    id: 'r1',
    nombre: 'Tasca El Callejón',
    municipio: 'La Laguna',
  ),
);

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('muestra el pill de distancia cuando hay distanceLabel',
      (tester) async {
    await tester.pumpWidget(_host(
      CuratedListItemCard(
        item: _item,
        accent: AppColors.atlantico,
        fallbackEyebrow: 'JONAY',
        distanceLabel: '320 m',
        onTap: () {},
      ),
    ));

    expect(find.text('320 m'), findsOneWidget);
    expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin distanceLabel no pinta pill (ni icono)', (tester) async {
    await tester.pumpWidget(_host(
      CuratedListItemCard(
        item: _item,
        accent: AppColors.atlantico,
        fallbackEyebrow: 'JONAY',
        onTap: () {},
      ),
    ));

    expect(find.byIcon(Icons.near_me_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('parseCoord: lat/lon vienen del JSON; 0 y null → null', () {
    final withCoords = CuratedListItemRestaurant.fromJson({
      'id': 'r1',
      'nombre': 'X',
      'lat': '28.46',
      'lon': -16.25,
    });
    expect(withCoords.lat, 28.46);
    expect(withCoords.lon, -16.25);

    final zero = CuratedListItemRestaurant.fromJson({
      'id': 'r2',
      'nombre': 'Y',
      'lat': 0,
      'lon': 0,
    });
    expect(zero.lat, isNull);
    expect(zero.lon, isNull);

    final missing = CuratedListItemRestaurant.fromJson({
      'id': 'r3',
      'nombre': 'Z',
    });
    expect(missing.lat, isNull);
    expect(missing.lon, isNull);
  });
}
