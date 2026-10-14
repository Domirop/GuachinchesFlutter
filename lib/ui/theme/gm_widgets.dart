import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Piezas reutilizables del rediseño iOS 27. Todas leen [GmColors.of].

/// Velo del lienzo bajo la barra de estado (edgeTop): se muestra cuando el
/// contenido de lienzo pasa por debajo del reloj. No intercepta toques.
class GmTopScrim extends StatelessWidget {
  final bool visible;
  final double extra;
  const GmTopScrim({super.key, required this.visible, this.extra = 16});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: top + extra,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gm.edgeTop0, gm.edgeTop1, gm.edgeFade0],
                stops: const [0, 0.7, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta e1: blanco puro, radio 24, filo 1 px + sombra cálida.
class GmCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Clip clip;

  const GmCard({
    super.key,
    required this.child,
    this.radius = GmRadius.card,
    this.padding,
    this.color,
    this.clip = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: gm.shadow1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: clip,
        child: ColoredBox(
          color: color ?? gm.card,
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Cristal líquido: desenfoque + velo + filo interior de 1 px + brillo
/// superior. Úsalo con moderación (barra, botones de herramientas).
class GmGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color tint;
  final Color edge;
  final double blur;
  final List<BoxShadow>? shadow;
  final double edgeWidth;

  const GmGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.tint,
    required this.edge,
    this.blur = 24,
    this.shadow,
    this.edgeWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    // La sombra se pinta solo FUERA del cristal (como `box-shadow` en CSS):
    // si quedara debajo, el desenfoque y el velo translúcido la dejarían ver
    // y el cristal saldría gris.
    return CustomPaint(
      painter: shadow == null || shadow!.isEmpty
          ? null
          : GmOuterShadowPainter(borderRadius: borderRadius, shadows: shadow!),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: borderRadius,
            ),
            position: DecorationPosition.background,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: edge, width: edgeWidth),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.35],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sombras de caja pintadas solo fuera del rectángulo redondeado.
class GmOuterShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  const GmOuterShadowPainter(
      {required this.borderRadius, required this.shadows});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(200))
      ..addRRect(rrect));
    for (final s in shadows) {
      canvas.drawRRect(
          rrect.shift(s.offset).inflate(s.spreadRadius), s.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GmOuterShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}

/// Botón de herramientas circular de 44 en cristal oscuro (sobre foto).
class GmToolbarButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final String? identifier;
  final double iconSize;

  /// `true` = cristal claro (sobre lienzo); `false` = cristal oscuro sobre foto.
  final bool light;

  const GmToolbarButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.identifier,
    this.iconSize = 18,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = light ? gm.glassInk : Colors.white;
    return Semantics(
      identifier: identifier,
      label: semanticLabel,
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: SizedBox(
          width: 44,
          height: 44,
          child: GmGlass(
            borderRadius: BorderRadius.circular(22),
            tint: light ? gm.glass : const Color(0x4D1C1612),
            edge: light ? gm.glassEdge : const Color(0x66FFFFFF),
            edgeWidth: light ? 1 : 0.5,
            blur: 20,
            shadow: light ? gm.shadow1 : null,
            child: Center(child: GmIcon(icon, size: iconSize, color: ink)),
          ),
        ),
      ),
    );
  }
}

/// Antetítulo de sección (13/18 · 600 · secundario) con glifo opcional.
class GmEyebrow extends StatelessWidget {
  final Widget? leading;
  final List<InlineSpan>? spans;
  final String? text;
  final Color? color;

  const GmEyebrow({super.key, this.leading, this.text, this.spans, this.color})
      : assert(text != null || spans != null);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        Flexible(
          child: Text.rich(
            TextSpan(text: text, children: spans),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GmText.eyebrow(color: color ?? gm.label2),
          ),
        ),
      ],
    );
  }
}

/// Cabecera de sección iOS 26/27: antetítulo + título pulsable con chevron
/// (sin enlaces azules «Ver todo»).
class GmSectionHeader extends StatelessWidget {
  final Widget? eyebrow;
  final String title;
  final VoidCallback? onTap;
  final String? identifier;

  const GmSectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.onTap,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final titleRow = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GmText.title2(color: gm.label),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 5),
            GmIcon(GmIcons.chevronRight, size: 18, color: gm.label2),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null) eyebrow!,
          if (onTap == null)
            titleRow
          else
            Semantics(
              identifier: identifier,
              button: true,
              label: title,
              excludeSemantics: true,
              child: GmPressable(
                onTap: onTap,
                pressedScale: 0.98,
                child: titleRow,
              ),
            ),
        ],
      ),
    );
  }
}

/// Título de bloque en pantallas de detalle («Detalles», «Servicios»…):
/// 20/25 · 700 en tipo frase, a 20 pt del borde (dentro de un margen de 16).
class GmDetailTitle extends StatelessWidget {
  final String text;
  const GmDetailTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        child:
            Text(text, style: GmText.poster(color: GmColors.of(context).label)),
      );
}

