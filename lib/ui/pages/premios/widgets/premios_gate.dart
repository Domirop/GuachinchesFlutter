import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';

/// Lo que impide votar o cargar, con la estética de los avisos de Revisar:
/// edición próxima o cerrada, móvil bloqueado o sin verificación posible,
/// versión antigua (botón a la tienda) o un fallo al cargar («Reintentar»).
/// Nada si el estado permite votar.
class PremiosGateCard extends StatelessWidget {
  final PremiosFlowState state;
  final VoidCallback onRetry;
  const PremiosGateCard(
      {super.key, required this.state, required this.onRetry});

  static bool shows(PremiosFlowState s) =>
      s.gate != null || s.load == PremiosLoad.error;

  @override
  Widget build(BuildContext context) {
    final gate = state.gate;
    if (gate != null) {
      final copy = premiosGateCopy(
        gate,
        store: premiosStoreName(),
        minVersion: state.minAppVersion,
        opensLabel: PremiosEditionStore.instance.current.opensLabel,
      );
      return PremiosAlertCard(
        identifier: 'premios-gate-${gate.name}',
        copy: copy,
        onAction: () => premiosGateAction(context, gate),
      );
    }
    if (state.load == PremiosLoad.error) {
      final c = premiosErrorCopy(state.loadError ?? PremiosErrorKind.server,
          store: premiosStoreName());
      return PremiosAlertCard(
        identifier: 'premios-load-error',
        copy: PremiosErrorCopy(
          title: c.title,
          message: c.message,
          help: '',
          tone: c.tone,
          icon: c.icon,
          action: 'Reintentar',
        ),
        onAction: onRetry,
      );
    }
    return const SizedBox.shrink();
  }
}

/// El botón de cada bloqueo: la tienda para actualizar; si no, el ranking.
void premiosGateAction(BuildContext context, PremiosGate gate) {
  if (gate == PremiosGate.upgradeRequired) {
    premiosOpenStore();
    return;
  }
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const PremiosRankingPage()));
}
