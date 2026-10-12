import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show fichaCategoryFeature;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/gm_ficha_header.dart'
    show FichaFeatureChips;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

class SearchFilterValues {
  final List<String> categoryIds;
  final List<String> typeIds;
  final List<String> municipalityIds;
  final bool openOnly;

  const SearchFilterValues({
    this.categoryIds = const [],
    this.typeIds = const [],
    this.municipalityIds = const [],
    this.openOnly = false,
  });

  int get count => listActiveFilterCount(
        types: typeIds.length,
        categories: categoryIds.length,
        municipalities: municipalityIds.length,
        openOnly: openOnly,
      );

  SearchFilterValues copyWith({
    List<String>? categoryIds,
    List<String>? typeIds,
    List<String>? municipalityIds,
    bool? openOnly,
  }) =>
      SearchFilterValues(
        categoryIds: categoryIds ?? this.categoryIds,
        typeIds: typeIds ?? this.typeIds,
        municipalityIds: municipalityIds ?? this.municipalityIds,
        openOnly: openOnly ?? this.openOnly,
      );

  bool sameAs(SearchFilterValues o) =>
      openOnly == o.openOnly &&
      _same(categoryIds, o.categoryIds) &&
      _same(typeIds, o.typeIds) &&
      _same(municipalityIds, o.municipalityIds);

  static bool _same(List<String> a, List<String> b) => sameIds(a, b);

  /// Mismos ids sin importar el orden.
  static bool sameIds(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}

/// Panel de filtros (tablero ListaFiltros): hoja iOS con «Abierto ahora»,
/// Tipo, Qué buscas (etiquetas limpias con glifo), Dónde (municipios con
/// recuento y buscador) y el botón fijo «Mostrar N resultados».
class SearchFilterSheet extends StatefulWidget {
  final SearchFilterValues initial;
  final List<ModelCategory> categories;
  final List<Types> types;
  final List<Municipality> municipalities;

  /// Resultados del servidor para los tipos actuales (sin filtros locales):
  /// dan los recuentos al momento. Si se cambian los tipos hay que volver a
  /// preguntar al servidor y el botón no puede adelantar el número.
  final List<Restaurant> base;
  final List<String> baseTypeIds;

  /// Cuenta de los que pasan los filtros (la pone la pantalla: suma los
  /// resultados por plato).
  final int Function(SearchFilterValues values)? countFor;