/// Botón cápsula primario (degradado Atlántico, texto blanco, 44 de alto).
class GmCapsuleButton extends StatelessWidget {
  final String label;
  final String? icon;
  final double iconSize;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final String? identifier;
  final double height;

  /// Widget delante del texto (p. ej. el indicador de «Enviando…»); manda
  /// sobre [icon].
  final Widget? leading;

  /// Widget detrás del texto (p. ej. un chevron).
  final Widget? trailing;
  final FontWeight fontWeight;

  /// Sombra propia (CTA destacados); por defecto la del sistema.
  final List<BoxShadow>? shadow;

  static const defaultShadow = [
    BoxShadow(
      color: Color(0x8C005A8C),
      offset: Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -6,
    ),
  ];

  const GmCapsuleButton({
    super.key,
    required this.label,
    this.icon,
    this.iconSize = 12,
    this.onTap,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.identifier,
    this.height = 44,
    this.leading,
    this.trailing,
    this.fontWeight = FontWeight.w600,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          // Mínimo de 44/52; crece con el tamaño de texto del sistema.
          constraints: BoxConstraints(minHeight: height),
          padding: padding.add(const EdgeInsets.symmetric(vertical: 6)),
          decoration: BoxDecoration(
            gradient: GmColors.accentFill,
            borderRadius: BorderRadius.circular(GmRadius.pill),
            boxShadow: shadow ?? defaultShadow,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GmRadius.pill),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x26FFFFFF),
                Color(0x00FFFFFF),
                Color(0x00002846),
                Color(0x1A002846)
              ],
              stops: [0, 0.12, 0.88, 1],
            ),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ] else if (icon != null) ...[
                  GmIcon(icon!, size: iconSize, color: Colors.white),
                  const SizedBox(width: 7),
                ],
                // Flexible: con texto grande parte en dos líneas.
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón cápsula secundario: relleno `accentSoft` y texto `accent`
/// («Saltar», «Borrar búsqueda», «Mis votos»). Sin [onTap] se pinta
/// deshabilitado (texto `label2`). [background] cambia el relleno (p. ej. la
/// tarjeta, para AA sobre el lienzo) y añade la sombra e1.
class GmSoftCapsuleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final String? identifier;
  final Color? background;
  final Widget? leading;

  const GmSoftCapsuleButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 44,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.identifier,
    this.background,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final enabled = onTap != null;
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: padding.add(const EdgeInsets.symmetric(vertical: 6)),
          decoration: BoxDecoration(
            color: background ?? gm.accentSoft,
            borderRadius: BorderRadius.circular(GmRadius.pill),
            boxShadow: background != null ? gm.shadow1 : null,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 7)],
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: enabled ? gm.accent : gm.label2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de cristal sobre foto (26 de alto, 12/16 · 600).
class GmPhotoChip extends StatelessWidget {
  final Widget? leading;
  final String label;

  /// Variante oscura (fecha en pósters).
  final bool dark;

