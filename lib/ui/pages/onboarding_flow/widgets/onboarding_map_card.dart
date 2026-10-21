import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Mapa claro estilizado del tablero (`map_card` en `gen_arranque.py`):
/// tierra, mar, parque, carretera principal y calles con los tokens `map*`
/// de día y de noche. Lienzo de referencia 370 × [refHeight]; se escala al
/// ancho disponible.
///
/// - [off]: en el centro, círculo con la flecha tachada (sin ubicación).
/// - [pins]: cuatro chinchetas con glifo de tema que **caen una vez**
///   (fotogramas `pin` del Sistema, 1,2 s, escalonadas) — sustituye al pulso
///   infinito del onboarding viejo.
///
/// Decorativo: fuera del árbol de accesibilidad.
class OnbMapCard extends StatelessWidget {
  final double refHeight;
  final bool off;
  final bool pins;
  final bool user;

  /// Centro del círculo «sin ubicación» (en el lienzo de referencia).
  final Offset offCenter;
  final double radius;

  const OnbMapCard({
    super.key,
    this.refHeight = 300,
    this.off = false,
    this.pins = true,
    this.user = true,
    this.offCenter = const Offset(184, 124),
    this.radius = 28,
  });

  static const double refWidth = 370;

  static const _pins = <(double, double, GmGlyphKind, int)>[
    (96, 92, GmGlyphKind.copa, 500),
    (282, 78, GmGlyphKind.barraquito, 700),
    (258, 196, GmGlyphKind.vieja, 900),
    (78, 208, GmGlyphKind.cabra, 1100),
  ];

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ExcludeSemantics(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : refWidth;
        final s = w / refWidth;
        final h = refHeight * s;
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: gm.shadow1,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SvgPicture.string(
                    onbMapSvg(gm,
                        height: refHeight,
                        off: off,
                        user: user,
                        offCenter: offCenter),
                    fit: BoxFit.fill,
                  ),
                ),
                if (pins)
                  for (final (x, y, glyph, delay) in _pins)
                    Positioned(
                      left: (x - 14) * s,
                      top: (y - 36) * s,
                      width: 28 * s,
                      height: 40 * s,
                      child: _DropPin(
                        glyph: glyph,
                        delay: Duration(milliseconds: delay),
                      ),
                    ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
String _op(Color c) => c.a.toStringAsFixed(3);
String _fill(Color c) => 'fill="${_hex(c)}" fill-opacity="${_op(c)}"';
String _stroke(Color c, double w) =>
    'fill="none" stroke="${_hex(c)}" stroke-opacity="${_op(c)}" stroke-width="$w"';

/// SVG del mapa (sin chinchetas) con los colores del tema. Público para
/// poder probar que no lleva colores claros fijos de noche.
String onbMapSvg(GmColors gm,
    {double height = 300,
    bool off = false,
    bool user = true,
    Offset offCenter = const Offset(184, 124)}) {
  final h = height;
  final b = StringBuffer()
    ..write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 370 $h" '
        'width="370" height="$h">')
    ..write('<rect width="370" height="$h" ${_fill(gm.mapLand)}/>')
    ..write('<path d="M0 ${h - 70}c60 10 90-20 150-6s110 30 220 0V${h}H0z" '
        '${_fill(gm.mapSea)}/>')
    ..write(
        '<path d="M240 20c30-6 70 6 90 30s0 50-30 46-70-10-70-40 0-30 10-36z" '
        '${_fill(gm.mapPark)}/>')
    ..write('<path d="M-10 150C80 130 120 170 200 140S320 90 380 110" '
        '${_stroke(gm.mapCasing, 12)}/>')
    ..write('<path d="M-10 150C80 130 120 170 200 140S320 90 380 110" '
        '${_stroke(gm.mapMajor, 9)}/>')
    ..write('<path d="M140 -10C150 60 170 120 160 ${h + 10}" '
        '${_stroke(gm.mapCasing, 8)}/>')
    ..write('<path d="M140 -10C150 60 170 120 160 ${h + 10}" '
        '${_stroke(gm.mapRoad, 6)}/>')
    ..write('<path d="M20 60C90 80 220 40 380 64" ${_stroke(gm.mapRoad, 5)}/>');
  if (off) {
    final ink = gm.label2;
    b
      ..write('<g transform="translate(${offCenter.dx} ${offCenter.dy})">')
      ..write('<circle r="30" ${_fill(gm.card)} stroke="${_hex(gm.mapCasing)}" '
          'stroke-opacity="${_op(gm.mapCasing)}"/>')
      ..write('<g transform="translate(-13 -14) scale(1.1)" fill="none" '
          'stroke="${_hex(ink)}" stroke-opacity="${_op(ink)}" stroke-width="2.2" '
          'stroke-linecap="round" stroke-linejoin="round">'
          '<path d="M20.5 3.5L3.5 10.6l7 2.4 2.4 7z"/><path d="M2.5 2.5l19 19"/></g>')
      ..write('</g>');
  } else if (user) {
    b.write('<g transform="translate(184 128)">'
        '<circle r="26" fill="#0085C4" fill-opacity="0.14"/>'
        '<circle r="9" fill="#FFFFFF"/><circle r="6.5" fill="#0085C4"/></g>');
  }
  b.write('</svg>');
  return b.toString();
}

/// Chincheta con glifo que cae una vez (fotogramas `pin`: −8 px y estirada
/// → aplasta al tocar suelo → rebote → quieta). Con reducir movimiento,
/// quieta desde el principio.
class _DropPin extends StatelessWidget {
  final GmGlyphKind glyph;
  final Duration delay;

