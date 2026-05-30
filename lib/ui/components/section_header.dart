import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
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
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.eyebrow(
                size: 10,
                color: context.brand.textSecondary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              identifier: 'section-header-cta',
              child: GestureDetector(
                onTap: onAction,
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
        ],
      ),
    );
  }
}
