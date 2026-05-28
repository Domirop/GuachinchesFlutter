import 'package:flutter/material.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/utils/horarios_utils.dart';

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
    final String status = horariosJson != null
        ? getOpenStatus(horariosJson, DateTime.now())
        : (fallbackOpen ? "Abierto" : "Cerrado");

    final Color color = _colorFor(status);

    final l10n = AppL10n.of(context);
    final String displayText = status == "Abierto"
        ? l10n.openStatusOpen
        : status == "Cerrado"
            ? l10n.openStatusClosed
            : status;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _colorFor(String status) {
    if (status == "Abierto") return Color.fromRGBO(149, 220, 0, 1);
    if (status == "Cerrado") return Color.fromRGBO(226, 120, 120, 1);
    return Colors.orange;
  }
}
