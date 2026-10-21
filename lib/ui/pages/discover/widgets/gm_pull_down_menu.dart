import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Opción de un menú desplegable de cristal (estilo pull-down de iOS).
class GmMenuItem<T> {
  final T value;
  final String label;

  /// Línea secundaria («Por fecha del vídeo»).
  final String? subtitle;

  /// Anclaje de tests: `Semantics(identifier:)` de la fila.
  final String? identifier;

  const GmMenuItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.identifier,
  });
}

/// Rectángulo global de [context] (el botón que abre el menú).
Rect gmAnchorRect(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Menú desplegable de cristal anclado a [anchor] (tableros
/// VisitasOrdenFiltros y ResenasTodas): título 13/18 en `label2`, filas de
/// 48 con check a la izquierda en la elegida y subtítulo opcional. Se alinea
/// al borde derecho del ancla y se abre hacia abajo (hacia arriba si no
/// cabe). Devuelve el valor elegido o `null` si se cierra tocando fuera.
///
/// Candidato a promover a `lib/ui/theme/` (lo usan Visitas y Reseñas).
Future<T?> showGmPullDownMenu<T>(
  BuildContext context, {
  required Rect anchor,
  required String title,
  required List<GmMenuItem<T>> items,
  T? selected,
  double width = 268,
  String? identifier,
}) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push<T>(_GmPullDownRoute<T>(
    anchor: anchor,
    title: title,
    items: items,
    selected: selected,
    width: width,
    identifier: identifier,
    reduced: GmMotion.reduced(context),
  ));
}

class _GmPullDownRoute<T> extends PopupRoute<T> {
  final Rect anchor;
  final String title;
  final List<GmMenuItem<T>> items;
  final T? selected;
  final double width;
  final String? identifier;
  final bool reduced;

  _GmPullDownRoute({
    required this.anchor,
    required this.title,
    required this.items,
    required this.selected,
    required this.width,
    required this.identifier,
    required this.reduced,
  });

  @override
  Color? get barrierColor => const Color(0x1F000000);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Cerrar menú';

  @override
  Duration get transitionDuration => Duration(milliseconds: reduced ? 0 : 260);

  @override
  Duration get reverseTransitionDuration =>
      Duration(milliseconds: reduced ? 0 : 160);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    const gap = 6.0;
    // Alto estimado: cabecera 32 + filas (48, 62 con subtítulo) + 12.
    final estimated = 44.0 +
        items.fold<double>(0, (h, i) => h + (i.subtitle == null ? 48 : 62) + 1);
    final w = width.clamp(0.0, screen.width - 32);
    final right = (screen.width - anchor.right).clamp(16.0, screen.width);
    final below = screen.height - anchor.bottom - media.padding.bottom - 16;
    final openUp = below < estimated && anchor.top > below;
    final menu = _GmPullDownPanel<T>(
      title: title,
      items: items,
      selected: selected,
      identifier: identifier,
    );
    return Stack(
      children: [
        Positioned(
          right: right,
          width: w,
          top: openUp ? null : anchor.bottom + gap,
          bottom: openUp ? screen.height - anchor.top + gap : null,
          child: AnimatedBuilder(
            animation: animation,
            child: menu,
            builder: (_, child) {
              final t = GmMotion.settle.transform(animation.value);
              return Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.86 + 0.14 * t,
                  alignment:
                      openUp ? Alignment.bottomRight : Alignment.topRight,
                  child: child,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GmPullDownPanel<T> extends StatelessWidget {
  final String title;
  final List<GmMenuItem<T>> items;
  final T? selected;
  final String? identifier;

  const _GmPullDownPanel({
    required this.title,
    required this.items,
    required this.selected,
    required this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: GmGlass(
        borderRadius: BorderRadius.circular(22),
        tint: gm.glass,
        edge: gm.glassEdge,
        blur: 30,
        shadow: const [
          BoxShadow(
            color: Color(0x73000000),
            offset: Offset(0, 24),
            blurRadius: 60,
            spreadRadius: -12,
          ),
        ],
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                  child: Semantics(
                    header: true,
                    child: Text(title, style: GmText.eyebrow(color: gm.label2)),
                  ),
                ),
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Container(height: 1, color: gm.sep),
                    ),
                  _row(context, gm, items[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, GmColors gm, GmMenuItem<T> item) {
    final on = item.value == selected;
    return Semantics(
      identifier: item.identifier,
      button: true,
      selected: on,
      inMutuallyExclusiveGroup: true,
      label: item.subtitle == null
          ? item.label
          : '${item.label}. ${item.subtitle}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(item.value);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: on
                    ? GmIcon(GmIcons.check, size: 15, color: gm.glassInk)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.label,
                        style: GmText.body17(color: gm.glassInk)
                            .copyWith(height: 22 / 17)),
                    if (item.subtitle != null)
                      Text(item.subtitle!,
                          style: GmText.meta(color: gm.label2)
                              .copyWith(height: 17 / 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
