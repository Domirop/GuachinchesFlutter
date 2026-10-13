import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_my_votes_page.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_header.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Ranking (tablero EncuestaRanking): «Así va la votación» / «Ganadores
/// 2026», control segmentado (se fija bajo la barra al hacer scroll),
/// tarjeta vino con la cuenta atrás, podio en vino con puestos compartidos
/// y la lista «Del 4.º en adelante».
class PremiosRankingPage extends StatefulWidget {
  final PremiosRankingController? controller;
  final PremiosCategory initialCategory;
  final DateTime Function()? clock;

  /// Se llama al refrescar (el Inicio viejo recarga su vista previa).
  final VoidCallback? onRefresh;

  const PremiosRankingPage({
    super.key,
    this.controller,
    this.initialCategory = PremiosCategory.tradicional,
    this.clock,
    this.onRefresh,
  });

  @override
  State<PremiosRankingPage> createState() => _PremiosRankingPageState();
}

class _PremiosRankingPageState extends State<PremiosRankingPage> {
  late final PremiosRankingController _c;
  late final bool _owned;
  late PremiosCategory _tab = widget.initialCategory;
  final _scroll = ScrollController();
  final _segKey = GlobalKey();
  double _offset = 0;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _owned = widget.controller == null;
    _c = widget.controller ?? LegacyPremiosRankingController();
    if (_c.state.load != PremiosLoad.ready) _c.refresh();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    if (_owned) _c.dispose();
    super.dispose();
  }

  void _onScroll() {
    final m = PremiosHeaderMetrics.of(context);
    final box = _segKey.currentContext?.findRenderObject() as RenderBox?;
    final segTop = box?.localToGlobal(Offset.zero).dy ?? double.infinity;
    final pinned = segTop <= m.buttonsTop + 48;
    final o = _scroll.offset;
    if (pinned != _pinned || (o - _offset).abs() > 2 || (o <= 0) != (_offset <= 0)) {
      setState(() {
        _pinned = pinned;
        _offset = o;
      });
    }
  }

  Future<void> _refresh() async {
    await _c.refresh();
    widget.onRefresh?.call();
  }

  Future<void> _vote() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiosVotePage()));
    if (mounted) _refresh();
  }

  void _myVotes() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PremiosMyVotesPage(controller: _c, onVote: _vote),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final m = PremiosHeaderMetrics.of(context);
    final now = (widget.clock ?? DateTime.now)();
    final edition = PremiosEdition.current;
    final phase = edition.phase(now);
    final open = phase != PremiosPhase.closed;
    final title = open ? 'Así va la votación' : 'Ganadores 2026';
    final inlineT = ((_offset - 30) / 50).clamp(0.0, 1.0);
    final seg = _Segmented(
      value: _tab,
      onChanged: (c) => setState(() => _tab = c),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              color: gm.accent,
              edgeOffset: m.textTop,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, m.textTop, 16,
                        PremiosBottomBar.scrollPadding(context)),
                    sliver: SliverToBoxAdapter(
                      child: ListenableBuilder(
                        listenable: _c,
                        builder: (context, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const PremiosEyebrow(),
                                  const SizedBox(height: 4),
                                  Semantics(
                                    header: true,
                                    identifier: 'premios-ranking-title',
                                    child: Text(title,
                                        style:
                                            GmText.largeTitle(color: gm.label)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Opacity(
                              key: _segKey,
                              opacity: _pinned ? 0 : 1,
                              child: seg,
                            ),
                            const SizedBox(height: 16),
                            _CountdownCard(
                                edition: edition, now: now, phase: phase),
                            const SizedBox(height: 10),
                            ..._content(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GmTopScrim(visible: _offset > 30, extra: m.buttonsTop + 136 - MediaQuery.paddingOf(context).top),
            Positioned(
              left: 16,
              right: 16,
              top: m.buttonsTop,
              height: 44,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GmToolbarButton(
                      icon: GmIcons.chevronLeft,
                      iconSize: 20,
                      light: true,
                      semanticLabel: 'Volver',
                      identifier: 'premios-ranking-back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Positioned(
                    left: 44,
                    right: 44,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: inlineT,
                          child: Center(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.guideTitle(color: gm.label)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_pinned)
              Positioned(
                left: 16,
                right: 16,
                top: m.buttonsTop + 48,
                child: seg,
              ),
            PremiosBottomBar(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  if (open)
                    GmSoftCapsuleButton(
                      label: 'Mis votos',
                      identifier: 'premios-ranking-my-votes',
                      height: 52,
                      fontSize: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onTap: _myVotes,
                    )
                  else
                    Expanded(
                      child: GmSoftCapsuleButton(
                        label: 'Mis votos',
                        identifier: 'premios-ranking-my-votes',
                        height: 52,
                        fontSize: 17,
                        onTap: _myVotes,
                      ),
                    ),
                  if (open) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GmCapsuleButton(
                        label: 'Votar',
                        identifier: 'premios-ranking-vote',
                        height: 52,
                        fontSize: 17,
                        onTap: _vote,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final gm = GmColors.of(context);
    final s = _c.state;
    if (s.load == PremiosLoad.error) {
      return [
        PremiosStateCard(
          identifier: 'premios-ranking-error',
          sad: true,
          title: 'No pudimos cargar el ranking',
          text: 'Revisa tu conexión e inténtalo de nuevo.',
          action: 'Reintentar',
          onAction: _refresh,
        ),
      ];
    }
    if (s.load == PremiosLoad.loading) {
      return const [
        SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ];
    }
    final list = s.of(_tab);
    if (list.isEmpty) {
      return [
        const PremiosStateCard(
          identifier: 'premios-ranking-empty',
          title: 'Aún no hay votos',
          text: 'Sé el primero: elige tu favorito y aparecerá aquí.',
        ),
      ];
    }
    final total = list.fold<int>(0, (a, e) => a + e.votes);
    final noun = _tab == PremiosCategory.tradicional ? 'guachinches' : 'sitios';
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '${premiosVotes(total)} · ${list.length} ${list.length == 1 ? noun.substring(0, noun.length - 1) : noun} con algún voto',
          style: GmText.meta(color: gm.label2),
        ),
      ),
      const SizedBox(height: 16),
      PodioPremios(
        key: ValueKey(_tab),
        category: _tab,
        entries: list.take(3).toList(),
      ),
      if (list.length > 3) ...[
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            header: true,
            child: Text('Del 4.º en adelante',
                style: GmText.eyebrow(color: gm.label2)),
          ),
        ),
        const SizedBox(height: 8),
        _RankList(
          key: ValueKey('list-$_tab'),
          category: _tab,
          entries: list.skip(3).toList(),
          max: list.first.votes,
        ),
      ],
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Con los mismos votos se comparte puesto. Se actualiza al deslizar '
          'hacia abajo.',
          style: GmText.meta(color: gm.label2),
        ),
      ),
    ];
  }
}

// ── Control segmentado ─────────────────────────────────────────────────────

class _Segmented extends StatelessWidget {
  final PremiosCategory value;
  final ValueChanged<PremiosCategory> onChanged;
  const _Segmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget seg(PremiosCategory c) {
      final on = c == value;
      return Expanded(
        child: Semantics(
          identifier: 'premios-ranking-tab-${c.short}',
          button: true,
          selected: on,
          label: c.plural,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(c),
            child: AnimatedContainer(
              duration:
                  Duration(milliseconds: GmMotion.reduced(context) ? 0 : 200),
              height: 38,
              decoration: BoxDecoration(
                color: on ? gm.card : Colors.transparent,
                borderRadius: BorderRadius.circular(GmRadius.pill),
                boxShadow: on
                    ? const [
                        BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 4,
                            offset: Offset(0, 1))
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PremiosCategoryGlyph(c,
                      size: c == PremiosCategory.tradicional ? 16 : 16,
                      ink: on
                          ? PremiosColors.catInk(c, gm)
                          : PremiosColors.catInk(c, gm)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(c.plural,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: on ? gm.label : gm.label2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: GmGlass(
        borderRadius: BorderRadius.circular(GmRadius.pill),
        tint: gm.glass,
        edge: gm.glassEdge,
        shadow: gm.shadow1,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            seg(PremiosCategory.tradicional),
            const SizedBox(width: 2),
            seg(PremiosCategory.moderno),
          ]),
        ),
      ),
    );
  }
}

// ── Cuenta atrás ───────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  final PremiosEdition edition;
  final DateTime now;
  final PremiosPhase phase;
  const _CountdownCard(
      {required this.edition, required this.now, required this.phase});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final open = phase != PremiosPhase.closed;
    final (n, unit) = edition.countdown(now);
    final eyebrow = !open
        ? 'Votación cerrada'
        : phase == PremiosPhase.lastDay
            ? 'Último día para votar'
            : 'La votación cierra en';
    final title = open ? edition.untilLabel : 'Enhorabuena a los ganadores';
    return Semantics(
      identifier: 'premios-ranking-countdown',
      container: true,
      label: open ? '${edition.remainingLabel(now)}. $title' : '$eyebrow. $title',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: PremiosColors.band(gm),
          borderRadius: BorderRadius.circular(24),
          border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
          boxShadow: const [
            BoxShadow(
                color: Color(0xB32A0E14),
                offset: Offset(0, 14),
                blurRadius: 30,
                spreadRadius: -16),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow,
                      style: GmText.eyebrow(color: PremiosColors.goldText)),
                  const SizedBox(height: 2),
                  Text(title,
                      style: GmText.guideTitle(color: GmColors.creamHi)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (open)
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFF6E6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x4DC9A96B)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$n',
                          style: const TextStyle(
                              fontSize: 26,
                              height: 28 / 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: GmColors.creamHi,
                              fontFeatures: [FontFeature.tabularFigures()])),
                      Text(unit,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 15 / 12,
                              fontWeight: FontWeight.w600,
                              color: PremiosColors.goldText)),
                    ],
                  ),
                ),
              )
            else
              const GmGlyph(GmGlyphKind.medalla, size: 44),
          ],
        ),
      ),
    );
  }
}

