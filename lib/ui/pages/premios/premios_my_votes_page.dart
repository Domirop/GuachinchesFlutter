import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_header.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Mis votos (tablero EncuestaMisVotos): por categoría, cada sitio votado
/// desde este móvil con su puesto REAL en el ranking (no la posición en la
/// lista) y sus votos de hoy.
class PremiosMyVotesPage extends StatefulWidget {
  final PremiosRankingController controller;

  /// «Votar a otros sitios» / «Votar ahora». Si no llega, abre Votar.
  final VoidCallback? onVote;
  final DateTime Function()? clock;

  /// Pide `my-votes` al servidor al abrir (los tests lo apagan).
  final bool refreshVoted;

  const PremiosMyVotesPage({
    super.key,
    required this.controller,
    this.onVote,
    this.clock,
    this.refreshVoted = true,
  });

  @override
  State<PremiosMyVotesPage> createState() => _PremiosMyVotesPageState();
}

class _PremiosMyVotesPageState extends State<PremiosMyVotesPage> {
  @override
  void initState() {
    super.initState();
    PremiosEditionStore.instance.ensureLoaded();
    // «Mis votos» sale del servidor (`my-votes` v3); la caché se ve mientras.
    if (widget.refreshVoted) PremiosVotedStore.instance.refreshFromServer();
    // Sin datos todavía (p. ej. desde el envoltorio viejo): se cargan.
    if (widget.controller.state.load != PremiosLoad.ready) {
      widget.controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final onVote = widget.onVote;
    final gm = GmColors.of(context);
    final m = PremiosHeaderMetrics.of(context);
    final now = (widget.clock ?? DateTime.now)();
    final open = PremiosEditionStore.instance.current.phase(now).canVote;
    void vote() {
      if (onVote != null) {
        onVote();
      } else {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PremiosVotePage()));
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final s = controller.state;
            final sections = [
              for (final c in PremiosCategory.values)
                (c, s.of(c).where((e) => e.mine).toList()),
            ].where((x) => x.$2.isNotEmpty).toList();
            final has = sections.isNotEmpty;
            return Stack(
              children: [
                Positioned.fill(
                  top: m.textTop,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                        16, 0, 16, PremiosBottomBar.scrollPadding(context)),
                    children: [
                      GmRise(
                        trigger: GmTrigger.mount,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PremiosEyebrow(),
                              const SizedBox(height: 4),
                              Semantics(
                                header: true,
                                identifier: 'premios-my-votes-title',
                                child: Text('Mis votos',
                                    style: GmText.largeTitle(color: gm.label)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  'Los sitios que has votado desde este móvil.',
                                  style: GmText.body(color: gm.label2)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (s.load == PremiosLoad.loading)
                        const SizedBox(
                          height: 200,
                          child: Center(
                              child: CircularProgressIndicator.adaptive()),
                        )
                      else if (s.load == PremiosLoad.error)
                        PremiosStateCard(
                          identifier: 'premios-my-votes-error',
                          sad: true,
                          title: 'No pudimos cargar tus votos',
                          text: 'Revisa tu conexión e inténtalo de nuevo.',
                          action: 'Reintentar',
                          onAction: controller.refresh,
                        )
                      else if (!has)
                        const GmRise(
                          index: 1,
                          trigger: GmTrigger.mount,
                          child: PremiosStateCard(
                            identifier: 'premios-my-votes-empty',
                            title: 'Aún no has votado por ningún guachinche.',
                            text:
                                'Elige tu favorito tradicional, el moderno o los dos.',
                          ),
                        )
                      else ...[
                        for (var i = 0; i < sections.length; i++) ...[
                          if (i > 0) const SizedBox(height: 20),
                          GmRise(
                            index: i + 1,
                            trigger: GmTrigger.mount,
                            child: _Section(
                                category: sections[i].$1,
                                entries: sections[i].$2),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Puesto y votos de hoy en el ranking. A cada sitio '
                            'solo le puedes votar una vez desde este móvil.',
                            style: GmText.meta(color: gm.label2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  top: m.buttonsTop,
                  child: GmToolbarButton(
                    icon: GmIcons.chevronLeft,
                    iconSize: 20,
                    light: true,
                    semanticLabel: 'Volver al ranking',
                    identifier: 'premios-my-votes-back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                if (open)
                  PremiosBottomBar(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        Expanded(
                          child: GmCapsuleButton(
                            label: has ? 'Votar a otros sitios' : 'Votar ahora',
                            identifier: 'premios-my-votes-vote',
                            height: 52,
                            fontSize: 17,
                            onTap: vote,
                          ),
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
}

class _Section extends StatelessWidget {
  final PremiosCategory category;
  final List<PremiosRankEntry> entries;
  const _Section({required this.category, required this.entries});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Semantics(
            header: true,
            child: GmEyebrow(
              leading: PremiosCategoryGlyph(category,
                  size: 14, ink: PremiosColors.catInk(category, gm)),
              text: category.title,
            ),
          ),
        ),
        GmCard(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 72),
                      color: gm.sep),
                Semantics(
                  identifier: 'premios-my-votes-row',
                  label: '${entries[i].name}, ${entries[i].rank}.º, '
                      '${premiosVotes(entries[i].votes)}',
                  excludeSemantics: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 72),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                      child: Row(
                        children: [
                          PremiosAvatar(
                              photoUrl: entries[i].photoUrl,
                              category: category),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entries[i].name,
                                    style: GmText.cardTitle(color: gm.label)),
                                if (entries[i].municipio.isNotEmpty)
                                  Text(entries[i].municipio,
                                      style: GmText.meta(color: gm.label2)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${entries[i].rank}.º',
                                  style: GmText.body(
                                          color: gm.label, w: FontWeight.w700)
                                      .copyWith(fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ])),
                              Text(premiosVotes(entries[i].votes),
                                  style: GmText.meta(color: gm.label2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