  const SearchFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
    required this.types,
    required this.municipalities,
    this.base = const [],
    this.baseTypeIds = const [],
    this.countFor,
  });

  static Future<SearchFilterValues?> show({
    required BuildContext context,
    required SearchFilterValues initial,
    required List<ModelCategory> categories,
    required List<Types> types,
    required List<Municipality> municipalities,
    List<Restaurant> base = const [],
    List<String> baseTypeIds = const [],
    int Function(SearchFilterValues values)? countFor,
  }) {
    return showModalBottomSheet<SearchFilterValues>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x4D000000),
      builder: (_) => SearchFilterSheet(
        initial: initial,
        categories: categories,
        types: types,
        municipalities: municipalities,
        base: base,
        baseTypeIds: baseTypeIds,
        countFor: countFor,
      ),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilterValues _values;
  final TextEditingController _muniSearch = TextEditingController();

  static const _weekDays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  @override
  void initState() {
    super.initState();
    _values = widget.initial;
    _muniSearch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _muniSearch.dispose();
    super.dispose();
  }

  void _toggle(List<String> ids, String id,
      SearchFilterValues Function(List<String>) commit) {
    HapticFeedback.selectionClick();
    final next = List<String>.from(ids);
    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _values = commit(next));
  }

  bool get _typesUnchanged =>
      SearchFilterValues._same(_values.typeIds, widget.baseTypeIds);

  int? get _resultCount {
    if (!_typesUnchanged) return null;
    final n = widget.countFor?.call(_values);
    return (n == null || n < 0) ? null : n;
  }

  /// Municipios con recuento en los resultados actuales.
  List<(String id, String name, int count)> _municipalityRows() {
    final counts = <String, int>{};
    for (final r in widget.base) {
      final k = listNormMunicipality(r.municipio);
      if (k.isEmpty) continue;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final q = listNormMunicipality(_muniSearch.text);
    final rows = <(String, String, int)>[];
    final seen = <String>{};
    for (final z in widget.municipalities) {
      for (final m in z.municipalities) {
        final k = listNormMunicipality(m.nombre);
        if (!seen.add(k)) continue;
        final n = counts[k] ?? 0;
        final selected = _values.municipalityIds.contains(m.id);
        final matches = q.isEmpty ? (n > 0 || selected) : k.contains(q);
        if (matches) rows.add((m.id, gmDisplayName(m.nombre), n));
      }
    }
    rows.sort((a, b) => a.$2.compareTo(b.$2));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final n = _resultCount;
    final today = _weekDays[DateTime.now().weekday - 1];
    final count = _values.count;

    return Semantics(
      identifier: 'advanced-search-filter-sheet',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 40,
                offset: Offset(0, -10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.92,
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                          color: gm.sep,
                          borderRadius: BorderRadius.circular(GmRadius.pill)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 16, 6),
                      child: Row(
                        children: [
                          Semantics(
                            identifier: 'advanced-search-filter-clear',
                            button: true,
                            child: TextButton(
                              onPressed: count == 0
                                  ? null
                                  : () => setState(() {
                                        _values = const SearchFilterValues();
                                        _muniSearch.clear();
                                      }),
                              style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  foregroundColor: gm.label),
                              child: Text('Limpiar todo',
                                  style: GmText.body(
                                          color:
                                              count == 0 ? gm.label2 : gm.label,
                                          w: FontWeight.w600)
                                      .copyWith(fontSize: 16)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              count == 0 ? 'Filtros' : 'Filtros · $count',
                              textAlign: TextAlign.center,
                              style: GmText.guideTitle(color: gm.label)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          GmToolbarButton(
                            icon: GmIcons.close,
                            iconSize: 15,
                            light: true,
                            semanticLabel: 'Cerrar',
                            identifier: 'advanced-search-filter-close',
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottom),
                        children: [
                          _OpenRow(
                            value: _values.openOnly,
                            today: today,
                            onChanged: (v) => setState(
                                () => _values = _values.copyWith(openOnly: v)),
                          ),
                          if (widget.types.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const _Head('Tipo'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final t in widget.types)
                                  _TagChip(
                                    label: _typeLabel(t),
                                    leading: _typeGlyph(t, gm),
                                    selected: _values.typeIds.contains(t.id),
                                    onTap: () => _toggle(_values.typeIds, t.id,
                                        (l) => _values.copyWith(typeIds: l)),
                                  ),
                              ],
                            ),
                          ],
                          if (widget.categories.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const _Head('Qué buscas'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in widget.categories)
                                  _TagChip(
                                    label: listCategoryLabel(c.nombre),
                                    leading: FichaFeatureChips.glyph(
                                        fichaCategoryFeature(c.nombre).glyph,
                                        gm),
                                    selected:
                                        _values.categoryIds.contains(c.id),
                                    onTap: () => _toggle(
                                        _values.categoryIds,
                                        c.id,
                                        (l) =>
                                            _values.copyWith(categoryIds: l)),
                                  ),
                              ],
                            ),
                          ],
                          if (widget.municipalities.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const _Head('Dónde'),
                            const SizedBox(height: 10),
                            _Municipalities(
                              controller: _muniSearch,
                              rows: _municipalityRows(),
                              selected: _values.municipalityIds,
                              onToggle: (id) => _toggle(
                                  _values.municipalityIds,
                                  id,
                                  (l) => _values.copyWith(municipalityIds: l)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // Botón fijo con fundido.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, bottom + 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [gm.edgeFade0, gm.canvas],
                        stops: const [0, 0.3],
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: GmCapsuleButton(
                        height: 54,
                        fontSize: 17,
                        identifier: 'advanced-search-filter-apply',
                        label: n == null
                            ? 'Mostrar resultados'
                            : (n == 1
                                ? 'Mostrar 1 resultado'
                                : 'Mostrar $n resultados'),
                        onTap: () => Navigator.pop(context, _values),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nombre del tipo como en los temas («Cofradías», «Lounge»…); si no se
  /// reconoce, el del servidor.
  static String _typeLabel(Types t) {
    final k = listThemeForType(t.id, t.nombre);
    return k == null ? t.nombre : kListThemes[k]!.title;
  }

  Widget? _typeGlyph(Types t, GmColors gm) {
    final k = listThemeForType(t.id, t.nombre);
    if (k == null) return null;
    final th = kListThemes[k]!;
    return ListThemeGlyph(th.glyph, size: 16, color: gm.label);
  }
}

class _Head extends StatelessWidget {
  final String text;
  const _Head(this.text);

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            height: 25 / 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: GmColors.of(context).label,
          ),
        ),
      );
}

class _OpenRow extends StatelessWidget {
  final bool value;
  final String today;
  final ValueChanged<bool> onChanged;
  const _OpenRow(
      {required this.value, required this.today, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'advanced-search-filter-open-now',
      toggled: value,
      label: 'Abierto ahora',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: GmCard(
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
            child: Row(
              children: [
                GmLiveDot(live: value),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Abierto ahora',
                          style: GmText.cardTitle(color: gm.label)),
                      Text('Según el horario de hoy, $today',
                          style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: value,
                  activeTrackColor: const Color(0xFF34C759),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta del panel (36 de alto, área de toque de 44).
class _TagChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.fromLTRB(leading == null ? 12 : 8, 6, 12, 6),
            decoration: BoxDecoration(
              color: selected ? gm.accentSoft : gm.fill,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              border: selected
                  ? Border.all(color: const Color(0x730085C4), width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  SizedBox(
                      width: 16, height: 16, child: FittedBox(child: leading)),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? gm.accent : gm.label,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 5),
                  GmIcon(GmIcons.check, size: 11, color: gm.accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Municipalities extends StatelessWidget {
  final TextEditingController controller;
  final List<(String id, String name, int count)> rows;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _Municipalities({
    required this.controller,
    required this.rows,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: gm.fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  GmIcon(GmIcons.search, size: 16, color: gm.label2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      identifier: 'advanced-search-filter-muni-search',
                      child: TextField(
                        controller: controller,
                        style: GmText.body17(color: gm.label),
                        cursorColor: gm.accent,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Municipio o zona',
                          hintStyle: GmText.body17(color: gm.label2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text('Ningún municipio con resultados.',
                  style: GmText.meta(color: gm.label2)),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            Divider(height: 1, thickness: 1, color: gm.sep, indent: 16),
            Semantics(
              button: true,
              selected: selected.contains(rows[i].$1),
              label: '${rows[i].$2}, ${rows[i].$3} sitios',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onToggle(rows[i].$1),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(rows[i].$2,
                            style: GmText.body17(color: gm.label)),
                      ),
                      if (rows[i].$3 > 0)
                        Text('${rows[i].$3}',
                            style: GmText.sub(color: gm.label2)),
                      const SizedBox(width: 12),
                      _Radio(on: selected.contains(rows[i].$1)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool on;
  const _Radio({required this.on});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? GmColors.atlantico : null,
        border: on ? null : Border.all(color: gm.sep, width: 1.5),
      ),
      alignment: Alignment.center,
      child: on ? GmIcon(GmIcons.check, size: 12, color: Colors.white) : null,
    );
  }
}
