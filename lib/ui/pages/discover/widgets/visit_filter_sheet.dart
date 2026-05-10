import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Active filters for the visits browser.
class VisitFilterValues {
  final Set<String> creators;
  final Set<String> sentiments; // muy_positivo | positivo | neutro | negativo
  final Set<String> zones;
  final bool onlyWithVideo;

  const VisitFilterValues({
    this.creators = const {},
    this.sentiments = const {},
    this.zones = const {},
    this.onlyWithVideo = false,
  });

  int get count =>
      creators.length +
      sentiments.length +
      zones.length +
      (onlyWithVideo ? 1 : 0);

  VisitFilterValues copyWith({
    Set<String>? creators,
    Set<String>? sentiments,
    Set<String>? zones,
    bool? onlyWithVideo,
  }) =>
      VisitFilterValues(
        creators: creators ?? this.creators,
        sentiments: sentiments ?? this.sentiments,
        zones: zones ?? this.zones,
        onlyWithVideo: onlyWithVideo ?? this.onlyWithVideo,
      );
}

const Map<String, String> kSentimentLabels = {
  'muy_positivo': 'Muy positivo',
  'positivo': 'Positivo',
  'neutro': 'Neutro',
  'negativo': 'Negativo',
};

class VisitFilterSheet extends StatefulWidget {
  final VisitFilterValues initial;
  final List<String> creators;
  final List<String> zones;

  const VisitFilterSheet({
    super.key,
    required this.initial,
    required this.creators,
    required this.zones,
  });

  static Future<VisitFilterValues?> show({
    required BuildContext context,
    required VisitFilterValues initial,
    required List<String> creators,
    required List<String> zones,
  }) {
    return showModalBottomSheet<VisitFilterValues>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.brand.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => VisitFilterSheet(
        initial: initial,
        creators: creators,
        zones: zones,
      ),
    );
  }

  @override
  State<VisitFilterSheet> createState() => _VisitFilterSheetState();
}

class _VisitFilterSheetState extends State<VisitFilterSheet> {
  late VisitFilterValues _values;

  @override
  void initState() {
    super.initState();
    _values = widget.initial;
  }

  void _toggleCreator(String c) {
    setState(() {
      final next = Set<String>.from(_values.creators);
      next.contains(c) ? next.remove(c) : next.add(c);
      _values = _values.copyWith(creators: next);
    });
  }

  void _toggleSentiment(String s) {
    setState(() {
      final next = Set<String>.from(_values.sentiments);
      next.contains(s) ? next.remove(s) : next.add(s);
      _values = _values.copyWith(sentiments: next);
    });
  }

  void _toggleZone(String z) {
    setState(() {
      final next = Set<String>.from(_values.zones);
      next.contains(z) ? next.remove(z) : next.add(z);
      _values = _values.copyWith(zones: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.86),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: context.brand.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtrar visitas',
                      style: AppTextStyles.displaySection(size: 18),
                    ),
                  ),
                  if (_values.count > 0)
                    GestureDetector(
                      onTap: () => setState(
                          () => _values = const VisitFilterValues()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: Text(
                          'Limpiar todo',
                          style: AppTextStyles.ui(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.atlanticoClaro,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.creators.isNotEmpty) ...[
                      _SectionTitle('Creador'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in widget.creators)
                            _PickerChip(
                              label: c,
                              selected: _values.creators.contains(c),
                              onTap: () => _toggleCreator(c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                    _SectionTitle('Sentimiento'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in kSentimentLabels.entries)
                          _PickerChip(
                            label: entry.value,
                            selected: _values.sentiments.contains(entry.key),
                            color: _sentimentColor(entry.key),
                            onTap: () => _toggleSentiment(entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (widget.zones.isNotEmpty) ...[
                      _SectionTitle('Zona'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final z in widget.zones)
                            _PickerChip(
                              label: z,
                              selected: _values.zones.contains(z),
                              onTap: () => _toggleZone(z),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                    _SectionTitle('Otros'),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.atlanticoClaro,
                      value: _values.onlyWithVideo,
                      onChanged: (v) => setState(() =>
                          _values = _values.copyWith(onlyWithVideo: v)),
                      title: Text(
                        'Solo visitas con vídeo',
                        style: AppTextStyles.ui(
                          size: 14,
                          color: context.brand.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer apply
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _values),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.atlantico,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    _values.count == 0
                        ? 'Ver visitas'
                        : 'Aplicar · ${_values.count} filtro${_values.count == 1 ? '' : 's'}',
                    style: AppTextStyles.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _sentimentColor(String s) {
    switch (s) {
      case 'muy_positivo':
        return AppColors.laurisilva;
      case 'positivo':
        return AppColors.atlantico;
      case 'neutro':
        return AppColors.arena;
      case 'negativo':
        return AppColors.mojo;
    }
    return null;
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.eyebrow(
        size: 11,
        color: AppColors.atlanticoClaro,
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _PickerChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.atlantico;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.18)
              : context.brand.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.55)
                : context.brand.borderStrong,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.ui(
            size: 13,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accent : context.brand.textPrimary,
          ),
        ),
      ),
    );
  }
}
