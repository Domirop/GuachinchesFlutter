import 'package:flutter/widgets.dart';
import 'package:guachinches/ui/pages/discover/widgets/gm_pull_down_menu.dart';

/// Orden de «Todas las visitas» (tablero VisitasOrdenFiltros).
enum VisitSort { newest, oldest, ratingDesc, nearest, alphaAsc }

extension VisitSortMeta on VisitSort {
  /// Texto de la fila del menú.
  String get label {
    switch (this) {
      case VisitSort.newest:
        return 'Más recientes';
      case VisitSort.oldest:
        return 'Más antiguas';
      case VisitSort.ratingDesc:
        return 'Mejor valoradas';
      case VisitSort.nearest:
        return 'Más cerca de ti';
      case VisitSort.alphaAsc:
        return 'Por nombre, de la A a la Z';
    }
  }

  /// Texto del botón de orden (corto).
  String get pillLabel => this == VisitSort.alphaAsc ? 'Por nombre' : label;

  String? get subtitle {
    switch (this) {
      case VisitSort.newest:
        return 'Por fecha del vídeo';
      case VisitSort.ratingDesc:
        return 'Según lo que dicen en el vídeo';
      case VisitSort.nearest:
        return 'Usa tu ubicación';
      case VisitSort.oldest:
      case VisitSort.alphaAsc:
        return null;
    }
  }

  String get identifier {
    switch (this) {
      case VisitSort.newest:
        return 'discover-sort-newest';
      case VisitSort.oldest:
        return 'discover-sort-oldest';
      case VisitSort.ratingDesc:
        return 'discover-sort-rating';
      case VisitSort.nearest:
        return 'discover-sort-nearest';
      case VisitSort.alphaAsc:
        return 'discover-sort-name';
    }
  }
}

/// Órdenes que se ofrecen: «Más cerca de ti» solo con ubicación.
List<VisitSort> visitSortOptions({required bool hasLocation}) => [
      for (final s in VisitSort.values)
        if (s != VisitSort.nearest || hasLocation) s
    ];

/// Menú de cristal anclado al botón de orden. Devuelve el orden elegido o
/// `null` si se cierra sin elegir.
Future<VisitSort?> showVisitSortMenu(
  BuildContext context, {
  required Rect anchor,
  required VisitSort current,
  required bool hasLocation,
}) {
  return showGmPullDownMenu<VisitSort>(
    context,
    anchor: anchor,
    title: 'Ordenar visitas',
    selected: current,
    identifier: 'discover-sort-menu',
    items: [
      for (final s in visitSortOptions(hasLocation: hasLocation))
        GmMenuItem(
          value: s,
          label: s.label,
          subtitle: s.subtitle,
          identifier: s.identifier,
        ),
    ],
  );
}
