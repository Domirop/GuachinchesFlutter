import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sectionHeaderTop,
        AppSpacing.gutter,
        AppSpacing.sectionHeaderBottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Título de sección real (no eyebrow): con las cards a 16, el
              // encabezado debe mandar — patrón Apple de section headers.
              style: AppTextStyles.displaySection(
                size: 18,
                color: context.brand.textPrimary,
              ).copyWith(letterSpacing: 0.6),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              identifier: 'section-header-cta',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: GestureDetector(
                  onTap: onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '$actionLabel ›',
                      style: AppTextStyles.ui(
                        size: 11,
                        color: AppColors.atlanticoClaro,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
