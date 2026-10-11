import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/curated_list.dart';

/// Card que muestra una lista curada en la que aparece este restaurante,
/// destacando su puesto.
class ListAppearanceCard extends StatelessWidget {
  final CuratedList list;
  final int position;
  final VoidCallback onTap;

  const ListAppearanceCard({
    super.key,
    required this.list,
    required this.position,
    required this.onTap,
  });

  String get _rank => position.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GmRadius.card),
          color: context.brand.surface,
          border: Border.all(color: context.brand.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              list.accent.withOpacity(0.85),
              list.accent.withOpacity(0.35),
              context.brand.surface,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Número de puesto gigante translúcido
            Positioned(
              right: -10,
              bottom: -28,
              child: Text(
                _rank,
                style: TextStyle(
                  fontSize: 140,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -6,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pill PUESTO Nº XX · CREATOR
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _topPill(),
                      style: GmText.chip(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Título
                  Expanded(
                    child: Text(
                      list.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.guideTitle(color: Colors.white).copyWith(
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  // Footer: X sitios + chevron
                  Row(
                    children: [
                      Text(
                        '${list.count} sitios',
                        style: AppTextStyles.ui(
                          size: 11,
                          weight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.75),
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

  String _topPill() {
    final puesto = 'Puesto nº $_rank';
    if (list.eyebrow.isEmpty) return puesto;
    final e = list.eyebrow.trim();
    final pretty = e == e.toUpperCase() && e.length > 1
        ? e[0] + e.substring(1).toLowerCase()
        : e;
    return '$puesto · $pretty';
  }
}
