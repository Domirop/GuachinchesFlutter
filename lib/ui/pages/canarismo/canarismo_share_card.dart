import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_logic.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

const _tag = 'canarismo-share';

/// Comparte un canarismo como **imagen 9:16** (1080 × 1920, para historias).
/// Renderiza [CanarismoShareCard] fuera de pantalla a PNG y lo comparte por
/// `share_plus`. Si la captura falla, cae a texto plano.
///
/// [date] / [isToday]: día del canarismo (hoy por defecto); uno pasado no
/// dice «del día». [includeText] = `false` comparte solo la imagen (botón
/// «Guardar»: la hoja del sistema ofrece «Guardar imagen»).
Future<void> shareCanarismoAsImage(
  BuildContext context,
  Canarismo c, {
  DateTime? date,
  bool? isToday,
  bool includeText = true,
}) async {
  final now = DateTime.now();
  final day = date ?? now;
  final today = isToday ?? canarismoIsSameDay(day, now);
  final text = canarismoShareText(c);
  Analytics.I.logEvent(AnalyticsEvents.canarismoShared, {
    'palabra': c.palabra,
    'mode': includeText ? 'share' : 'save',
  });
  try {
    final bytes = await _captureCard(
      context,
      CanarismoShareCard(canarismo: c, date: day, isToday: today),
      CanarismoShareCard.size, // 9:16
      pixelRatio: 3, // → 1080×1920
    );
    if (bytes == null) {
      await SharePlus.instance.share(ShareParams(text: text));
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/canarismo_${_slug(c.palabra)}.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        text: includeText ? text : null,
        files: [XFile(file.path, mimeType: 'image/png')],
      ),
    );
  } catch (e, st) {
    // Fallback robusto: nunca dejar al usuario sin compartir.
    AppLogger.error(_tag, e, st);
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

String _slug(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.runes) {
    final c = String.fromCharCode(ch);
    if (RegExp(r'[a-z0-9]').hasMatch(c)) {
      buf.write(c);
    } else if (c == ' ') {
      buf.write('_');
    }
  }
  final out = buf.toString();
  return out.isEmpty ? 'canarismo' : out;
}

