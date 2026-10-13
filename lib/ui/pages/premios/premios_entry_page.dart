import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_header.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Entrada de la encuesta (tablero EncuestaEntrada): cabecera «La papeleta
/// a la barrica», las dos categorías, cómo se vota y la barra con la cuenta
/// atrás y «Votar ahora».
class PremiosEntryPage extends StatefulWidget {
  /// Si no llega, la pantalla crea (y libera) la suya sobre el presenter
  /// actual.
  final PremiosFlowController? controller;
  final VoidCallback? onVoted;

  /// Para tests: «ahora».
  final DateTime Function()? clock;

  const PremiosEntryPage({super.key, this.controller, this.onVoted, this.clock});

  @override
  State<PremiosEntryPage> createState() => _PremiosEntryPageState();
}

class _PremiosEntryPageState extends State<PremiosEntryPage> {
  late final PremiosFlowController _c;
  late final bool _owned;
  final _scroll = ScrollController();
  final _sceneOn = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _owned = widget.controller == null;
    _c = widget.controller ?? LegacyPremiosFlowController(onVoted: widget.onVoted);
    if (_owned) _c.load();
    _scroll.addListener(() {
      final w = MediaQuery.sizeOf(context).width;
      _sceneOn.value = _scroll.offset < PapeletaBarricaScene.heightFor(w) - 30;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _sceneOn.dispose();
    if (_owned) _c.dispose();
    super.dispose();
  }

  void _vote(PremiosCategory start) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PremiosVotePage(controller: _c, initialCategory: start),
    ));
  }

  void _ranking() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiosRankingPage()));
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final now = (widget.clock ?? DateTime.now)();
    final edition = PremiosEdition.current;
    final phase = edition.phase(now);
    final open = phase != PremiosPhase.closed;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: Stack(
          children: [
            // El rebote de arriba enseña vino, no lienzo.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: MediaQuery.sizeOf(context).height / 2,
              child: ColoredBox(color: PremiosColors.band(gm)),
            ),
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: PremiosWineHeader(
                    scene: ValueListenableBuilder<bool>(
                      valueListenable: _sceneOn,
                      builder: (_, on, __) => PapeletaBarricaScene(active: on),
                    ),
                    title: '¿Cuál es tu favorito?',
                    subtitle: 'Vota y decide quién se lo lleva.',
                    titleIdentifier: 'premios-entry-title',
                    leading: PremiosWineGlassButton(
                      semanticLabel: 'Ahora no, cerrar',
                      identifier: 'premios-entry-close',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    trailing: PremiosWineGlassButton(
                      label: 'Ranking',
                      leading: const PremiosPodiumIcon(
                          size: 18, color: GmColors.creamHi),
                      semanticLabel: 'Ver el ranking',
                      identifier: 'premios-entry-ranking',
                      onTap: _ranking,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: gm.canvas,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, 16, 16, PremiosBottomBar.scrollPadding(context)),
                      child: ListenableBuilder(
                        listenable: _c,
                        builder: (_, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GmRise(
                              index: 1,
                              trigger: GmTrigger.mount,
                              child: _Categories(
                                state: _c.state,
                                onTap: open ? _vote : null,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const GmRise(
                              index: 2,
                              trigger: GmTrigger.mount,
                              child: _HowTo(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ColoredBox(color: gm.canvas),
                ),
              ],
            ),
            PremiosBottomBar(
              child: Row(
                children: [
                  Expanded(
                    child: open
                        ? _CountdownText(edition: edition, now: now)
                        : const PremiosBarText(
                            label: 'Votación cerrada',
                            value: 'Enhorabuena a los ganadores'),
                  ),
                  const SizedBox(width: 8),
                  GmCapsuleButton(
                    label: open ? 'Votar ahora' : 'Ver ganadores',
                    identifier: 'premios-entry-vote',
                    height: 52,
                    fontSize: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    onTap: open
                        ? () => _vote(PremiosCategory.tradicional)
                        : _ranking,
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

class _CountdownText extends StatelessWidget {
  final PremiosEdition edition;
  final DateTime now;
  const _CountdownText({required this.edition, required this.now});

  @override
  Widget build(BuildContext context) => PremiosBarText(
        label: edition.remainingLabel(now),
        value: edition.untilLabel,
      );
}

class _Categories extends StatelessWidget {
  final PremiosFlowState state;
  final ValueChanged<PremiosCategory>? onTap;
  const _Categories({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    String sub(PremiosCategory c) {
      final flavour = c == PremiosCategory.tradicional
          ? 'vino de la casa'
          : 'con otra vuelta';
      if (state.load != PremiosLoad.ready) return flavour;
      final n = state.candidatesOf(c).length;
      return '$n ${n == 1 ? 'candidato' : 'candidatos'} · $flavour';
    }

    Widget row(PremiosCategory c) => GmPressable(
          onTap: onTap == null ? null : () => onTap!(c),
          pressedScale: 0.98,
          semanticsIdentifier: 'premios-entry-category-${c.short}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PremiosColors.catTint(c, gm),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: PremiosCategoryGlyph(c,
                        size: c == PremiosCategory.tradicional ? 22 : 23,
                        ink: PremiosColors.catInk(c, gm)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: GmText.cardTitle(color: gm.label)),
                        Text(sub(c), style: GmText.meta(color: gm.label2)),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
                ],
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CapHead('Las categorías'),
        GmCard(
          child: Column(
            children: [
              row(PremiosCategory.tradicional),
              Container(
                  height: 1,
                  margin: const EdgeInsets.only(left: 68),
                  color: gm.sep),
              row(PremiosCategory.moderno),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo();

  static const _steps = [
    'Elige tu favorito en cada categoría. Si no lo tienes claro, sáltala.',
    'Al final revisas los votos y los envías juntos.',
    'Luego puedes votar a otros sitios: a cada uno, una vez.',
  ];

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CapHead('Cómo se vota'),
        GmCard(
          child: Column(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0)
                  Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 56),
                      color: gm.sep),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: gm.fill, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: gm.label)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_steps[i],
                              style: GmText.body(color: gm.label)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
          child: Text(
              'El orden de la lista es aleatorio para no favorecer a nadie.',
              style: GmText.meta(color: gm.label2)),
        ),
      ],
    );
  }
}

/// Cabecera de grupo 13/18 · 600 en label2.
class _CapHead extends StatelessWidget {
  final String text;
  const _CapHead(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Semantics(
          header: true,
          child: Text(text,
              style: GmText.eyebrow(color: GmColors.of(context).label2)),
        ),
      );
}
