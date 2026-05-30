import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/components/curated_hero_image.dart';

/// Card grande estilo revista para recopilatorios editoriales.
class CardCuratedList extends StatelessWidget {
  final CuratedList list;
  final VoidCallback onTap;

  const CardCuratedList({
    super.key,
    required this.list,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.brand.surface,
          border: Border.all(
            color: context.brand.border,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero visual
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo degradado con el accent
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          list.accent.withOpacity(0.55),
                          list.accent.withOpacity(0.15),
                          context.brand.surface,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                  // Portada: URL remota (S3) o asset local — el helper decide.
                  if (list.heroAsset != null)
                    CuratedHeroImage(source: list.heroAsset!)
                  else if (list.heroEmoji != null)
                    Positioned(
                      right: -14,
                      bottom: -22,
                      child: Text(
                        list.heroEmoji!,
                        style: const TextStyle(fontSize: 140),
                      ),
                    ),
                  // Eyebrow flotante arriba-izquierda
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        list.eyebrow,
                        style: AppTextStyles.eyebrow(
                          size: 9,
                          color: AppColors.crema.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  // Contador en píldora arriba-derecha
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.brand.textPrimary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${list.count} sitios',
                        style: AppTextStyles.ui(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pie editorial
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displayHero(size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    list.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.editorial(size: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: context.brand.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        list.location,
                        style: AppTextStyles.ui(
                          size: 10,
                          weight: FontWeight.w500,
                          color: context.brand.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'VER LISTA',
                        style: AppTextStyles.eyebrow(
                          size: 9,
                          color: AppColors.atlanticoClaro,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.atlanticoClaro,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