// ── Podio ──────────────────────────────────────────────────────────────────

class _Metal {
  final List<Color> grad;
  final Color number;
  final String name;
  const _Metal(this.grad, this.number, this.name);

  static const oro = _Metal(
      [Color(0xFFF3DFA8), Color(0xFFD6B675), Color(0xFFB08A48)],
      Color(0xFFE8CF9A),
      'oro');
  static const plata = _Metal(
      [Color(0xFFF4F4F6), Color(0xFFC9CCD3), Color(0xFF9EA2AB)],
      Color(0xFFE4E6EA),
      'plata');
  static const bronce = _Metal(
      [Color(0xFFF2C9A2), Color(0xFFCD8F5C), Color(0xFF9C6236)],
      Color(0xFFE9B98E),
      'bronce');

  static _Metal of(int p) => p == 1 ? oro : (p == 2 ? plata : bronce);

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: grad,
        stops: const [0, 0.48, 1],
      );
}

/// Podio en vino: 2.º · 1.º · 3.º con alturas 104 / 78 / 56 según el puesto
/// real (los empates igualan columnas). Los bloques crecen (3.º, 2.º, 1.º)
/// y los avatares caen con squash; brillo de 1,1 s solo en el oro.
class PodioPremios extends StatelessWidget {
  final PremiosCategory category;
  final List<PremiosRankEntry> entries;
  const PodioPremios({super.key, required this.category, required this.entries});

