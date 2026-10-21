import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/map_pins.dart';
import 'package:guachinches/ui/pages/map/map_style.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

void main() {
  test('estilo del mapa: JSON válido, sin POIs, colores del token', () {
    for (final gm in [GmColors.day, GmColors.night]) {
      final style = mapStyleFor(gm);
      final list = jsonDecode(style) as List;
      expect(list, isNotEmpty);
      expect(style,
          contains('"featureType":"poi","stylers":[{"visibility":"off"}]'));
      expect(style, contains(mapHex(gm.mapSea)));
      expect(style, contains(mapHex(gm.mapMajor)));
      // Google solo admite #RRGGBB.
      expect(RegExp(r'#[0-9A-F]{8}').hasMatch(style), isFalse);
    }
    expect(mapHex(GmColors.day.mapLand), '#F1ECE2');
    expect(mapHex(GmColors.night.mapSea), '#0D2737');
  });

  testWidgets('pinta chinchetas de todos los tipos y burbujas, día y noche',
      (tester) async {
    var ready = 0;
    final f = MapPinFactory(onReady: () => ready++);
    final kinds = <ListThemeKind?>[null, ...kMapChipOrder];
    await tester.runAsync(() async {
      for (final dark in [false, true]) {
        for (final k in kinds) {
          for (final v in MapPinVariant.values) {
            f.pin(k, v, dark: dark);
          }
        }
        f.pin(ListThemeKind.tradicional, MapPinVariant.selected,
            dark: dark, label: 'El Parralito');
        f.cluster(4, dark: dark);
        f.cluster(84, dark: dark);
      }
      final expected = 2 * (kinds.length * 3 + 3);
      for (var i = 0; i < 200 && ready < expected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(ready, expected);
    });
    final sel =
        f.pin(ListThemeKind.moderno, MapPinVariant.selected, dark: false)!;
    // El ancla del elegido es la punta del pie, no el centro.
    expect(sel.anchor.dy, greaterThan(0.7));
    final normal =
        f.pin(ListThemeKind.moderno, MapPinVariant.normal, dark: false)!;
    expect(normal.anchor.dy, closeTo(0.5, 0.01));
    expect(f.cluster(4, dark: true), isNotNull);
    f.dispose();
  });
}
