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
      child: Container(
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.brand.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pros.isNotEmpty)
              _Block(
                title: 'A FAVOR',
                items: pros,
                accent: AppColors.laurisilva,
                icon: Icons.check_rounded,
              ),
            if (pros.isNotEmpty && cons.isNotEmpty)
              Divider(
                height: 1,
                thickness: 1,
                color: context.brand.border,
              ),
            if (cons.isNotEmpty)
              _Block(
                title: 'EN CONTRA',
                items: cons,
                accent: AppColors.mojo,
                icon: Icons.close_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color accent;
  final IconData icon;

  const _Block({
    required this.title,
    required this.items,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.displaySection(size: 11, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _capitalize(item),
                      style: AppTextStyles.ui(
                        size: 12,
                        color: context.brand.textPrimary,
                      ).copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
