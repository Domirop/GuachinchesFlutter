import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_logic.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_share_card.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_visuals.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Abre la hoja «Tarjeta para historias» (tablero CanarismoTarjeta).
Future<void> showCanarismoStorySheet(
  BuildContext context, {
  required Canarismo canarismo,
  required DateTime date,
  required bool isToday,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x52000000),
    builder: (_) => CanarismoStorySheet(
      canarismo: canarismo,
      date: date,
      isToday: isToday,
    ),
  );
}

/// Hoja con la vista previa de la tarjeta 9:16 y «Guardar» / «Compartir».
///
/// No hay plugin de galería: «Guardar» comparte solo el PNG (la hoja del
/// sistema ofrece «Guardar imagen») y «Compartir» el PNG + el texto.
class CanarismoStorySheet extends StatefulWidget {
  final Canarismo canarismo;
  final DateTime date;
  final bool isToday;

  const CanarismoStorySheet({
    super.key,
    required this.canarismo,
    required this.date,
    required this.isToday,
  });

  @override
  State<CanarismoStorySheet> createState() => _CanarismoStorySheetState();
}

class _CanarismoStorySheetState extends State<CanarismoStorySheet> {
  bool _busy = false;

  Future<void> _share({required bool includeText}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await shareCanarismoAsImage(
        context,
        widget.canarismo,
        date: widget.date,
        isToday: widget.isToday,
        includeText: includeText,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final mq = MediaQuery.of(context);
    final bottom = math.max(mq.padding.bottom, 16.0);
    // Cabecera (~120) + botones (52 + márgenes): la tarjeta ocupa el resto,
    // hasta 300 de ancho como el tablero.
    final availH = mq.size.height - mq.padding.top - 130 - (52 + 24 + bottom);
    final previewW = math.max(
      120.0,
      math.min(300.0, math.min(availH * 9 / 16, mq.size.width - 64)),
    );

    return Semantics(
      identifier: 'canarismo-card-sheet',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 30,
                offset: Offset(0, -10)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 7),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: gm.sep,
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(70, 14, 70, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Tarjeta para historias',
                      textAlign: TextAlign.center,
                      style: GmText.guideTitle(color: gm.label)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 18),
                  child: Text(
                    'Formato historia, 1080 × 1920. Lista para Instagram o '
                    'WhatsApp.',
                    textAlign: TextAlign.center,
                    style: GmText.sub(color: gm.label2),
                  ),
                ),
                Semantics(
                  image: true,
                  label: '${canarismoCardEyebrow(isToday: widget.isToday)}: '
                      '${widget.canarismo.palabra}',
                  child: ExcludeSemantics(
                    child: CanarismoStoryPreview(
                      width: previewW,
                      canarismo: widget.canarismo,
                      date: widget.date,
                      isToday: widget.isToday,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
                  child: Row(
                    children: [
                      Expanded(
                        child: GmSoftCapsuleButton(
                          label: 'Guardar',
                          height: 52,
                          identifier: 'canarismo-card-sheet-save',
                          leading: GmIcon(kCanarismoDownloadIcon,
                              size: 16, color: gm.accent),
                          onTap:
                              _busy ? null : () => _share(includeText: false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GmCapsuleButton(
                          label: 'Compartir',
                          icon: GmIcons.share,
                          iconSize: 16,
                          height: 52,
                          identifier: 'canarismo-card-sheet-share',
                          onTap: _busy ? null : () => _share(includeText: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              top: 14,
              child: GmToolbarButton(
                icon: GmIcons.close,
                light: true,
                semanticLabel: 'Cerrar',
                identifier: 'canarismo-card-sheet-close',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
