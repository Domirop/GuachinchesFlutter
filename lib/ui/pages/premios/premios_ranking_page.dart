import 'dart:math' as math;
import 'dart:ui' as ui;

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

  /// Scroll y segmentado fijado: van en notifiers para no reconstruir la
  /// pantalla en cada fotograma de scroll.
  final _offset = ValueNotifier<double>(0);
  final _pinned = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _owned = widget.controller == null;
    _c = widget.controller ?? PremiosResultsController();
    if (_c.state.load != PremiosLoad.ready) _c.refresh();
    PremiosEditionStore.instance.ensureLoaded();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    _pinned.dispose();
    if (_owned) _c.dispose();
    super.dispose();
  }

  void _onScroll() {
    final m = PremiosHeaderMetrics.of(context);
    final box = _segKey.currentContext?.findRenderObject() as RenderBox?;
    final segTop = box?.localToGlobal(Offset.zero).dy ?? double.infinity;
    _pinned.value = segTop <= m.buttonsTop + 48;
    _offset.value = _scroll.offset;
  }

  Future<void> _refresh() async {
    await _c.refresh();
    widget.onRefresh?.call();
  }

  Future<void> _vote() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PremiosVotePage()));
    if (mounted) _refresh();
  }

  void _myVotes(bool canVote) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PremiosMyVotesPage(
          controller: _c, onVote: canVote ? _vote : null, clock: widget.clock),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PremiosEdition>(
      valueListenable: PremiosEditionStore.instance,
      builder: (context, edition, _) => _build(context, edition),
    );
  }

  Widget _build(BuildContext context, PremiosEdition edition) {
    final gm = GmColors.of(context);
    final m = PremiosHeaderMetrics.of(context);
    final now = (widget.clock ?? DateTime.now)();
    final phase = edition.phase(now);
    final canVote = phase.canVote;
    final title =
        phase == PremiosPhase.closed ? 'Ganadores 2026' : 'Así va la votación';
    final seg = PremiosSegmented(
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
              child: ListenableBuilder(
                listenable: _c,
                builder: (context, _) => CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, m.textTop, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
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
                            ValueListenableBuilder<bool>(
                              valueListenable: _pinned,
                              builder: (_, pinned, child) => Opacity(
                                  opacity: pinned ? 0 : 1, child: child),
                              child: KeyedSubtree(key: _segKey, child: seg),
                            ),
                            if (phase.counting ||
                                phase == PremiosPhase.closed) ...[
                              const SizedBox(height: 16),
                              _CountdownCard(
                                  edition: edition, now: now, phase: phase),
                            ],
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    ..._content(context),
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: PremiosBottomBar.scrollPadding(context)),
                    ),
                  ],
                ),
              ),
            ),
            // Velo superior con desenfoque (opaco hasta el 86 %).
            ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (_, o, __) => _TopScrim(
                height: m.buttonsTop + 136,
                visible: o > 30,
              ),
            ),
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
                        child: ValueListenableBuilder<double>(
                          valueListenable: _offset,
                          builder: (_, o, child) => Opacity(
                            opacity: ((o - 30) / 50).clamp(0.0, 1.0),
                            child: child,
                          ),
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
            ValueListenableBuilder<bool>(
              valueListenable: _pinned,
              builder: (_, pinned, child) => pinned
                  ? Positioned(
                      left: 16,
                      right: 16,
                      top: m.buttonsTop + 48,
                      child: child!,
                    )
                  : const SizedBox.shrink(),
              child: seg,
            ),
            PremiosBottomBar(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  if (canVote)
                    GmSoftCapsuleButton(
                      label: 'Mis votos',
                      identifier: 'premios-ranking-my-votes',
                      height: 52,
                      fontSize: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onTap: () => _myVotes(canVote),
                    )
                  else
                    Expanded(
                      child: GmSoftCapsuleButton(
                        label: 'Mis votos',
                        identifier: 'premios-ranking-my-votes',
                        height: 52,
                        fontSize: 17,
                        onTap: () => _myVotes(canVote),
                      ),
                    ),
                  if (canVote) ...[
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

  /// El cuerpo en slivers: la lista «El resto» se construye a demanda.
  List<Widget> _content(BuildContext context) {
    final gm = GmColors.of(context);
    final s = _c.state;
    Widget box(Widget child) => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: child),
        );
    if (s.load == PremiosLoad.error) {
      return [
        box(PremiosStateCard(
          identifier: 'premios-ranking-error',
          sad: true,
          title: 'No pudimos cargar el ranking',
          text: 'Revisa tu conexión e inténtalo de nuevo.',
          action: 'Reintentar',
          onAction: _refresh,
        )),
      ];
    }
    if (s.load == PremiosLoad.loading) {
      return [
        box(const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator.adaptive()),
        )),
      ];
    }
    if (s.hidden) {
      return [
        box(PremiosHiddenRanking(
            untilShort: PremiosEditionStore.instance.current.untilShort)),
      ];
    }
    final list = s.of(_tab);
    if (list.isEmpty) {
      return [
        box(const PremiosStateCard(
          identifier: 'premios-ranking-empty',
          title: 'Aún no hay votos',
          text: 'Sé el primero: elige tu favorito y aparecerá aquí.',
        )),
      ];
    }
    final total = s.totals[_tab] ?? list.fold<int>(0, (a, e) => a + e.votes);
    final noun = _tab.candidatesNoun(list.length);
    final rest = list.skip(3).toList();
    final ink = PremiosColors.catInk(_tab, gm);
    return [
      box(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${premiosVotes(total)} · ${list.length} $noun con algún voto',
              style: GmText.meta(color: gm.label2),
            ),
          ),
          const SizedBox(height: 16),
          PodioPremios(
            key: ValueKey(_tab),
            category: _tab,
            entries: list.take(3).toList(),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                header: true,
                child:
                    Text('El resto', style: GmText.eyebrow(color: gm.label2)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      )),
      if (rest.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: gm.card,
              borderRadius: BorderRadius.circular(GmRadius.card),
              boxShadow: gm.shadow1,
            ),
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              sliver: SliverList.builder(
                key: ValueKey('list-$_tab'),
                itemCount: rest.length,
                itemBuilder: (_, i) => Column(
                  children: [
                    if (i > 0)
                      Container(
                          height: 1,
                          margin: const EdgeInsets.only(left: 96),
                          color: gm.sep),
                    PremiosRankRow(
                      entry: rest[i],
                      category: _tab,
                      max: list.first.votes,
                      ink: ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      box(Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
        child: Text(
          'Con los mismos votos se comparte puesto. Se actualiza al deslizar '
          'hacia abajo.',
          style: GmText.meta(color: gm.label2),
        ),
      )),
    ];
  }
}

