import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_home_extras.dart';
import 'package:guachinches/ui/pages/premios/widgets/papeleta_barrica_scene.dart';
import 'package:guachinches/ui/pages/premios/widgets/premios_widgets.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Posiciones del patrón de cabecera (tableros: botones en y 56 y bloque de
/// título en y 106 con la barra de estado de 62). Se apoyan en el margen
/// seguro real.
class PremiosHeaderMetrics {
  final double buttonsTop;
  final double textTop;
  const PremiosHeaderMetrics(this.buttonsTop, this.textTop);

  static PremiosHeaderMetrics of(BuildContext context) {
    final top = math.max(MediaQuery.paddingOf(context).top - 6, 8.0);
    return PremiosHeaderMetrics(top, top + 50);
  }
}

/// Cabecera vino de 370 con la escena de la barrica (Entrada y Gracias):
/// botones arriba, antetítulo con medalla, título 34/39 crema y subtítulo,
/// y el borde de nubes del lienzo. Mide 370 − 30 (la hoja de contenido
/// sube 30 sobre la mesa).
class PremiosWineHeader extends StatelessWidget {
  final Widget scene;
  final String title;
  final String subtitle;
  final String titleIdentifier;
  final Widget leading;
  final Widget? trailing;

  const PremiosWineHeader({
    super.key,
    required this.scene,
    required this.title,
    required this.subtitle,
    required this.titleIdentifier,
    required this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sceneH = PapeletaBarricaScene.heightFor(width);
    final m = PremiosHeaderMetrics.of(context);
    final s = width / PapeletaBarricaScene.designWidth;
    return SizedBox(
      height: sceneH - 30,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(left: 0, right: 0, top: 0, height: sceneH, child: scene),
          Positioned(
            left: 16,
            right: 16,
            top: m.buttonsTop,
            child: Row(
              children: [
                leading,
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 120 * s,
            top: m.textTop,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PremiosEyebrow(color: PremiosColors.goldText),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    identifier: titleIdentifier,
                    child: Text(
                      title,
                      style: GmText.largeTitle(color: GmColors.creamHi)
                          .copyWith(height: 39 / 34, letterSpacing: -0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      maxLines: 2,
                      style: GmText.body(color: PremiosColors.cream2)),
                ],
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: -1, child: GmCloudEdge()),
        ],
      ),
    );
  }
}

/// Barra de estado de las pantallas con cabecera vino: clara sobre el vino
/// y, al subir la hoja de lienzo por debajo del reloj, la del tema (oscura
/// de día). Solo reconstruye cuando cambia.
class PremiosWineStatusBar extends StatefulWidget {
  final ScrollController scroll;
  final Widget child;
  const PremiosWineStatusBar(
      {super.key, required this.scroll, required this.child});

  @override
  State<PremiosWineStatusBar> createState() => _PremiosWineStatusBarState();
}

class _PremiosWineStatusBarState extends State<PremiosWineStatusBar> {
  bool _overCanvas = false;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scroll.hasClients) return;
    final w = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    // La hoja de lienzo empieza en (370 − 30) a escala; las nubes la
    // adelantan unos 20.
    final edge = PapeletaBarricaScene.heightFor(w) - 30 - 20 - top;
    final over = widget.scroll.offset > edge;
    if (over != _overCanvas) setState(() => _overCanvas = over);
  }

  @override
  Widget build(BuildContext context) {
    final dark = GmColors.of(context).isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overCanvas && !dark
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: widget.child,
    );
  }
}
