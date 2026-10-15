import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/discover/discover_logic.dart'
    show discoverNormalize, discoverShortMunicipio;
import 'package:guachinches/ui/pages/discover/visit_filter_logic.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

export 'package:guachinches/ui/pages/discover/visit_filter_logic.dart';

/// Hoja «Filtrar visitas» (tablero VisitasOrdenFiltros, patrón ListaFiltros):
/// cabecera fija «Limpiar todo · Filtrar visitas · N · X», «Lo que les
/// pareció», «Tipo de sitio» con glifos, «Con fotos de los platos»,
/// «Precio por persona» y «Dónde» con recuentos al momento, y el botón fijo
/// «Mostrar N visitas». Sin resultados, dice qué filtro quitar.
class VisitFilterSheet extends StatefulWidget {
  final VisitFilterValues initial;

  /// Visitas de la isla con la búsqueda ya aplicada (base de los recuentos).
  final List<Visit> visits;

  const VisitFilterSheet({
    super.key,
    required this.initial,
    required this.visits,
  });

  static Future<VisitFilterValues?> show({
    required BuildContext context,
    required VisitFilterValues initial,
    required List<Visit> visits,
  }) {
    return showModalBottomSheet<VisitFilterValues>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x5C0A0806),
      builder: (_) => VisitFilterSheet(initial: initial, visits: visits),
    );
  }

  @override
  State<VisitFilterSheet> createState() => _VisitFilterSheetState();
}

