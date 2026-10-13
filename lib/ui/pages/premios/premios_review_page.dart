import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_thanks_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_header.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Revisar (tablero EncuestaRevisar): la papeleta con los dos votos y
/// «Cambiar»/«Elegir», los avisos tipados y «Enviar votos». Al volver con
/// una categoría, Votar salta a ese paso.
class PremiosReviewPage extends StatefulWidget {
  final PremiosFlowController controller;
  const PremiosReviewPage({super.key, required this.controller});

  @override
  State<PremiosReviewPage> createState() => _PremiosReviewPageState();
}

class _PremiosReviewPageState extends State<PremiosReviewPage> {
  PremiosFlowController get _c => widget.controller;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onState);
  }

  @override
  void dispose() {
    _c.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (_left || !mounted || _c.state.sent == null) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PremiosThanksPage(controller: _c, sent: _c.state.sent!),
      ),
    );
  }

  void _change(PremiosCategory c) => Navigator.of(context).pop(c);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final m = PremiosHeaderMetrics.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final s = _c.state;
            final picks = s.picks;
            // Sin votos el aviso sale ya al llegar (tablero «sin votos»).
            final error = s.error ??
                (picks.isEmpty
                    ? const PremiosError(PremiosErrorKind.noSelection)
                    : null);
            final copy = error == null
                ? null
                : premiosErrorCopy(error.kind,
                    rowFlagged: error.kind == PremiosErrorKind.alreadyVoted &&
                        s.flagged.isNotEmpty);
            final (count, sub) = premiosPickSummary(picks);
            return Stack(
              children: [
                // Como en el tablero: el contenido empieza bajo la barra y
                // se recorta ahí (no pasa por debajo de los botones).
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
                                identifier: 'premios-review-title',
                                child: Text('Tus votos',
                                    style: GmText.largeTitle(color: gm.label)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  'Revísalos antes de enviar. Puedes cambiar '
                                  'cualquiera.',
                                  style: GmText.body(color: gm.label2)),
                            ],
                          ),
                        ),
                      ),
                      if (copy != null) ...[
                        const SizedBox(height: 18),
                        PremiosAlertCard(
                          copy: copy,
                          onAction: () => _change(PremiosCategory.tradicional),
                        ),
                      ],
                      const SizedBox(height: 18),
                      GmRise(
                        index: 2,
                        trigger: GmTrigger.mount,
                        child: PapeletaCard(
                          trailing: '2 categorías',
                          rows: [
                            for (final c in PremiosCategory.values)
                              PapeletaVoteRow(
                                category: c,
                                name: picks[c]?.name,
                                flagged: picks[c] != null &&
                                    s.flagged.contains(picks[c]!.value),
                                action: picks[c] == null ? 'Elegir' : 'Cambiar',
                                onAction:
                                    s.submitting ? null : () => _change(c),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Los votos se envían juntos. Después puedes votar a '
                          'otros sitios, pero a cada uno solo una vez.',
                          style: GmText.meta(color: gm.label2),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: m.buttonsTop,
                  child: Row(
                    children: [
                      GmToolbarButton(
                        icon: GmIcons.chevronLeft,
                        iconSize: 20,
                        light: true,
                        semanticLabel: 'Volver a votar',
                        identifier: 'premios-review-back',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: ExcludeSemantics(
                              child: PremiosProgress(filled: 2))),
                      const SizedBox(width: 8),
                      Text('Revisar',
                          style: GmText.body(
                              color: gm.label2, w: FontWeight.w600)),
                    ],
                  ),
                ),
                PremiosBottomBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          identifier: 'premios-review-summary',
                          child: PremiosBarText(label: count, value: sub),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SendButton(
                          state: s,
                          retry: copy?.retry ?? false,
                          onSend: _c.submit),
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

class _SendButton extends StatelessWidget {
  final PremiosFlowState state;
  final bool retry;
  final VoidCallback onSend;
  const _SendButton(
      {required this.state, required this.retry, required this.onSend});

  @override
  Widget build(BuildContext context) {
    if (state.picks.isEmpty) {
      return const GmSoftCapsuleButton(
        label: 'Enviar votos',
        identifier: 'premios-review-send',
        height: 52,
        fontSize: 17,
        padding: EdgeInsets.symmetric(horizontal: 24),
      );
    }
    return GmCapsuleButton(
      label: state.submitting
          ? 'Enviando…'
          : retry
              ? 'Reintentar'
              : 'Enviar votos',
      leading: state.submitting ? const PremiosSpinner() : null,
      identifier: 'premios-review-send',
      height: 52,
      fontSize: 17,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: state.submitting ? null : onSend,
    );
  }
}
