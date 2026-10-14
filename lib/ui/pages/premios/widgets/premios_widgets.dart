import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Piezas de la encuesta (tableros Encuesta*) sobre la capa Gm.

// ── Colores propios de la encuesta (common.py) ────────────────────────────

class PremiosColors {
  PremiosColors._();

  /// Texto oro sobre vino.
  static const goldText = Color(0xFFE8CF9A);

  /// Crema secundaria sobre vino (0,80).
  static const cream2 = Color(0xCCF2E8D5);

  /// Banda vino de las papeletas, el podio y la cuenta atrás.
  static Color band(GmColors gm) =>
      gm.isDark ? const Color(0xFF1E0A0F) : GmColors.wine;

  /// Banda y tinta de cada categoría (tradicional = vino y mantel rojo;
  /// moderno = «Guachinches modernos», oro viejo).
  static Color catBand(PremiosCategory c, GmColors gm) =>
      c == PremiosCategory.tradicional
          ? (gm.isDark ? const Color(0xFF25141A) : const Color(0xFFF3DCDF))
          : (gm.isDark ? const Color(0xFF241D12) : const Color(0xFFF1E7D2));

  static Color catInk(PremiosCategory c, GmColors gm) =>
      c == PremiosCategory.tradicional
          ? (gm.isDark ? const Color(0xFFE6A3AE) : const Color(0xFF7A1E2C))
          : (gm.isDark ? const Color(0xFFE2C48A) : const Color(0xFF7A5A20));

  static Color catTint(PremiosCategory c, GmColors gm) =>
      c == PremiosCategory.tradicional
          ? (gm.isDark ? const Color(0x33E6A3AE) : const Color(0xFFF3DCDF))
          : (gm.isDark ? const Color(0x33E2C48A) : const Color(0xFFF1E7D2));

  static Color sepStrong(GmColors gm) =>
      gm.isDark ? const Color(0x38C8E1F5) : const Color(0x385A4018);

  static Color selBg(GmColors gm) =>
      gm.isDark ? const Color(0x1F4DAEDB) : const Color(0x140085C4);

  static Color glassInk2(GmColors gm) =>
      gm.isDark ? const Color(0xA3F3EEE4) : const Color(0xFF6E6253);

  /// Azul del progreso y del check (#0085C4).
  static const progress = Color(0xFF0085C4);

  /// Sombra del check elegido.
  static const progressShadow = Color(0x80005A8C);

  // Crema sobre vino (tarjeta del Inicio, cuenta atrás).
  static const creamInk = Color(0xFFF2E8D5);
  static const cream82 = Color(0xD1F2E8D5);
  static const creamDim = Color(0x80F2E8D5);
  static const creamLine = Color(0x24F2E8D5);
  static const creamFill = Color(0x1FF2E8D5);
  static const creamEdge = Color(0x38F2E8D5);

  /// Cristal crema sobre la banda vino (X, «Ranking»).
  static const wineGlass = Color(0x24FFF6E6);
  static const wineGlassEdge = Color(0x38FFF6E6);

  /// Casilla de la cuenta atrás.
  static const digitFill = Color(0x1AFFF6E6);
  static const digitEdge = Color(0x4DC9A96B);

  // Card vino del Inicio (tablero EncuestaInicioCard).
  /// Segmentado sobre vino: relleno, filo y pestaña activa.
  static const wineSegFill = Color(0x14FFF6E6); // .08
  static const wineSegEdge = Color(0x29F2E8D5); // .16
  static const wineSegOn = Color(0x29FFF6E6); // .16
  static const wineSegOnEdge = Color(0x73C9A96B); // .45

  /// Bloques del podio sobre vino (#4A1B27 → #3A1520) y su filo oro .30.
  static const podiumWineTop = Color(0xFF4A1B27);
  static const podiumWineEdge = Color(0x4DC9A96B);

  /// Crema al 72 % (paréntesis y municipio sobre vino).
  static const cream72 = Color(0xB8F2E8D5);

  /// Fila «Tu voto» sobre vino.
  static const wineRowFill = Color(0x14FFF6E6);
  static const wineRowEdge = Color(0x24F2E8D5);

