import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/list_appearance_card.dart';

class ListAppearance {
  final CuratedList list;
  final int position;
  const ListAppearance({required this.list, required this.position});
}

class ListAppearancesSection extends StatelessWidget {
  final List<ListAppearance> appearances;
  final ValueChanged<ListAppearance>? onTapAppearance;
  final VoidCallback? onSeeAll;

  const ListAppearancesSection({
    super.key,
    required this.appearances,
    this.onTapAppearance,
    this.onSeeAll,
  });

  static bool shouldRender(List<ListAppearance> a) => a.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'APARECE EN LISTAS',
                  style: AppTextStyles.displaySection(
                    size: 11,
                    color: AppColors.atlantico,
                  ),
                ),
              ),
              if (onSeeAll != null && appearances.length > 1)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${appearances.length} LISTAS',
                        style: AppTextStyles.eyebrow(
                          size: 10,
                          color: AppColors.atlanticoClaro,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.atlanticoClaro,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: appearances.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final a = appearances[i];
              return ListAppearanceCard(
                list: a.list,
                position: a.position,
                onTap: () => onTapAppearance?.call(a),
              );
            },
          ),
        ),
      ],
    );
  }
}
