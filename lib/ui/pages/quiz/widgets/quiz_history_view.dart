import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

/// Pestaña HISTÓRICO: todas tus partidas terminadas (cada una independiente).
class QuizHistoryView extends StatelessWidget {
  final QuizGameState state;
  const QuizHistoryView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final history = state.history;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 48, color: AppColors.crema.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Aún no has jugado',
                  style: AppTextStyles.displaySection(
                      size: 15, color: AppColors.crema)),
              const SizedBox(height: 6),
              Text('Tus partidas terminadas aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.editorial(
                      size: 13,
                      color: AppColors.crema.withValues(alpha: 0.55))),
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
                    size: 13, color: AppColors.crema)),
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
    final won = summary.isWon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: won
              ? AppColors.laurisilva.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(won ? Icons.emoji_events_rounded : Icons.flag_rounded,
              color: won
                  ? AppColors.sol
                  : AppColors.crema.withValues(alpha: 0.5),
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(won ? '¡Pleno!' : 'Derrota',
                    style: AppTextStyles.ui(
                        size: 13,
                        color: won ? AppColors.laurisilva : AppColors.crema,
                        weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${summary.wedges.length}/7 quesitos · ${_date(summary.endedAt)}',
                    style: AppTextStyles.ui(
                        size: 11,
                        color: AppColors.crema.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Text('${summary.score}',
              style: AppTextStyles.displaySection(
                  size: 17, color: AppColors.crema)),
          const SizedBox(width: 3),
          Text('PTS',
              style: AppTextStyles.eyebrow(
                  size: 8, color: AppColors.crema.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
