import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
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
                child: GmDetailTitle('Aparece en listas'),
              ),
              if (onSeeAll != null && appearances.length > 1)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${appearances.length} listas',
                        style: GmText.eyebrow(
                            color: GmColors.of(context).label2),
                      ),
                      const SizedBox(width: 3),
                      GmIcon(GmIcons.chevronRight,
                          size: 13, color: GmColors.of(context).label2),
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
