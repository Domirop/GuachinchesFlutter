import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class ListasFilterValues {
  final List<String> authors;
  final bool featuredOnly;
  final int minCount;

  const ListasFilterValues({
    this.authors = const [],
    this.featuredOnly = false,
    this.minCount = 0,
  });

  int get count =>
      authors.length +
      (featuredOnly ? 1 : 0) +
      (minCount > 0 ? 1 : 0);

  ListasFilterValues copyWith({
    List<String>? authors,
    bool? featuredOnly,
    int? minCount,
  }) =>
      ListasFilterValues(
        authors: authors ?? this.authors,
        featuredOnly: featuredOnly ?? this.featuredOnly,
        minCount: minCount ?? this.minCount,
      );
}

class ListasFilterSheet extends StatefulWidget {
  final ListasFilterValues initial;

  const ListasFilterSheet({super.key, required this.initial});

  static Future<ListasFilterValues?> show({
    required BuildContext context,
    required ListasFilterValues initial,
  }) {
    return showModalBottomSheet<ListasFilterValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.brand.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ListasFilterSheet(initial: initial),
    );
  }

  @override
  State<ListasFilterSheet> createState() => _ListasFilterSheetState();
}

class _ListasFilterSheetState extends State<ListasFilterSheet> {
  late ListasFilterValues _values;

  static const _kAuthors = [
    ('JONAY', 'Jonay'),
    ('JOANA', 'Joana'),
  ];

  static const _kMinCounts = [
    (5, '≥ 5 sitios'),
    (10, '≥ 10 sitios'),
  ];

  @override
  void initState() {
    super.initState();
    _values = widget.initial;
  }

  void _clearAll() => setState(() => _values = const ListasFilterValues());

  void _toggleAuthor(String key) {
    final next = List<String>.from(_values.authors);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    setState(() => _values = _values.copyWith(authors: next));
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
                      'FILTROS',
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
                    _SheetSectionLabel(title: 'AUTOR'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kAuthors.map((entry) {
                        final (key, label) = entry;
                        return _SheetChip(
                          label: label,
                          selected: _values.authors.contains(key),
                          onTap: () => _toggleAuthor(key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    _SheetSectionLabel(title: 'DESTACADAS'),
                    const SizedBox(height: 10),
                    _SheetChip(
                      label: 'Solo destacadas',
                      selected: _values.featuredOnly,
                      onTap: () => setState(
                        () => _values = _values.copyWith(
                          featuredOnly: !_values.featuredOnly,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SheetSectionLabel(title: 'TAMAÑO'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kMinCounts.map((entry) {
                        final (value, label) = entry;
                        final selected = _values.minCount == value;
                        return _SheetChip(
                          label: label,
                          selected: selected,
                          onTap: () => setState(
                            () => _values = _values.copyWith(
                              minCount: selected ? 0 : value,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
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
                        ? 'Ver resultados · ${_values.count} filtros'
                        : 'Ver resultados',
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

class _SheetSectionLabel extends StatelessWidget {
  final String title;
  const _SheetSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.eyebrow(size: 11, color: AppColors.atlanticoClaro),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _SheetChip({
    required this.label,
    required this.selected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.atlantico.withValues(alpha: 0.18)
                : context.brand.surface,
            border: Border.all(
              color: selected
                  ? AppColors.atlantico.withValues(alpha: 0.55)
                  : context.brand.borderStrong,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: AppTextStyles.ui(
              size: 13,
              weight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.atlanticoClaro
                  : context.brand.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
