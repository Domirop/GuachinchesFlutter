import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart' show GmGinghamPainter;

/// Cómo se pinta una chincheta.
enum MapPinVariant {
  /// Abierto o sin horario confirmado.
  normal,

  /// Cerrado ahora (al 50 %).
  dimmed,

  /// Elegido: disco grande de 52 con pie (el ancla es la punta del pie).
  selected,
}

/// Bitmap ya pintado con su ancla.
class MapPinBitmap {
  final BitmapDescriptor icon;
  final Offset anchor;
  const MapPinBitmap(this.icon, this.anchor);
}

/// Pinta y guarda en caché las chinchetas del mapa (tablero TabMapa):
/// disco `card` con el aro y el glifo de la tinta del tipo (`list_theme`),
/// neutra y pequeña sin tipo, atenuada si está cerrada, grande con pie si
/// está elegida, y burbujas numeradas para los grupos. Como en
/// `list_map_view.dart`, pero con un tema por sitio y día/noche.
///
/// [pin] y [cluster] devuelven `null` mientras el bitmap se pinta; al
/// terminar se llama a [onReady] para que el mapa repinte sus marcadores.
class MapPinFactory {
  final VoidCallback onReady;
  MapPinFactory({required this.onReady});

  final Map<String, MapPinBitmap> _cache = {};
  final Set<String> _pending = {};
  bool _disposed = false;

  void dispose() => _disposed = true;

  static double get _dpr =>
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  MapPinBitmap? pin(
    ListThemeKind? kind,
    MapPinVariant variant, {
    required bool dark,
    double size = 34,
    String? label,
  }) {
    final key = 'p|${kind?.name}|${variant.name}|$dark|$size|${label ?? ''}';
    return _get(
        key,
        () => _renderPin(kind, variant,
            dark: dark, size: size, label: label, dpr: _dpr));
  }

  MapPinBitmap? cluster(int n, {required bool dark, double size = 36}) {
    final key = 'c|$n|$dark|$size';
    return _get(
        key, () => _renderCluster(n, dark: dark, size: size, dpr: _dpr));
  }

