import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glyphs.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Piezas comunes del juego (tableros `Quiz*`). Leen [GmColors]; nada de
/// colores claros fijos en noche.

/// Colores de estado propios del juego (respuesta correcta / fallida).
class QuizStateColors {
  final Color okSoft;
  final Color koSoft;
  final Color onAccent;
  const QuizStateColors._(this.okSoft, this.koSoft, this.onAccent);

  static const day = QuizStateColors._(
      Color(0x1F2FBF5B), Color(0x14C0352B), Color(0xFFFFFFFF));
  static const night = QuizStateColors._(
      Color(0x2430D158), Color(0x24FF6B5E), Color(0xFF0A141B));

  static QuizStateColors of(GmColors gm) => gm.isDark ? night : day;
}

/// Píldora de cristal de 44 (marcador, chips de la tarjeta de conquista).
class QuizPill extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  const QuizPill({
    super.key,
    required this.child,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return SizedBox(
      height: height,
      child: GmGlass(
        borderRadius: BorderRadius.circular(height / 2),
        tint: gm.glass,
        edge: gm.glassEdge,
        shadow: gm.shadow1,
        child: Padding(
          padding: padding,
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: child)]),
        ),
      ),
    );
  }
}

/// Barra superior: dos botones de cristal de 44 y algo en medio.
class QuizTopBar extends StatelessWidget {
  final Widget left;
  final Widget? center;
  final Widget? right;
  const QuizTopBar({super.key, required this.left, this.center, this.right});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          left,
          const SizedBox(width: 8),
          Expanded(child: Center(child: center ?? const SizedBox.shrink())),
          const SizedBox(width: 8),
          right ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Control segmentado de cristal (Inicio / Historial / Ranking).
class QuizSegmented extends StatelessWidget {
  final List<String> labels;
  final List<String> identifiers;
  final int index;
  final ValueChanged<int> onChanged;
  const QuizSegmented({
    super.key,
    required this.labels,
    required this.identifiers,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    return SizedBox(
      height: 44,
      child: GmGlass(
        borderRadius: BorderRadius.circular(22),
        tint: gm.glass,
        edge: gm.glassEdge,
        shadow: gm.shadow1,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 2 * (labels.length - 1)) / labels.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: Duration(milliseconds: reduced ? 0 : 320),
                  curve: GmMotion.settle,
                  left: index * (w + 2),
                  top: 0,
                  width: w,
                  height: 38,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: gm.card,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1F000000),
                            offset: Offset(0, 1),
                            blurRadius: 4),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      SizedBox(
                        width: w,
                        height: 38,
                        child: Semantics(
                          identifier: identifiers[i],
                          button: true,
                          selected: i == index,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onChanged(i),
                            child: Center(
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: i == index ? gm.label : gm.label2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Bloque de esqueleto (relleno quieto, sin brillo en bucle).
class QuizSkel extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const QuizSkel(
      {super.key, this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GmColors.of(context).fill,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Tarjeta de estado (error o vacío) con el volcán.
class QuizStateCard extends StatelessWidget {
  final String identifier;
  final String title;
  final String text;
  final QuizVolcanoMood mood;
  final String? action;
  final String? actionIdentifier;
  final VoidCallback? onAction;
  final bool bounce;

  const QuizStateCard({
    super.key,
    required this.identifier,
    required this.title,
    required this.text,
    this.mood = QuizVolcanoMood.sad,
    this.action,
    this.actionIdentifier,
    this.onAction,
    this.bounce = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget volcano = QuizVolcano(mood: mood, width: 96);
    if (bounce) volcano = QuizHop(child: volcano);
    return Semantics(
      identifier: identifier,
      container: true,
      child: GmCard(
        radius: GmRadius.guide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            children: [
              volcano,
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GmText.poster(color: gm.label)),
              const SizedBox(height: 4),
              Text(text,
                  textAlign: TextAlign.center,
                  style: GmText.body(color: gm.label2)),
              if (action != null && onAction != null) ...[
                const SizedBox(height: 18),
                GmCapsuleButton(
                  label: action!,
                  identifier: actionIdentifier,
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

/// Barra inferior de cristal (64, a 28 del borde) con fundido del lienzo.
class QuizBottomBar extends StatelessWidget {
  final List<Widget> children;
  const QuizBottomBar({super.key, required this.children});

  /// Distancia de la barra al borde inferior.
  static double bottomOf(BuildContext context) =>
      math.max(16, MediaQuery.paddingOf(context).bottom - 6);

  /// Hueco que necesita el contenido que pasa por debajo.
  static double scrollPadding(BuildContext context) =>
      bottomOf(context) + 64 + 28;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
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
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        children[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón principal de 52 a todo lo ancho.
class QuizCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? identifier;
  final String? icon;
  final Widget? leading;
  const QuizCta({
    super.key,
    required this.label,
    this.onTap,
    this.identifier,
    this.icon,
    this.leading,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: GmCapsuleButton(
          label: label,
          onTap: onTap,
          identifier: identifier,
          icon: icon,
          leading: leading,
          height: 52,
          fontSize: 17,
          iconSize: 14,
        ),
      );
}

/// Botón secundario de 52 (`accentSoft` + `accent`).
class QuizSoftCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? identifier;
  final bool expand;
  const QuizSoftCta({
    super.key,
    required this.label,
    this.onTap,
    this.identifier,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    // Como `GmSoftCapsuleButton` (accentSoft + accent; sin acción, label2),
    // pero el texto parte en dos líneas con letra grande en vez de desbordar.
    final gm = GmColors.of(context);
    final enabled = onTap != null;
    final b = Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: gm.accentSoft,
            borderRadius: BorderRadius.circular(GmRadius.pill),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: enabled ? gm.accent : gm.label2,
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: b) : b;
  }
}

/// Acción destructiva en texto (`closedText`), 44 de alto.
class QuizDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? identifier;
  const QuizDangerButton(
      {super.key, required this.label, required this.onTap, this.identifier});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: gm.closedText)),
          ),
        ),
      ),
    );
  }
}

/// Hoja con asa (r32 arriba). Se presenta con [showQuizSheet].
class QuizSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final String? closeIdentifier;
  const QuizSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.closeIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: gm.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E000000), offset: Offset(0, -10), blurRadius: 30)
        ],
      ),
      padding: EdgeInsets.fromLTRB(0, 8, 0, math.max(16, bottom)),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: gm.sep,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: QuizTopBar(
                  left: onClose == null
                      ? const SizedBox(width: 44)
                      : GmToolbarButton(
                          icon: GmIcons.close,
                          light: true,
                          semanticLabel: 'Cerrar',
                          identifier: closeIdentifier,
                          onTap: onClose!,
                        ),
                  center:
                      Text(title!, style: GmText.guideTitle(color: gm.label)),
                ),
              ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Presenta una [QuizSheet] modal.
Future<T?> showQuizSheet<T>(BuildContext context, WidgetBuilder builder,
    {bool isDismissible = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    useSafeArea: true,
    builder: builder,
  );
}

/// Escalera de arenas: Marea (bronce) · Volcán (plata) · Leyenda (oro).
class QuizLadder extends StatelessWidget {
  final int tier;
  const QuizLadder({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final items = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final on = i == tier - 1;
      if (i > 0) {
        items.add(Flexible(
          flex: 1,
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: gm.sep,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ));
      }
      final medal = QuizMedal(kind: quizTierMedal(i + 1), size: on ? 30 : 26);
      items.add(Flexible(
        flex: 5,
        child: Semantics(
          label: '${kQuizTierNames[i]}: ${quizLadderStatus(i, tier)}',
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                on
                    ? Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gm.card,
                          border: Border.all(color: GmColors.gold, width: 1.5),
                        ),
                        child: medal,
                      )
                    : medal,
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(kQuizTierNames[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight:
                                  on ? FontWeight.w700 : FontWeight.w600,
                              color: gm.label)),
                      Text(quizLadderStatus(i, tier),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, height: 15 / 12, color: gm.label2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    return Row(children: items);
  }
}

/// Progreso de 7 segmentos (oro los conquistados).
class QuizProgress7 extends StatelessWidget {
  final int value;
  final int total;
  const QuizProgress7({super.key, required this.value, this.total = 7});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      label: '$value de $total islas',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < value ? null : gm.fill,
                  gradient: i < value
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE3C98E), Color(0xFFB08A48)])
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Salto del volcán feliz (una vez, 900 ms).
class QuizHop extends StatelessWidget {
  final Widget child;
  const QuizHop({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GmOnce(
        duration: const Duration(milliseconds: 900),
        delay: const Duration(milliseconds: 250),
        trigger: GmTrigger.mount,
        child: child,
        builder: (_, t, c) {
          final dy = gmKeyframes(
              t, const [(0, 0), (0.3, -10), (0.55, 0), (0.75, -4), (1, 0)]);
          final sy = gmKeyframes(
              t, const [(0, 1), (0.5, 0.94), (0.6, 1.02), (0.7, 1), (1, 1)]);
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(2 - sy, sy, 1),
              child: c,
            ),
          );
        },
      );
}

/// Desánimo del volcán triste/sorprendido (una vez, 900 ms).
class QuizDroop extends StatelessWidget {
  final Widget child;
  const QuizDroop({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GmOnce(
        duration: const Duration(milliseconds: 900),
        delay: const Duration(milliseconds: 250),
        trigger: GmTrigger.mount,
        child: child,
        builder: (_, t, c) {
          final sx = gmKeyframes(
              t, const [(0, 1), (0.35, 1.04), (0.65, 0.98), (1, 1)]);
          final sy = gmKeyframes(
              t, const [(0, 1), (0.35, 0.92), (0.65, 1.02), (1, 1)]);
          final dy =
              gmKeyframes(t, const [(0, 0), (0.35, 2), (0.65, 0), (1, 0)]);
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: c,
            ),
          );
        },
      );
}

/// Pop grande (escala 0,7 y −14° con muelle), una vez.
class QuizBigPop extends StatelessWidget {
  final Widget child;
  final Duration delay;
  const QuizBigPop(
      {super.key,
      required this.child,
      this.delay = const Duration(milliseconds: 100)});

  @override
  Widget build(BuildContext context) => GmOnce(
        duration: const Duration(milliseconds: 760),
        delay: delay,
        trigger: GmTrigger.mount,
        child: child,
        builder: (_, t, c) {
          final s = gmKeyframes(t, const [(0, 0.7), (0.6, 1.06), (1, 1)]);
          final r = gmKeyframes(t, const [(0, -14), (0.6, 3), (1, 0)]);
          return Transform.rotate(
            angle: r * math.pi / 180,
            child: Transform.scale(scale: s, child: c),
          );
        },
      );
}

/// Chispas oro alrededor de un elemento (aparecen una vez).
class QuizSparks extends StatelessWidget {
  final double size;
  const QuizSparks({super.key, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: GmOnce(
          duration: const Duration(milliseconds: 1300),
          trigger: GmTrigger.mount,
          builder: (_, t, __) =>
              CustomPaint(size: Size.square(size), painter: _SparksPainter(t)),
        ),
      );
}

class _SparksPainter extends CustomPainter {
  final double t;
  _SparksPainter(this.t);

  static const _pts = [
    Offset(14, 20),
    Offset(88, 12),
    Offset(96, 46),
    Offset(6, 52)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final ms = t * 1300;
    for (var i = 0; i < _pts.length; i++) {
      final p = GmMotion.spring
          .transform(((ms - 700 - i * 90) / 600).clamp(0.0, 1.0));
      if (p <= 0) continue;
      final c = _pts[i];
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-40 * (1 - p) * math.pi / 180);
      canvas.scale(p);
      final star = Path()
        ..moveTo(0, -7)
        ..lineTo(1.6, -1.6)
        ..lineTo(7, 0)
        ..lineTo(1.6, 1.6)
        ..lineTo(0, 7)
        ..lineTo(-1.6, 1.6)
        ..lineTo(-7, 0)
        ..lineTo(-1.6, -1.6)
        ..close();
      canvas.drawPath(star, Paint()..color = GmColors.gold);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SparksPainter o) => o.t != t;
}

/// Confeti de los quesitos + oro. Cae UNA vez (1,6 s) y desaparece; con
/// «reducir movimiento» no se pinta.
class QuizConfetti extends StatelessWidget {
  final int count;
  final int seed;
  const QuizConfetti({super.key, this.count = 26, this.seed = 3});

  @override
  Widget build(BuildContext context) {
    if (GmMotion.reduced(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: GmOnce(
        duration: const Duration(milliseconds: 2300),
        trigger: GmTrigger.mount,
        builder: (_, t, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(t: t, count: count, seed: seed),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final int count;
  final int seed;
  _ConfettiPainter({required this.t, required this.count, required this.seed});

  static const _sizes = [Size(8, 4), Size(6, 6), Size(10, 4), Size(5, 9)];

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final rnd = math.Random(seed);
    final colors = [
      for (final q in kQuizQuesitos) q.fill,
      GmColors.gold,
      GmColors.gold,
    ];
    final ms = t * 2300;
    final k = size.width / 402;
    for (var i = 0; i < count; i++) {
      final x = (10 + rnd.nextInt(382)) * k;
      final y = (80 + rnd.nextInt(250)).toDouble();
      final s = _sizes[rnd.nextInt(_sizes.length)];
      final rot = (rnd.nextInt(121) - 60) * math.pi / 180;
      final color = colors[rnd.nextInt(colors.length)];
      final p = ((ms - 200 - (i % 12) * 40) / 1600).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final e = const Cubic(0.2, 0.7, 0.4, 1).transform(p);
      final dy = -160 + 250 * e;
      final opacity = p < 0.75 ? 1.0 : (1 - (p - 0.75) / 0.25);
      canvas.save();
      canvas.translate(x, y + dy);
      canvas.rotate(rot + 200 * e * math.pi / 180);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: s.width, height: s.height),
            const Radius.circular(1.5)),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}

/// Puntos sobre vino («+420 puntos»).
class QuizWinePoints extends StatelessWidget {
  final String text;
  const QuizWinePoints(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: GmColors.wine,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x80C9A96B)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8CF9A))),
        ]),
      );
}