  /// Metal del filo de la card (135°: #F3DFA8 → #D6B675 48 % → #B08A48).
  static const metal = [
    Color(0xFFF3DFA8),
    Color(0xFFD6B675),
    Color(0xFFB08A48)
  ];

  /// Arriba del degradado de los bloques del podio (#3A1520 → vino).
  static const podiumTop = Color(0xFF3A1520);

  /// Sombras vino (tarjetas y bloques del podio).
  static const wineShadow = Color(0xB32A0E14);
  static const wineShadowSoft = Color(0x732A0E14);

  /// Brillos de la tarjeta del Inicio.
  static const goldGlow = Color(0x38C9A96B);
  static const wineGlow = Color(0x8C781E2D);

  /// Velo de la hoja y su sombra.
  static const sheetBarrier = Color(0x6B0A0604);
  static const sheetShadow = Color(0x2E000000);

  // Manteles: rojo y oro de las franjas, filo del glifo moderno.
  static const stripRed = Color(0x80C8202C);
  static const stripGold = Color(0x9EC9A96B);
  static const mantelEdge = Color(0x667A5A20);
  static const stripShade = Color(0x1F280A0E);

  // Avisos de Revisar: filos ámbar y rojo, relleno rojo suave.
  static const warnEdge = Color(0x47D69614);
  static const closedEdge = Color(0x38C0352B);
  static Color closedSoft(GmColors gm) =>
      gm.isDark ? const Color(0x24FF6B5E) : const Color(0x1AC0352B);
}

// ── Glifos ─────────────────────────────────────────────────────────────────

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Copa de vino de la categoría tradicional (trazo [ink], vino #B23A4C).
class PremiosCopa extends StatelessWidget {
  final double size;
  final Color ink;
  const PremiosCopa({super.key, this.size = 24, required this.ink});

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="${_hex(ink)}" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">'
        '<path d="M7.3 7.5h9.4l-.1.8a4.6 4.6 0 01-9.2 0z" fill="#B23A4C" stroke="none"/>'
        '<path d="M7 3h10l-.4 5.2a4.6 4.6 0 01-9.2 0z"/><path d="M12 13v7M8.5 21h7"/></svg>',
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
}

/// Mantel de «Guachinches modernos»: cuadros oro sobre crema.
class PremiosMantel extends StatelessWidget {
  final double size;
  const PremiosMantel({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final r = math.max(4.0, size / 4).floorToDouble();
    final cell = math.max(6.0, size / 3).floorToDouble() / 2;
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: PremiosColors.mantelEdge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: CustomPaint(
          painter: GmGinghamPainter(
            cell: cell,
            base: GmGinghamPainter.goldBase,
            stripe: GmGinghamPainter.goldStripe,
          ),
        ),
      ),
    );
  }
}

/// Glifo de cada categoría (copa / mantel).
class PremiosCategoryGlyph extends StatelessWidget {
  final PremiosCategory category;
  final double size;
  final Color ink;
  const PremiosCategoryGlyph(this.category,
      {super.key, required this.size, required this.ink});

  @override
  Widget build(BuildContext context) => category == PremiosCategory.tradicional
      ? PremiosCopa(size: size, ink: ink)
      : PremiosMantel(size: size * 0.86);
}

/// Podio (icono de «Ver el ranking»).
class PremiosPodiumIcon extends StatelessWidget {
  final double size;
  final Color color;
  const PremiosPodiumIcon({super.key, this.size = 18, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = _hex(color);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$c" '
      'stroke-width="2" stroke-linejoin="round" stroke-linecap="round">'
      '<path d="M9 9.5h6V21H9zM3 13.5h6V21H3zM15 15.5h6V21h-6z"/>'
      '<path d="M12 2.8l.9 1.8 2 .3-1.5 1.4.4 2-1.8-1-1.8 1 .4-2-1.5-1.4 2-.3z" fill="$c" stroke="none"/></svg>',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}

/// Antetítulo con la medalla: «Premios Donde Comer Canarias 2026».
class PremiosEyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  final Widget? leading;
  const PremiosEyebrow(
      {super.key,
      this.text = 'Premios Donde Comer Canarias 2026',
      this.color,
      this.leading});

  @override
  Widget build(BuildContext context) => GmEyebrow(
        leading: leading ?? const GmGlyph(GmGlyphKind.medalla, size: 14),
        text: text,
        color: color,
      );
}

// ── Escarapelas ────────────────────────────────────────────────────────────

/// Escarapela de premio de la cabecera de Votar (64 × 82): disco de oro,
/// cintas del color de la categoría y su glifo.
class PremioRosette extends StatelessWidget {
  final PremiosCategory category;
  final double width;
  const PremioRosette(this.category, {super.key, this.width = 64});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, width * 92 / 72),
        painter: _RosettePainter(category),
      );
}