  const GmPhotoChip({
    super.key,
    required this.label,
    this.leading,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = dark ? Colors.white : gm.photoInk;
    // Chip de 26 sobre foto: el texto escala como mucho a 1,3×.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: dark ? const Color(0x5714100C) : gm.photoGlass,
          borderRadius: BorderRadius.circular(GmRadius.pill),
          border: Border.all(
              color: dark ? const Color(0x59FFFFFF) : gm.photoEdge, width: 0.5),
          boxShadow: dark
              ? null
              : const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(0, 2),
                      blurRadius: 8),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GmText.chip(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Corazón de cristal sobre foto (44 de toque, 32 visibles). Cableado a los
/// guardados locales ([GmFavorites]). Squash al tocar.
class GmFavButton extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const GmFavButton({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<GmFavButton> createState() => _GmFavButtonState();
}

class _GmFavButtonState extends State<GmFavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void initState() {
    super.initState();
    GmFavorites.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    if (!GmMotion.reduced(context)) _c.forward(from: 0);
    await GmFavorites.instance.toggle(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: GmFavorites.instance,
      builder: (_, ids, __) {
        final saved = ids.contains(widget.restaurantId);
        return Semantics(
          button: true,
          toggled: saved,
          label: saved
              ? 'Quitar ${widget.restaurantName} de guardados'
              : 'Guardar ${widget.restaurantName}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, child) {
                    final t = _c.value;
                    final sx = gmKeyframes(t, const [
                      (0, 1),
                      (0.3, 1.25),
                      (0.52, 0.9),
                      (0.72, 1.05),
                      (1, 1)
                    ]);
                    final sy = gmKeyframes(t, const [
                      (0, 1),
                      (0.3, 0.82),
                      (0.52, 1.1),
                      (0.72, 0.97),
                      (1, 1)
                    ]);
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(sx, sy, 1),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: gm.photoGlass,
                      shape: BoxShape.circle,
                      border: Border.all(color: gm.photoEdge, width: 0.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1F000000),
                            offset: Offset(0, 2),
                            blurRadius: 8),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: GmIcon(
                      saved ? GmIcons.heartFilled : GmIcons.heart,
                      size: 16,
                      color: saved ? GmColors.heart : gm.photoInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Punto verde «abierto» (7 px). Con [live] emite una onda cada 3,2 s.
class GmLiveDot extends StatelessWidget {
  final bool live;
  final Color? color;
  final double size;

  const GmLiveDot({super.key, this.live = false, this.color, this.size = 7});

  @override
  Widget build(BuildContext context) {
    final c = color ?? GmColors.of(context).green;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    if (!live) return dot;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: GmLoop(
                period: GmMotion.livePing,
                builder: (_, t, __) {
                  // ping: 0% scale 1 · .55 → 70% scale 3.2 · 0 (ease-out).
                  final k = (t / 0.7).clamp(0.0, 1.0);
                  final e = const Cubic(0, 0, 0.2, 1).transform(k);
                  final scale = 1 + 2.2 * e;
                  final op = t >= 0.7 ? 0.0 : 0.55 * (1 - e);
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: op,
                      child: DecoratedBox(
                        decoration:
                            BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          dot,
        ],
      ),
    );
  }
}

/// «★ 4,9». Devuelve nada si la valoración es 0 (nunca «★ —»).
class GmRating extends StatelessWidget {
  final double value;
  final double fontSize;
  final double starSize;

  const GmRating(this.value,
      {super.key, this.fontSize = 13, this.starSize = 12});

  static String format(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();
    final gm = GmColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GmIcon(GmIcons.star, size: starSize, color: GmColors.star),
        const SizedBox(width: 3),
        Text(
          format(value),
          style: TextStyle(
            fontSize: fontSize,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: gm.label,
          ),
        ),
      ],
    );
  }
}

/// «● Abierto» en verde.
class GmOpenLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  const GmOpenLabel({super.key, this.text = 'Abierto', this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GmLiveDot(),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            color: gm.greenText,
          ),
        ),
      ],
    );
  }
}

/// Mantel de cuadros (vichy rojo) — banda/glifo «Mantel». Con [base] y
/// [stripe] pinta otros manteles (el oro sobre crema de «Guachinches
/// modernos»).
class GmGinghamPainter extends CustomPainter {
  final double cell;
  final Color base;
  final Color stripe;
  const GmGinghamPainter({
    this.cell = 7,
    this.base = const Color(0xFFFFF7EC),
    this.stripe = const Color(0x9EC8202C), // rgba(200,32,44,.62)
  });

  /// Mantel de «Guachinches modernos»: cuadros oro #C9A96B sobre crema.
  static const goldStripe = Color(0xC7C9A96B); // .78
  static const goldBase = Color(0xFFFFF6E6);

  @override
  void paint(Canvas canvas, Size size) => paintCells(
        canvas,
        Offset.zero & size,
        cell: cell,
        base: base,
        stripe: stripe,
        phase: Offset(0, cell),
      );

  /// Vichy en [rect] (recortado a [clip] si llega): franjas de [cell] cada
  /// 2·[cell] en los dos sentidos, desplazadas por [phase]; donde se cruzan
  /// se superponen (más oscuro), como el vichy real y el `pattern` de los
  /// tableros. Lo usan todos los manteles (listas, encuesta, glifos).
  static void paintCells(
    Canvas canvas,
    Rect rect, {
    double cell = 7,
    Color base = const Color(0xFFFFF7EC),
    Color stripe = const Color(0x9EC8202C),
    Offset phase = Offset.zero,
    Path? clip,
  }) {
    canvas.save();
    canvas.clipRect(rect);
    if (clip != null) canvas.clipPath(clip);
    canvas.drawRect(rect, Paint()..color = base);
    final p = Paint()..color = stripe;
    final step = cell * 2;
    double first(double origin, double from) =>
        origin - ((origin - from) / step).ceil() * step;
    for (double x = first(phase.dx, rect.left - cell);
        x < rect.right;
        x += step) {
      canvas.drawRect(Rect.fromLTWH(x, rect.top, cell, rect.height), p);
    }
    for (double y = first(phase.dy, rect.top - cell);
        y < rect.bottom;
        y += step) {
      canvas.drawRect(Rect.fromLTWH(rect.left, y, rect.width, cell), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GmGinghamPainter old) =>
      old.cell != cell || old.base != base || old.stripe != stripe;
}

/// Imagen de red con fondo de relleno mientras carga (sin parpadeos).
class GmFill extends StatelessWidget {
  final Widget? child;
  const GmFill({super.key, this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: GmColors.of(context).fill,
      child: child ?? const SizedBox.expand());
}