/// Velo superior del ranking: desenfoque 12 en el tramo opaco y degradado
/// del lienzo hasta transparente.
class _TopScrim extends StatelessWidget {
  final double height;
  final bool visible;
  const _TopScrim({required this.height, required this.visible});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 180),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (visible)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: height * 0.86,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gm.edgeTop0, gm.edgeTop1, gm.edgeFade0],
                    stops: const [0, 0.7, 1],
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

// ── Control segmentado ─────────────────────────────────────────────────────

class PremiosSegmented extends StatelessWidget {
  final PremiosCategory value;
  final ValueChanged<PremiosCategory> onChanged;

  /// Inicio: relleno `fill` en vez de cristal.
  final bool flat;
  final String identifierPrefix;
  const PremiosSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.flat = false,
    this.identifierPrefix = 'premios-ranking-tab',
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget seg(PremiosCategory c) {
      final on = c == value;
      return Expanded(
        child: Semantics(
          identifier: '$identifierPrefix-${c.short}',
          button: true,
          selected: on,
          label: flat ? c.singular : c.plural,
          onTap: () => onChanged(c),
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
                      size: 16, ink: PremiosColors.catInk(c, gm)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(flat ? c.singular : c.plural,
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

    final row = Padding(
      padding: const EdgeInsets.all(3),
      child: Row(children: [
        seg(PremiosCategory.tradicional),
        const SizedBox(width: 2),
        seg(PremiosCategory.moderno),
      ]),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: flat
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: gm.fill,
                borderRadius: BorderRadius.circular(GmRadius.pill),
              ),
              child: row,
            )
          : GmGlass(
              borderRadius: BorderRadius.circular(GmRadius.pill),
              tint: gm.glass,
              edge: gm.glassEdge,
              shadow: gm.shadow1,
              child: row,
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
    final open = phase.counting;
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
      label:
          open ? '${edition.remainingLabel(now)}. $title' : '$eyebrow. $title',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: PremiosColors.band(gm),
          borderRadius: BorderRadius.circular(24),
          border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
          boxShadow: const [
            BoxShadow(
                color: PremiosColors.wineShadow,
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
                  constraints:
                      const BoxConstraints(minWidth: 64, minHeight: 56),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PremiosColors.digitFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PremiosColors.digitEdge),
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
/// Medidas del podio: el del Ranking y el compacto del Inicio.
class _PodiumMetrics {
  final Map<int, double> blockH;
  final double avatar1, avatar, ring, zone, avatarGap, gap;
  final double topR, bottomR, cap, number1, number, numberTop1, numberTop;
  final double nameSize, nameLine, metaSize, metaLine, nameTop;
  final bool paren;
  final Duration grow, drop, sheenDelay;
  final double dropDy;

  const _PodiumMetrics({
    required this.blockH,
    required this.avatar1,
    required this.avatar,
    required this.ring,
    required this.zone,
    required this.avatarGap,
    required this.gap,
    required this.topR,
    required this.bottomR,
    required this.cap,
    required this.number1,
    required this.number,
    required this.numberTop1,
    required this.numberTop,
    required this.nameSize,
    required this.nameLine,
    required this.metaSize,
    required this.metaLine,
    required this.nameTop,
    required this.paren,
    required this.grow,
    required this.drop,
    required this.sheenDelay,
    required this.dropDy,
  });

  static const full = _PodiumMetrics(
    blockH: {1: 104, 2: 78, 3: 56},
    avatar1: 72,
    avatar: 60,
    ring: 3,
    zone: 192,
    avatarGap: 10,
    gap: 10,
    topR: 16,
    bottomR: 6,
    cap: 6,
    number1: 32,
    number: 24,
    numberTop1: 18,
    numberTop: 14,
    nameSize: 14,
    nameLine: 18,
    metaSize: 13,
    metaLine: 18,
    nameTop: 10,
    paren: true,
    grow: Duration(milliseconds: 760),
    drop: Duration(milliseconds: 820),
    sheenDelay: Duration(milliseconds: 1600),
    dropDy: 14,
  );

  /// Inicio (tablero EncuestaInicioTarjeta): bloques de 54 / 40 / 30.
  static const compact = _PodiumMetrics(
    blockH: {1: 54, 2: 40, 3: 30},
    avatar1: 52,
    avatar: 44,
    ring: 2.5,
    zone: 120,
    avatarGap: 7,
    gap: 8,
    topR: 12,
    bottomR: 5,
    cap: 5,
    number1: 22,
    number: 17,
    numberTop1: 11,
    numberTop: 8,
    nameSize: 13,
    nameLine: 16,
    metaSize: 12,
    metaLine: 16,
    nameTop: 8,
    paren: false,
    grow: Duration(milliseconds: 700),
    drop: Duration(milliseconds: 760),
    sheenDelay: Duration(milliseconds: 1500),
    dropDy: 12,
  );
}

/// Podio en vino: 2.º · 1.º · 3.º con alturas según el puesto real (los
/// empates igualan columnas). Los bloques crecen (3.º, 2.º, 1.º) y los
/// avatares caen con squash; brillo una vez solo en el oro. [compact] es el
/// del Inicio (arranca al verse en pantalla).
class PodioPremios extends StatelessWidget {
  final PremiosCategory category;
  final List<PremiosRankEntry> entries;
  final bool compact;
  const PodioPremios({
    super.key,
    required this.category,
    required this.entries,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final m = compact ? _PodiumMetrics.compact : _PodiumMetrics.full;
    final order = <(PremiosRankEntry, double)>[
      if (entries.length > 1) (entries[1], 0.30),
      if (entries.isNotEmpty) (entries[0], 0.45),
      if (entries.length > 2) (entries[2], 0.15),
    ];
    // Con texto grande las cajas de nombre crecen con el TextScaler (hasta
    // 1,2×) en vez de desbordar.
    return Semantics(
      identifier: compact ? 'home-premios-podium' : 'premios-ranking-podium',
      container: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Padding(
          padding:
              compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(2, 4, 2, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: m.gap),
                Expanded(
                  child: i < order.length
                      ? _PodiumColumn(
                          entry: order[i].$1,
                          category: category,
                          delay: order[i].$2,
                          m: m,
                          trigger:
                              compact ? GmTrigger.visible : GmTrigger.mount,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PremiosRankEntry entry;
  final PremiosCategory category;
  final double delay;
  final _PodiumMetrics m;
  final GmTrigger trigger;
  const _PodiumColumn({
    required this.entry,
    required this.category,
    required this.delay,
    required this.m,
    required this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final p = math.min(entry.rank, 3);
    final metal = _Metal.of(p);
    final h = m.blockH[p]!;
    final av = p == 1 ? m.avatar1 : m.avatar;
    final (name, paren) = premiosSplitName(entry.name);
    final ts = MediaQuery.textScalerOf(context);
    final vt = premiosVotes(entry.votes) + (entry.tied ? ' · empate' : '');
    final radius = BorderRadius.vertical(
        top: Radius.circular(m.topR), bottom: Radius.circular(m.bottomR));
    final ring = Container(
      padding: EdgeInsets.all(m.ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: metal.gradient,
        boxShadow: const [
          BoxShadow(
              color: PremiosColors.wineShadowSoft,
              offset: Offset(0, 6),
              blurRadius: 14,
              spreadRadius: -6),
        ],
      ),
      child:
          PremiosAvatar(photoUrl: entry.photoUrl, category: category, size: av),
    );
    final block = Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PremiosColors.podiumTop, GmColors.wine],
        ),
        border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
        boxShadow: const [
          BoxShadow(
              color: PremiosColors.wineShadow,
              offset: Offset(0, 14),
              blurRadius: 30,
              spreadRadius: -16),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: m.cap,
              child: DecoratedBox(
                  decoration: BoxDecoration(gradient: metal.gradient)),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    EdgeInsets.only(top: p == 1 ? m.numberTop1 : m.numberTop),
                child: MediaQuery.withNoTextScaling(
                  child: Text('${entry.rank}',
                      style: TextStyle(
                          fontSize: p == 1 ? m.number1 : m.number,
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
            height: m.zone,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GmOnce(
                  duration: m.drop,
                  delay:
                      Duration(milliseconds: ((delay + 0.35) * 1000).round()),
                  trigger: trigger,
                  child:
                      p == 1 ? _Sheen(delay: m.sheenDelay, child: ring) : ring,
                  builder: (_, t, c) {
                    const cv = Cubic(0.3, 0.7, 0.3, 1);
                    final dy = gmKeyframes(
                        t, [(0, -m.dropDy), (0.55, 2), (0.78, -2), (1, 0)],
                        curve: cv);
                    final sx = gmKeyframes(t,
                        const [(0, 0.92), (0.55, 1.12), (0.78, 0.97), (1, 1)],
                        curve: cv);
                    final sy = gmKeyframes(
                        t, const [(0, 1.1), (0.55, 0.88), (0.78, 1.03), (1, 1)],
                        curve: cv);
                    return Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.translationValues(0, dy, 0)
                        ..multiply(Matrix4.diagonal3Values(sx, sy, 1)),
                      child: c,
                    );
                  },
                ),
                SizedBox(height: m.avatarGap),
                GmOnce(
                  duration: m.grow,
                  delay: Duration(milliseconds: (delay * 1000).round()),
                  trigger: trigger,
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
          SizedBox(height: m.nameTop),
          SizedBox(
            height: ts.scale(m.nameLine) * 2,
            child: Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: m.nameSize,
                    height: m.nameLine / m.nameSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: gm.label)),
          ),
          if (m.paren)
            SizedBox(
              height: ts.scale(16),
              child: Text(paren,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GmText.chip(color: gm.label2, w: FontWeight.w400)),
            ),
          SizedBox(
            height: ts.scale(m.metaLine),
            child: Text(vt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: m.metaSize,
                    height: m.metaLine / m.metaSize,
                    fontWeight: FontWeight.w400,
                    color: gm.label2,
                    fontFeatures: const [FontFeature.tabularFigures()])),
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
  final Duration delay;
  const _Sheen({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: ClipOval(
                child: GmOnce(
                  duration: const Duration(milliseconds: 1100),
                  delay: delay,
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

// ── El resto ───────────────────────────────────────────────────────────────

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

  Widget _bar(GmColors gm, double frac) => Container(
        height: 4,
        decoration: BoxDecoration(
          color: gm.fill,
          borderRadius: BorderRadius.circular(GmRadius.pill),
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
                borderRadius: BorderRadius.circular(GmRadius.pill),
              ),
            ),
          ),
          builder: (_, t, c) => Transform.scale(
            scaleX: 0.15 + 0.85 * GmMotion.settle.transform(t),
            alignment: Alignment.centerLeft,
            child: c,
          ),
        ),
      );

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
                                        color: gm.greenText, w: FontWeight.w700)
                                    .copyWith(height: 1)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: LayoutBuilder(builder: (context, c) {
                            // El municipio va entero: la barra cede su
                            // sitio (mínimo 24) y, si aun así no cabe, el
                            // municipio pasa a dos líneas.
                            final muniStyle = GmText.meta(color: gm.label2);
                            double mw = 0;
                            if (entry.municipio.isNotEmpty) {
                              final tp = TextPainter(
                                text: TextSpan(
                                    text: entry.municipio, style: muniStyle),
                                textDirection: TextDirection.ltr,
                                textScaler: MediaQuery.textScalerOf(context),
                                maxLines: 1,
                              )..layout();
                              mw = tp.width + 1;
                              tp.dispose();
                            }
                            final gap = mw > 0 ? 8.0 : 0.0;
                            final muniW = math.min(
                                mw, math.max(0.0, c.maxWidth - gap - 24));
                            return Row(
                              children: [
                                Expanded(child: _bar(gm, frac)),
                                if (mw > 0) ...[
                                  SizedBox(width: gap),
                                  SizedBox(
                                    width: muniW,
                                    child:
                                        Text(entry.municipio, style: muniStyle),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ),
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
