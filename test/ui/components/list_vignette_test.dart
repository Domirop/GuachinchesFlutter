import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/components/vignettes/list_vignette.dart';

Widget _scene(ListVignetteKind kind, {bool active = true, bool reduce = false}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 128,
            child: ListVignette(kind: kind, active: active),
          ),
        ),
      ),
    );

void main() {
  test('la viñeta de cada lista sale del id y el título', () {
    expect(listVignetteFor('brunch-tenerife Para hacer brunch'),
        ListVignetteKind.brunch);
    expect(listVignetteFor('top-bocadillos-cochino-2026 Mejores bocadillos'),
        ListVignetteKind.bocadillo);
    expect(listVignetteFor('japoneses-en-tenerife JAPONESES EN TENERIFE'),
        ListVignetteKind.japones);
    expect(listVignetteFor('x Sushi del sur'), ListVignetteKind.japones);
    expect(
        listVignetteFor(
            'cenas-especiales-tenerife Sitios para ocasiones especiales'),
        ListVignetteKind.celebracion);
    expect(listVignetteFor('Japón y más'), ListVignetteKind.japones);
    expect(listVignetteFor('top-guachinches Los mejores guachinches'), isNull);
  });

  test('reposo al final del bucle de 8 s', () {
    // Brunch: activo 0,45–6,6 y 7,0–8,0; reposo 6,6–7,0.
    expect(vignetteQuietRemaining(ListVignetteKind.brunch, 2.0), 0);
    expect(vignetteQuietRemaining(ListVignetteKind.brunch, 6.8),
        closeTo(0.2, 1e-9));
    // Bocadillo: reposo 6,45 → 8,45 (0,45 del bucle siguiente).
    expect(vignetteQuietRemaining(ListVignetteKind.bocadillo, 7.0),
        closeTo(1.45, 1e-9));
    // Al despertar en el borde no se vuelve a dormir.
    final wake = 7.0 + vignetteQuietRemaining(ListVignetteKind.bocadillo, 7.0);
    expect(vignetteQuietRemaining(ListVignetteKind.bocadillo, wake), 0);
  });

  for (final kind in ListVignetteKind.values) {
    testWidgets('$kind se pinta, anima y duerme en el reposo', (tester) async {
      await tester.pumpWidget(_scene(kind));
      await tester.pump(const Duration(milliseconds: 16));
      final s = tester.state<ListVignetteState>(find.byType(ListVignette));
      expect(s.isStatic, isFalse);
      expect(s.isTicking, isTrue);
      // Recorre el bucle entero fotograma a fotograma: nada lanza.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 130));
      }
      expect(tester.takeException(), isNull);
      // 6,5 s → reposo de todas salvo celebración (que duerme desde 6,3).
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('$kind con movimiento reducido: reposo sin reloj',
        (tester) async {
      await tester.pumpWidget(_scene(kind, reduce: true));
      await tester.pump(const Duration(milliseconds: 16));
      final s = tester.state<ListVignetteState>(find.byType(ListVignette));
      expect(s.isStatic, isTrue);
      expect(s.isTicking, isFalse);
    });
  }

  testWidgets('fuera de pantalla no corre', (tester) async {
    await tester.pumpWidget(_scene(ListVignetteKind.japones, active: false));
    await tester.pump(const Duration(milliseconds: 16));
    final s = tester.state<ListVignetteState>(find.byType(ListVignette));
    expect(s.isTicking, isFalse);
    await tester.pumpWidget(_scene(ListVignetteKind.japones));
    await tester.pump(const Duration(milliseconds: 16));
    expect(s.isTicking, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
