import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_home_extras.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_review_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_header.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Abre Votar. Cada paso es su propia ruta (el gesto atrás de iOS vuelve
/// del paso 2 al 1); si se empieza por moderno se apilan los dos.
void premiosOpenVote(BuildContext context, PremiosFlowController? controller,
    PremiosCategory start) {
  final nav = Navigator.of(context);
  nav.push(MaterialPageRoute(
      builder: (_) => PremiosVotePage(controller: controller)));
  if (start == PremiosCategory.moderno && controller != null) {
    nav.push(MaterialPageRoute(
      builder: (_) => PremiosVotePage(
          controller: controller, category: PremiosCategory.moderno),
    ));
  }
}

/// Votar, un paso por categoría (tablero EncuestaVotar): cabecera temática
/// de 306 que se va con la lista y deja una barra compacta del color de la
/// banda, el buscador fijo justo debajo, filas de 52 con radio y la barra
/// de cristal «Tu voto · …» con «Saltar» o «Siguiente».
class PremiosVotePage extends StatefulWidget {
  /// Obligatorio en el paso 2; el paso 1 crea el suyo si no llega.
  final PremiosFlowController? controller;
  final PremiosCategory category;

  const PremiosVotePage({
    super.key,
    this.controller,
    this.category = PremiosCategory.tradicional,
  }) : assert(controller != null || category == PremiosCategory.tradicional);

  @override
  State<PremiosVotePage> createState() => _PremiosVotePageState();
}

class _PremiosVotePageState extends State<PremiosVotePage> {
  late final PremiosFlowController _c;
  late final bool _owned;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  int _bump = 0;
  bool _hadSent = false;

  PremiosCategory get _cat => widget.category;
  bool get _first => _cat == PremiosCategory.tradicional;

  @override
  void initState() {
    super.initState();
    _owned = widget.controller == null;
    _c = widget.controller ?? LegacyPremiosFlowController();
    if (_owned) _c.load();
    _hadSent = _c.state.sent != null;
    _c.addListener(_onState);
    _search.addListener(_onSearch);
  }

  String _lastQuery = '';
  void _onSearch() {
    if (_search.text != _lastQuery) {
      _lastQuery = _search.text;
      setState(() {});
    }
  }

  /// «Votar a otros sitios» vacía la papeleta: el paso 2 se retira y el 1
  /// vuelve arriba y sin búsqueda.
  void _onState() {
    final sent = _c.state.sent != null;
    if (_hadSent && !sent && mounted) {
      if (_first) {
        _search.clear();
        if (_scroll.hasClients) _scroll.jumpTo(0);
      } else {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      }
    }
    _hadSent = sent;
  }

  @override
  void dispose() {
    _c.removeListener(_onState);
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    if (_owned) _c.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    _searchFocus.unfocus();
    final nav = Navigator.of(context);
    if (_first) {
      nav.push(MaterialPageRoute(
        builder: (_) =>
            PremiosVotePage(controller: _c, category: PremiosCategory.moderno),
      ));
      return;
    }
    final back = await nav.push<PremiosCategory>(
      MaterialPageRoute(builder: (_) => PremiosReviewPage(controller: _c)),
    );
    // «Cambiar» el tradicional: de vuelta al paso 1.
    if (back == PremiosCategory.tradicional && mounted) nav.pop();
  }

  void _pick(PremiosCandidate c) {
    HapticFeedback.selectionClick();
    _c.pick(_cat, c);
    setState(() => _bump++);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final cat = _cat;
    final band = PremiosColors.catBand(cat, gm);
    final m = PremiosHeaderMetrics.of(context);
    final barH = m.buttonsTop + 44;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: gm.canvas,
        resizeToAvoidBottomInset: false,
        body: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final state = _c.state;
            final all = state.candidatesOf(cat);
            final list = premiosFilter(all, _search.text);
            final picked = state.picks[cat];
            return Stack(
              children: [
                Positioned.fill(
                  top: barH,
                  child: CustomScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _StepHeader(
                          category: cat,
                          metrics: m,
                          barH: barH,
                          bump: _bump,
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchHeader(
                          controller: _search,
                          focusNode: _searchFocus,
                          hint: state.load == PremiosLoad.ready
                              ? 'Buscar entre ${all.length} ${cat.candidatesNoun(all.length)}'
                              : 'Buscar',
                          canvas: gm.canvas,
                          textScale: MediaQuery.textScalerOf(context).scale(1),
                        ),
                      ),
                      ..._body(context, state, all, list, picked),
                      SliverToBoxAdapter(
                        child: SizedBox(
                            height: PremiosBottomBar.scrollPadding(context)),
                      ),
                    ],
                  ),
                ),
                // Barra compacta del color de la banda (fija).
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: barH,
                  child: ColoredBox(
                    color: band,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, m.buttonsTop - 4, 16, 0),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            _first
                                ? GmToolbarButton(
                                    icon: GmIcons.close,
                                    light: true,
                                    semanticLabel: 'Cerrar encuesta',
                                    identifier: 'premios-vote-close',
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                  )
                                : GmToolbarButton(
                                    icon: GmIcons.chevronLeft,
                                    iconSize: 20,
                                    light: true,
                                    semanticLabel:
                                        'Volver a la categoría tradicional',
                                    identifier: 'premios-vote-back',
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                  ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Semantics(
                                label: 'Categoría ${cat.index + 1} de 2',
                                child: ExcludeSemantics(
                                  child: PremiosProgress(filled: cat.index + 1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 44),
                              child: ExcludeSemantics(
                                child: Text('${cat.index + 1} de 2',
                                    textAlign: TextAlign.right,
                                    style: GmText.body(
                                        color: gm.label2, w: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                PremiosBottomBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: GmOnce(
                          key: ValueKey('pop-$_bump-${picked?.value}'),
                          duration: const Duration(milliseconds: 520),
                          trigger: GmTrigger.mount,
                          builder: (_, t, child) {
                            if (picked == null || _bump == 0) return child!;
                            final s = gmKeyframes(
                                t, const [(0, 0.9), (0.55, 1.04), (1, 1)],
                                curve: GmMotion.spring);
                            final dy = gmKeyframes(
                                t, const [(0, 4), (0.55, 0), (1, 0)],
                                curve: GmMotion.spring);
                            return Transform.translate(
                              offset: Offset(0, dy),
                              child: Transform.scale(
                                scale: s,
                                alignment: Alignment.centerLeft,
                                child: child,
                              ),
                            );
                          },
                          child: Semantics(
                            identifier: 'premios-vote-choice',
                            child: PremiosBarText(
                              labelFirst: true,
                              label: 'Tu voto · ${cat.short}',
                              value: picked?.name ?? 'Elige uno de la lista',
                              valueColor: picked == null
                                  ? PremiosColors.glassInk2(gm)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (picked == null)
                        GmSoftCapsuleButton(
                          label: 'Saltar',
                          identifier: 'premios-vote-skip',
                          height: 52,
                          fontSize: 17,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          onTap: _next,
                        )
                      else
                        GmCapsuleButton(
                          label: 'Siguiente',
                          identifier: 'premios-vote-next',
                          height: 52,
                          fontSize: 17,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          onTap: _next,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(
      BuildContext context,
      PremiosFlowState state,
      List<PremiosCandidate> all,
      List<PremiosCandidate> list,
      PremiosCandidate? picked) {
    final gm = GmColors.of(context);
    final q = _search.text.trim();
    Widget pad(Widget w) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16), sliver: w);

    if (state.load == PremiosLoad.error) {
      return [
        pad(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: PremiosStateCard(
              identifier: 'premios-vote-load-error',
              sad: true,
              volcanoWidth: 84,
              title: 'No pudimos cargar los candidatos',
              text: 'Revisa tu conexión e inténtalo de nuevo.',
              action: 'Reintentar',
              onAction: _c.load,
            ),
          ),
        )),
      ];
    }
    final count = Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Text(
        state.load != PremiosLoad.ready
            ? 'Cargando candidatos…'
            : q.isNotEmpty
                ? (list.length == 1
                    ? '1 resultado'
                    : '${list.length} resultados')
                : '${all.length} candidatos · elige uno o sáltate la categoría',
        style: GmText.eyebrow(color: gm.label2),
      ),
    );
    final note = Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Text(
        'El orden es aleatorio para no favorecer a nadie. No salen los sitios '
        'a los que ya votaste desde este móvil.',
        style: GmText.meta(color: gm.label2),
      ),
    );
    if (state.load != PremiosLoad.ready) {
      return [
        SliverToBoxAdapter(child: count),
        pad(const SliverToBoxAdapter(child: _SkeletonList())),
      ];
    }
    if (list.isEmpty) {
      return [
        SliverToBoxAdapter(child: count),
        pad(SliverToBoxAdapter(
          child: q.isEmpty
              ? PremiosStateCard(
                  identifier: 'premios-vote-empty',
                  volcanoWidth: 84,
                  title: 'Ya votaste a todos',
                  text: 'Desde este móvil ya tienen tu voto todos los de esta '
                      'categoría. Sáltala o vuelve a la otra.',
                )
              : PremiosStateCard(
                  identifier: 'premios-vote-no-results',
                  sad: true,
                  volcanoWidth: 84,
                  title: 'Ninguno se llama «$q»',
                  text: 'Prueba con otra palabra, sin «guachinche» delante, o '
                      'sáltate esta categoría.',
                  action: 'Borrar búsqueda',
                  onAction: _search.clear,
                ),
        )),
        SliverToBoxAdapter(child: note),
      ];
    }
    return [
      SliverToBoxAdapter(child: count),
      pad(DecoratedSliver(
        decoration: BoxDecoration(
          color: gm.card,
          borderRadius: BorderRadius.circular(GmRadius.card),
          boxShadow: gm.shadow1,
        ),
        sliver: SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final c = list[i];
            final first = i == 0, last = i == list.length - 1;
            return ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(first ? GmRadius.card : 0),
                bottom: Radius.circular(last ? GmRadius.card : 0),
              ),
              child: Column(
                children: [
                  if (!first)
                    Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 18),
                        color: gm.sep),
                  _CandidateRow(
                    key: ValueKey(c.value),
                    candidate: c,
                    selected: picked == c,
                    onTap: () => _pick(c),
                  ),
                ],
              ),
            );
          },
        ),
      )),
      SliverToBoxAdapter(child: note),
    ];
  }
}

