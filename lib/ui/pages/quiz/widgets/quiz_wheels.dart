import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glyphs.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Rueda de 7 quesitos (como la tarjeta del Inicio): los conseguidos a color,
/// los demás al 24 %. [center] = texto del buje («3/7»). Con [pop] los
/// quesitos entran una vez (escala 0,6 y −18° con muelle, 85 ms de desfase).
class QuizQuesera extends StatelessWidget {
  final double size;
  final Set<String> owned;
  final String? center;
  final bool pop;
  final String? semanticsLabel;

  const QuizQuesera({
    super.key,
    required this.size,
    required this.owned,
    this.center,
    this.pop = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final label = semanticsLabel ?? '${owned.length} de 7 quesitos conseguidos';
    Widget paint(double t) => CustomPaint(
          size: Size.square(size),
          painter: _QueseraPainter(
              gm: gm, owned: owned, center: center, t: t, pop: pop),
        );
    return Semantics(
      label: label,
      image: true,
      child: RepaintBoundary(
        child: pop
            ? GmOnce(
                duration: const Duration(milliseconds: 1300),
                builder: (_, t, __) => paint(t),
              )
            : paint(1),
      ),
    );
  }
}

class _QueseraPainter extends CustomPainter {
  final GmColors gm;
  final Set<String> owned;
  final String? center;
  final double t;
  final bool pop;

  _QueseraPainter({
    required this.gm,
    required this.owned,
    required this.center,
    required this.t,
    required this.pop,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final size = s.width;
    final c = Offset(size / 2, size / 2);
    final r = size / 2 - 3;
    canvas.drawCircle(c, size / 2 - 1, Paint()..color = gm.card);
    canvas.drawCircle(
        c,
        size / 2 - 1,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    const sweep = 2 * math.pi / 7;
    final ms = t * 1300;
    for (var i = 0; i < 7; i++) {
      final q = kQuizQuesitos[i];
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), start, sweep, false)
        ..close();
      final on = owned.contains(q.slug);
      canvas.save();
      if (pop) {
        final p = GmMotion.spring
            .transform(((ms - 100 - i * 85) / 640).clamp(0.0, 1.0));
        final mid = start + sweep / 2;
        final pivot = c + Offset(math.cos(mid), math.sin(mid)) * r * 0.5;
        canvas.translate(pivot.dx, pivot.dy);
        canvas.rotate(-18 * (1 - p) * math.pi / 180);
        canvas.scale(0.6 + 0.4 * p);
        canvas.translate(-pivot.dx, -pivot.dy);
      }
      canvas.drawPath(
          path, Paint()..color = q.fill.withValues(alpha: on ? 1 : 0.24));
      canvas.drawPath(
          path,
          Paint()
            ..color = gm.card
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = math.max(2, size / 40));
      canvas.restore();
    }
    if (center != null) {
      final hr = size * 0.17;
      canvas.drawCircle(c, hr, Paint()..color = gm.card);
      canvas.drawCircle(
          c,
          hr,
          Paint()
            ..color = gm.sep
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      final tp = TextPainter(
        text: TextSpan(
          text: center,
          style: TextStyle(
            fontSize: math.max(11, (size * 0.135).roundToDouble()),
            fontWeight: FontWeight.w800,
            color: gm.label,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _QueseraPainter o) =>
      o.t != t || o.gm != gm || o.center != center || !_same(o.owned, owned);

  static bool _same(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Ficha redonda de un quesito para la tira del marcador.
class QuizQuesitoChip extends StatelessWidget {
  final QuizQuesito quesito;
  final bool owned;
  final double size;
  const QuizQuesitoChip(
      {super.key, required this.quesito, required this.owned, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = quesito.ink(gm.isDark);
    final Widget inner;
    if (owned) {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: quesito.fill,
          boxShadow: [
            BoxShadow(
              color: quesito.fill.withValues(alpha: 0.7),
              offset: const Offset(0, 3),
              blurRadius: 8,
              spreadRadius: -3,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x59FFFFFF), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: size - 12,
          height: size - 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: gm.card),
          alignment: Alignment.center,
          child: QuizGlyph(quesito.glyph,
              size: size - 18, color: ink, strokeWidth: 2.2),
        ),
      );
    } else {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: quesito.soft(gm.isDark)),
        alignment: Alignment.center,
        child: QuizGlyph(quesito.glyph, size: size - 16, color: ink),
      );
    }
    return Semantics(
      label: '${quesito.name}: ${owned ? 'conseguido' : 'pendiente'}',
      child: ExcludeSemantics(child: inner),
    );
  }
}

/// Tira de los 7 quesitos (marcador de la partida) con pie opcional.
class QuizQuesitoStrip extends StatelessWidget {
  final Set<String> owned;
  final double size;
  final double gap;
  final bool caption;
  const QuizQuesitoStrip({
    super.key,
    required this.owned,
    this.size = 34,
    this.gap = 8,
    this.caption = true,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final n = kQuizQuesitos.where((q) => owned.contains(q.slug)).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final q in kQuizQuesitos)
              QuizQuesitoChip(
                  quesito: q, owned: owned.contains(q.slug), size: size),
          ],
        ),
        if (caption) ...[
          const SizedBox(height: 6),
          Text('$n de 7 quesitos',
              textAlign: TextAlign.center,
              style: GmText.eyebrow(color: gm.label2)),
        ],
      ],
    );
  }
}

/// Ruleta grande: 7 sectores con su glifo en una ficha y el sello vino+oro en
/// los quesitos ya conseguidos. Se pinta quieta; quien la usa la rota.
class QuizBigWheel extends StatelessWidget {
  final double size;
  final Set<String> owned;
  const QuizBigWheel({super.key, required this.size, required this.owned});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final c = size / 2;
    final r = c - 6;
    const sweep = 2 * math.pi / 7;
    final badge = size * 22 / 316;
    final check = size * 10 / 316;
    Offset at(double radius, double angle) =>
        Offset(c + radius * math.sin(angle), c - radius * math.cos(angle));
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BigWheelPainter(gm: gm)),
          ),
          for (var i = 0; i < 7; i++) ...[
            () {
              final q = kQuizQuesitos[i];
              final p = at(r * 0.66, (i + 0.5) * sweep);
              return Positioned(
                left: p.dx - badge,
                top: p.dy - badge,
                width: badge * 2,
                height: badge * 2,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: gm.card),
                  child: Center(
                    child: QuizGlyph(q.glyph,
                        size: badge * 24 / 22,
                        color: q.ink(gm.isDark),
                        strokeWidth: 2.1),
                  ),
                ),
              );
            }(),
            if (owned.contains(kQuizQuesitos[i].slug))
              () {
                final p = at(r * 0.9, (i + 0.5) * sweep);
                return Positioned(
                  left: p.dx - check,
                  top: p.dy - check,
                  width: check * 2,
                  height: check * 2,
                  child: CustomPaint(painter: _CheckSealPainter()),
                );
              }(),
          ],
        ],
      ),
    );
  }
}

