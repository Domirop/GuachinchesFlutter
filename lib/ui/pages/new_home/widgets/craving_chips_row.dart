import 'package:flutter/material.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/domain/cravings/craving.dart';

/// Fila "¿Qué te apetece ahora?" — chips de antojo que cambian según hora,
/// clima y día (ranking en [rankCravings]). Tocar uno abre la búsqueda con su
/// filtro temático aplicado.
///
/// Solo presentación: recibe ya la lista rankeada y delega el tap. La lógica
/// vive en `domain/cravings/` (testeable en aislamiento).
class CravingChipsRow extends StatelessWidget {
  final List<Craving> cravings;
  final ValueChanged<Craving> onTap;

  const CravingChipsRow({
    super.key,
    required this.cravings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cravings.isEmpty) return const SizedBox.shrink();
    final brand = context.brand;
    return Semantics(
      identifier: 'home-section-cravings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 10),
            child: Text(
              '¿QUÉ TE APETECE AHORA?',
              style: AppTextStyles.eyebrow(size: 11, color: brand.textSecondary),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              itemCount: cravings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = cravings[i];
                return _CravingChip(craving: c, onTap: () => onTap(c));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CravingChip extends StatelessWidget {
  final Craving craving;
  final VoidCallback onTap;
  const _CravingChip({required this.craving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'home-craving-${craving.id}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: brand.glass,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: brand.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(craving.emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Text(
                craving.label,
                style: AppTextStyles.ui(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: brand.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
