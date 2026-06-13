import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_share_card.dart';

void main() {
  // La parte que fallaba en producción era la rasterización de la tarjeta a
  // PNG (el gate usaba `debugNeedsPaint`, API solo-debug que lanza en
  // profile/release y caía siempre al fallback de texto). Aquí montamos
  // `CanarismoShareCard` a su tamaño real 9:16 y comprobamos que `toImage`
  // produce un PNG 1080×1920 — sin tocar `share_plus` (plugin de plataforma).
  testWidgets('CanarismoShareCard se rasteriza a PNG 1080x1920', (tester) async {
    // Superficie exacta 360×640 lógicos @3x = 1080×1920 físicos (formato Story).
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const c = Canarismo('Guagua', 'Autobús.');
    final key = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: const CanarismoShareCard(canarismo: c),
        ),
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

    expect(width, 1080);
    expect(height, 1920);
    expect(byteLength, greaterThan(0));
  });
}
