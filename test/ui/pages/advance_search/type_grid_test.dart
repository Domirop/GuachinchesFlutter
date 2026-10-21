import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/type_grid.dart';

/// QA multidispositivo (M2): en el Nexus S «Por tipo» partía las palabras
/// («Restaura/ntes»). Con la palabra más larga sin sitio, una columna.
void main() {
  double perChar(String w) => w.length * 8.0;

  test('dos columnas si la palabra más larga cabe; si no, una', () {
    const titles = ['Restaurantes', 'Guachinches modernos', 'Bar/Cafetería'];
    // «Guachinches» y «Restaurantes»: 12 letras × 8 = 96.
    expect(typeGridColumns(titles, 100, perChar), 2);
    expect(typeGridColumns(titles, 90, perChar), 1);
    // «Bar/Cafetería» se puede partir en la barra.
    expect(typeGridColumns(['Bar/Cafetería'], 75, perChar), 2);
  });

  testWidgets('a 320 de ancho, una loseta por fila y sin desbordes',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 1.5, 533 * 1.5);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    final types = [
      for (final n in ['Restaurantes', 'Guachinches modernos', 'Tascas'])
        Types(id: n, nombre: n),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TypeGrid(types: types, pool: const [], onPick: (_) {}),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final tiles = find.byWidgetPredicate((w) =>
        w is Semantics &&
        (w.properties.identifier ?? '').startsWith('advanced-search-type'));
    expect(tiles, findsNWidgets(3));
    final xs = {
      for (final e in tiles.evaluate())
        tester.getRect(find.byWidget(e.widget)).left
    };
    expect(xs.length, 1, reason: 'una sola columna');
  });
}
