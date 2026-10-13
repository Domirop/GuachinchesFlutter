import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_home_card.dart';

/// Hoja de la encuesta al abrir la app (tablero EncuestaInicioTarjeta,
/// «hoja al abrir»). En el Inicio nuevo la gestiona `PremiosHomeSlot`; esto
/// queda para las pantallas de siempre que la llamaban.
class SurveyPopup {
  /// Muestra la hoja una sola vez por sesión de la app.
  static void showIfNeeded(BuildContext context, {VoidCallback? onVoted}) {
    if (PremiosHomeStore.sheetShownThisSession) return;
    PremiosHomeStore.sheetShownThisSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final vote = await showPremiosSheet(context);
      if (!context.mounted) return;
      if (vote == true) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PremiosEntryPage(onVoted: onVoted),
        ));
      } else {
        PremiosHomeStore.dismiss(DateTime.now());
      }
    });
  }
}