  MapPinBitmap? _get(String key, Future<MapPinBitmap> Function() render) {
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_pending.add(key)) {
      render().then((b) {
        _pending.remove(key);
        if (_disposed) return;
        _cache[key] = b;
        onReady();
      }).catchError((Object e) {
        _pending.remove(key);
        AppLogger.warn('mapa', 'no se pudo pintar la chincheta $key: $e');
      });
    }
    return null;
  }

  // ── Pintado ──────────────────────────────────────────────────────────────

  static Color _card(bool dark) =>
      dark ? GmColors.night.card : GmColors.day.card;

  /// Aro de la burbuja: day rgba(31,26,20,.38) · night rgba(243,238,228,.42).
  static Color clusterRing(bool dark) =>
      dark ? const Color(0x6BF3EEE4) : const Color(0x611F1A14);

  /// Tinta de los trazos oscuros fijos de los glifos (#2A0E14) en noche.
  static const _gInkNight = '#F3EEE4';

  static Color ringFor(ListThemeKind? kind, bool dark) {
    if (kind == null) return dark ? GmColors.night.label2 : GmColors.day.label2;
    return kListThemes[kind]!.ink(dark);
  }

  static Future<MapPinBitmap> _renderPin(
    ListThemeKind? kind,
    MapPinVariant variant, {
    required bool dark,
    required double size,
    required double dpr,
    String? label,
  }) async {
    final selected = variant == MapPinVariant.selected;
    // Sin tipo: chincheta neutra y más pequeña.
    final disc = selected ? 52.0 : (kind == null ? size * 0.78 : size);
    const pad = 8.0;
    const stem = 8.0;
    final ring = ringFor(kind, dark);

    TextPainter? lp;
    if (selected && label != null && label.isNotEmpty) {
      lp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: dark ? GmColors.night.glassInk : GmColors.day.glassInk,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 200);
    }
    final labelW = lp == null ? 0.0 : lp.width + 18;
    final contentW = math.max(disc, labelW);
    final w = contentW + pad * 2;
    final h =
        pad + disc + (selected ? stem : 0) + (lp == null ? 0 : 6 + 24) + pad;

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(dpr, dpr);
    if (variant == MapPinVariant.dimmed) {
      c.saveLayer(
          Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0x80000000));
    }
    final center = Offset(w / 2, pad + disc / 2);
    final r = disc / 2;
    // Sombra: 0 4px 10px rgba(0,0,0,.2) (elegida: 0 8px 18px .25).
    c.drawCircle(
        center + Offset(0, selected ? 4 : 2),
        r,
        Paint()
          ..color = Color(selected ? 0x40000000 : 0x33000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, selected ? 6 : 3.5));
    if (selected) {
      c.drawRect(Rect.fromLTWH(center.dx - 1.5, center.dy + r, 3, stem),
          Paint()..color = ring);
    }
    c.drawCircle(center, r, Paint()..color = _card(dark));
    final ringW = (selected || disc >= 44) ? 3.0 : 2.0;
    c.drawCircle(
        center,
        r - ringW / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringW
          ..color = ring);

    final g = kind == null ? disc * 0.56 : disc * 0.64;
    await _paintGlyph(c, kind, center, g, ring, dark);

    if (lp != null) {
      final top = pad + disc + stem + 6;
      final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(w / 2, top + 12), width: labelW, height: 24),
          const Radius.circular(12));
      c.drawRRect(
          rect.shift(const Offset(0, 1)),
          Paint()
            ..color = const Color(0x26000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      c.drawRRect(
          rect,
          Paint()
            ..color = dark ? const Color(0xF216222C) : const Color(0xF2FFFFFF));
      c.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = dark ? const Color(0x1FFFFFFF) : const Color(0x1A5A4018));
      lp.paint(c, Offset(w / 2 - lp.width / 2, top + 12 - lp.height / 2));
    }

    if (variant == MapPinVariant.dimmed) c.restore();
    final img =
        await rec.endRecording().toImage((w * dpr).ceil(), (h * dpr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final anchor = selected
        ? Offset(0.5, (pad + disc + stem) / h)
        : Offset(0.5, center.dy / h);
    return MapPinBitmap(
      BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr),
      anchor,
    );
  }

  /// Glifo del tipo (o los cubiertos en gris si no tiene tipo).
  static Future<void> _paintGlyph(Canvas c, ListThemeKind? kind, Offset center,
      double size, Color ink, bool dark) async {
    final glyph =
        kind == null ? ListGlyph.restaurante : kListThemes[kind]!.glyph;
    if (glyph == ListGlyph.moderno) {
      // Mantel de cuadros (losa de vichy, como `ListThemeGlyph`).
      final s = size * 0.72;
      final rect = Rect.fromCenter(center: center, width: s, height: s);
      final clip = Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)));
      GmGinghamPainter.paintCells(c, rect,
          cell: s / 6, phase: rect.topLeft + Offset(0, s / 6), clip: clip);
      return;
    }
    var svg = ListThemeGlyph.svgFor(glyph, ink);
    if (svg.isEmpty) return;
    if (dark) svg = svg.replaceAll('#2A0E14', _gInkNight);
    final info = await vg.loadPicture(SvgStringLoader(svg), null);
    c.save();
    c.translate(center.dx - size / 2, center.dy - size / 2);
    c.scale(size / info.size.width, size / info.size.height);
    c.drawPicture(info.picture);
    c.restore();
    info.picture.dispose();
  }

  static Future<MapPinBitmap> _renderCluster(int n,
      {required bool dark, required double size, required double dpr}) async {
    final d = n >= 10 ? size + 6 : size;
    const pad = 9.0;
    final w = d + pad * 2;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(dpr, dpr);
    final center = Offset(w / 2, w / 2);
    final r = d / 2;
    c.drawCircle(
        center + const Offset(0, 2),
        r + 4.5,
        Paint()
          ..color = const Color(0x38000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // 0 0 0 2px card, 0 0 0 4.5px cluRing.
    c.drawCircle(center, r + 4.5, Paint()..color = clusterRing(dark));
    // El aro translúcido no debe dejar ver la sombra: disco de tarjeta.
    c.drawCircle(center, r + 2, Paint()..color = _card(dark));
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(
          fontSize: d > 40 ? 15 : 14,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: dark ? GmColors.night.label : GmColors.day.label,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
    final img =
        await rec.endRecording().toImage((w * dpr).ceil(), (w * dpr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return MapPinBitmap(
      BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr),
      const Offset(0.5, 0.5),
    );
  }
}