  static const _blockH = {1: 104.0, 2: 78.0, 3: 56.0};

  @override
  Widget build(BuildContext context) {
    final order = <(PremiosRankEntry, double)>[
      if (entries.length > 1) (entries[1], 0.30),
      if (entries.isNotEmpty) (entries[0], 0.45),
      if (entries.length > 2) (entries[2], 0.15),
    ];
    return Semantics(
      identifier: 'premios-ranking-podium',
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: i < order.length
                    ? _PodiumColumn(
                        entry: order[i].$1,
                        category: category,
                        delay: order[i].$2,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PremiosRankEntry entry;
  final PremiosCategory category;
  final double delay;
  const _PodiumColumn(
      {required this.entry, required this.category, required this.delay});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final p = math.min(entry.rank, 3);
    final metal = _Metal.of(p);
    final h = PodioPremios._blockH[p]!;
    final av = p == 1 ? 72.0 : 60.0;
    final (name, paren) = premiosSplitName(entry.name);
    final vt = premiosVotes(entry.votes) + (entry.tied ? ' · empate' : '');
    final ring = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: metal.gradient,
        boxShadow: const [
          BoxShadow(
              color: Color(0x732A0E14),
              offset: Offset(0, 6),
              blurRadius: 14,
              spreadRadius: -6),
        ],
      ),
      child: PremiosAvatar(
          photoUrl: entry.photoUrl, category: category, size: av),
    );
    final block = Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16), bottom: Radius.circular(6)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A1520), Color(0xFF2A0E14)],
        ),
        border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0xB32A0E14),
              offset: Offset(0, 14),
              blurRadius: 30,
              spreadRadius: -16),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16), bottom: Radius.circular(6)),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 6,
              child: DecoratedBox(
                  decoration: BoxDecoration(gradient: metal.gradient)),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: p == 1 ? 18 : 14),
                child: MediaQuery.withNoTextScaling(
                  child: Text('${entry.rank}',
                      style: TextStyle(
                          fontSize: p == 1 ? 32 : 24,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: metal.number,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      label: '${entry.rank}.º puesto, medalla de ${metal.name}: '
          '${entry.name}, $vt',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 192,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GmOnce(
                  duration: const Duration(milliseconds: 820),
                  delay: Duration(milliseconds: ((delay + 0.35) * 1000).round()),
                  trigger: GmTrigger.mount,
                  child: p == 1 ? _Sheen(child: ring) : ring,
                  builder: (_, t, c) {
                    const cv = Cubic(0.3, 0.7, 0.3, 1);
                    final dy = gmKeyframes(t, const [(0, -14), (0.55, 2), (0.78, -2), (1, 0)], curve: cv);
                    final sx = gmKeyframes(t, const [(0, 0.92), (0.55, 1.12), (0.78, 0.97), (1, 1)], curve: cv);
                    final sy = gmKeyframes(t, const [(0, 1.1), (0.55, 0.88), (0.78, 1.03), (1, 1)], curve: cv);
                    return Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.translationValues(0, dy, 0)
                        ..multiply(Matrix4.diagonal3Values(sx, sy, 1)),
                      child: c,
                    );
                  },
                ),
                const SizedBox(height: 10),
                GmOnce(
                  duration: const Duration(milliseconds: 760),
                  delay: Duration(milliseconds: (delay * 1000).round()),
                  trigger: GmTrigger.mount,
                  child: block,
                  builder: (_, t, c) {
                    final inset = 0.62 *
                        (1 - const Cubic(0.34, 1.3, 0.64, 1).transform(t));
                    return ClipRect(
                      clipper: _TopInset(inset.clamp(0.0, 1.0)),
                      child: c,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GmText.sub(color: gm.label, w: FontWeight.w600)
                    .copyWith(height: 18 / 14, letterSpacing: -0.2)),
          ),
          SizedBox(
            height: 16,
            child: Text(paren,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GmText.chip(color: gm.label2, w: FontWeight.w400)),
          ),
          SizedBox(
            height: 18,
            child: Text(vt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GmText.meta(color: gm.label2)),
          ),
        ],
      ),
    );
  }
}

