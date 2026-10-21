import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Piezas visuales del detalle del canarismo y de su tarjeta para historias
/// (tableros «Canarismo» y «CanarismoTarjeta»): degradado vino, mantel de
/// cuadros, icono de descarga y el ajuste de la palabra grande.

/// Tonos del degradado vino de los tableros (#4A1A24 → #2A0E14 → #1C080D).
const Color kCanarismoWineHi = Color(0xFF4A1A24);
const Color kCanarismoWine = Color(0xFF2A0E14);
const Color kCanarismoWineLo = Color(0xFF1C080D);

/// Crema del significado (#F2E8D5) y oro claro del dominio (#E8CF9A).
const Color kCanarismoMeaning = Color(0xFFF2E8D5);
const Color kCanarismoGoldHi = Color(0xFFE8CF9A);

/// Vichy rojo de los tableros: rgba(200,32,44,.55).
const Color kCanarismoGinghamStripe = Color(0x8CC8202C);

/// Base del mantel del hero (vino) y de la tarjeta (crema).
const Color kCanarismoHeroGinghamBase = Color(0xFF3A1219);
const Color kCanarismoCardGinghamBase = Color(0xFFFFF7EC);

/// `radial-gradient(rx% ry% at x% y%, …)` de CSS: elipse con radios
/// relativos al ancho ([rx]) y al alto ([ry]) de la caja.
class _CssEllipse extends GradientTransform {
  final Alignment center;
  final double rx;
  final double ry;
  const _CssEllipse(this.center, this.rx, this.ry);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final c = center.withinRect(bounds);
    final short = bounds.shortestSide;
    if (short <= 0) return Matrix4.identity();
    final sx = rx * bounds.width / short;
    final sy = ry * bounds.height / short;
    return Matrix4.translationValues(c.dx, c.dy, 0)
      ..multiply(Matrix4.diagonal3Values(sx, sy, 1))
      ..multiply(Matrix4.translationValues(-c.dx, -c.dy, 0));
  }
}

RadialGradient _wineGradient(
        Alignment center, double rx, double ry, double midStop) =>
    RadialGradient(
      center: center,
      radius: 1,
      colors: const [kCanarismoWineHi, kCanarismoWine, kCanarismoWineLo],
      stops: [0, midStop, 1],
      transform: _CssEllipse(center, rx, ry),
    );

/// Hero del detalle: `radial-gradient(120% 80% at 90% 0%, …60%…)`.
final RadialGradient kCanarismoHeroGradient =
    _wineGradient(const Alignment(0.8, -1), 1.2, 0.8, 0.6);

/// Tarjeta para historias: `radial-gradient(120% 70% at 85% 0%, …55%…)`.
final RadialGradient kCanarismoCardGradient =
    _wineGradient(const Alignment(0.7, -1), 1.2, 0.7, 0.55);

/// Franja de mantel de cuadros (vichy rojo) a todo el ancho.
class CanarismoGinghamStrip extends StatelessWidget {
  final double height;
  final double cell;
  final Color base;

  const CanarismoGinghamStrip({
    super.key,
    required this.height,
    this.cell = 7,
    this.base = kCanarismoCardGinghamBase,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: GmGinghamPainter(
            cell: cell,
            base: base,
            stripe: kCanarismoGinghamStripe,
          ),
        ),
      );
}

/// Icono «Guardar» (bandeja con flecha hacia abajo), mismo trazo que
/// `GmIcons.share`. Candidato a `GmIcons.download`.
const String kCanarismoDownloadIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2.2" stroke-linecap="round" '
    'stroke-linejoin="round"><path d="M12 4v11M7.5 10.5L12 15l4.5-4.5"/>'
    '<path d="M5 13v5.5A1.5 1.5 0 006.5 20h11a1.5 1.5 0 001.5-1.5V13"/></svg>';

/// Resultado de [fitCanarismoWord]: estilo final (tamaño y espaciado ya
/// ajustados) y líneas que ocupa.
class CanarismoWordFit {
  final TextStyle style;
  final int lines;
  const CanarismoWordFit(this.style, this.lines);

  double get fontSize => style.fontSize!;

  /// Alto de la palabra (líneas × interlineado, sin escalado de texto).
  double get height => lines * fontSize * (style.height ?? 1);
}

/// Busca el mayor tamaño (≤ [maxSize], ≥ [minSize]) al que [text] cabe en
/// [maxWidth] sin partir ninguna palabra y en ≤ [maxLines] líneas. [style]
/// debe llevar ya la familia/peso finales y su `fontSize` de diseño (se mide
/// con él; el `letterSpacing` se escala en proporción). Si ni al mínimo cabe,
/// devuelve el mínimo (el `Text` corta con elipsis).
CanarismoWordFit fitCanarismoWord(
  String text,
  TextStyle style,
  double maxWidth, {
  required double maxSize,
  required double minSize,
  int maxLines = 3,
  double step = 2,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  CanarismoWordFit? last;
  for (var size = maxSize; size >= minSize - 0.01; size -= step) {
    final ls = style.letterSpacing;
    final s = style.copyWith(
      fontSize: size,
      letterSpacing: ls == null || style.fontSize == null
          ? ls
          : ls * size / style.fontSize!,
    );
    final fitsWords = words.every((w) {
      final p = TextPainter(
        text: TextSpan(text: w, style: s),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final ok = p.width <= maxWidth;
      p.dispose();
      return ok;
    });
    final p = TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final lines = p.computeLineMetrics().length.clamp(1, maxLines);
    final fits = fitsWords && !p.didExceedMaxLines;
    p.dispose();
    last = CanarismoWordFit(s, lines);
    if (fits) return last;
  }
  return last ?? CanarismoWordFit(style.copyWith(fontSize: minSize), maxLines);
}