class _RosettePainter extends CustomPainter {
  final PremiosCategory category;
  const _RosettePainter(this.category);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 72);
    final trad = category == PremiosCategory.tradicional;
    final ribA = trad ? const Color(0xFF7A1E2C) : const Color(0xFF7A5A20);
    final ribB = trad ? const Color(0xFFA02A3C) : const Color(0xFF9A7330);
    canvas.drawPath(
        Path()
          ..moveTo(24, 52)
          ..lineTo(14, 88)
          ..lineTo(24, 81)
          ..lineTo(31, 90)
          ..lineTo(36, 56)
          ..close(),
        Paint()..color = ribA);
    canvas.drawPath(
        Path()
          ..moveTo(48, 52)
          ..lineTo(58, 88)
          ..lineTo(48, 81)
          ..lineTo(41, 90)
          ..lineTo(36, 56)
          ..close(),
        Paint()..color = ribB);
    const c = Offset(36, 33);
    canvas.drawCircle(
        c,
        31,
        Paint()
          ..shader = premiosGoldShader(Rect.fromCircle(center: c, radius: 31)));
    canvas.drawCircle(
        c,
        31,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF8A6A2E));
    _dashedCircle(canvas, c, 25);
    if (trad) {
      canvas.translate(24, 21);
      _paintCopa(canvas);
    } else {
      canvas.translate(25, 22);
      _paintMantel(canvas, 22);
    }
    canvas.restore();
  }

  void _dashedCircle(Canvas canvas, Offset c, double r) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xB3FFF3D6);
    const dash = 2.6, gap = 3.0;
    final circ = 2 * math.pi * r;
    final n = (circ / (dash + gap)).floor();
    for (var i = 0; i < n; i++) {
      final a0 = i * (dash + gap) / r;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), a0, dash / r, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RosettePainter old) => old.category != category;
}

/// Copa en 24 × 24 (trazo vino oscuro sobre el oro).
void _paintCopa(Canvas canvas) {
  canvas.drawPath(
      Path()
        ..moveTo(7.3, 7.5)
        ..lineTo(16.7, 7.5)
        ..lineTo(16.6, 8.3)
        ..arcToPoint(const Offset(7.4, 8.3), radius: const Radius.circular(4.6))
        ..close(),
      Paint()..color = const Color(0xFFB23A4C));
  final s = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF5A1420);
  canvas.drawPath(
      Path()
        ..moveTo(7, 3)
        ..lineTo(17, 3)
        ..lineTo(16.6, 8.2)
        ..arcToPoint(const Offset(7.4, 8.2), radius: const Radius.circular(4.6))
        ..close(),
      s);
  canvas.drawLine(const Offset(12, 13), const Offset(12, 20), s);
  canvas.drawLine(const Offset(8.5, 21), const Offset(15.5, 21), s);
}

/// Mantel de cuadros oro en [s] × [s] (glifo de «Guachinches modernos»).
void _paintMantel(Canvas canvas, double s) {
  final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s), Radius.circular(s / 4.4));
  GmGinghamPainter.paintCells(canvas, Offset.zero & Size(s, s),
      cell: s / 4,
      base: GmGinghamPainter.goldBase,
      stripe: PremiosColors.stripGold,
      clip: Path()..addRRect(r));
  canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = PremiosColors.mantelEdge);
}

/// Medalla de 44 de cada fila de la papeleta (disco de oro con el glifo).
class PremiosMiniMedal extends StatelessWidget {
  final PremiosCategory category;
  final double size;
  const PremiosMiniMedal(this.category, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _MiniMedalPainter(category, GmColors.of(context).isDark),
      );
}

