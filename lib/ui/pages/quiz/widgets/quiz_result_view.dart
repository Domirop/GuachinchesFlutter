import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/quiz_logic.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glyphs.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_island_map.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_ui.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wheels.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Fin de partida (tablero `QuizResultado`). Pleno → elegir isla →
/// conquistada (o «¡Subes a la arena …!» si completa las 7). Derrota con los
/// quesitos que faltaron. El confeti cae una sola vez.
class QuizResultView extends StatefulWidget {
  final QuizGameState state;
  final ValueChanged<String> onConquer;
  final VoidCallback onHome;
  final VoidCallback onPlayAgain;
  final ValueChanged<String> onShare;

  const QuizResultView({
    super.key,
    required this.state,
    required this.onConquer,
    required this.onHome,
    required this.onPlayAgain,
    required this.onShare,
  });

  @override
  State<QuizResultView> createState() => _QuizResultViewState();
}

enum _Kind { pick, conquered, ascend, simpleWin, lost }

class _QuizResultViewState extends State<QuizResultView> {
  String? _selected;

  _Kind get _kind {
    final s = widget.state;
    if (s.phase == QuizPhase.lost) return _Kind.lost;
    final r = s.conquerResult;
    if (r != null) return r.promoted ? _Kind.ascend : _Kind.conquered;
    final c = s.conquest;
    if (c != null && c.remaining.isNotEmpty) return _Kind.pick;
    return _Kind.simpleWin;
  }

  String _islandName(String slug) {
    final c = widget.state.conquerResult?.conquest ?? widget.state.conquest;
    for (final i in c?.islands ?? const <QuizIsland>[]) {
      if (i.slug == slug && i.name.trim().isNotEmpty) return i.name.trim();
    }
    return quizIslandName(slug);
  }

