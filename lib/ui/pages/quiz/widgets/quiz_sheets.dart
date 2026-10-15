import 'package:flutter/material.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glyphs.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_ui.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wheels.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Hojas del juego (tablero `QuizHojas`).

// ── Cómo se juega ───────────────────────────────────────────────────────────

/// Textos de las 6 reglas (los segundos salen de las arenas reales).
List<(String, String)> quizRules() => [
      (
        'Gira la ruleta',
        'Cae en una de las 7 categorías y te toca una pregunta de esa categoría.'
      ),
      (
        'Gana los 7 quesitos',
        'Acierta una pregunta de cada categoría para llevarte su quesito. Con los 7 haces pleno.'
      ),
      (
        'Tienes 3 vidas',
        'Cada fallo o pregunta sin responder te cuesta una copa. Sin copas, se acaba la partida.'
      ),
      (
        'Juegas contra el reloj',
        '${quizTierSeconds(1)} segundos por pregunta en ${quizTierName(1)}, '
            '${quizTierSeconds(2)} en ${quizTierName(2)} y ${quizTierSeconds(3)} en '
            '${quizTierName(3)}. Cuanto antes aciertes, más puntos.'
      ),
      (
        'Encadena aciertos',
        'Cada 3 aciertos seguidos sumas un 20 % más, hasta el doble.'
      ),
      (
        'Conquista las islas',
        'Con cada pleno eliges una isla. Conquista las 7 y subes de arena: Marea, Volcán y Leyenda.'
      ),
    ];

Future<void> showQuizRulesSheet(BuildContext context) {
  return showQuizSheet<void>(context, (ctx) => const _RulesSheet());
}

class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final rules = quizRules();
    final folclore = quizQuesitoFor('folclore');
    final icons = <(Widget, Color)>[
      (QuizGlyph('ruleta', size: 18, color: gm.accent), gm.accentSoft),
      (
        QuizGlyph('quesito', size: 18, color: folclore.ink(gm.isDark)),
        folclore.soft(gm.isDark)
      ),
      (const QuizCopa(full: true, size: 20), gm.avTbg),
      (QuizGlyph('clock', size: 18, color: gm.warnText), gm.warnSoft),
      (QuizGlyph('racha', size: 18, color: gm.warnText), gm.warnSoft),
      (QuizGlyph('isla', size: 18, color: gm.greenText), gm.okSoft),
    ];
    return QuizSheet(
      title: 'Cómo se juega',
      closeIdentifier: 'quiz-rules-close-button',
      onClose: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GmCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < rules.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 62),
                        child: Container(height: 1, color: gm.sep),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: icons[i].$2,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: ExcludeSemantics(child: icons[i].$1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rules[i].$1,
                                    style: GmText.body17(
                                        color: gm.label, w: FontWeight.w600)),
                                const SizedBox(height: 1),
                                Text(rules[i].$2,
                                    style: GmText.sub(color: gm.label2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            QuizCta(
              label: 'Entendido',
              identifier: 'quiz-rules-ok-button',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ¿Salir de la partida? ───────────────────────────────────────────────────

enum QuizExitChoice { keepPlaying, leave, abandon }

/// Hoja «¿Salir de la partida?». Quien la abre pausa el reloj y lo reanuda si
/// vuelve `null` o [QuizExitChoice.keepPlaying].
Future<QuizExitChoice?> showQuizExitSheet(
  BuildContext context, {
  required QuizSession? session,
  required bool clockPaused,
}) {
  return showQuizSheet<QuizExitChoice>(
    context,
    (ctx) => _ExitSheet(session: session, clockPaused: clockPaused),
  );
}

class _ExitSheet extends StatelessWidget {
  final QuizSession? session;
  final bool clockPaused;
  const _ExitSheet({required this.session, required this.clockPaused});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final s = session;
    final n = (s?.wedges.length ?? 0).clamp(0, 7);
    final nav = Navigator.of(context);
    return QuizSheet(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('¿Salir de la partida?',
                        style: GmText.title2(color: gm.label)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Si sales, podrás continuarla luego. Si la abandonas, la pierdes.',
                    style: GmText.body(color: gm.label2),
                  ),
                ],
              ),
            ),
            if (s != null) ...[
              const SizedBox(height: 14),
              GmCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    QuizQuesera(
                        size: 48, owned: s.wedges.toSet(), center: '$n/7'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '$n de 7 quesitos · ${quizFormatInt(s.score)} puntos',
                              style: GmText.cardTitle(color: gm.label)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              QuizCopas(lives: s.lives, size: 15),
                              if (clockPaused) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                      'El reloj se para mientras decides',
                                      style: GmText.meta(color: gm.label2)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            QuizCta(
              label: 'Seguir jugando',
              identifier: 'quiz-exit-continue-button',
              onTap: () => nav.pop(QuizExitChoice.keepPlaying),
            ),
            const SizedBox(height: 8),
            QuizSoftCta(
              label: 'Salir y continuar luego',
              identifier: 'quiz-exit-leave-button',
              onTap: () => nav.pop(QuizExitChoice.leave),
            ),
            const SizedBox(height: 4),
            QuizDangerButton(
              label: 'Abandonar partida',
              identifier: 'quiz-exit-abandon-button',
              onTap: () => nav.pop(QuizExitChoice.abandon),
            ),
          ],
        ),
      ),
    );
  }
}

// ── «Nueva» con una partida en curso ────────────────────────────────────────

enum QuizNewGameChoice { resume, startNew }

/// Confirma empezar una partida nueva cuando hay otra en curso (la en curso
/// se abandona). `null` = cerrada sin elegir.
Future<QuizNewGameChoice?> showQuizNewGameSheet(
    BuildContext context, QuizSession active) {
  return showQuizSheet<QuizNewGameChoice>(
      context, (ctx) => _NewGameSheet(active: active));
}

class _NewGameSheet extends StatelessWidget {
  final QuizSession active;
  const _NewGameSheet({required this.active});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final n = active.wedges.length.clamp(0, 7);
    final nav = Navigator.of(context);
    return QuizSheet(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('¿Empezar una partida nueva?',
                  style: GmText.title2(color: gm.label)),
            ),
            const SizedBox(height: 4),
            Text(
              'Tienes una partida en curso con $n de 7 quesitos y ${quizFormatInt(active.score)} puntos. Si empiezas otra, la abandonas y no podrás continuarla.',
              style: GmText.body(color: gm.label2),
            ),
            const SizedBox(height: 18),
            QuizCta(
              label: 'Continuar mi partida',
              icon: GmIcons.play,
              identifier: 'quiz-new-resume-button',
              onTap: () => nav.pop(QuizNewGameChoice.resume),
            ),
            const SizedBox(height: 4),
            QuizDangerButton(
              label: 'Abandonarla y empezar otra',
              identifier: 'quiz-new-confirm-button',
              onTap: () => nav.pop(QuizNewGameChoice.startNew),
            ),
          ],
        ),
      ),
    );
  }
}
