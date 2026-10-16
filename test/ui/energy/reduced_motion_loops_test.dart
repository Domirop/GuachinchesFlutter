import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/ui/components/clouds_overlay.dart';
import 'package:guachinches/ui/components/open_now_callout.dart';
import 'package:guachinches/ui/components/rain_overlay.dart';

/// Con «Quitar animaciones» (MediaQuery.disableAnimations) ningún bucle debe
/// seguir corriendo: el sistema acorta las duraciones y un controlador en
/// `repeat()` se pone a girar a toda velocidad.
void main() {
  Future<void> pump(WidgetTester t, Widget child, {required bool reduce}) =>
      t.pumpWidget(MaterialApp(
        theme: appLightTheme,
        builder: (ctx, c) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(disableAnimations: reduce),
          child: c!,
        ),
        home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
      ));

  final cases = <String, Widget>{
    'nubes': const CloudsOverlay(),
    'lluvia': const RainOverlay(),
    'abiertos ahora': const OpenNowCallout(count: 3, contextLabel: 'almuerzo'),
  };

  for (final e in cases.entries) {
    testWidgets('${e.key}: sin bucle con movimiento reducido', (t) async {
      await pump(t, e.value, reduce: true);
      await t.pump(const Duration(seconds: 1));
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('${e.key}: sigue animando sin movimiento reducido', (t) async {
      await pump(t, e.value, reduce: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(t.hasRunningAnimations, isTrue);
      await t.pumpWidget(const SizedBox());
    });
  }
}
