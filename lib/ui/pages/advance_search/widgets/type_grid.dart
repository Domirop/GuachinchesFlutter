import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Losetas que se pintan en «Explorar por tipo» / «Por tipo»: con sitios ya
/// cargados ([pool]) solo los tipos que tienen alguno, de más a menos; sin
/// ellos, todos los tipos tal cual y sin recuento.
List<(Types, int?)> typeGridEntries(List<Types> types, List<Restaurant> pool) {
  final counts = <String, int>{};
  for (final r in pool) {
    counts[r.type] = (counts[r.type] ?? 0) + 1;
  }
  final list = [...types];
  if (pool.isNotEmpty) {
    list.removeWhere((t) => (counts[t.id] ?? 0) == 0);
    list.sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
  }
  return [for (final t in list) (t, counts[t.id])];
}

/// «Explorar por tipo»: loseta con el tinte y el glifo de cada tipo y su
/// recuento real (si la home ya trajo los sitios). La usan la lista de
/// resultados ([AdvancedSearch]) y la pestaña Listas («Por tipo»).
class TypeGrid extends StatelessWidget {
  final List<Types> types;
  final List<Restaurant> pool;
  final ValueChanged<Types> onPick;
  final double inset;

  /// Prefijo del anchor de cada loseta (`<prefijo>-<tema>`).
  final String identifierPrefix;

  const TypeGrid({
    super.key,
    required this.types,
    required this.pool,
    required this.onPick,
    this.inset = 16,
    this.identifierPrefix = 'advanced-search-type',
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final list = typeGridEntries(types, pool);

    Widget tile((Types, int?) entry) {
      final (t, n) = entry;
      final k = listThemeForType(t.id, t.nombre) ?? ListThemeKind.restaurante;
      final th = kListThemes[k]!;
      return Semantics(
        identifier: '$identifierPrefix-${k.name}',
        button: true,
        label: n == null ? th.title : '${th.title}, $n sitios',
        excludeSemantics: true,
        child: GmPressable(
          onTap: () => onPick(t),
          child: GmCard(
            radius: 22,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: th.tint(dark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child:
                        ListThemeGlyph(th.glyph, size: 30, color: th.ink(dark)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(th.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GmText.cardTitle(color: gm.label)
                                .copyWith(fontSize: 15, height: 19 / 15)),
                        if (n != null)
                          Text(n == 1 ? '1 sitio' : '$n sitios',
                              style: GmText.meta(color: gm.label2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(list[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < list.length
                        ? tile(list[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
