import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glyphs.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_ui.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wheels.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Marcador de la partida (tablero `QuizPartida`): X, 3 copas de vino y
/// píldora de puntos. [losing]: la copa que se acaba de perder se vuelca.
class QuizHud extends StatelessWidget {
  final int lives;
  final int score;
  final VoidCallback onExit;
  final bool losing;
  const QuizHud({
    super.key,
    required this.lives,
    required this.score,
    required this.onExit,
    this.losing = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return QuizTopBar(
      left: GmToolbarButton(
        icon: GmIcons.close,
        light: true,
        semanticLabel: 'Salir de la partida',
        identifier: 'quiz-hud-exit-button',
        onTap: onExit,
      ),
      center: Semantics(
        label: '$lives de 3 vidas',
        child: QuizPill(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  if (losing && i == lives)
                    _TippingCopa(key: ValueKey('tip-$lives'))
                  else
                    QuizCopa(full: i < lives),
                ],
              ],
            ),
          ),
        ),
      ),
      right: Semantics(
        label: '${quizFormatInt(score)} puntos',
        child: QuizPill(
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(quizFormatInt(score),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: gm.label)),
                const SizedBox(width: 6),
                Text('puntos',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: gm.label2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La copa que se pierde: se vuelca una vez (900 ms) y queda vacía.
class _TippingCopa extends StatelessWidget {
  const _TippingCopa({super.key});

  @override
  Widget build(BuildContext context) => GmOnce(
        duration: const Duration(milliseconds: 900),
        delay: const Duration(milliseconds: 200),
        trigger: GmTrigger.mount,
        child: const QuizCopa(full: false),
        builder: (_, t, c) {
          final r =
              gmKeyframes(t, const [(0, 0), (0.35, -28), (0.7, -8), (1, 0)]);
          final s = gmKeyframes(t, const [(0, 1), (0.7, 0.9), (1, 0.92)]);
          return Transform(
            alignment: const Alignment(0, 0.8),
            transform: Matrix4.rotationZ(r * math.pi / 180)
              ..scaleByDouble(s, s, 1, 1),
            child: c,
          );
        },
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Ruleta
// ═══════════════════════════════════════════════════════════════════════════

/// Ruleta (fase `spinning`). Al entrar precarga la tirada ([onPrefetch]: el
/// cubit elige categoría y pide la pregunta, sin arrancar el reloj). El giro
/// lo lanza el usuario con «Girar»; al parar avisa con [onSettled].
class QuizWheelView extends StatefulWidget {
  final QuizGameState state;
  final VoidCallback onPrefetch;
  final VoidCallback onSettled;
  final VoidCallback onExit;

  const QuizWheelView({
    super.key,
    required this.state,
    required this.onPrefetch,
    required this.onSettled,
    required this.onExit,
  });

  @override
  State<QuizWheelView> createState() => _QuizWheelViewState();
}

class _QuizWheelViewState extends State<QuizWheelView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000));
  Animation<double> _angle = const AlwaysStoppedAnimation(0);
  bool _wantSpin = false;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _settle();
    });
    if (widget.state.landed == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPrefetch();
      });
    }
  }

  @override
  void didUpdateWidget(QuizWheelView old) {
    super.didUpdateWidget(old);
    if (_wantSpin && old.state.landed == null && widget.state.landed != null) {
      _spin();
    }
  }

  void _onTapSpin() {
    if (_wantSpin) return;
    setState(() => _wantSpin = true);
    HapticFeedback.mediumImpact();
    if (widget.state.landed != null) _spin();
  }

  void _spin() {
    if (_spinning || widget.state.landed == null) return;
    _spinning = true;
    final idx = math.max(0, quizQuesitoIndex(widget.state.landed!.slug));
    const sweep = 2 * math.pi / 7;
    final end = 4 * 2 * math.pi - (idx * sweep + sweep / 2);
    if (GmMotion.reduced(context)) {
      _angle = AlwaysStoppedAnimation(end);
      setState(() {});
      Future.delayed(const Duration(milliseconds: 400), _settle);
      return;
    }
    _angle = Tween<double>(begin: 0, end: end)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward(from: 0);
  }

  bool _settled = false;
  void _settle() {
    if (!mounted || _settled) return;
    _settled = true;
    HapticFeedback.lightImpact();
    widget.onSettled();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final s = widget.state;
    final owned = s.wedges.toSet();
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, math.max(16, bottom)),
      child: Column(
        children: [
          QuizHud(lives: s.lives, score: s.score, onExit: widget.onExit),
          const SizedBox(height: 14),
          GmRise(
            index: 1,
            trigger: GmTrigger.mount,
            child: QuizQuesitoStrip(owned: owned),
          ),
          const SizedBox(height: 22),
          GmRise(
            index: 2,
            trigger: GmTrigger.mount,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: Text('Gira la ruleta',
                        textAlign: TextAlign.center,
                        style: GmText.largeTitle(color: gm.label)),
                  ),
                  const SizedBox(height: 4),
                  Text(quizWheelSubtitle(owned, s.categories),
                      textAlign: TextAlign.center,
                      style: GmText.body(color: gm.label2)),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final size = math.max(160.0,
                  math.min(316.0, math.min(c.maxWidth - 70, c.maxHeight - 40)));
              final btn = size * 92 / 316;
              return Center(
                child: SizedBox(
                  width: size,
                  height: size + 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 24,
                        width: size,
                        height: size,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, child) => Transform.rotate(
                              angle: _angle.value, child: child),
                          child: RepaintBoundary(
                            child: QuizBigWheel(size: size, owned: owned),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Center(child: QuizWheelPointer()),
                      ),
                      Positioned(
                        left: (size - btn) / 2,
                        top: 24 + (size - btn) / 2,
                        width: btn,
                        height: btn,
                        child: QuizBigPop(
                          child: _SpinButton(
                            enabled: !_wantSpin,
                            onTap: _onTapSpin,
                            fontSize: 19 * size / 316,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (owned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const QuizCheckSeal(size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Quesito ya conseguido: si cae, suma puntos',
                        textAlign: TextAlign.center,
                        style: GmText.meta(color: gm.label2)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SpinButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final double fontSize;
  const _SpinButton(
      {required this.enabled, required this.onTap, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'quiz-wheel-spin-button',
      button: true,
      enabled: enabled,
      label: 'Girar la ruleta',
      child: GmPressable(
        onTap: enabled ? onTap : null,
        pressedScale: 0.92,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: GmColors.accentFill,
            border: Border.all(color: gm.card, width: 4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xB3005A8C),
                  offset: Offset(0, 10),
                  blurRadius: 22,
                  spreadRadius: -8),
            ],
          ),
          alignment: Alignment.center,
          child: ExcludeSemantics(
            child: Text('Girar',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pregunta
// ═══════════════════════════════════════════════════════════════════════════

enum _Opt { idle, selected, ok, ko, dim }

/// Pregunta (fases `question` y `revealing`): cabecera con el quesito y el
/// anillo del reloj, la pregunta y cuatro respuestas; al resolver, panel de
/// acierto / fallo / sin tiempo con «Siguiente» (sin avance automático).
class QuizQuestionView extends StatelessWidget {
  final QuizGameState state;
  final ValueChanged<int> onAnswer;
  final VoidCallback onNext;
  final VoidCallback onExit;

  const QuizQuestionView({
    super.key,
    required this.state,
    required this.onAnswer,
    required this.onNext,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final q = state.question!;
    final quesito = quizQuesitoFor(q.categorySlug);
    final revealing = state.phase == QuizPhase.revealing;
    final result = state.result;
    final selected = state.selectedIndex;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final warn = !revealing && state.secondsLeft <= 5;
    final losing = revealing && result != null && !result.isCorrect;
    final name = q.categoryName.trim().isNotEmpty
        ? q.categoryName.trim()
        : quizCategoryName(q.categorySlug, state.categories);

    _Opt optState(int i) {
      if (revealing && result != null) {
        if (i == result.correctIndex) return _Opt.ok;
        if (i == selected && !result.isCorrect) return _Opt.ko;
        return _Opt.dim;
      }
      if (selected != null) return i == selected ? _Opt.selected : _Opt.idle;
      return _Opt.idle;
    }

    final canAnswer = !revealing &&
        selected == null &&
        !state.paused &&
        state.secondsLeft > 0;

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
                child: Column(
                  children: [
                    QuizHud(
                      lives: state.lives,
                      score: state.score,
                      onExit: onExit,
                      losing: losing,
                    ),
                    const SizedBox(height: 12),
                    QuizQuesitoStrip(
                        owned: state.wedges.toSet(),
                        size: 30,
                        gap: 7,
                        caption: false),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 22, 20, revealing ? 360 : math.max(60, bottom + 40)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GmRise(
                        index: 2,
                        trigger: GmTrigger.mount,
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: quesito.soft(gm.isDark),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: QuizGlyph(quesito.glyph,
                                  size: 28, color: quesito.ink(gm.isDark)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    [
                                      if (q.island.trim().isNotEmpty)
                                        'Quesito de ${q.island.trim()}',
                                      quizDifficultyLabel(q.difficulty),
                                    ].join(' · '),
                                    style: GmText.eyebrow(color: gm.label2),
                                  ),
                                  Text(name,
                                      style: GmText.poster(color: gm.label)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            QuizTimerRing(
                              secondsLeft: state.secondsLeft,
                              total: state.secondsTotal,
                              color: quesito.fill,
                              warn: warn,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GmRise(
                        index: 3,
                        trigger: GmTrigger.mount,
                        child: Semantics(
                          header: true,
                          child: Text(
                            q.question,
                            style: TextStyle(
                              fontSize: 24,
                              height: 30 / 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: gm.label,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < q.options.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        GmRise(
                          index: 4 + i,
                          trigger: GmTrigger.mount,
                          child: _OptionCard(
                            index: i,
                            text: q.options[i],
                            kind: optState(i),
                            onTap: canAnswer ? () => onAnswer(i) : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!revealing)
          Positioned(
            left: 24,
            right: 24,
            bottom: math.max(16, bottom + 4),
            child: IgnorePointer(
              child: Text(
                warn
                    ? '¡Corre, que se acaba el tiempo!'
                    : 'Cuanto antes aciertes, más puntos.',
                textAlign: TextAlign.center,
                style: GmText.meta(color: gm.label2),
              ),
            ),
          ),
        if (revealing && result != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: math.max(24, bottom),
            child: _RevealPanel(
              state: state,
              result: result,
              question: q,
              onNext: onNext,
            ),
          ),
      ],
    );
  }
}

/// Anillo del reloj en el color del quesito; rojo (`closedText`) con ≤ 5 s,
/// con un pequeño golpe en cada segundo final.
class QuizTimerRing extends StatelessWidget {
  final int secondsLeft;
  final int total;
  final Color color;
  final bool warn;
  const QuizTimerRing({
    super.key,
    required this.secondsLeft,
    required this.total,
    required this.color,
    required this.warn,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ring = warn ? gm.closedText : color;
    final frac = total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    final reduced = GmMotion.reduced(context);
    Widget dial = TweenAnimationBuilder<double>(
      tween: Tween(end: frac),
      duration: Duration(milliseconds: reduced ? 0 : 900),
      curve: Curves.linear,
      builder: (_, v, __) => CustomPaint(
        size: const Size.square(64),
        painter: _RingPainter(
            frac: secondsLeft == 0 ? 0 : v,
            color: ring,
            track: gm.fill,
            bg: gm.card),
      ),
    );
    if (warn && secondsLeft > 0) {
      dial = GmOnce(
        key: ValueKey(secondsLeft),
        duration: const Duration(milliseconds: 600),
        trigger: GmTrigger.mount,
        child: dial,
        builder: (_, t, c) => Transform.scale(
            scale: 1.12 - 0.12 * GmMotion.spring.transform(t), child: c),
      );
    }
    return Semantics(
      label: 'Quedan $secondsLeft segundos',
      liveRegion: warn,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              dial,
              Text('$secondsLeft',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: warn ? gm.closedText : gm.label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double frac;
  final Color color;
  final Color track;
  final Color bg;
  _RingPainter(
      {required this.frac,
      required this.color,
      required this.track,
      required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 26.0;
    canvas.drawCircle(c, r, Paint()..color = bg);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    if (frac > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * frac,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.frac != frac || o.color != color || o.track != track || o.bg != bg;
}

class _OptionCard extends StatelessWidget {
  final int index;
  final String text;
  final _Opt kind;
  final VoidCallback? onTap;
  const _OptionCard({
    required this.index,
    required this.text,
    required this.kind,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final sc = QuizStateColors.of(gm);
    final letter = 'ABCD'[index.clamp(0, 3)];
    Color bg = gm.card;
    Color letterBg = gm.fill;
    Color letterInk = gm.label2;
    Border? ring;
    List<BoxShadow>? shadow = gm.shadow1;
    Widget? tag;
    switch (kind) {
      case _Opt.ok:
        bg = sc.okSoft;
        letterBg = gm.greenText;
        letterInk = sc.onAccent;
        ring = Border.all(color: gm.greenText, width: 2);
        shadow = null;
        tag = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GmIcon(GmIcons.check, size: 16, color: gm.greenText),
            const SizedBox(width: 4),
            Text('Correcta',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: gm.greenText)),
          ],
        );
      case _Opt.ko:
        bg = sc.koSoft;
        letterBg = gm.closedText;
        letterInk = sc.onAccent;
        ring = Border.all(color: gm.closedText, width: 2);
        shadow = null;
        tag = Text('Tu respuesta',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: gm.closedText));
      case _Opt.dim:
        bg = gm.fill;
        shadow = null;
      case _Opt.selected:
        bg = gm.accentSoft;
        letterBg = gm.accent;
        letterInk = sc.onAccent;
        ring = Border.all(color: gm.accent, width: 2);
        shadow = null;
      case _Opt.idle:
        break;
    }
    final stateText = switch (kind) {
      _Opt.ok => ', correcta',
      _Opt.ko => ', tu respuesta, incorrecta',
      _Opt.selected => ', elegida',
      _ => '',
    };
    Widget card = Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: ring,
        boxShadow: shadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(letter,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: letterInk)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: gm.label)),
          ),
          if (tag != null) ...[const SizedBox(width: 8), tag],
        ],
      ),
    );
    if (kind == _Opt.ko) {
      card = GmOnce(
        duration: const Duration(milliseconds: 420),
        delay: const Duration(milliseconds: 150),
        trigger: GmTrigger.mount,
        child: card,
        builder: (_, t, c) => Transform.translate(
          offset: Offset(
              gmKeyframes(
                  t, const [(0, 0), (0.25, -6), (0.5, 5), (0.75, -3), (1, 0)]),
              0),
          child: c,
        ),
      );
    }
    return Semantics(
      identifier: 'quiz-question-option-$index',
      button: onTap != null,
      enabled: onTap != null,
      label: 'Respuesta $letter: $text$stateText',
      child: ExcludeSemantics(
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.98,
          child: card,
        ),
      ),
    );
  }
}

class _RevealPanel extends StatelessWidget {
  final QuizGameState state;
  final QuizAnswerResult result;
  final QuizQuestion question;
  final VoidCallback onNext;
  const _RevealPanel({
    required this.state,
    required this.result,
    required this.question,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final correct = result.isCorrect;
    final timeout = !correct && state.selectedIndex == null;
    final options = question.options;
    final answer =
        (result.correctIndex >= 0 && result.correctIndex < options.length)
            ? options[result.correctIndex]
            : null;
    final title = correct
        ? '¡Correcto!'
        : (timeout ? 'Se acabó el tiempo' : 'Casi, pero no');
    final sub = correct
        ? quizCorrectSubtitle(result)
        : (answer != null ? 'La correcta era $answer.' : '');
    final volcano = QuizVolcano(
      mood: correct
          ? QuizVolcanoMood.happy
          : (timeout ? QuizVolcanoMood.surprised : QuizVolcanoMood.sad),
      width: 76,
    );
    final quesito = quizQuesitoFor(question.categorySlug);
    final explanation = result.explanation?.trim();
    final reduced = GmMotion.reduced(context);

    final panel = Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: gm.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: gm.shadow2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                correct ? QuizHop(child: volcano) : QuizDroop(child: volcano),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GmText.title2(color: gm.label)),
                      if (sub.isNotEmpty)
                        Text(sub, style: GmText.body(color: gm.label2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (correct) ...[
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                QuizWinePoints('+${quizFormatInt(result.points)} puntos'),
                if (result.newWedge)
                  Container(
                    height: 30,
                    padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                    decoration: BoxDecoration(
                      color: quesito.soft(gm.isDark),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QuizBigPop(
                          child: QuizQuesera(
                            size: 22,
                            owned: {quesito.slug},
                            semanticsLabel: 'Quesito',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Quesito de ${quesito.short}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: quesito.ink(gm.isDark))),
                      ],
                    ),
                  ),
              ],
            ),
            if (explanation != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(explanation, style: GmText.body(color: gm.label)),
            ],
          ] else ...[
            if (explanation != null && explanation.isNotEmpty) ...[
              Text(explanation, style: GmText.body(color: gm.label)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                QuizCopas(lives: state.lives, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(quizLivesLeftText(state.lives),
                      style: GmText.meta(color: gm.label2)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          QuizCta(
            label: 'Siguiente',
            identifier: 'quiz-reveal-next-button',
            onTap: onNext,
          ),
        ],
      ),
    );

    if (reduced) return panel;
    return GmOnce(
      duration: const Duration(milliseconds: 560),
      trigger: GmTrigger.mount,
      child: panel,
      builder: (_, t, c) {
        final p = GmMotion.spring.transform(t);
        return Transform.translate(
          offset: Offset(0, 40 * (1 - p)),
          child: Transform.scale(scale: 0.98 + 0.02 * p, child: c),
        );
      },
    );
  }
}