class _BigWheelPainter extends CustomPainter {
  final GmColors gm;
  _BigWheelPainter({required this.gm});

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final rr = s.width / 2;
    final r = rr - 6;
    final k = s.width / 316;
    canvas.drawCircle(
        c + Offset(0, 16 * k),
        rr,
        Paint()
          ..color = const Color(0x473C280A)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * k));
    canvas.drawCircle(c, rr, Paint()..color = gm.card);
    const sweep = 2 * math.pi / 7;
    for (var i = 0; i < 7; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), start, sweep, false)
        ..close();
      canvas.drawPath(path, Paint()..color = kQuizQuesitos[i].fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = gm.card
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 4 * k);
    }
    canvas.drawCircle(
        c,
        rr - 2,
        Paint()
          ..color = gm.card
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * k);
  }

  @override
  bool shouldRepaint(covariant _BigWheelPainter o) => o.gm != gm;
}

/// Sello vino con check oro (quesito ya conseguido).
class _CheckSealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    canvas.drawCircle(c, r, Paint()..color = GmColors.wine);
    canvas.drawCircle(
        c,
        r - 0.75,
        Paint()
          ..color = GmColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    final k = r / 10;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 4.2 * k, c.dy)
        ..relativeLineTo(2.8 * k, 2.8 * k)
        ..relativeLineTo(5.4 * k, -5.6 * k),
      Paint()
        ..color = const Color(0xFFE8CF9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sello del quesito conseguido (leyenda bajo la ruleta).
class QuizCheckSeal extends StatelessWidget {
  final double size;
  const QuizCheckSeal({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _CheckSealPainter());
}

/// Puntero de la ruleta: gota vino con filo y punto oro.
class QuizWheelPointer extends StatelessWidget {
  const QuizWheelPointer({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(40, 44), painter: _PointerPainter());
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(20, 42)
      ..lineTo(5, 12)
      ..arcToPoint(const Offset(35, 12),
          radius: const Radius.circular(15), largeArc: true)
      ..close();
    canvas.drawShadow(p, GmColors.wine, 4, false);
    canvas.drawPath(p, Paint()..color = GmColors.wine);
    canvas.drawPath(
        p,
        Paint()
          ..color = GmColors.gold
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.5);
    canvas.drawCircle(const Offset(20, 14), 5, Paint()..color = GmColors.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
