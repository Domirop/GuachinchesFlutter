import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class SectionErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryAnchor;

  const SectionErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryAnchor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.ui(
                size: 13,
                color: context.brand.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            identifier: retryAnchor,
            child: GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'Reintentar',
                  style: AppTextStyles.ui(
                    size: 13,
                    color: AppColors.atlanticoClaro,
                    weight: FontWeight.w600,
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
