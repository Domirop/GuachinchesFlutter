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

/// Lobby del juego (tablero `QuizInicio`): «¿Cuánto sabes de Canarias?» /
/// «Conquista Canarias» con Inicio · Historial · Ranking y la barra de cristal
/// Jugar / Nueva + Continuar / Jugar mi primera partida.
class QuizLobbyView extends StatefulWidget {
  final QuizGameState state;
  final VoidCallback onClose;
  final VoidCallback onHelp;
  final VoidCallback onPlay;
  final VoidCallback onNew;
  final ValueChanged<QuizSession> onResume;
  final VoidCallback onRetryLobby;
  final VoidCallback onRetryHistory;
  final VoidCallback onLoadRanking;
  final int initialTab;

  const QuizLobbyView({
    super.key,
    required this.state,
    required this.onClose,
    required this.onHelp,
    required this.onPlay,
    required this.onNew,
    required this.onResume,
    required this.onRetryLobby,
    required this.onRetryHistory,
    required this.onLoadRanking,
    this.initialTab = 0,
  });

  @override
  State<QuizLobbyView> createState() => _QuizLobbyViewState();
}

class _QuizLobbyViewState extends State<QuizLobbyView> {
  late int _tab = widget.initialTab;
  final _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final s = _scroll.hasClients && _scroll.offset > 4;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
    if (_tab == 2) _maybeLoadRanking();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadRanking() {
    final s = widget.state;
    if (!s.rankingLoaded && !s.rankingLoading && !s.rankingFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadRanking();
      });
    }
  }

  void _select(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
    if (i == 2) _maybeLoadRanking();
  }

  bool get _loading {
    final s = widget.state;
    return s.phase == QuizPhase.loading ||
        (s.phase == QuizPhase.idle && s.categories.isEmpty && !s.lobbyFailed);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final s = widget.state;
    final top = MediaQuery.paddingOf(context).top;
    final cta = quizLobbyCta(stats: s.stats, active: s.activeSession);
    final showDock = !_loading && !s.lobbyFailed;

    final Widget content = switch (_tab) {
      1 => _history(context),
      2 => _ranking(context),
      _ => _inicio(context),
    };

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(16, top + 8 + 44 + 8, 16,
                QuizBottomBar.scrollPadding(context) + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GmRise(
                  trigger: GmTrigger.mount,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GmEyebrow(
                          leading: QuizQuesera(
                            size: 16,
                            owned: {for (final q in kQuizQuesitos) q.slug},
                            semanticsLabel: 'Quiz',
                          ),
                          text: '¿Cuánto sabes de Canarias?',
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          header: true,
                          child: Text('Conquista Canarias',
                              style: GmText.largeTitle(color: gm.label)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GmRise(
                  index: 1,
                  trigger: GmTrigger.mount,
                  child: QuizSegmented(
                    labels: const ['Inicio', 'Historial', 'Ranking'],
                    identifiers: const [
                      'quiz-lobby-tab-inicio',
                      'quiz-lobby-tab-historial',
                      'quiz-lobby-tab-ranking',
                    ],
                    index: _tab,
                    onChanged: _select,
                  ),
                ),
                const SizedBox(height: 14),
                content,
              ],
            ),
          ),
        ),
        GmTopScrim(visible: _scrolled, extra: 8 + 44 + 8),
        Positioned(
          left: 16,
          right: 16,
          top: top + 8,
          child: QuizTopBar(
            left: GmToolbarButton(
              icon: GmIcons.close,
              light: true,
              semanticLabel: 'Cerrar el juego',
              identifier: 'quiz-lobby-close-button',
              onTap: widget.onClose,
            ),
            right: GmToolbarButton(
              icon: QuizGlyphs.svg('help', width: 2.2),
              light: true,
              iconSize: 20,
              semanticLabel: 'Cómo se juega',
              identifier: 'quiz-lobby-help-button',
              onTap: widget.onHelp,
            ),
          ),
        ),
        if (showDock)
          Positioned.fill(
            child: QuizBottomBar(
              children: [
                if (cta == QuizLobbyCta.resume)
                  QuizSoftCta(
                    label: 'Nueva',
                    expand: false,
                    identifier: 'quiz-lobby-new-button',
                    onTap: widget.onNew,
                  ),
                Expanded(
                  child: QuizCta(
                    label: switch (cta) {
                      QuizLobbyCta.firstGame => 'Jugar mi primera partida',
                      QuizLobbyCta.resume => 'Continuar partida',
                      QuizLobbyCta.play => 'Jugar',
                    },
                    icon: GmIcons.play,
                    identifier: 'quiz-lobby-play-button',
                    onTap: cta == QuizLobbyCta.resume
                        ? () => widget.onResume(s.activeSession!)
                        : widget.onPlay,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Inicio ────────────────────────────────────────────────────────────────

  Widget _inicio(BuildContext context) {
    final s = widget.state;
    if (s.lobbyFailed && !_loading) {
      return QuizStateCard(
        identifier: 'quiz-lobby-error',
        title: 'No pudimos cargar el juego',
        text: 'Revisa tu conexión e inténtalo de nuevo.',
        action: 'Reintentar',
        actionIdentifier: 'quiz-lobby-retry-button',
        onAction: widget.onRetryLobby,
      );
    }
    if (_loading) return const _InicioSkeleton();
    final first = quizIsFirstTime(stats: s.stats, active: s.activeSession);
    final conquest = s.conquest ?? QuizConquest.empty();
    final active = s.activeSession;
    final children = <Widget>[
      _ConquestCard(conquest: conquest, first: first),
      if (first) const _WelcomeCard(),
      if (!first && active != null && active.isActive)
        _ActiveGameCard(session: active, onTap: () => widget.onResume(active)),
      if (!first && s.stats != null) _MarksSection(stats: s.stats!),
      _RulesRow(onTap: widget.onHelp),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          GmRise(index: 2 + i, trigger: GmTrigger.mount, child: children[i]),
        ],
      ],
    );
  }

  // ── Historial ─────────────────────────────────────────────────────────────

  Widget _history(BuildContext context) {
    final gm = GmColors.of(context);
    final s = widget.state;
    if (_loading) return const _ListSkeleton(rows: 4, ranking: false);
    if (s.historyFailed) {
      return QuizStateCard(
        identifier: 'quiz-history-error',
        title: 'No pudimos cargar tus partidas',
        text: 'Revisa tu conexión e inténtalo de nuevo.',
        action: 'Reintentar',
        actionIdentifier: 'quiz-history-retry-button',
        onAction: widget.onRetryHistory,
      );
    }
    if (s.history.isEmpty) {
      return const QuizStateCard(
        identifier: 'quiz-history-empty',
        title: 'Aún no has jugado',
        text:
            'Tus partidas terminadas aparecerán aquí, con sus quesitos y sus puntos.',
        mood: QuizVolcanoMood.happy,
        bounce: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GmRise(
          index: 2,
          trigger: GmTrigger.mount,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(quizHistoryHeader(s.history, s.stats),
                style: GmText.poster(color: gm.label)),
          ),
        ),
        const SizedBox(height: 8),
        GmRise(
          index: 3,
          trigger: GmTrigger.mount,
          child: _Grouped(
            inset: 72,
            children: [for (final h in s.history) _HistoryRow(h)],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Las partidas abandonadas no cuentan. La que tienes en curso aparecerá aquí cuando termine.',
            style: GmText.meta(color: gm.label2),
          ),
        ),
      ],
    );
  }

  // ── Ranking ───────────────────────────────────────────────────────────────

  Widget _ranking(BuildContext context) {
    final gm = GmColors.of(context);
    final s = widget.state;
    if (s.rankingFailed && !s.rankingLoading) {
      return QuizStateCard(
        identifier: 'quiz-ranking-error',
        title: 'No pudimos cargar el ranking',
        text: 'Revisa tu conexión e inténtalo de nuevo.',
        action: 'Reintentar',
        actionIdentifier: 'quiz-ranking-retry-button',
        onAction: widget.onLoadRanking,
      );
    }
    if (!s.rankingLoaded || s.rankingLoading) {
      return const _ListSkeleton(rows: 6, ranking: true);
    }
    final me = quizMyPlace(s.ranking, s.stats);
    final count = s.ranking.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GmRise(
          index: 1,
          trigger: GmTrigger.mount,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child:
                      Text('Por puntos', style: GmText.poster(color: gm.label)),
                ),
                if (count > 0)
                  Text(
                      count >= 50
                          ? 'Top 50'
                          : quizCount(count, 'jugador', 'jugadores'),
                      style: GmText.meta(color: gm.label2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GmRise(index: 2, trigger: GmTrigger.mount, child: _MyPlaceCard(me)),
        const SizedBox(height: 10),
        if (s.ranking.isNotEmpty)
          GmRise(
            index: 3,
            trigger: GmTrigger.mount,
            child: _Grouped(
              inset: 104,
              children: [for (final e in s.ranking) _RankingRow(e)],
            ),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Puntos de todas tus partidas. En el ranking solo sale tu nombre de pila.',
            style: GmText.meta(color: gm.label2),
          ),
        ),
      ],
    );
  }
}

// ── Piezas del Inicio ───────────────────────────────────────────────────────

class _ConquestCard extends StatelessWidget {
  final QuizConquest conquest;
  final bool first;
  const _ConquestCard({required this.conquest, required this.first});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final mc = QuizMapColors.of(gm);
    final n = conquest.conqueredCount;
    final total = conquest.total == 0 ? 7 : conquest.total;
    final (a, b, c) = quizConquestFoot(conquest);
    final chipText =
        TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: gm.label);
    return Semantics(
      container: true,
      label: 'Conquista',
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
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: QuizPill(
                          height: 34,
                          padding: const EdgeInsets.fromLTRB(5, 0, 12, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QuizMedal(
                                  kind: quizTierMedal(conquest.tier), size: 24),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                    'Arena ${quizTierName(conquest.tier)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: chipText),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: QuizPill(
                          height: 34,
                          child: Text('$n de $total islas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: chipText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  QuizIslandMap(owned: conquest.conqueredIslands.toSet()),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (first)
                    Text(
                      'Haz pleno —los 7 quesitos en una partida— y conquista tu primera isla.',
                      style: GmText.body(color: gm.label2),
                    )
                  else ...[
                    QuizProgress7(value: n, total: total),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: a),
                        TextSpan(
                            text: b,
                            style: TextStyle(
                                color: gm.label, fontWeight: FontWeight.w600)),
                        TextSpan(text: c),
                      ]),
                      style: GmText.body(color: gm.label2),
                    ),
                  ],
                  const SizedBox(height: 12),
                  QuizLadder(tier: conquest.tier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveGameCard extends StatelessWidget {
  final QuizSession session;
  final VoidCallback onTap;
  const _ActiveGameCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final n = session.wedges.length.clamp(0, 7);
    return GmPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticsIdentifier: 'quiz-lobby-resume-card',
      semanticsLabel:
          'Partida en curso: $n de 7 quesitos, ${session.lives} vidas, ${quizFormatInt(session.score)} puntos. Continuar',
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: ExcludeSemantics(
          child: Row(
            children: [
              QuizQuesera(
                  size: 64,
                  owned: session.wedges.toSet(),
                  center: '$n/7',
                  pop: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partida en curso',
                        style: GmText.eyebrow(color: gm.label2)),
                    Text('$n de 7 quesitos',
                        style: GmText.guideTitle(color: gm.label)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        QuizCopas(lives: session.lives, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                              '· ${quizFormatInt(session.score)} puntos',
                              style: GmText.sub(color: gm.label2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarksSection extends StatelessWidget {
  final QuizStats stats;
  const _MarksSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final progress = quizRankProgress(stats);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            header: true,
            child: Text('Tus marcas', style: GmText.eyebrow(color: gm.label2)),
          ),
        ),
        const SizedBox(height: 8),
        GmCard(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    _Stat(quizFormatInt(stats.totalPoints), 'puntos'),
                    const _VSep(),
                    _Stat(quizFormatInt(stats.gamesWon),
                        stats.gamesWon == 1 ? 'pleno' : 'plenos'),
                    const _VSep(),
                    _Stat(quizFormatInt(stats.bestStreak), 'mejor racha'),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(8, 14, 8, 0),
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: gm.sep))),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: gm.warnSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const GmGlyph(GmGlyphKind.medalla, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rango ${quizRankName(stats.rank.name)}',
                              style: GmText.body17(
                                  color: gm.label, w: FontWeight.w500)),
                          Text(progress ?? 'Has llegado al rango más alto.',
                              style: GmText.meta(color: gm.label2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

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
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: gm.label)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.meta(color: gm.label2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VSep extends StatelessWidget {
  const _VSep();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: GmColors.of(context).sep,
      );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
      child: Row(
        children: [
          const QuizHop(
              child: QuizVolcano(mood: QuizVolcanoMood.happy, width: 78)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Bienvenido al reto!',
                    style: GmText.poster(color: gm.label)),
                const SizedBox(height: 4),
                Text(
                  'Gira la ruleta, acierta una pregunta de cada categoría y llévate los 7 quesitos.',
                  style: GmText.body(color: gm.label2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesRow extends StatelessWidget {
  final VoidCallback onTap;
  const _RulesRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticsIdentifier: 'quiz-lobby-rules-row',
      semanticsLabel: 'Cómo se juega',
      child: GmCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: gm.fill,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: QuizGlyph('help', size: 18, color: gm.label),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cómo se juega',
                          style: GmText.body17(
                              color: gm.label, w: FontWeight.w500)),
                      Text('Ruleta, quesitos, vidas y arenas',
                          style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Listas agrupadas ────────────────────────────────────────────────────────

class _Grouped extends StatelessWidget {
  final List<Widget> children;
  final double inset;
  const _Grouped({required this.children, required this.inset});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.only(left: inset),
                child: Container(height: 1, color: gm.sep),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final QuizSessionSummary h;
  const _HistoryRow(this.h);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final n = h.isWon ? 7 : h.wedges.length.clamp(0, 7);
    final title = h.isWon ? 'Pleno' : '$n de 7 quesitos';
    final sub = quizHistorySub(h);
    return Semantics(
      label: '$title, $sub, ${quizFormatInt(h.score)} puntos',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                QuizQuesera(
                  size: 44,
                  owned: h.isWon
                      ? {for (final q in kQuizQuesitos) q.slug}
                      : h.wedges.toSet(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(title,
                                style: GmText.body17(
                                    color: gm.label, w: FontWeight.w600)),
                          ),
                          if (h.isWon) ...[
                            const SizedBox(width: 6),
                            const GmGlyph(GmGlyphKind.medalla, size: 18),
                          ],
                        ],
                      ),
                      Text(sub, style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(quizFormatInt(h.score),
                        style: TextStyle(
                            fontSize: 17,
                            height: 22 / 17,
                            fontWeight: FontWeight.w700,
                            color: gm.label)),
                    Text('puntos',
                        style: TextStyle(
                            fontSize: 12, height: 16 / 12, color: gm.label2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar con inicial (tintes A/T/P por puesto).
class _Avatar extends StatelessWidget {
  final String text;
  final Color bg;
  final Color ink;
  const _Avatar(this.text, this.bg, this.ink);

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(text,
            maxLines: 1,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
      );
}

class _Position extends StatelessWidget {
  final int position;
  const _Position(this.position);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    if (position >= 1 && position <= 3) {
      final kind = const [
        QuizMedalKind.gold,
        QuizMedalKind.silver,
        QuizMedalKind.bronze
      ][position - 1];
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            shape: BoxShape.circle, gradient: quizMedalGradient(kind)),
        alignment: Alignment.center,
        child: Text('$position',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3A2A12))),
      );
    }
    return SizedBox(
      width: 30,
      child: Text(position > 0 ? '$position' : '–',
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: gm.label2)),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final QuizRankingEntry e;
  const _RankingRow(this.e);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final name = quizFirstName(e.name);
    final tints = [
      (gm.avAbg, gm.avAink),
      (gm.avTbg, gm.avTink),
      (gm.avPbg, gm.avPink),
    ][e.position % 3];
    final sub = quizRankingSub(e);
    return Semantics(
      label:
          'Puesto ${e.position}: $name, $sub, ${quizFormatInt(e.totalPoints)} puntos',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            child: Row(
              children: [
                _Position(e.position),
                const SizedBox(width: 12),
                _Avatar(quizInitial(name), tints.$1, tints.$2),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.body17(
                              color: gm.label, w: FontWeight.w600)),
                      Text(sub, style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(quizFormatInt(e.totalPoints),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: gm.label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyPlaceCard extends StatelessWidget {
  final QuizMyPlace me;
  const _MyPlaceCard(this.me);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'quiz-ranking-me-card',
      label:
          'Tu puesto${me.position != null ? ' ${me.position}' : ''}. ${me.subtitle}',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
          decoration: BoxDecoration(
            color: gm.card,
            borderRadius: BorderRadius.circular(GmRadius.card),
            border: Border.all(color: GmColors.gold, width: 1.5),
            boxShadow: gm.shadow1,
          ),
          child: Row(
            children: [
              _Position(me.position ?? 0),
              const SizedBox(width: 12),
              const _Avatar('Tú', GmColors.wine, Color(0xFFE8CF9A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu puesto',
                        style:
                            GmText.body17(color: gm.label, w: FontWeight.w700)),
                    Text(me.subtitle, style: GmText.meta(color: gm.label2)),
                  ],
                ),
              ),
              if (me.points != null) ...[
                const SizedBox(width: 8),
                Text(quizFormatInt(me.points!),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: gm.label)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Esqueletos ──────────────────────────────────────────────────────────────

class _InicioSkeleton extends StatelessWidget {
  const _InicioSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'quiz-lobby-loading',
      label: 'Cargando',
      child: const ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GmCard(
              radius: GmRadius.guide,
              padding: EdgeInsets.fromLTRB(6, 6, 6, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuizSkel(height: 214, radius: 22),
                  SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QuizSkel(height: 8, radius: 4),
                        SizedBox(height: 10),
                        FractionallySizedBox(
                            widthFactor: 0.78,
                            child: QuizSkel(height: 16, radius: 8)),
                        SizedBox(height: 10),
                        QuizSkel(height: 30, radius: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            GmCard(
              padding: EdgeInsets.fromLTRB(14, 14, 16, 14),
              child: Row(
                children: [
                  QuizSkel(width: 64, height: 64, radius: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                            widthFactor: 0.4, child: QuizSkel(height: 12)),
                        SizedBox(height: 8),
                        FractionallySizedBox(
                            widthFactor: 0.7, child: QuizSkel(height: 16)),
                        SizedBox(height: 8),
                        FractionallySizedBox(
                            widthFactor: 0.55, child: QuizSkel(height: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            GmCard(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(child: QuizSkel(height: 50)),
                  SizedBox(width: 12),
                  Expanded(child: QuizSkel(height: 50)),
                  SizedBox(width: 12),
                  Expanded(child: QuizSkel(height: 50)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final int rows;
  final bool ranking;
  const _ListSkeleton({required this.rows, required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              widthFactor: ranking ? 0.4 : 0.52,
              child: const QuizSkel(height: 24, radius: 8),
            ),
            const SizedBox(height: 10),
            GmCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < rows; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          if (ranking) ...[
                            const QuizSkel(width: 30, height: 30, radius: 15),
                            const SizedBox(width: 12),
                          ],
                          QuizSkel(
                              width: ranking ? 36 : 44,
                              height: ranking ? 36 : 44,
                              radius: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FractionallySizedBox(
                                    widthFactor: 0.55,
                                    child: QuizSkel(height: 15)),
                                SizedBox(height: 7),
                                FractionallySizedBox(
                                    widthFactor: 0.35,
                                    child: QuizSkel(height: 12)),
                              ],
                            ),
                          ),
                          const QuizSkel(width: 50, height: 17),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