/// Cabecera temática del paso (se va con el scroll).
class _StepHeader extends StatelessWidget {
  final PremiosCategory category;
  final PremiosHeaderMetrics metrics;
  final double barH;
  final int bump;
  const _StepHeader({
    required this.category,
    required this.metrics,
    required this.barH,
    required this.bump,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final band = PremiosColors.catBand(category, gm);
    final ink = PremiosColors.catInk(category, gm);
    final stripTop = metrics.textTop + 130;
    final height = stripTop + 70 - 30 - barH;
    final trad = category == PremiosCategory.tradicional;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: ColoredBox(color: band)),
          Positioned(
            left: 0,
            right: 0,
            top: stripTop - barH,
            height: 70,
            child: CustomPaint(
              painter: _StripPainter(
                trad: trad,
                band: band,
                veil: gm.isDark ? 0.55 : 0,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 100,
            top: metrics.textTop - barH,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GmEyebrow(
                    leading: PremiosCategoryGlyph(category,
                        size: trad ? 14 : 15, ink: ink),
                    text: 'Premios 2026',
                    color: ink,
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    identifier: 'premios-vote-title',
                    child: Text(
                      'Mejor guachinche\n${category.short}',
                      maxLines: 2,
                      style: GmText.largeTitle(color: gm.label).copyWith(
                          fontSize: 32, height: 38 / 32, letterSpacing: -0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trad
                        ? 'Vino de la casa y mantel de cuadros.'
                        : 'Lo de siempre, con otra vuelta.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.body(color: gm.label2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 178 - 106 + metrics.textTop - barH,
            child: ExcludeSemantics(
              child: _SwingingRosette(
                  key: ValueKey(category), category: category, bump: bump),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: -1, child: GmCloudEdge()),
        ],
      ),
    );
  }
}

/// Escarapela que cae al entrar (0,9 s) y se balancea al elegir.
class _SwingingRosette extends StatelessWidget {
  final PremiosCategory category;
  final int bump;
  const _SwingingRosette(
      {super.key, required this.category, required this.bump});

  @override
  Widget build(BuildContext context) {
    final rosette = PremioRosette(category);
    return GmOnce(
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 150),
      trigger: GmTrigger.mount,
      child: rosette,
      builder: (_, t, child) {
        final dy = gmKeyframes(t, const [(0, -40), (0.6, 4), (1, 0)],
            curve: GmMotion.spring);
        final rot = gmKeyframes(t, const [(0, -18), (0.6, 9), (0.8, 4), (1, 6)],
            curve: GmMotion.spring);
        final s = gmKeyframes(t, const [(0, 0.7), (0.6, 1.04), (1, 1)],
            curve: GmMotion.spring);
        return Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.translationValues(0, dy, 0)
            ..multiply(Matrix4.rotationZ(rot * math.pi / 180))
            ..multiply(Matrix4.diagonal3Values(s, s, 1)),
          child: bump == 0
              ? child
              : GmOnce(
                  key: ValueKey(bump),
                  duration: const Duration(milliseconds: 900),
                  trigger: GmTrigger.mount,
                  child: child,
                  builder: (_, u, c) {
                    final r = gmKeyframes(u, const [
                      (0, 0),
                      (0.25, -16),
                      (0.55, 6),
                      (0.8, -3),
                      (1, 0),
                    ]);
                    final y = gmKeyframes(
                        u, const [(0, 0), (0.25, -4), (0.55, 0), (1, 0)]);
                    return Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.translationValues(0, y, 0)
                        ..multiply(Matrix4.rotationZ(r * math.pi / 180)),
                      child: c,
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Franja de mantel bajo el título (rojo en tradicional, oro en moderno).
class _StripPainter extends CustomPainter {
  final bool trad;
  final Color band;
  final double veil;
  const _StripPainter(
      {required this.trad, required this.band, required this.veil});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    GmGinghamPainter.paintCells(
      canvas,
      rect,
      cell: 7,
      base: trad ? const Color(0xFFFFF7EC) : GmGinghamPainter.goldBase,
      stripe: trad ? PremiosColors.stripRed : PremiosColors.stripGold,
    );
    if (veil > 0)
      canvas.drawRect(rect, Paint()..color = band.withValues(alpha: veil));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 10),
        Paint()..color = PremiosColors.stripShade);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripPainter old) =>
      old.trad != trad || old.band != band || old.veil != veil;
}

/// Buscador fijo bajo la barra compacta.
class _SearchHeader extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final Color canvas;
  final double textScale;

  _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.canvas,
    required this.textScale,
  });

  double get _h => 68 + 17 * (textScale.clamp(1.0, 1.4) - 1);

  @override
  double get minExtent => _h;

  @override
  double get maxExtent => _h;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final gm = GmColors.of(context);
    return ColoredBox(
      color: canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Semantics(
          identifier: 'premios-vote-search',
          textField: true,
          child: Container(
            height: _h - 18,
            decoration: BoxDecoration(
              color: gm.card,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              boxShadow: gm.shadow1,
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                GmIcon(GmIcons.search, size: 19, color: gm.label2),
                const SizedBox(width: 9),
                Expanded(
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.4,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      autocorrect: false,
                      style: GmText.body17(color: gm.label),
                      cursorColor: gm.accent,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: GmText.body17(color: gm.label2),
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, v, __) => v.text.isEmpty
                      ? const SizedBox(width: 16)
                      : Semantics(
                          button: true,
                          label: 'Borrar búsqueda',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: controller.clear,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: GmIcon(GmIcons.xSmall,
                                    size: 14, color: gm.label2),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeader old) =>
      old.hint != hint ||
      old.canvas != canvas ||
      old.textScale != textScale ||
      old.controller != controller;
}

/// Fila de 52: nombre (2 líneas como mucho) y radio; al elegir, check con
/// squash, la fila se tiñe y rebota.
class _CandidateRow extends StatelessWidget {
  final PremiosCandidate candidate;
  final bool selected;
  final VoidCallback onTap;
  const _CandidateRow({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final row = AnimatedContainer(
      duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 200),
      color: selected ? PremiosColors.selBg(gm) : Colors.transparent,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(18, 7, 16, 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              candidate.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GmText.cardTitle(color: gm.label),
            ),
          ),
          const SizedBox(width: 12),
          selected
              ? GmOnce(
                  duration: const Duration(milliseconds: 560),
                  trigger: GmTrigger.mount,
                  builder: (_, t, c) {
                    final sx = gmKeyframes(
                        t, const [(0, 0.6), (0.4, 1.18), (0.7, 0.94), (1, 1)],
                        curve: GmMotion.spring);
                    final sy = gmKeyframes(
                        t, const [(0, 0.6), (0.4, 0.86), (0.7, 1.06), (1, 1)],
                        curve: GmMotion.spring);
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(sx, sy, 1),
                      child: c,
                    );
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: PremiosColors.progress,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: PremiosColors.progressShadow,
                            offset: Offset(0, 3),
                            blurRadius: 8,
                            spreadRadius: -2),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: GmIcon(GmIcons.check, size: 14, color: Colors.white),
                  ),
                )
              : Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: PremiosColors.sepStrong(gm), width: 2),
                  ),
                ),
        ],
      ),
    );
    return Semantics(
      identifier: 'premios-vote-row',
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: candidate.name,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: selected
            ? GmOnce(
                duration: const Duration(milliseconds: 420),
                trigger: GmTrigger.mount,
                child: row,
                builder: (_, t, c) => Transform.scale(
                  scale: gmKeyframes(t, const [(0, 0.985), (0.6, 1.01), (1, 1)],
                      curve: GmMotion.spring),
                  child: c,
                ),
              )
            : row,
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmCard(
      child: Column(
        children: [
          for (var i = 0; i < 8; i++)
            Container(
              height: 52,
              padding: const EdgeInsets.fromLTRB(18, 0, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 120.0 + (i * 37) % 110,
                    height: 14,
                    decoration: BoxDecoration(
                      color: gm.fill,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration:
                        BoxDecoration(color: gm.fill, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
