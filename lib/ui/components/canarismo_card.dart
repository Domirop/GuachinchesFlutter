import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_detail_screen.dart';

/// "Canarismo del día" — teaser compacto en el feed del home.
/// Al tocar navega a CanarismoDetailScreen con la palabra del día.
class CanarismoCard extends StatelessWidget {
  const CanarismoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final c = canarismoOfDay();

    return Semantics(
      identifier: 'home-canarismo',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(
          color: brand.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brand.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Semantics(
          identifier: 'home-canarismo-toggle',
          button: true,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CanarismoDetailScreen(initial: c),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('🗣️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CANARISMO DEL DÍA',
                          style: AppTextStyles.eyebrow(
                            size: 10,
                            color: AppColors.atlantico,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '"${c.palabra}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displaySection(
                            size: 16,
                            color: brand.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: brand.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
