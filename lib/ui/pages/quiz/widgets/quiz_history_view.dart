import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

/// Pestaña HISTÓRICO: todas tus partidas terminadas (cada una independiente).
class QuizHistoryView extends StatelessWidget {
  final QuizGameState state;
  const QuizHistoryView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final history = state.history;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 48, color: brand.textMuted),
              const SizedBox(height: 12),
              Text('Aún no has jugado',
                  style: AppTextStyles.displaySection(
                      size: 15, color: brand.textPrimary)),
              const SizedBox(height: 6),
              Text('Tus partidas terminadas aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.editorial(
                      size: 13,
                      color: brand.textSecondary)),
            ],
          ),
        ),
      );
    }
    final won = history.where((h) => h.isWon).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            Text('${history.length} PARTIDAS',
                style: AppTextStyles.displaySection(
                    size: 13, color: brand.textPrimary)),
            const Spacer(),
            Text('$won ganadas',
                style: AppTextStyles.ui(
                    size: 12, color: AppColors.laurisilva)),
          ],
        ),
        const SizedBox(height: 12),
        for (final h in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QuizHistoryRow(summary: h),
          ),
      ],
    );
  }
}

class QuizHistoryRow extends StatelessWidget {
  final QuizSessionSummary summary;
  const QuizHistoryRow({super.key, required this.summary});

  String _date(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const m = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${m[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final won = summary.isWon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: brand.glass,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: won
              ? AppColors.laurisilva.withValues(alpha: 0.3)
              : brand.border,
        ),
      ),
      child: Row(
        children: [
          Icon(won ? Icons.emoji_events_rounded : Icons.flag_rounded,
              color: won
                  ? AppColors.sol
                  : brand.textSecondary,
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(won ? '¡Pleno!' : 'Derrota',
                    style: AppTextStyles.ui(
                        size: 13,
                        color: won ? AppColors.laurisilva : brand.textPrimary,
                        weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${summary.wedges.length}/7 quesitos · ${_date(summary.endedAt)}',
                    style: AppTextStyles.ui(
                        size: 11,
                        color: brand.textSecondary)),
              ],
            ),
          ),
          Text('${summary.score}',
              style: AppTextStyles.displaySection(
                  size: 17, color: brand.textPrimary)),
          const SizedBox(width: 3),
          Text('PTS',
              style: AppTextStyles.eyebrow(
                  size: 8, color: brand.textMuted)),
        ],
      ),
    );
  }
}
