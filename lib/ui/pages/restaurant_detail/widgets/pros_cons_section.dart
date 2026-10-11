import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/config/app_colors.dart';

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
      child: GmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pros.isNotEmpty)
              _Block(
                title: 'A favor',
                items: pros,
                accent: AppColors.laurisilva,
                icon: Icons.check_rounded,
              ),
            if (pros.isNotEmpty && cons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(height: 1, color: GmColors.of(context).sep),
              ),
            if (cons.isNotEmpty)
              _Block(
                title: 'En contra',
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
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GmText.cardTitle(color: gm.label),
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _capitalize(item),
                      style: GmText.body(color: gm.label),
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