class _VisitFilterSheetState extends State<VisitFilterSheet> {
  late VisitFilterValues _values = widget.initial;
  final TextEditingController _muniSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muniSearch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _muniSearch.dispose();
    super.dispose();
  }

  void _set(VisitFilterValues v) {
    HapticFeedback.selectionClick();
    setState(() => _values = v);
  }

  Set<T> _toggled<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final counts =
        visitFacetCounts(widget.visits, _values, discoverShortMunicipio);
    final hint = counts.total == 0 && _values.count > 0
        ? visitEmptyHint(widget.visits, _values, discoverShortMunicipio)
        : null;
    final types = visitTypeOptions(widget.visits, _values);

    return Semantics(
      identifier: 'discover-filter-sheet',
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
                    _header(gm),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 130 + bottom),
                        children: [
                          if (hint != null) ...[
                            _EmptyHint(
                              text: visitEmptyHintText(hint.label, hint.count),
                              onRemove: () => _set(hint.without),
                            ),
                            const SizedBox(height: 22),
                          ],
                          const _Head('Lo que les pareció'),
                          const SizedBox(height: 4),
                          _Caption('Según el tono del vídeo de Jonay y Joana.'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final m in VisitMood.values)
                                _FilterChip(
                                  identifier: 'discover-filter-mood-${m.name}',
                                  label: m.label,
                                  count: counts.moods[m] ?? 0,
                                  leading: m == VisitMood.loved
                                      ? GmIcon(GmIcons.thumb,
                                          size: 16,
                                          color: _values.moods.contains(m)
                                              ? gm.accent
                                              : gm.label)
                                      : null,
                                  selected: _values.moods.contains(m),
                                  onTap: () => _set(_values.copyWith(
                                      moods: _toggled(_values.moods, m))),
                                ),
                            ],
                          ),
                          if (types.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const _Head('Tipo de sitio'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final k in types)
                                  _FilterChip(
                                    identifier:
                                        'discover-filter-type-${k.name}',
                                    label: kListThemes[k]!.title,
                                    count: counts.types[k] ?? 0,
                                    leading: ListThemeGlyph(
                                        kListThemes[k]!.glyph,
                                        size: 16,
                                        color: _values.types.contains(k)
                                            ? gm.accent
                                            : gm.label),
                                    selected: _values.types.contains(k),
                                    onTap: () => _set(_values.copyWith(
                                        types: _toggled(_values.types, k))),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          _PhotosRow(
                            value: _values.withDishPhotos,
                            count: counts.photos,
                            onChanged: (v) =>
                                _set(_values.copyWith(withDishPhotos: v)),
                          ),
                          const SizedBox(height: 24),
                          const _Head('Precio por persona'),
                          const SizedBox(height: 4),
                          _Caption(visitPriceCaption(counts.noPrice)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in VisitPrice.values)
                                _FilterChip(
                                  identifier:
                                      'discover-filter-price-${p.index + 1}',
                                  label: p.label,
                                  semanticLabel: _priceSemantic(p),
                                  count: counts.prices[p] ?? 0,
                                  selected: _values.prices.contains(p),
                                  onTap: () => _set(_values.copyWith(
                                      prices: _toggled(_values.prices, p))),
                                ),
                            ],
                          ),
                          if (counts.municipios.isNotEmpty ||
                              _values.municipios.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const _Head('Dónde'),
                            const SizedBox(height: 10),
                            _Municipalities(
                              controller: _muniSearch,
                              rows: _muniRows(counts),
                              selected: _values.municipios,
                              onToggle: (m) => _set(_values.copyWith(
                                  municipios: _toggled(_values.municipios, m))),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
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
                      child: counts.total == 0
                          ? const _DisabledCta()
                          : GmCapsuleButton(
                              height: 54,
                              fontSize: 17,
                              identifier: 'discover-filter-apply',
                              label: visitFilterCta(counts.total),
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

  Widget _header(GmColors gm) {
    final n = _values.count;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 6),
      child: Row(
        children: [
          Semantics(
            identifier: 'discover-filter-clear',
            button: true,
            child: TextButton(
              onPressed: n == 0
                  ? null
                  : () {
                      _muniSearch.clear();
                      _set(const VisitFilterValues());
                    },
              style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44), foregroundColor: gm.label),
              child: Text('Limpiar todo',
                  style: GmText.body(
                          color: n == 0 ? gm.label2 : gm.label,
                          w: FontWeight.w600)
                      .copyWith(fontSize: 16)),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                visitFilterTitle(n),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GmText.guideTitle(color: gm.label)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          GmToolbarButton(
            icon: GmIcons.close,
            iconSize: 15,
            light: true,
            semanticLabel: 'Cerrar',
            identifier: 'discover-filter-close',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  List<(String, int)> _muniRows(VisitFacetCounts counts) {
    final rows = [...counts.municipios];
    for (final m in _values.municipios) {
      if (!rows.any((r) => r.$1 == m)) rows.add((m, 0));
    }
    final q = discoverNormalize(_muniSearch.text.trim());
    return [
      for (final r in rows)
        if (q.isEmpty || discoverNormalize(r.$1).contains(q)) r
    ];
  }

  static String _priceSemantic(VisitPrice p) {
    switch (p) {
      case VisitPrice.low:
        return 'Menos de 15 euros por persona';
      case VisitPrice.mid:
        return 'De 15 a 30 euros por persona';
      case VisitPrice.high:
        return 'Más de 30 euros por persona';
    }
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

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: GmText.meta(color: GmColors.of(context).label2));
}

/// Chip del panel (36 de alto, toque de 44) con recuento. Con 0 y sin
/// marcar se pinta deshabilitado.
class _FilterChip extends StatelessWidget {
  final String identifier;
  final String label;
  final String? semanticLabel;
  final int count;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.identifier,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.leading,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final disabled = count == 0 && !selected;
    final fg = selected ? gm.accent : gm.label;
    return Semantics(
      identifier: identifier,
      button: true,
      selected: selected,
      enabled: !disabled,
      label: '${semanticLabel ?? label}, $count',
      excludeSemantics: true,
      child: GmPressable(
        onTap: disabled ? null : onTap,
        pressedScale: 0.95,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Opacity(
            opacity: disabled ? 0.55 : 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: EdgeInsets.fromLTRB(leading == null ? 12 : 9, 6, 12, 6),
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
                        width: 16,
                        height: 16,
                        child: FittedBox(child: leading)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: disabled ? gm.label2 : fg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w500,
                      color: selected ? gm.accent : gm.label2,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
      ),
    );
  }
}

/// Tarjeta «Con fotos de los platos» con interruptor.
class _PhotosRow extends StatelessWidget {
  final bool value;
  final int count;
  final ValueChanged<bool> onChanged;

  const _PhotosRow(
      {required this.value, required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final sub = count == 1
        ? '1 visita con la foto de lo que pidieron'
        : '$count visitas con la foto de lo que pidieron';
    return Semantics(
      identifier: 'discover-filter-photos',
      toggled: value,
      label: 'Con fotos de los platos. $sub',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: GmCard(
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: gm.fill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: GmIcon(_kCameraIcon, size: 18, color: gm.label),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Con fotos de los platos',
                          style: GmText.cardTitle(color: gm.label)),
                      Text(sub, style: GmText.meta(color: gm.label2)),
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

const _kCameraIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<path d="M4 8.5a2 2 0 012-2h2l1.4-2h5.2l1.4 2h2a2 2 0 012 2V18a2 2 0 01-2 2H6a2 2 0 01-2-2z"/>'
    '<circle cx="12" cy="13" r="3.6"/></svg>';

/// Aviso sin resultados: qué filtro quitar, con «Quitar ×».
class _EmptyHint extends StatelessWidget {
  final String text;
  final VoidCallback onRemove;
  const _EmptyHint({required this.text, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'discover-filter-empty-hint',
      liveRegion: true,
      container: true,
      child: GmOnce(
        duration: const Duration(milliseconds: 320),
        trigger: GmTrigger.mount,
        builder: (_, t, c) => Transform.translate(
            offset: Offset(0, -8 * (1 - GmMotion.settle.transform(t))),
            child: c),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: gm.warnSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: GmText.sub(color: gm.label)),
              ),
              const SizedBox(width: 10),
              Semantics(
                identifier: 'discover-filter-empty-hint-remove',
                button: true,
                label: 'Quitar filtro',
                excludeSemantics: true,
                child: GmPressable(
                  onTap: onRemove,
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                        decoration: BoxDecoration(
                          color: gm.accentSoft,
                          borderRadius: BorderRadius.circular(GmRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Quitar',
                                style: GmText.sub(
                                    color: gm.accent, w: FontWeight.w600)),
                            const SizedBox(width: 6),
                            GmIcon(GmIcons.xSmall, size: 10, color: gm.accent),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Municipalities extends StatelessWidget {
  final TextEditingController controller;
  final List<(String, int)> rows;
  final Set<String> selected;
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  GmIcon(GmIcons.search, size: 16, color: gm.label2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      identifier: 'discover-filter-muni-search',
                      child: TextField(
                        controller: controller,
                        style: GmText.body17(color: gm.label),
                        cursorColor: gm.accent,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Municipio',
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
              child: Text('Ningún municipio con ese nombre.',
                  style: GmText.meta(color: gm.label2)),
            ),
          for (final (name, n) in rows) ...[
            Divider(height: 1, thickness: 1, color: gm.sep),
            Semantics(
              button: true,
              selected: selected.contains(name),
              label: n == 1 ? '$name, 1 visita' : '$name, $n visitas',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onToggle(name),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Text(name, style: GmText.body17(color: gm.label)),
                      ),
                      Text('$n', style: GmText.sub(color: gm.label2)),
                      const SizedBox(width: 12),
                      _Radio(on: selected.contains(name)),
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
        gradient: on ? GmColors.accentFill : null,
        border: on ? null : Border.all(color: gm.sep, width: 1.5),
      ),
      alignment: Alignment.center,
      child: on ? GmIcon(GmIcons.check, size: 12, color: Colors.white) : null,
    );
  }
}

/// Botón fijo sin resultados: `accentSoft` + `label2`, sin acción (el
/// texto parte en dos líneas con letra grande).
class _DisabledCta extends StatelessWidget {
  const _DisabledCta();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'discover-filter-apply',
      button: true,
      enabled: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: gm.accentSoft,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        child: Text(
          visitFilterCta(0),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: gm.label2,
          ),
        ),
      ),
    );
  }
}