class _TopInset extends CustomClipper<Rect> {
  final double f;
  const _TopInset(this.f);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-40, size.height * f, size.width + 40, size.height + 40);

  @override
  bool shouldReclip(covariant _TopInset old) => old.f != f;
}

/// Brillo que cruza el anillo de oro una vez (1,1 s a 1,6 s).
class _Sheen extends StatelessWidget {
  final Widget child;
  const _Sheen({required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipOval(
                child: GmOnce(
                  duration: const Duration(milliseconds: 1100),
                  delay: const Duration(milliseconds: 1600),
                  trigger: GmTrigger.mount,
                  builder: (_, t, __) {
                    if (t <= 0 || t >= 1) return const SizedBox.shrink();
                    final x = -1.3 + 2.6 * GmMotion.ease.transform(t);
                    return FractionalTranslation(
                      translation: Offset(x, 0),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1, -0.4),
                            end: Alignment(1, 0.4),
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xBFFFFFFF),
                              Color(0x00FFFFFF),
                            ],
                            stops: [0.35, 0.5, 0.65],
                          ),
                        ),
                        child: SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
}

// ── Del 4.º en adelante ────────────────────────────────────────────────────

class _RankList extends StatelessWidget {
  final PremiosCategory category;
  final List<PremiosRankEntry> entries;
  final int max;
  const _RankList(
      {super.key,
      required this.category,
      required this.entries,
      required this.max});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = PremiosColors.catInk(category, gm);
    return GmCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0)
                Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 96),
                    color: gm.sep),
              PremiosRankRow(
                entry: entries[i],
                category: category,
                max: max,
                ink: ink,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila del ranking: puesto, avatar, nombre, «Tu voto», barra proporcional,
/// municipio y votos.
class PremiosRankRow extends StatelessWidget {
  final PremiosRankEntry entry;
  final PremiosCategory category;
  final int max;
  final Color ink;
  const PremiosRankRow({
    super.key,
    required this.entry,
    required this.category,
    required this.max,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final frac = max <= 0 ? 0.0 : entry.votes / max;
    return Semantics(
      identifier: 'premios-ranking-row',
      label: '${entry.rank}.º, ${entry.name}, ${premiosVotes(entry.votes)}'
          '${entry.mine ? ', tu voto' : ''}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('${entry.rank}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: gm.label2,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              const SizedBox(width: 10),
              PremiosAvatar(photoUrl: entry.photoUrl, category: category),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.cardTitle(color: gm.label)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (entry.mine) ...[
                          Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: gm.okSoft,
                              borderRadius:
                                  BorderRadius.circular(GmRadius.pill),
                            ),
                            child: Text('Tu voto',
                                style: GmText.chip(
                                        color: gm.greenText,
                                        w: FontWeight.w700)
                                    .copyWith(height: 1)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 36),
                            height: 4,
                            decoration: BoxDecoration(
                              color: gm.fill,
                              borderRadius:
                                  BorderRadius.circular(GmRadius.pill),
                            ),
                            alignment: Alignment.centerLeft,
                            child: GmOnce(
                              duration: const Duration(milliseconds: 900),
                              delay: const Duration(milliseconds: 500),
                              child: FractionallySizedBox(
                                widthFactor: frac.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ink.withValues(alpha: 0.75),
                                    borderRadius:
                                        BorderRadius.circular(GmRadius.pill),
                                  ),
                                ),
                              ),
                              builder: (_, t, c) => Transform.scale(
                                scaleX: 0.15 + 0.85 * GmMotion.settle.transform(t),
                                alignment: Alignment.centerLeft,
                                child: c,
                              ),
                            ),
                          ),
                        ),
                        if (entry.municipio.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 2,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 112),
                              child: Text(entry.municipio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GmText.meta(color: gm.label2)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(premiosVotes(entry.votes),
                  style: GmText.body(color: gm.label, w: FontWeight.w600)
                      .copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ),
    );
  }
}
