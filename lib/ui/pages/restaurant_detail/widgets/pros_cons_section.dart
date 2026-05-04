import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class ProsConsSection extends StatelessWidget {
  final List<String> pros;
  final List<String> cons;

  const ProsConsSection({
    super.key,
    required this.pros,
    required this.cons,
  });

  static bool shouldRender(List<String> pros, List<String> cons) =>
      pros.isNotEmpty || cons.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pros.isNotEmpty)
            Expanded(
              child: _Column(
                title: 'A FAVOR',
                items: pros,
                prefix: '+',
                prefixColor: AppColors.laurisilva,
              ),
            ),
          if (pros.isNotEmpty && cons.isNotEmpty)
            const SizedBox(width: 16),
          if (cons.isNotEmpty)
            Expanded(
              child: _Column(
                title: 'EN CONTRA',
                items: cons,
                prefix: '–',
                prefixColor: AppColors.mojo,
              ),
            ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final List<String> items;
  final String prefix;
  final Color prefixColor;

  const _Column({
    required this.title,
    required this.items,
    required this.prefix,
    required this.prefixColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.displaySection(
            size: 10,
            color: AppColors.atlantico,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefix,
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: prefixColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.ui(
                      size: 11,
                      color: context.brand.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
