import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

enum VisitSort {
  newest,
  oldest,
  ratingDesc,
  alphaAsc,
  byCreator,
}

extension VisitSortMeta on VisitSort {
  String get label {
    switch (this) {
      case VisitSort.newest:
        return 'Más recientes';
      case VisitSort.oldest:
        return 'Más antiguas';
      case VisitSort.ratingDesc:
        return 'Mejor valoradas';
      case VisitSort.alphaAsc:
        return 'A-Z restaurante';
      case VisitSort.byCreator:
        return 'Por autor';
    }
  }

  IconData get icon {
    switch (this) {
      case VisitSort.newest:
        return Icons.schedule_rounded;
      case VisitSort.oldest:
        return Icons.history_rounded;
      case VisitSort.ratingDesc:
        return Icons.star_rounded;
      case VisitSort.alphaAsc:
        return Icons.sort_by_alpha_rounded;
      case VisitSort.byCreator:
        return Icons.person_rounded;
    }
  }
}

class VisitSortSheet extends StatelessWidget {
  final VisitSort current;

  const VisitSortSheet({super.key, required this.current});

  static Future<VisitSort?> show({
    required BuildContext context,
    required VisitSort current,
  }) {
    return showModalBottomSheet<VisitSort>(
      context: context,
      backgroundColor: context.brand.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => VisitSortSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 14),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.brand.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Ordenar por',
                style: AppTextStyles.displaySection(size: 16),
              ),
            ),
            for (final s in VisitSort.values)
              _SortRow(
                option: s,
                selected: s == current,
                onTap: () => Navigator.pop(context, s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  final VisitSort option;
  final bool selected;
  final VoidCallback onTap;

  const _SortRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.atlanticoClaro
        : context.brand.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.atlantico.withOpacity(0.18)
                    : context.brand.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.atlantico.withOpacity(0.45)
                      : context.brand.border,
                ),
              ),
              child: Icon(option.icon, size: 18, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.ui(
                  size: 14,
                  weight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  size: 18, color: AppColors.atlanticoClaro),
          ],
        ),
      ),
    );
  }
}
