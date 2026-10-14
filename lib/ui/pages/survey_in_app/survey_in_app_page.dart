import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';

/// Entrada de la encuesta desde las pantallas de siempre (hero del Inicio
/// viejo, ranking, onboarding). Pinta el rediseño (tablero EncuestaEntrada);
/// la votación va por el contrato v3 (`SurveyVotePresenter`) a través de
/// `V3PremiosFlowController`.
class SurveyInAppPage extends StatelessWidget {
  final VoidCallback? onVoted;

  const SurveyInAppPage({Key? key, this.onVoted}) : super(key: key);

  @override
  Widget build(BuildContext context) => PremiosEntryPage(onVoted: onVoted);
}