/// Renderiza [child] (de tamaño [size]) fuera de pantalla y devuelve su PNG.
Future<Uint8List?> _captureCard(
  BuildContext context,
  Widget child,
  Size size, {
  double pixelRatio = 3,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final repaintKey = GlobalKey();

  // El glifo del volcán es un SVG de assets: precargarlo para que esté en la
  // caché antes de rasterizar (si no, podría salir sin pintar).
  try {
    await SvgAssetLoader(GmGlyphKind.volcan.asset).loadBytes(null);
  } catch (e, st) {
    AppLogger.error(_tag, e, st);
  }

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // Fuera de pantalla pero montado y pintado (RepaintBoundary crea su capa,
      // así que toImage la rasteriza aunque no esté visible).
      left: -9999,
      top: -9999,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: repaintKey,
          child: MediaQuery(
            data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Bombear varios frames para que el subárbol offscreen haga layout, cargue
    // fuentes y glifos y pinte su capa antes de rasterizar. NO usamos
    // `debugNeedsPaint`: es una API solo-debug que lanza
    // LateInitializationError en profile/release (rompía la captura fuera de
    // debug y caía siempre al fallback de texto).
    for (var i = 0; i < 4; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      AppLogger.warn(_tag, 'RepaintBoundary no encontrado');
      return null;
    }
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  } catch (e, st) {
    AppLogger.error(_tag, e, st);
    return null;
  } finally {
    entry.remove();
  }
}

/// Tarjeta 9:16 para historias (tablero «CanarismoTarjeta»): degradado vino,
/// chispas oro, marca con el volcán, «El canarismo del día» (o «Un
/// canarismo» si no es el de hoy), la palabra, filete oro, significado,
/// fecha y, abajo, el pie «Diccionario del habla canaria ·
/// dondecomercanarias.com» sobre el mantel de cuadros.
///
/// Se diseña a [size] lógicos (360 × 640; ×3 = 1080 × 1920). Para verla más
/// pequeña, escalarla con [CanarismoStoryPreview].
class CanarismoShareCard extends StatelessWidget {
  static const Size size = Size(360, 640);

  /// Escala del tablero (tarjeta de 270 de ancho) a 360.
  static const double _s = 360 / 270;

  final Canarismo canarismo;

  /// Día del canarismo (hoy si es null).
  final DateTime? date;

  /// `false` para un canarismo pasado: no dice «del día».
  final bool isToday;

  const CanarismoShareCard({
    super.key,
    required this.canarismo,
    this.date,
    this.isToday = true,
  });

  // Caja del bloque central: arranca a 150 (tablero) y sube si la palabra o
  // el significado son largos, sin pisar la marca ni el pie.
  static const double _blockTop = 150 * _s;
  static const double _blockMinTop = 56 * _s;
  static const double _blockBottom = 640 - 72 * _s - 2 * 15 * _s - 10 * _s;
  static const double _side = 24 * _s;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    TextStyle st(double size, double line, FontWeight w, Color color,
            {double ls = 0}) =>
        base.merge(TextStyle(
          fontSize: size * _s,
          height: line / size,
          fontWeight: w,
          letterSpacing: ls * _s,
          color: color,
          decoration: TextDecoration.none,
          leadingDistribution: TextLeadingDistribution.even,
        ));

    final eyebrow = st(13, 18, FontWeight.w600, GmColors.gold);
    final meaningStyle = st(17, 24, FontWeight.w400, kCanarismoMeaning);
    final dateStyle = st(12, 16, FontWeight.w400, const Color(0xB8F2E8D5));
    final foot = st(11, 15, FontWeight.w400, const Color(0xC7F2E8D5));
    // Alto fijo del bloque (todo menos palabra y significado).
    const gap = 8 * _s;
    const rule = 3 * _s + 2 * 6 * _s;
    final fixed = eyebrow.fontSize! * eyebrow.height! +
        gap * 4 +
        rule +
        10 * _s +
        dateStyle.fontSize! * dateStyle.height!;
    final meaningLine = meaningStyle.fontSize! * meaningStyle.height!;
    const textW = 360 - 2 * _side;
    final meaningPainter = TextPainter(
      text: TextSpan(text: canarismo.significado, style: meaningStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textW);
    final meaningNeeded = meaningPainter.computeLineMetrics().length;
    meaningPainter.dispose();

    // La palabra manda, pero si con ella el significado no cabe entero, se
    // reduce un poco más (hasta 30) antes de cortar el significado.
    final wordBase = st(54, 58, FontWeight.w800, GmColors.creamHi, ls: -1.6);
    late CanarismoWordFit wordFit;
    late int meaningLines;
    for (var max = 54 * _s;; max -= 4) {
      wordFit = fitCanarismoWord(canarismo.palabra, wordBase, textW,
          maxSize: max < 30 ? 30 : max, minSize: 30);
      final avail = (_blockBottom - _blockMinTop) - fixed - wordFit.height - 1;
      meaningLines = (avail / meaningLine).floor().clamp(1, 6);
      if (meaningLines >= meaningNeeded || max <= 30) break;
    }

    final d = date ?? DateTime.now();
    final block = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          canarismoCardEyebrow(isToday: isToday),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: eyebrow,
        ),
        const SizedBox(height: gap),
        Text(
          canarismo.palabra,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: wordFit.style,
        ),
        const SizedBox(height: gap),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6 * _s),
          width: 36 * _s,
          height: 3 * _s,
          decoration: BoxDecoration(
            color: GmColors.gold,
            borderRadius: BorderRadius.circular(3 * _s),
          ),
        ),
        const SizedBox(height: gap),
        Text(
          canarismo.significado,
          maxLines: meaningLines,
          overflow: TextOverflow.ellipsis,
          style: meaningStyle,
        ),
        const SizedBox(height: gap + 10 * _s),
        Text(canarismoFullDate(d), maxLines: 1, style: dateStyle),
      ],
    );

    final mq = MediaQuery.maybeOf(context);
    Widget card = DecoratedBox(
      decoration: BoxDecoration(gradient: kCanarismoCardGradient),
      child: SizedBox.expand(
        child: Stack(
          children: [
            const Positioned(
              right: 22 * _s,
              top: 26 * _s,
              child: _Sparkle(size: 54 * _s),
            ),
            Positioned(
              left: _side,
              right: _side,
              top: 34 * _s,
              child: Row(
                children: [
                  const GmGlyph(GmGlyphKind.volcan, size: 14 * _s),
                  const SizedBox(width: 6 * _s),
                  Flexible(
                    child: Text(
                      'Dónde Comer Canarias',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          st(10.5, 14, FontWeight.w700, GmColors.gold, ls: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: _side,
              right: _side,
              top: 0,
              bottom: 0,
              child: CustomSingleChildLayout(
                delegate: const _BlockLayout(
                  preferredTop: _blockTop,
                  minTop: _blockMinTop,
                  bottom: _blockBottom,
                ),
                child: block,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 56 * _s,
              child: const Opacity(
                opacity: 0.92,
                child: CanarismoGinghamStrip(height: 56 * _s, cell: 7 * _s),
              ),
            ),
            Positioned(
              left: 16 * _s,
              right: 16 * _s,
              bottom: 72 * _s,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Diccionario del habla canaria',
                      maxLines: 2,
                      style: foot,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // El dominio nunca se parte: como mucho, se encoge.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'dondecomercanarias.com',
                        maxLines: 1,
                        style: st(11, 15, FontWeight.w700, kCanarismoGoldHi),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // La tarjeta es una imagen: no crece con el tamaño de texto del sistema.
    if (mq != null) {
      card = MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.noScaling),
        child: card,
      );
    }
    return card;
  }
}

/// Coloca el bloque central en [preferredTop]; si no cabe hasta [bottom],
/// lo sube (nunca por encima de [minTop]).
class _BlockLayout extends SingleChildLayoutDelegate {
  final double preferredTop;
  final double minTop;
  final double bottom;
  const _BlockLayout({
    required this.preferredTop,
    required this.minTop,
    required this.bottom,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        minWidth: constraints.maxWidth,
        maxHeight: (bottom - minTop).clamp(0, constraints.maxHeight),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = (bottom - childSize.height).clamp(minTop, preferredTop);
    return Offset(0, top);
  }

  @override
  bool shouldRelayout(_BlockLayout old) =>
      old.preferredTop != preferredTop ||
      old.minTop != minTop ||
      old.bottom != bottom;
}

/// Chispas oro (estrella grande + pequeña al 70 %), como los tableros.
class _Sparkle extends StatelessWidget {
  final double size;
  const _Sparkle({required this.size});

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M12 2l1.6 6.4L20 10l-6.4 1.6L12 18l-1.6-6.4L4 10l6.4-1.6z"/>'
      '<path d="M19.5 15l.7 2.3 2.3.7-2.3.7-.7 2.3-.7-2.3-2.3-.7 2.3-.7z" opacity=".7"/></svg>';

  @override
  Widget build(BuildContext context) =>
      GmIcon(_svg, size: size, color: GmColors.gold);
}

/// Chispas oro del hero del detalle (mismo dibujo que la tarjeta).
class CanarismoSparkle extends StatelessWidget {
  final double size;
  const CanarismoSparkle({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => _Sparkle(size: size);
}

/// [CanarismoShareCard] a [width] de ancho (9:16): esquinas redondeadas
/// (22 a escala del tablero), filo oro y sombra. Para la miniatura del
/// detalle y la vista previa de la hoja.
class CanarismoStoryPreview extends StatelessWidget {
  final double width;
  final Canarismo canarismo;
  final DateTime? date;
  final bool isToday;

  const CanarismoStoryPreview({
    super.key,
    required this.width,
    required this.canarismo,
    this.date,
    this.isToday = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = width / 270;
    final height = width * 16 / 9;
    final radius = BorderRadius.circular(22 * k);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0x99000000),
              offset: Offset(0, 30 * k),
              blurRadius: 60 * k,
              spreadRadius: -20 * k,
            ),
          ],
        ),
        position: DecorationPosition.background,
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: const Color(0x47C9A96B)),
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox.fromSize(
                size: CanarismoShareCard.size,
                child: CanarismoShareCard(
                  canarismo: canarismo,
                  date: date,
                  isToday: isToday,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