  const _DropPin({required this.glyph, required this.delay});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    // Relleno de la chincheta: blanco de día, oro suave de noche (tablero).
    final pinFill = gm.isDark ? const Color(0xFFE2C48A) : Colors.white;
    return LayoutBuilder(builder: (context, c) {
      final s = c.maxWidth / 28;
      final pin = Stack(
        clipBehavior: Clip.none,
        children: [
          // Sombra de contacto (no cae: se queda en el suelo).
          Positioned(
            left: 7 * s,
            top: 35.6 * s,
            width: 14 * s,
            height: 4.8 * s,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x2E000000),
                borderRadius: BorderRadius.all(Radius.elliptical(7, 2.4)),
              ),
            ),
          ),
          Positioned.fill(
            child: GmOnce(
              duration: const Duration(milliseconds: 1200),
              delay: delay,
              trigger: GmTrigger.mount,
              builder: (_, t, child) {
                final dy = gmKeyframes(
                    t, const [(0, -8), (0.4, 0), (0.62, -2), (0.8, 0)],
                    curve: GmMotion.ease);
                final sx = gmKeyframes(
                    t, const [(0, 0.94), (0.4, 1.14), (0.62, 0.97), (0.8, 1)],
                    curve: GmMotion.ease);
                final sy = gmKeyframes(
                    t, const [(0, 1.08), (0.4, 0.84), (0.62, 1.04), (0.8, 1)],
                    curve: GmMotion.ease);
                return Transform.translate(
                  offset: Offset(0, dy * s),
                  child: Transform(
                    alignment: const Alignment(0, 0.8),
                    transform: Matrix4.diagonal3Values(sx, sy, 1),
                    child: child,
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 1 * s,
                    width: 28 * s,
                    height: 35 * s,
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-14.5 -35.5 29 36">'
                      '<path d="M0 0c-8-9-14-14-14-21a14 14 0 0128 0c0 7-6 12-14 21z" '
                      '${_fill(pinFill)} stroke="${_hex(gm.mapCasing)}" '
                      'stroke-opacity="${_op(gm.mapCasing)}" stroke-width="1"/></svg>',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 4 * s,
                    top: 5 * s,
                    width: 20 * s,
                    height: 20 * s,
                    child: GmGlyph(glyph, size: 20 * s),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      return pin;
    });
  }
}
