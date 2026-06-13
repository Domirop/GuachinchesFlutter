import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';

class VisitHeaderSection extends StatelessWidget {
  final Visit visit;

  const VisitHeaderSection({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _JJAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.creator?.toUpperCase() ?? 'JONAY Y JOANA',
                  style: AppTextStyles.displaySection(
                    size: 12,
                    color: context.brand.textPrimary,
                  ),
                ),
                if (visit.sortDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(visit.sortDate!),
                    style: AppTextStyles.muted(
                      size: 10,
                      color: context.brand.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (visit.overallSentiment != null)
            _SentimentBadge(visit.overallSentiment!),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const months = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}

class _JJAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.atlantico,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'JJ',
        style: AppTextStyles.displaySection(
          size: 11,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SentimentBadge extends StatelessWidget {
  final String sentiment;
  const _SentimentBadge(this.sentiment);

  @override
  Widget build(BuildContext context) {
    final label = _label(sentiment);
    final color = _color(sentiment);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.displaySection(size: 10, color: color),
        ),
      ],
    );
  }

  String _label(String s) {
    switch (s.toLowerCase()) {
      case 'muy_positivo':
        return 'MUY POSITIVO';
      case 'positivo':
        return 'POSITIVO';
      case 'neutro':
        return 'NEUTRO';
      case 'negativo':
        return 'NEGATIVO';
      default:
        return s.toUpperCase().replaceAll('_', ' ');
    }
  }

  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'muy_positivo':
      case 'positivo':
        return AppColors.laurisilva;
      case 'negativo':
        return AppColors.mojo;
      default:
        return AppColors.crema.withOpacity(0.45);
    }
  }
}