class _MiniMedalPainter extends CustomPainter {
  final PremiosCategory category;
  final bool dark;
  const _MiniMedalPainter(this.category, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 44);
    if (dark) {
      // brightness(.84) de noche.
      canvas.saveLayer(
          null,
          Paint()
            ..colorFilter = const ColorFilter.matrix(<double>[
              0.84, 0, 0, 0, 0, //
              0, 0.84, 0, 0, 0, //
              0, 0, 0.84, 0, 0, //
              0, 0, 0, 1, 0,
            ]));
    }
    const c = Offset(22, 22);
    canvas.drawCircle(
        c,
        21,
        Paint()
          ..shader = premiosGoldShader(Rect.fromCircle(center: c, radius: 21)));
    canvas.drawCircle(
        c,
        21,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF8A6A2E));
    if (category == PremiosCategory.tradicional) {
      canvas.translate(10, 9);
      _paintCopa(canvas);
    } else {
      canvas.translate(12, 12);
      _paintMantel(canvas, 20);
    }
    if (dark) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniMedalPainter old) =>
      old.category != category || old.dark != dark;
}

// ── Botones sobre vino ─────────────────────────────────────────────────────

/// Botón de cristal crema sobre la banda vino (X 44 o cápsula «Ranking»).
class PremiosWineGlassButton extends StatelessWidget {
  final String? icon;
  final Widget? leading;
  final String? label;
  final String semanticLabel;
  final String identifier;
  final VoidCallback onTap;

  const PremiosWineGlassButton({
    super.key,
    this.icon,
    this.leading,
    this.label,
    required this.semanticLabel,
    required this.identifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final round = label == null;
    return Semantics(
      identifier: identifier,
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.92,
        child: SizedBox(
          height: 44,
          width: round ? 44 : null,
          child: GmGlass(
            borderRadius: BorderRadius.circular(22),
            tint: PremiosColors.wineGlass,
            edge: PremiosColors.wineGlassEdge,
            blur: 24,
            child: round
                ? Center(
                    child: GmIcon(icon ?? GmIcons.close,
                        size: 18, color: GmColors.creamHi))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 7)
                        ],
                        Text(label!,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: GmColors.creamHi)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Barra inferior de cristal ──────────────────────────────────────────────

/// Fundido inferior de 140 + barra de cristal (márgenes 16, a 28 del borde,
/// alto 64: padding 6 + cápsula 52). Va en un `Stack` a pantalla completa.
class PremiosBottomBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PremiosBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 6, 6, 6),
  });

  /// Distancia de la barra al borde inferior.
  static double bottomOf(BuildContext context) =>
      math.max(16, MediaQuery.paddingOf(context).bottom - 6);

  /// Padding inferior que necesita el scroll (28 + 64 + 24).
  static double scrollPadding(BuildContext context) =>
      bottomOf(context) + 64 + 24;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 140,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gm.edgeFade0, gm.edgeFade1, gm.canvas],
                  stops: const [0, 0.4, 0.62],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomOf(context),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: GmGlass(
              borderRadius: BorderRadius.circular(32),
              tint: gm.glass,
              edge: gm.glassEdge,
              blur: 30,
              shadow: gm.shadow2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dos líneas de la barra: título y subtítulo.
class PremiosBarText extends StatelessWidget {
  final String label;
  final String value;
  final bool labelFirst;
  final Color? valueColor;
  const PremiosBarText({
    super.key,
    required this.label,
    required this.value,
    this.labelFirst = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: labelFirst
          ? [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.chip(color: PremiosColors.glassInk2(gm))),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.cardTitle(color: valueColor ?? gm.glassInk)),
            ]
          : [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.cardTitle(color: gm.glassInk)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.meta(color: PremiosColors.glassInk2(gm))),
            ],
    );
  }
}

/// Indicador de «Enviando…».
class PremiosSpinner extends StatelessWidget {
  final Color color;
  const PremiosSpinner({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: color,
          value: GmMotion.reduced(context) ? 0.75 : null,
        ),
      );
}

// ── Barra de progreso de Votar/Revisar ─────────────────────────────────────