  String _shareText(_Kind k) {
    final s = widget.state;
    final pts = quizFormatInt(s.session?.score ?? 0);
    const tail = ' ¿Cuánto sabes tú de Canarias? — Dónde Comer Canarias';
    switch (k) {
      case _Kind.conquered:
        return 'He conquistado ${_islandName(s.conquerResult!.island)}.$tail';
      case _Kind.ascend:
        return 'He conquistado las 7 islas y subo a la arena ${quizTierName(s.conquerResult!.conquest.tier)}.$tail';
      case _Kind.lost:
        return 'He conseguido ${s.wedges.length} de 7 quesitos y $pts puntos.$tail';
      case _Kind.pick:
      case _Kind.simpleWin:
        return 'He hecho pleno: 7 de 7 quesitos y $pts puntos.$tail';
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final top = MediaQuery.paddingOf(context).top;
    final s = widget.state;

    final Widget body = switch (kind) {
      _Kind.pick => _pick(context),
      _Kind.conquered => _conquered(context),
      _Kind.ascend => _ascend(context),
      _Kind.simpleWin => _simpleWin(context),
      _Kind.lost => _lost(context),
    };

    final Widget dock;
    if (kind == _Kind.pick) {
      final sel = _selected;
      dock = QuizBottomBar(children: [
        Expanded(
          child: sel == null
              ? const QuizSoftCta(label: 'Elige una isla')
              : QuizCta(
                  label: 'Conquistar ${_islandName(sel)}',
                  identifier: 'quiz-result-conquer-button',
                  leading: s.conquering
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const QuizGlyph('bandera',
                          size: 18, color: Colors.white, strokeWidth: 2.2),
                  onTap: s.conquering ? null : () => widget.onConquer(sel),
                ),
        ),
      ]);
    } else {
      final again = kind == _Kind.ascend
          ? 'Jugar en ${quizTierName(s.conquerResult!.conquest.tier)}'
          : 'Jugar otra vez';
      dock = QuizBottomBar(children: [
        QuizSoftCta(
          label: 'Inicio',
          expand: false,
          identifier: 'quiz-result-home-button',
          onTap: widget.onHome,
        ),
        Expanded(
          child: QuizCta(
            label: again,
            identifier: 'quiz-result-again-button',
            onTap: widget.onPlayAgain,
          ),
        ),
      ]);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                16, top + 8, 16, QuizBottomBar.scrollPadding(context) + 12),
            child: body,
          ),
        ),
        if (kind == _Kind.pick ||
            kind == _Kind.simpleWin ||
            kind == _Kind.ascend)
          Positioned.fill(
            child: QuizConfetti(
                key: ValueKey(kind),
                seed: kind == _Kind.ascend ? 7 : 3,
                count: kind == _Kind.ascend ? 30 : 26),
          ),
        Positioned(
          left: 16,
          right: 16,
          top: top + 8,
          child: QuizTopBar(
            left: GmToolbarButton(
              icon: GmIcons.close,
              light: true,
              semanticLabel: 'Volver al inicio del juego',
              identifier: 'quiz-result-close-button',
              onTap: widget.onHome,
            ),
            right: GmToolbarButton(
              icon: GmIcons.share,
              light: true,
              semanticLabel: 'Compartir',
              identifier: 'quiz-result-share-button',
              onTap: () => widget.onShare(_shareText(kind)),
            ),
          ),
        ),
        Positioned.fill(child: dock),
      ],
    );
  }

  // ── Pleno ─────────────────────────────────────────────────────────────────

  Widget _hero(BuildContext context) {
    final gm = GmColors.of(context);
    final se = widget.state.session;
    final all = {for (final q in kQuizQuesitos) q.slug};
    final parts = [
      '7 de 7 quesitos',
      '${quizFormatInt(se?.score ?? 0)} puntos',
      if ((se?.bestStreak ?? 0) > 0) 'mejor racha ${se!.bestStreak}',
    ];
    return Column(
      children: [
        SizedBox(
          width: 124,
          height: 124,
          child: Stack(
            alignment: Alignment.center,
            children: [
              QuizQuesera(
                  size: 96,
                  owned: all,
                  center: '7/7',
                  pop: true,
                  semanticsLabel: '7 de 7 quesitos: pleno'),
              const QuizSparks(size: 124),
            ],
          ),
        ),
        Semantics(
          header: true,
          child: Text('¡Pleno!',
              textAlign: TextAlign.center,
              style: GmText.largeTitle(color: gm.label)),
        ),
        const SizedBox(height: 2),
        Text(parts.join(' · '),
            textAlign: TextAlign.center, style: GmText.body(color: gm.label2)),
      ],
    );
  }

  Widget _pick(BuildContext context) {
    final gm = GmColors.of(context);
    final mc = QuizMapColors.of(gm);
    final s = widget.state;
    final c = s.conquest!;
    final owned = c.conqueredIslands.toSet();
    final free = [
      for (final slug in kQuizIslandOrder)
        if (c.islands.any((i) => i.slug == slug) && !owned.contains(slug)) slug,
      for (final i in c.islands)
        if (!kQuizIslandOrder.contains(i.slug) && !owned.contains(i.slug))
          i.slug,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _hero(context),
        const SizedBox(height: 22),
        GmRise(
          index: 4,
          trigger: GmTrigger.mount,
          child: GmCard(
            radius: GmRadius.guide,
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Elige la isla que quieres conquistar',
                            style: GmText.poster(color: gm.label)),
                      ),
                      Text('Toca una isla en el mapa o en la lista.',
                          style: GmText.sub(color: gm.label2)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    gradient: mc.sea,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
                  child: QuizIslandMap(
                    owned: owned,
                    selected: _selected,
                    selectable: free.toSet(),
                    onSelect: s.conquering
                        ? null
                        : (slug) => setState(() => _selected = slug),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slug in free)
                        _IslandChip(
                          slug: slug,
                          label: _islandName(slug),
                          selected: slug == _selected,
                          onTap: s.conquering
                              ? null
                              : () => setState(() => _selected = slug),
                        ),
                    ],
                  ),
                ),
                if (s.error != null && !s.conquering) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                          'No pudimos conquistar la isla. Revisa tu conexión e inténtalo de nuevo.',
                          style: GmText.sub(color: gm.closedText)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _simpleWin(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      children: [
        const SizedBox(height: 40),
        _hero(context),
        const SizedBox(height: 16),
        Text('Los puntos de esta partida ya suman en el ranking.',
            textAlign: TextAlign.center, style: GmText.meta(color: gm.label2)),
      ],
    );
  }

  Widget _conquered(BuildContext context) {
    final gm = GmColors.of(context);
    final mc = QuizMapColors.of(gm);
    final r = widget.state.conquerResult!;
    final c = r.conquest;
    final name = _islandName(r.island);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 52),
        GmRise(
          trigger: GmTrigger.mount,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GmEyebrow(
                  leading: QuizMedal(kind: quizTierMedal(c.tier), size: 18),
                  text: 'Arena ${quizTierName(c.tier)}',
                ),
                Semantics(
                  header: true,
                  child: Text('¡$name, conquistada!',
                      style: GmText.largeTitle(color: gm.label)),
                ),
                const SizedBox(height: 2),
                Text(quizConqueredSubtitle(c),
                    style: GmText.body(color: gm.label2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        GmRise(
          index: 2,
          trigger: GmTrigger.mount,
          child: GmCard(
            radius: GmRadius.guide,
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: mc.sea,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 34, 14, 14),
                  child: QuizIslandMap(
                    owned: c.conqueredIslands.toSet(),
                    fresh: r.island,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      QuizProgress7(
                          value: c.conqueredCount,
                          total: c.total == 0 ? 7 : c.total),
                      const SizedBox(height: 12),
                      QuizLadder(tier: c.tier),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        GmRise(
          index: 4,
          trigger: GmTrigger.mount,
          child: _ChallengeCard(
            quote: '«He conquistado $name. ¿Cuánto sabes tú de Canarias?»',
            onShare: () => widget.onShare(_shareText(_Kind.conquered)),
          ),
        ),
      ],
    );
  }

  Widget _ascend(BuildContext context) {
    final gm = GmColors.of(context);
    final mc = QuizMapColors.of(gm);
    final r = widget.state.conquerResult!;
    final tier = r.conquest.tier;
    final prev = quizTierName(math.max(1, tier - 1));
    final name = quizTierName(tier);
    final secs = quizTierSeconds(tier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 52),
        GmRise(
          trigger: GmTrigger.mount,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              color: GmColors.wine,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: gm.wineEdge),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xB32A0E14),
                    offset: Offset(0, 14),
                    blurRadius: 30,
                    spreadRadius: -16),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 128,
                  height: 128,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QuizBigPop(
                          child:
                              QuizMedal(kind: quizTierMedal(tier), size: 96)),
                      const QuizSparks(size: 128),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Arena $prev completada',
                    textAlign: TextAlign.center,
                    style: GmText.eyebrow(color: GmColors.gold)),
                Semantics(
                  header: true,
                  child: Text('¡Subes a la arena $name!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 30,
                          height: 36 / 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          color: GmColors.creamHi)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Has conquistado las 7 islas. En $name las preguntas son más difíciles y tienes $secs segundos para cada una.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, height: 21 / 15, color: GmColors.cream),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        GmRise(
          index: 3,
          trigger: GmTrigger.mount,
          child: GmCard(
            radius: GmRadius.guide,
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: mc.sea,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
                  child: QuizIslandMap(owned: kQuizIslandOrder.toSet()),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: QuizLadder(tier: tier),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Derrota ───────────────────────────────────────────────────────────────

  Widget _lost(BuildContext context) {
    final gm = GmColors.of(context);
    final s = widget.state;
    final owned = s.wedges.toSet();
    final n = owned.length.clamp(0, 7);
    final missing = quizMissingNames(owned, s.categories);
    final missText = n == 0
        ? 'Esta vez no cayó ningún quesito.'
        : 'Te faltaron ${quizJoin(missing)}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 56),
        const Center(
          child: QuizDroop(
              child: QuizVolcano(mood: QuizVolcanoMood.sad, width: 132)),
        ),
        const SizedBox(height: 8),
        GmRise(
          index: 1,
          trigger: GmTrigger.mount,
          child: Semantics(
            header: true,
            child: Text('Fin de la partida',
                textAlign: TextAlign.center,
                style: GmText.largeTitle(color: gm.label)),
          ),
        ),
        const SizedBox(height: 4),
        GmRise(
          index: 2,
          trigger: GmTrigger.mount,
          child: Text('Te quedaste sin vidas. A la próxima, la isla es tuya.',
              textAlign: TextAlign.center,
              style: GmText.body(color: gm.label2)),
        ),
        const SizedBox(height: 26),
        GmRise(
          index: 3,
          trigger: GmTrigger.mount,
          child: GmCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    QuizQuesera(
                        size: 72,
                        owned: owned,
                        center: '$n/7',
                        pop: true,
                        semanticsLabel: '$n de 7 quesitos'),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$n de 7 quesitos',
                              style: GmText.poster(color: gm.label)),
                          const SizedBox(height: 2),
                          Text(missText, style: GmText.body(color: gm.label2)),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: gm.sep))),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _ResultStat(quizFormatInt(s.score), 'puntos'),
                        Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: gm.sep),
                        _ResultStat(
                            '${s.session?.bestStreak ?? 0}', 'mejor racha'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('Los puntos de esta partida ya suman en el ranking.',
            textAlign: TextAlign.center, style: GmText.meta(color: gm.label2)),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  const _ResultStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Expanded(
      child: Semantics(
        label: '$value $label',
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: gm.label)),
              Text(label, style: GmText.meta(color: gm.label2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip de isla de 44 (elegir isla).
class _IslandChip extends StatelessWidget {
  final String slug;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _IslandChip({
    required this.slug,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'quiz-result-island-$slug',
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.95,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? gm.accentSoft : gm.fill,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  GmIcon(GmIcons.check, size: 14, color: gm.accent),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? gm.accent : gm.label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta vino «Reta a tus amigos».
class _ChallengeCard extends StatelessWidget {
  final String quote;
  final VoidCallback onShare;
  const _ChallengeCard({required this.quote, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: GmColors.wine,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: gm.wineEdge),
        boxShadow: const [
          BoxShadow(
              color: Color(0xB32A0E14),
              offset: Offset(0, 14),
              blurRadius: 30,
              spreadRadius: -16),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reta a tus amigos',
                    style: GmText.eyebrow(color: GmColors.gold)),
                const SizedBox(height: 3),
                Text(quote,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: FontWeight.w600,
                        color: GmColors.creamHi)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            identifier: 'quiz-result-challenge-share-button',
            button: true,
            label: 'Compartir',
            child: ExcludeSemantics(
              child: GmPressable(
                onTap: onShare,
                pressedScale: 0.95,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x24FFF6E6),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x4DF2E8D5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GmIcon(GmIcons.share, size: 16, color: GmColors.creamHi),
                      const SizedBox(width: 6),
                      const Text('Compartir',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: GmColors.creamHi)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
