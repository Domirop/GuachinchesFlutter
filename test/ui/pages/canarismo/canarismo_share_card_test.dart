import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_share_card.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';

/// Monta la tarjeta a su tamaño real 9:16 (360×640 @3x = 1080×1920),
/// comprueba que no hay overflow y la rasteriza con `toImage` (lo que hace
/// `shareCanarismoAsImage`, sin tocar `share_plus`).
Future<(int, int, int)> _rasterize(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(key: key, child: card),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));

  // No debe haber overflow de layout al tamaño real de la tarjeta.
  expect(tester.takeException(), isNull);

  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;

  // `toImage` es async real (motor): en widget tests debe ir dentro de
  // `runAsync`, si no el reloj fake bloquea su Future ("did not complete").
  late final int width;
  late final int height;
  late final int byteLength;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    width = image.width;
    height = image.height;
    byteLength = data!.lengthInBytes;
    image.dispose();
  });
  return (width, height, byteLength);
}

void main() {
  // La parte que fallaba en producción era la rasterización de la tarjeta a
  // PNG (el gate usaba `debugNeedsPaint`, API solo-debug que lanza en
  // profile/release y caía siempre al fallback de texto).
  testWidgets('CanarismoShareCard se rasteriza a PNG 1080x1920',
      (tester) async {
    const c = Canarismo('Guagua', 'Autobús.');
    final (w, h, bytes) =
        await _rasterize(tester, const CanarismoShareCard(canarismo: c));
    expect(w, 1080);
    expect(h, 1920);
    expect(bytes, greaterThan(0));
    expect(find.text('El canarismo del día'), findsOneWidget);
    expect(find.text('Dónde Comer Canarias'), findsOneWidget);
    expect(find.text('Diccionario del habla canaria'), findsOneWidget);
    expect(find.text('dondecomercanarias.com'), findsOneWidget);
  });

  testWidgets('fecha completa y canarismo pasado sin «del día»',
      (tester) async {
    const c = Canarismo('Tasca', 'Bar pequeño; banco de pesca en el mar.');
    final (w, h, _) = await _rasterize(
      tester,
      CanarismoShareCard(
        canarismo: c,
        date: DateTime(2026, 10, 12),
        isToday: false,
      ),
    );
    expect((w, h), (1080, 1920));
    expect(find.text('Un canarismo'), findsOneWidget);
    expect(find.textContaining('del día'), findsNothing);
    expect(find.text('12 de octubre de 2026'), findsOneWidget);
  });

  for (final c in const [
    Canarismo('Pasar más hambre que un maestro',
        'Tener muchísima hambre; pasar grandes penurias económicas.'),
    Canarismo('Escarranchado/a', 'Con las piernas muy abiertas.'),
    Canarismo('Hacer de tripas corazón', 'Sobreponerse a algo desagradable.'),
  ]) {
    testWidgets('palabra larga «${c.palabra}» cabe sin overflow',
        (tester) async {
      final (w, h, _) =
          await _rasterize(tester, CanarismoShareCard(canarismo: c));
      expect((w, h), (1080, 1920));

      // La palabra se reduce y nunca pasa de 3 líneas.
      final word = tester.widget<Text>(find.text(c.palabra));
      expect(word.style!.fontSize, lessThanOrEqualTo(72));
      expect(word.maxLines, 3);

      // El bloque central no pisa la marca ni el pie.
      final wordBox = tester.getRect(find.text(c.palabra));
      final footBox = tester.getRect(find.text('dondecomercanarias.com'));
      final dateBox = tester.getRect(find.textContaining(' de 20'));
      expect(wordBox.top, greaterThan(60));
      expect(dateBox.bottom, lessThan(footBox.top));
    });
  }

  testWidgets('el significado más largo del diccionario no desborda',
      (tester) async {
    final longest = kCanarismos
        .reduce((a, b) => a.significado.length >= b.significado.length ? a : b);
    final c = Canarismo('Pasar más hambre que un maestro', longest.significado);
    final (w, h, _) =
        await _rasterize(tester, CanarismoShareCard(canarismo: c));
    expect((w, h), (1080, 1920));
    final dateBox = tester.getRect(find.textContaining(' de 20'));
    final footBox = tester.getRect(find.text('dondecomercanarias.com'));
    expect(dateBox.bottom, lessThan(footBox.top));
  });

  testWidgets('fitCanarismoWord baja de tamaño para que quepa cada palabra',
      (tester) async {
    const style = TextStyle(fontSize: 72, height: 58 / 54);
    // Fuente de test: 1 em por letra. «Tasca» = 5 em → 360 a 72: cabe en 400.
    expect(
        fitCanarismoWord('Tasca', style, 400, maxSize: 72, minSize: 30)
            .fontSize,
        72);
    // «Escarranchado/a» = 15 em: en 296 solo cabría a ≤ 19,7 → mínimo.
    final f = fitCanarismoWord('Escarranchado/a', style, 296,
        maxSize: 72, minSize: 30);
    expect(f.fontSize, 30);
    // «Hacer de tripas corazón»: «corazón» = 7 em → en 296, ≤ 42.
    final g = fitCanarismoWord('Hacer de tripas corazón', style, 296,
        maxSize: 72, minSize: 30);
    expect(g.fontSize, lessThanOrEqualTo(42));
    expect(g.lines, lessThanOrEqualTo(3));
  });
}