class PremiosProgress extends StatelessWidget {
  final int filled;
  const PremiosProgress({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget bar(bool on) => Expanded(
          child: AnimatedContainer(
            duration:
                Duration(milliseconds: GmMotion.reduced(context) ? 0 : 320),
            curve: GmMotion.settle,
            height: 6,
            decoration: BoxDecoration(
              color: on ? PremiosColors.progress : PremiosColors.sepStrong(gm),
              borderRadius: BorderRadius.circular(GmRadius.pill),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(children: [
        bar(filled >= 1),
        const SizedBox(width: 6),
        bar(filled >= 2),
      ]),
    );
  }
}

// ── Aviso de Revisar ───────────────────────────────────────────────────────

/// Tarjeta de aviso: blanca e1 r20 con filo ámbar o rojo, icono de 30 en
/// círculo, título 16/21 · 600 y mensaje en label2. Tiembla una vez.
class PremiosAlertCard extends StatelessWidget {
  final PremiosErrorCopy copy;
  final VoidCallback? onAction;
  final String identifier;
  const PremiosAlertCard({
    super.key,
    required this.copy,
    this.onAction,
    this.identifier = 'premios-review-alert',
  });

  static String _icon(PremiosAlertIcon i) => switch (i) {
        PremiosAlertIcon.warn =>
          '<path d="M12 3.5l9.5 16.5h-19z"/><path d="M12 10v4.5"/><circle cx="12" cy="17.2" r="0.6" fill="currentColor"/>',
        PremiosAlertIcon.clock =>
          '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
        PremiosAlertIcon.network =>
          '<path d="M2.5 9a14 14 0 0119 0M5.5 12.5a9.5 9.5 0 0113 0M8.6 16a5 5 0 016.8 0"/><circle cx="12" cy="19.2" r="0.9" fill="currentColor"/><path d="M3.5 3.5l17 17"/>',
        PremiosAlertIcon.error =>
          '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v5.5"/><circle cx="12" cy="16.4" r="0.6" fill="currentColor"/>',
      };

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final warn = copy.tone == PremiosTone.warn;
    final soft = warn ? gm.warnSoft : PremiosColors.closedSoft(gm);
    final ink = warn ? gm.warnText : gm.closedText;
    final edge = warn ? PremiosColors.warnEdge : PremiosColors.closedEdge;
    final card = Container(
      decoration: BoxDecoration(
        color: gm.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: gm.shadow1,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: edge),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
              'stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">${_icon(copy.icon)}</svg>',
              width: 18,
              height: 18,
              theme: SvgTheme(currentColor: ink),
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.title, style: GmText.cardTitle(color: gm.label)),
                  const SizedBox(height: 2),
                  Text(
                      [copy.message, copy.help]
                          .where((t) => t.isNotEmpty)
                          .join(' '),
                      style: GmText.body(color: gm.label2)),
                  if (copy.action != null && onAction != null) ...[
                    const SizedBox(height: 10),
                    GmSoftCapsuleButton(
                      label: copy.action!,
                      identifier: '$identifier-action',
                      onTap: onAction,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      identifier: identifier,
      liveRegion: true,
      container: true,
      child: GmOnce(
        key: ValueKey(copy.title),
        duration: const Duration(milliseconds: 520),
        delay: const Duration(milliseconds: 250),
        trigger: GmTrigger.mount,
        child: card,
        builder: (_, t, c) {
          final dx = gmKeyframes(
              t,
              const [
                (0, 0),
                (0.2, -6),
                (0.4, 5),
                (0.6, -3),
                (0.8, 2),
                (1, 0),
              ],
              curve: const Cubic(0.36, 0.07, 0.19, 0.97));
          return Transform.translate(offset: Offset(dx, 0), child: c);
        },
      ),
    );
  }
}

// ── Papeleta ───────────────────────────────────────────────────────────────

/// Recorte de la papeleta: radio 24 arriba y festón abajo (semicírculos de
/// 7 cada 18, como la máscara `radial-gradient` del tablero).
class PapeletaClipper extends CustomClipper<Path> {
  const PapeletaClipper();

  static Path pathFor(Size size) {
    const r = 24.0, bite = 7.0, step = 18.0;
    final w = size.width, h = size.height;
    final p = Path()
      ..moveTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, h);
    // Festón de derecha a izquierda.
    final n = (w / step).ceil();
    for (var i = n - 1; i >= 0; i--) {
      final cx = i * step + step / 2;
      final right = math.min(w, cx + bite);
      final left = math.max(0.0, cx - bite);
      p.lineTo(right, h);
      p.arcToPoint(Offset(left, h),
          radius: const Radius.circular(bite), clockwise: false);
    }
    p.lineTo(0, h);
    return p..close();
  }

  @override
  Path getClip(Size size) => pathFor(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// La papeleta: cabecera vino «Papeleta · Premios 2026», línea perforada,
/// filas y festón. La sombra sigue el festón (un BoxShadow no lo haría).
class PapeletaCard extends StatelessWidget {
  final String? trailing;
  final List<Widget> rows;
  final Widget? overlay;
  const PapeletaCard(
      {super.key, this.trailing, required this.rows, this.overlay});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 46,
          color: PremiosColors.band(gm),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const GmGlyph(GmGlyphKind.medalla, size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text('Papeleta · Premios 2026',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.eyebrow(
                        color: PremiosColors.goldText, w: FontWeight.w700)),
              ),
              if (trailing != null)
                Text(trailing!,
                    style: GmText.eyebrow(color: PremiosColors.cream2)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: CustomPaint(
            size: const Size(double.infinity, 2),
            painter: _DashPainter(PremiosColors.sepStrong(gm)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 14),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 70),
                        color: gm.sep,
                      ),
                    rows[i],
                  ],
                ],
              ),
              if (overlay != null) Positioned.fill(child: overlay!),
            ],
          ),
        ),
      ],
    );
    return CustomPaint(
      painter: _PapeletaShadowPainter(gm.isDark),
      child: ClipPath(
        clipper: const PapeletaClipper(),
        child: DecoratedBox(
          decoration: BoxDecoration(color: gm.card),
          position: DecorationPosition.background,
          child: CustomPaint(
            foregroundPainter: gm.isDark ? _EdgePainter(gm.wineEdge) : null,
            child: body,
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 1), Offset(math.min(x + 5, size.width), 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

class _EdgePainter extends CustomPainter {
  final Color color;
  const _EdgePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Solo el cuerpo: la cabecera vino no lleva filo.
    canvas.clipRect(Rect.fromLTRB(0, 46, size.width, size.height));
    canvas.drawPath(
        PapeletaClipper.pathFor(size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) => old.color != color;
}

class _PapeletaShadowPainter extends CustomPainter {
  final bool dark;
  const _PapeletaShadowPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final path = PapeletaClipper.pathFor(size);
    // drop-shadow(0 1 1 rgba(90,64,24,.10)) drop-shadow(0 10 14 rgba(60,40,10,.14))
    canvas.drawPath(
        path.shift(const Offset(0, 10)),
        Paint()
          ..color = dark ? const Color(0x80000000) : const Color(0x243C280A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawPath(
        path.shift(const Offset(0, 1)),
        Paint()
          ..color = dark ? const Color(0x33000000) : const Color(0x1A5A4018)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5));
  }

  @override
  bool shouldRepaint(covariant _PapeletaShadowPainter old) => old.dark != dark;
}

/// Fila de la papeleta: medalla, categoría, nombre (o «Sin voto») y acción.
class PapeletaVoteRow extends StatelessWidget {
  final PremiosCategory category;
  final String? name;
  final bool flagged;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const PapeletaVoteRow({
    super.key,
    required this.category,
    required this.name,
    this.flagged = false,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 8, 12),
    this.minHeight = 76,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'premios-ballot-row-${category.short}',
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: padding,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  PremiosMiniMedal(category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.title,
                            style: GmText.eyebrow(color: gm.label2)),
                        const SizedBox(height: 1),
                        Text(
                          name ?? 'Sin voto',
                          style: GmText.body17(
                              color: name == null ? gm.label2 : gm.label,
                              w: FontWeight.w600),
                        ),
                        // Hueco del aviso: el chip va en una línea y puede
                        // pasar por debajo de «Cambiar» (como el tablero).
                        if (flagged) const SizedBox(height: 26),
                      ],
                    ),
                  ),
                  if (action != null)
                    Semantics(
                      identifier: 'premios-ballot-change-${category.short}',
                      button: true,
                      child: GmPressable(
                        onTap: onAction,
                        pressedScale: 0.94,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          child: Text(action!,
                              style: GmText.cardTitle(color: gm.accent)
                                  .copyWith(fontSize: 16)),
                        ),
                      ),
                    ),
                ],
              ),
              if (flagged)
                Positioned(
                  left: 56,
                  bottom: 0,
                  child: Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: gm.warnSoft,
                      borderRadius: BorderRadius.circular(GmRadius.pill),
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.1,
                      child: Text(
                        'Ya votaste a este sitio desde este móvil',
                        maxLines: 1,
                        style:
                            GmText.chip(color: gm.warnText, w: FontWeight.w700)
                                .copyWith(height: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sello «Votado 2026» ────────────────────────────────────────────────────

/// Sello de 76 a −14° que cae sobre la papeleta (1,05 s, muelle) con
/// háptica ligera al posarse.
class SelloVotado extends StatefulWidget {
  const SelloVotado({super.key});

  @override
  State<SelloVotado> createState() => _SelloVotadoState();
}

class _SelloVotadoState extends State<SelloVotado> {
  static const _delay = Duration(milliseconds: 1050);
  static const _dur = Duration(milliseconds: 620);
  Timer? _buzz;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Háptica ligera cuando el sello se posa (55 % de la caída).
    if (_buzz == null && !GmMotion.reduced(context)) {
      _buzz = Timer(_delay + _dur * 0.55, premiosLightHaptic);
    }
  }

  @override
  void dispose() {
    _buzz?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = PremiosColors.catInk(PremiosCategory.tradicional, gm);
    final stamp = Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink, width: 2.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: 1.5),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(7),
        child: MediaQuery.withNoTextScaling(
          // Nunca se sale del aro.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Votado',
                    style: TextStyle(
                        fontSize: 15,
                        height: 18 / 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        color: ink)),
                Text('2026',
                    style: TextStyle(
                        fontSize: 12,
                        height: 15 / 12,
                        fontWeight: FontWeight.w700,
                        color: ink)),
              ],
            ),
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: GmOnce(
        duration: _dur,
        delay: _delay,
        trigger: GmTrigger.mount,
        child: stamp,
        builder: (_, t, c) {
          const sp = GmMotion.spring;
          final rot = gmKeyframes(
              t, const [(0, -24), (0.55, -12), (0.75, -15), (1, -14)],
              curve: sp);
          final s = gmKeyframes(
              t, const [(0, 1.9), (0.55, 0.9), (0.75, 1.04), (1, 1)],
              curve: sp);
          final op = gmKeyframes(t, const [(0, 0), (0.55, 1), (1, 0.92)],
                  curve: Curves.linear)
              .clamp(0.0, 1.0);
          return Opacity(
            opacity: op,
            child: Transform.rotate(
              angle: rot * math.pi / 180,
              child: Transform.scale(scale: s, child: c),
            ),
          );
        },
      ),
    );
  }
}

