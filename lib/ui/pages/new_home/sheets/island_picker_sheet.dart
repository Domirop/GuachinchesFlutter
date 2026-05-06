import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/defaultData/allIsland.dart';
import 'package:guachinches/data/model/Island.dart';

/// Bottom sheet para cambiar de isla. Mismo lenguaje visual que ZonePickerSheet.
class IslandPickerSheet extends StatelessWidget {
  final String selectedIslandId;
  final ValueChanged<Island> onSelect;

  const IslandPickerSheet({
    super.key,
    required this.selectedIslandId,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required String selectedIslandId,
    required ValueChanged<Island> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.brand.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => IslandPickerSheet(
        selectedIslandId: selectedIslandId,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final islands = AllIsland().allIsland;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.brand.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'CAMBIA DE ISLA',
              style: AppTextStyles.displaySection(size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige dónde quieres comer hoy',
              style: AppTextStyles.muted(size: 12),
            ),
            const SizedBox(height: 16),
            ...islands.map((island) {
              final active = island.id == selectedIslandId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _IslandListCard(
                  island: island,
                  active: active,
                  onTap: () {
                    Navigator.pop(context);
                    if (!active) onSelect(island);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _IslandListCard extends StatelessWidget {
  final Island island;
  final bool active;
  final VoidCallback onTap;

  const _IslandListCard({
    required this.island,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.atlantico.withOpacity(0.12)
                : context.brand.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? AppColors.atlantico.withOpacity(0.55)
                  : context.brand.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IslandThumb(asset: 'assets/images/${island.photo}'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            island.name.toUpperCase(),
                            style: AppTextStyles.displaySection(size: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.atlantico,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _description(island.id),
                      style: AppTextStyles.muted(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: context.brand.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _description(String id) {
    switch (id) {
      case '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d':
        return 'Guachinches, mar y Teide';
      case '6f91d60f-0996-4dde-9088-167aab83a21a':
        return 'Capital, dunas y kilómetros de costa';
      default:
        return '';
    }
  }
}

class _IslandThumb extends StatelessWidget {
  final String asset;
  const _IslandThumb({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.atlanticoClaro, AppColors.atlantico],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(
          image: AssetImage(asset),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
    );
  }
}
