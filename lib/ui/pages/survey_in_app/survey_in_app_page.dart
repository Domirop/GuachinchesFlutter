import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';

/// Entrada de la encuesta desde las pantallas de siempre (hero del Inicio
/// viejo, ranking, onboarding). Pinta el rediseño (tablero EncuestaEntrada);
/// el envío sigue en [SurveyInAppPresenter] a través de
/// `LegacyPremiosFlowController`.
class SurveyInAppPage extends StatelessWidget {
  final VoidCallback? onVoted;

  const SurveyInAppPage({Key? key, this.onVoted}) : super(key: key);

  @override
  Widget build(BuildContext context) => PremiosEntryPage(onVoted: onVoted);
}