// ── Avatares del ranking ───────────────────────────────────────────────────

/// Foto del sitio o, si no hay, el glifo de la categoría sobre su tinte.
class PremiosAvatar extends StatelessWidget {
  final String? photoUrl;
  final PremiosCategory category;
  final double size;
  const PremiosAvatar(
      {super.key,
      required this.photoUrl,
      required this.category,
      this.size = 44});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(PremiosColors.catTint(category, gm), gm.card),
      ),
      alignment: Alignment.center,
      child: PremiosCategoryGlyph(category,
          size: size * 0.46, ink: PremiosColors.catInk(category, gm)),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: (size * 3).round(),
          placeholder: (_, __) => const GmFill(),
          errorWidget: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

// ── Volcán de los estados vacíos ───────────────────────────────────────────

/// El volcán mascota (100 × 70): contento o con boca triste.
class PremiosVolcano extends StatelessWidget {
  final bool sad;
  final double width;
  const PremiosVolcano({super.key, this.sad = false, this.width = 100});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = _hex(gm.volcInk);
    final mouth = sad ? 'M45 58q5-3.4 10 0' : 'M45 56q5 3.8 10 0';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70">'
      '<path d="M6 68l28-34c3-3.4 6-4.1 8.6-2.2l4.3 3c3.2 2.2 6.6 2.2 9.8 0l4.3-3c2.6-1.9 5.6-1.2 8.6 2.2L94 68z" '
      'fill="${_hex(gm.volcFill)}" stroke="${_hex(gm.sep)}" stroke-opacity="${gm.sep.a.toStringAsFixed(3)}" stroke-width="1.2" stroke-linejoin="round"/>'
      '<path d="M38.5 33.5l5.6 4c4 2.8 9.2 2.8 13.2 0l5.6-4" fill="none" stroke="#E0603A" stroke-width="3.4" stroke-linecap="round"/>'
      '<circle cx="42.5" cy="50" r="2.8" fill="$ink"/><circle cx="57.5" cy="50" r="2.8" fill="$ink"/>'
      '<path d="$mouth" fill="none" stroke="$ink" stroke-width="2.2" stroke-linecap="round"/></svg>',
      width: width,
      height: width * 0.7,
      excludeFromSemantics: true,
    );
  }
}

