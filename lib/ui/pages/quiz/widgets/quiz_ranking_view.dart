import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';

/// Pestaña RANKING: tabla de jugadores por puntos totales. Tu fila resaltada.
class QuizRankingView extends StatelessWidget {
  final QuizGameState state;
  const QuizRankingView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    if (state.rankingLoading && state.ranking.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.atlanticoClaro),
      );
    }
    if (state.ranking.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.leaderboard_rounded,
                  size: 48, color: brand.textMuted),
              const SizedBox(height: 12),
              Text('Aún no hay ranking',
                  style: AppTextStyles.displaySection(
                      size: 15, color: brand.textPrimary)),
              const SizedBox(height: 6),
              Text('Juega una partida y aparece tu nombre aquí.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.editorial(
                      size: 13,
                      color: brand.textSecondary)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: state.ranking.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RankRow(entry: state.ranking[i]),
    );
  }
}

class _RankRow extends StatelessWidget {
  final QuizRankingEntry entry;
  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final me = entry.isMe;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: me
            ? AppColors.atlantico.withValues(alpha: 0.16)
            : brand.glass,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: me
              ? AppColors.atlantico.withValues(alpha: 0.5)
              : brand.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: _Position(position: entry.position)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me ? '${entry.name} (tú)' : entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ui(
                        size: 14,
                        color: brand.textPrimary,
                        weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(entry.rank.name,
                    style: AppTextStyles.eyebrow(
                        size: 9, color: AppColors.atlanticoClaro)),
              ],
            ),
          ),
          Text('${entry.totalPoints}',
              style:
                  AppTextStyles.displaySection(size: 16, color: brand.textPrimary)),
          const SizedBox(width: 3),
          Text('PTS',
              style: AppTextStyles.eyebrow(
                  size: 8, color: brand.textMuted)),
        ],
      ),
    );
  }
}

class _Position extends StatelessWidget {
  final int position;
  const _Position({required this.position});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    Color? medal;
    if (position == 1) medal = AppColors.sol;
    if (position == 2) medal = const Color(0xFFC0C0C0);
    if (position == 3) medal = const Color(0xFFCD7F32);
    if (medal != null) {
      return Center(
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: medal.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: medal),
          ),
          child: Text('$position',
              style: AppTextStyles.displaySection(size: 14, color: medal)),
        ),
      );
    }
    return Center(
      child: Text('$position',
          style: AppTextStyles.displaySection(
              size: 15, color: brand.textSecondary)),
    );
  }
}
