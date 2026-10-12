import 'package:flutter/material.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/utils/open_state.dart';

/// Etiqueta «Abierto / Cierra en N min / Cerrado / Horario sin confirmar».
///
/// Misma regla que el resto de la app ([computeOpenState]): sin horario
/// fiable se pinta neutra, nunca como cerrado.
class OpenStatusBadge extends StatelessWidget {
  final Map<String, dynamic>? horariosJson;
  final bool fallbackOpen;

  const OpenStatusBadge({
    Key? key,
    required this.horariosJson,
    required this.fallbackOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = computeOpenState(horariosJson, DateTime.now(),
        fallbackOpen: horariosJson == null ? fallbackOpen : null);
    final l10n = AppL10n.of(context);
    final (String text, Color color) = switch (s.kind) {
      OpenKind.open => (l10n.openStatusOpen, const Color.fromRGBO(149, 220, 0, 1)),
      OpenKind.closingSoon => ('Cierra en ${s.minutesToClose} min', Colors.orange),
      OpenKind.closed => (l10n.openStatusClosed, const Color.fromRGBO(226, 120, 120, 1)),
      OpenKind.unknown => (l10n.openStatusUnknown, const Color(0xFF9A8F80)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