/// Tarjeta de estado vacío/error de la encuesta.
class PremiosStateCard extends StatelessWidget {
  final String identifier;
  final bool sad;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final double volcanoWidth;

  const PremiosStateCard({
    super.key,
    required this.identifier,
    required this.title,
    required this.text,
    this.sad = false,
    this.action,
    this.onAction,
    this.volcanoWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      child: GmCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            children: [
              PremiosVolcano(sad: sad, width: volcanoWidth),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GmText.guideTitle(color: gm.label)),
              const SizedBox(height: 6),
              Text(text,
                  textAlign: TextAlign.center,
                  style: GmText.body(color: gm.label2)),
              if (action != null && onAction != null) ...[
                const SizedBox(height: 14),
                GmSoftCapsuleButton(
                  label: action!,
                  identifier: '$identifier-action',
                  onTap: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tienda ─────────────────────────────────────────────────────────────────

/// «la App Store» / «Google Play» (textos de actualizar).
String premiosStoreName() => Platform.isIOS ? 'la App Store' : 'Google Play';

/// Abre la ficha de la app en su tienda (la misma que «Actualizar»).
Future<void> premiosOpenStore() async {
  final uri = Uri.parse(Platform.isIOS
      ? 'https://apps.apple.com/es/app/guachinches-modernos/id1575882373'
      : 'https://play.google.com/store/apps/details?id=com.jonay.guachinches');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    AppLogger.warn('premios', 'abrir la tienda: ${e.runtimeType}');
  }
}

// ── Ranking oculto hasta el cierre ─────────────────────────────────────────

/// «El ranking se desvela al cierre» (resultados con `hidden: true`, modo
/// `after_close`): la barrica guarda los votos y el podio sale al cerrar.
class PremiosHiddenRanking extends StatelessWidget {
  /// «hasta el 20 de marzo» (vacío sin fecha).
  final String untilShort;
  const PremiosHiddenRanking({super.key, required this.untilShort});

  static String textFor(String untilShort) {
    final when = untilShort.isEmpty
        ? 'al cierre'
        : 'el ${untilShort.replaceFirst('hasta el ', '')}';
    return 'Los votos se cuentan a puerta cerrada y el podio sale $when. '
        'Mientras, vota a tus favoritos.';
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'premios-ranking-hidden',
      container: true,
      child: GmCard(
        radius: GmRadius.guide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PremiosMiniBarrel(width: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('El ranking se desvela al cierre',
                        style: GmText.cardTitle(color: gm.label)),
                    const SizedBox(height: 3),
                    Text(textFor(untilShort),
                        style: GmText.body(color: gm.label2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Candado de 14 en oro (píldora del ranking oculto).
class PremiosLockIcon extends StatelessWidget {
  const PremiosLockIcon({super.key});

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="${_hex(PremiosColors.goldText)}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">'
        '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V8a4 4 0 018 0v2.5"/></svg>',
        width: 14,
        height: 14,
        excludeFromSemantics: true,
      );
}

/// Papeleta con check (icono del CTA «Votar ahora»).
class PremiosBallotIcon extends StatelessWidget {
  final double size;
  final Color color;
  const PremiosBallotIcon(
      {super.key, this.size = 20, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="${_hex(color)}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'
        '<path d="M6 3.5h9l3.5 3.5v13.5H6z"/><path d="M9 12.5l2.2 2.2 4.3-4.6"/></svg>',
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
}
