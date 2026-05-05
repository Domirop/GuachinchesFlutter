import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/Types.dart';

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

  int get count =>
      categoryIds.length +
      typeIds.length +
      municipalityIds.length +
      (openOnly ? 1 : 0);

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
}

class SearchFilterSheet extends StatefulWidget {
  final SearchFilterValues initial;
  final List<ModelCategory> categories;
  final List<Types> types;
  final List<Municipality> municipalities;

  const SearchFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
    required this.types,
    required this.municipalities,
  });

  static Future<SearchFilterValues?> show({
    required BuildContext context,
    required SearchFilterValues initial,
    required List<ModelCategory> categories,
    required List<Types> types,
    required List<Municipality> municipalities,
  }) {
    return showModalBottomSheet<SearchFilterValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.brand.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SearchFilterSheet(
        initial: initial,
        categories: categories,
        types: types,
        municipalities: municipalities,
      ),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilterValues _values;
  final TextEditingController _muniSearchCtrl = TextEditingController();
  final Set<String> _expandedZones = {};

  @override
  void initState() {
    super.initState();
    _values = widget.initial;
    _muniSearchCtrl.addListener(() => setState(() {}));
    // Auto-expand zones that already have selections
    for (final z in widget.municipalities) {
      if (_zoneSelectionState(z) > 0) _expandedZones.add(z.id);
    }
  }

  @override
  void dispose() {
    _muniSearchCtrl.dispose();
    super.dispose();
  }

  void _toggle(List<String> ids, String id, void Function(List<String>) commit) {
    final next = List<String>.from(ids);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    setState(() => commit(next));
  }

  void _clearAll() {
    setState(() {
      _values = const SearchFilterValues();
      _muniSearchCtrl.clear();
    });
  }

  List<SimpleMunicipality> get _flatMunicipalities =>
      widget.municipalities.expand((g) => g.municipalities).toList();

  /// 0 = nada, 1 = parcial, 2 = todos
  int _zoneSelectionState(Municipality zone) {
    if (zone.municipalities.isEmpty) return 0;
    var hits = 0;
    for (final m in zone.municipalities) {
      if (_values.municipalityIds.contains(m.id)) hits++;
    }
    if (hits == 0) return 0;
    if (hits == zone.municipalities.length) return 2;
    return 1;
  }

  void _toggleZoneExpansion(Municipality zone) {
    setState(() {
      if (_expandedZones.contains(zone.id)) {
        _expandedZones.remove(zone.id);
      } else {
        _expandedZones.add(zone.id);
      }
    });
  }

  void _selectAllInZone(Municipality zone) {
    final ids = List<String>.from(_values.municipalityIds);
    final childIds = zone.municipalities.map((m) => m.id).toSet();
    final allSelected =
        childIds.every((id) => _values.municipalityIds.contains(id));
    if (allSelected) {
      ids.removeWhere(childIds.contains);
    } else {
      for (final id in childIds) {
        if (!ids.contains(id)) ids.add(id);
      }
    }
    setState(() => _values = _values.copyWith(municipalityIds: ids));
  }

  List<SimpleMunicipality> _filteredMunis(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _flatMunicipalities
        .where((m) => m.nombre.toLowerCase().contains(q))
        .toList();
  }

  Municipality? _zoneOf(String muniId) {
    for (final z in widget.municipalities) {
      if (z.municipalities.any((m) => m.id == muniId)) return z;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.brand.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'FILTRAR',
                      style: AppTextStyles.displayHero(size: 22),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAll,
                    child: Text(
                      'Limpiar todo',
                      style: AppTextStyles.ui(
                        size: 13,
                        weight: FontWeight.w500,
                        color: AppColors.atlanticoClaro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.categories.isNotEmpty) ...[
                      _SectionHeader(title: 'CATEGORÍA'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OpenNowChip(
                            selected: _values.openOnly,
                            onTap: () => setState(
                              () => _values = _values.copyWith(
                                openOnly: !_values.openOnly,
                              ),
                            ),
                          ),
                          ...widget.categories.map((c) {
                            final selected =
                                _values.categoryIds.contains(c.id);
                            return _Chip(
                              label: c.nombre,
                              selected: selected,
                              onTap: () => _toggle(
                                _values.categoryIds,
                                c.id,
                                (next) => _values =
                                    _values.copyWith(categoryIds: next),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (widget.types.isNotEmpty) ...[
                      _SectionHeader(title: 'TIPO DE RESTAURANTE'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.types.map((t) {
                          final selected = _values.typeIds.contains(t.id);
                          return _Chip(
                            label: t.nombre,
                            selected: selected,
                            leading: _ColorDot(seed: t.id),
                            onTap: () => _toggle(
                              _values.typeIds,
                              t.id,
                              (next) =>
                                  _values = _values.copyWith(typeIds: next),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (widget.municipalities.isNotEmpty) ...[
                      _SectionHeader(title: 'MUNICIPIO / ZONA'),
                      const SizedBox(height: 10),
                      _MuniSearchField(controller: _muniSearchCtrl),
                      const SizedBox(height: 12),
                      _MunicipalitiesPicker(
                        zones: widget.municipalities,
                        selectedIds: _values.municipalityIds,
                        expandedZoneIds: _expandedZones,
                        query: _muniSearchCtrl.text,
                        zoneState: _zoneSelectionState,
                        onToggleZoneExpansion: _toggleZoneExpansion,
                        onSelectAllInZone: _selectAllInZone,
                        onToggleMuni: (id) => _toggle(
                          _values.municipalityIds,
                          id,
                          (next) =>
                              _values = _values.copyWith(municipalityIds: next),
                        ),
                        zoneOf: _zoneOf,
                        filteredMunis: _filteredMunis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.atlantico,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, _values),
                  child: Text(
                    _values.count > 0
                        ? 'MOSTRAR RESULTADOS · ${_values.count}'
                        : 'MOSTRAR RESULTADOS',
                    style: AppTextStyles.displaySection(size: 12)
                        .copyWith(color: Colors.white, letterSpacing: 1.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.eyebrow(
        size: 11,
        color: AppColors.atlanticoClaro,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.atlantico.withOpacity(0.18)
              : context.brand.surface,
          border: Border.all(
            color: selected
                ? AppColors.atlantico.withOpacity(0.55)
                : context.brand.borderStrong,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.ui(
                size: 13,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.atlanticoClaro
                    : context.brand.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenNowChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _OpenNowChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.laurisilva.withOpacity(0.18)
              : context.brand.surface,
          border: Border.all(
            color: selected
                ? AppColors.laurisilva.withOpacity(0.6)
                : context.brand.borderStrong,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.laurisilva
                    : context.brand.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Abierto ahora',
              style: AppTextStyles.ui(
                size: 13,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.laurisilva
                    : context.brand.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final String seed;
  const _ColorDot({required this.seed});

  static const _palette = [
    AppColors.tierra,
    AppColors.atlantico,
    AppColors.sol,
    AppColors.mojo,
    AppColors.laurisilva,
    AppColors.arena,
  ];

  Color get _color {
    if (seed.isEmpty) return _palette.first;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}

class _MuniSearchField extends StatelessWidget {
  final TextEditingController controller;
  const _MuniSearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: context.brand.borderStrong),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: context.brand.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.ui(
                size: 13,
                color: context.brand.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar municipio o zona…',
                hintStyle: AppTextStyles.ui(
                  size: 13,
                  color: context.brand.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => controller.clear(),
              child: Padding(
                padding: const EdgeInsets.only(right: 10, left: 4),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 16,
                  color: context.brand.textMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _MunicipalitiesPicker extends StatelessWidget {
  final List<Municipality> zones;
  final List<String> selectedIds;
  final Set<String> expandedZoneIds;
  final String query;
  final int Function(Municipality) zoneState;
  final void Function(Municipality) onToggleZoneExpansion;
  final void Function(Municipality) onSelectAllInZone;
  final void Function(String muniId) onToggleMuni;
  final Municipality? Function(String muniId) zoneOf;
  final List<SimpleMunicipality> Function(String) filteredMunis;

  const _MunicipalitiesPicker({
    required this.zones,
    required this.selectedIds,
    required this.expandedZoneIds,
    required this.query,
    required this.zoneState,
    required this.onToggleZoneExpansion,
    required this.onSelectAllInZone,
    required this.onToggleMuni,
    required this.zoneOf,
    required this.filteredMunis,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    if (hasQuery) {
      return _searchResults(context);
    }
    return _zonesView(context);
  }

  Widget _searchResults(BuildContext context) {
    final results = filteredMunis(query);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Sin coincidencias',
          style: AppTextStyles.muted(size: 12),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: results.map((m) {
        final selected = selectedIds.contains(m.id);
        final z = zoneOf(m.id);
        final subtitle = z?.nombre;
        return _Chip(
          label: subtitle != null ? '${m.nombre} · $subtitle' : m.nombre,
          selected: selected,
          onTap: () => onToggleMuni(m.id),
        );
      }).toList(),
    );
  }

  Widget _zonesView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < zones.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ZoneRow(
            zone: zones[i],
            state: zoneState(zones[i]),
            expanded: expandedZoneIds.contains(zones[i].id),
            selectedIds: selectedIds,
            onToggleExpansion: () => onToggleZoneExpansion(zones[i]),
            onSelectAll: () => onSelectAllInZone(zones[i]),
            onToggleMuni: onToggleMuni,
          ),
        ],
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final Municipality zone;
  final int state; // 0/1/2
  final bool expanded;
  final List<String> selectedIds;
  final VoidCallback onToggleExpansion;
  final VoidCallback onSelectAll;
  final void Function(String muniId) onToggleMuni;

  const _ZoneRow({
    required this.zone,
    required this.state,
    required this.expanded,
    required this.selectedIds,
    required this.onToggleExpansion,
    required this.onSelectAll,
    required this.onToggleMuni,
  });

  @override
  Widget build(BuildContext context) {
    final selectedAll = state == 2;
    final partial = state == 1;
    final highlight = selectedAll || partial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggleExpansion,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.atlantico.withOpacity(0.10)
                  : context.brand.surface,
              border: Border.all(
                color: highlight
                    ? AppColors.atlantico.withOpacity(0.45)
                    : context.brand.borderStrong,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  selectedAll
                      ? Icons.check_circle_rounded
                      : partial
                          ? Icons.indeterminate_check_box_rounded
                          : Icons.location_on_outlined,
                  size: 16,
                  color: highlight
                      ? AppColors.atlanticoClaro
                      : context.brand.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.nombre,
                    style: AppTextStyles.ui(
                      size: 13,
                      weight:
                          highlight ? FontWeight.w600 : FontWeight.w500,
                      color: highlight
                          ? AppColors.atlanticoClaro
                          : context.brand.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.brand.elevated,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${zone.municipalities.length}',
                    style: AppTextStyles.ui(
                      size: 11,
                      weight: FontWeight.w600,
                      color: context.brand.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: context.brand.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 4, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onSelectAll,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selectedAll
                                    ? Icons.check_box_rounded
                                    : Icons
                                        .check_box_outline_blank_rounded,
                                size: 16,
                                color: selectedAll
                                    ? AppColors.atlanticoClaro
                                    : context.brand.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                selectedAll
                                    ? 'Quitar toda la zona'
                                    : 'Seleccionar toda la zona',
                                style: AppTextStyles.ui(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: AppColors.atlanticoClaro,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: zone.municipalities.map((m) {
                          final selected = selectedIds.contains(m.id);
                          return _Chip(
                            label: m.nombre,
                            selected: selected,
                            onTap: () => onToggleMuni(m.id),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
