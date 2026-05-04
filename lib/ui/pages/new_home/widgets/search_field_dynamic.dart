import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class SearchFieldDynamic extends StatelessWidget {
  final String? zone;
  final VoidCallback onTap;

  const SearchFieldDynamic({
    super.key,
    this.zone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = zone != null
        ? 'Buscar en $zone...'
        : 'Buscar restaurante...';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: context.brand.surface.withOpacity(0.6),
          border: Border.all(
            color: context.brand.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.atlanticoClaro,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                placeholder,
                style: AppTextStyles.editorial(
                  size: 13,
                  color: context.brand.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
