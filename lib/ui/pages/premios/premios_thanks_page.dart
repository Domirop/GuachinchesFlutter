import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_header.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Gracias (tablero EncuestaGracias): la escena en modo celebración (una
/// vez, confeti), la papeleta enviada con el sello «Votado 2026» y los
/// caminos «Ver el ranking» y «Votar a otros sitios». La X vuelve al Inicio.
class PremiosThanksPage extends StatelessWidget {
  final PremiosFlowController controller;
  const PremiosThanksPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final sent = controller.state.sent ?? const {};
    final both = sent.length == 2;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: MediaQuery.sizeOf(context).height / 2,
              child: ColoredBox(color: PremiosColors.band(gm)),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: PremiosWineHeader(
                    scene: const PapeletaBarricaCelebration(),
                    title: both ? 'Gracias por tus votos' : 'Gracias por tu voto',
                    subtitle: both
                        ? 'Tus votos ya están en la barrica.'
                        : 'Tu voto ya está en la barrica.',
                    titleIdentifier: 'premios-thanks-title',
                    leading: PremiosWineGlassButton(
                      semanticLabel: 'Cerrar y volver al inicio',
                      identifier: 'premios-thanks-close',
                      onTap: () => Navigator.of(context)
                          .popUntil((r) => r.isFirst),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: gm.canvas,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, 14, 16, 40 + MediaQuery.paddingOf(context).bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GmRise(
                            index: 1,
                            trigger: GmTrigger.mount,
                            child: _SentBallot(sent: sent),
                          ),
                          const SizedBox(height: 14),
                          GmRise(
                            index: 2,
                            trigger: GmTrigger.mount,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '¿Te quedó alguno? Puedes votar a más '
                                'guachinches: a cada uno, una vez.',
                                style: GmText.body(color: gm.label2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          GmRise(
                            index: 3,
                            trigger: GmTrigger.mount,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GmCapsuleButton(
                                  label: 'Ver el ranking',
                                  identifier: 'premios-thanks-ranking',
                                  height: 52,
                                  fontSize: 17,
                                  leading: const PremiosPodiumIcon(
                                      size: 18, color: Colors.white),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PremiosRankingPage()),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GmSoftCapsuleButton(
                                  label: 'Votar a otros sitios',
                                  identifier: 'premios-thanks-vote-again',
                                  height: 52,
                                  fontSize: 17,
                                  background: gm.card,
                                  onTap: () {
                                    controller.voteAgain();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
          ],
        ),
      ),
    );
  }
}

/// La papeleta enviada. Sello: con dos votos, al centro del cuerpo; con
/// uno, centrado en la fila votada (nunca sobre «Sin voto»). Las filas
/// reservan 96 a la derecha.
class _SentBallot extends StatelessWidget {
  final Map<PremiosCategory, PremiosCandidate> sent;
  const _SentBallot({required this.sent});

  @override
  Widget build(BuildContext context) {
    final both = sent.length == 2;
    Widget row(PremiosCategory c) {
      final r = PapeletaVoteRow(
        category: c,
        name: sent[c]?.name,
        minHeight: 72,
        padding: const EdgeInsets.fromLTRB(14, 12, 96, 12),
      );
      if (both || sent[c] == null) return r;
      return Stack(
        children: [
          r,
          const Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(child: SelloVotado()),
          ),
        ],
      );
    }

    return Semantics(
      identifier: 'premios-thanks-ballot',
      container: true,
      child: PapeletaCard(
        rows: [for (final c in PremiosCategory.values) row(c)],
        overlay: both
            ? const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SelloVotado(),
                ),
              )
            : null,
      ),
    );
  }
}
