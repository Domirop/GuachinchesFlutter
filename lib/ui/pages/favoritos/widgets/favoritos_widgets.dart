import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show listOpenLabel;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/utils/open_state.dart';

/// «● Abierto hasta 16:00» / «● Cerrado · abre hoy 13:00» en una línea, con
/// el color del estado (tablero Guardados). Texto de [listOpenLabel]: la
/// misma fuente que listas y ficha.
class FavOpenLine extends StatelessWidget {
  final OpenState state;
  const FavOpenLine(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final l = listOpenLabel(state);
    final (Color dot, Color ink) = switch (l.kind) {
      OpenKind.open => (gm.green, gm.greenText),
      OpenKind.closingSoon => (gm.warnText, gm.warnText),
      OpenKind.closed => (gm.closedText, gm.closedText),
      OpenKind.unknown => (gm.label2, gm.label2),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (l.kind == OpenKind.unknown)
          GmIcon(GmIcons.clock, size: 12, color: gm.label2)
        else
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            l.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: l.kind == OpenKind.unknown
                  ? FontWeight.w400
                  : FontWeight.w600,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Corazón lleno (44 de toque) que quita el sitio de guardados.
class FavRemoveHeart extends StatefulWidget {
  final String restaurantId;
  final String name;
  final VoidCallback onRemove;

  const FavRemoveHeart({
    super.key,
    required this.restaurantId,
    required this.name,
    required this.onRemove,
  });

  @override
  State<FavRemoveHeart> createState() => _FavRemoveHeartState();
}

class _FavRemoveHeartState extends State<FavRemoveHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    if (!GmMotion.reduced(context)) await _c.forward(from: 0);
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'favoritos-remove-${widget.restaurantId}',
      button: true,
      label: 'Quitar ${widget.name} de guardados',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final s = gmKeyframes(
                    _c.value, const [(0, 1), (0.4, 0.78), (1, 0.92)]);
                return Transform.scale(scale: s, child: child);
              },
              child:
                  GmIcon(GmIcons.heartFilled, size: 22, color: GmColors.heart),
            ),
          ),
        ),
      ),
    );
  }
}
