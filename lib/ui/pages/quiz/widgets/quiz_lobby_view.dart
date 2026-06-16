import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_map_board.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Pestaña INICIO: el **mapa de conquista de Canarias**. Las 7 islas se
/// iluminan en el color del tier al conquistarlas. Debajo: continuar / nueva
/// partida y tus marcas.
class QuizLobbyView extends StatelessWidget {
  final QuizGameState state;
  final VoidCallback onPlay;
  final ValueChanged<QuizSession> onResume;
  final VoidCallback onHowTo;

  const QuizLobbyView({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onResume,
    required this.onHowTo,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final conquest = state.conquest;
    final tier = conquest?.tier ?? 1;
    final tierName = conquest?.tierName ?? 'Marea';
    final owned = conquest?.conqueredIslands.toSet() ?? <String>{};
    final color = quizTierColor(tier);
    final active = state.activeSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        // Tier + progreso
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: color.withValues(alpha: 0.55)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.terrain_rounded, size: 15, color: color),
                  const SizedBox(width: 6),
                  Text('ARENA · ${tierName.toUpperCase()}',
                      style: AppTextStyles.eyebrow(size: 10, color: color)),
                ],
              ),
            ),
            const Spacer(),
            Text('${owned.length}/7 islas',
                style: AppTextStyles.displaySection(
                    size: 13, color: brand.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        Text('CONQUISTA CANARIAS',
            style: AppTextStyles.displayHero(size: 26, color: brand.textPrimary)),
        Text('Gana partidas para conquistar islas. Completa la arena y asciende.',
            style: AppTextStyles.editorial(size: 13, color: brand.textSecondary)),
        const SizedBox(height: 14),
        // El mapa
        QuizMapBoard(owned: owned, tierColor: color),
        const SizedBox(height: 18),
        // Partida en curso
        if (active != null) ...[
          _ActiveGameCard(
              session: active,
              tierColor: color,
              onResume: () => onResume(active)),
          const SizedBox(height: 12),
        ],
        _PlayButton(
            label: active != null ? 'NUEVA PARTIDA' : 'JUGAR', onTap: onPlay),
        const SizedBox(height: 20),
        // Marcas
        _StatsRow(stats: state.stats),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onHowTo,
            child: Text('¿Cómo se juega?',
                style: AppTextStyles.ui(
                    size: 13,
                    color: brand.textSecondary,
                    weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _ActiveGameCard extends StatelessWidget {
  final QuizSession session;
  final Color tierColor;
  final VoidCallback onResume;
  const _ActiveGameCard({
    required this.session,
    required this.tierColor,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return QuizGlassCard(
      tint: AppColors.atlantico.withValues(alpha: 0.16),
      borderColor: AppColors.atlantico.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded,
              color: AppColors.atlanticoClaro, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PARTIDA EN CURSO',
                    style: AppTextStyles.eyebrow(
                        size: 10, color: AppColors.atlanticoClaro)),
                const SizedBox(height: 2),
                Text(
                    '${session.wedges.length}/7 quesitos · ${session.lives} vidas · ${session.score} pts',
                    style: AppTextStyles.ui(size: 12, color: brand.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onResume,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.atlantico,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text('CONTINUAR',
                  style: AppTextStyles.displaySection(
                      size: 12, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final QuizStats? stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return QuizGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _Stat(label: 'PUNTOS', value: '${stats?.totalPoints ?? 0}'),
          _Divider(),
          _Stat(label: 'GANADAS', value: '${stats?.gamesWon ?? 0}'),
          _Divider(),
          _Stat(label: 'MEJOR RACHA', value: '${stats?.bestStreak ?? 0}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displaySection(
                  size: 16, color: brand.textPrimary)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.eyebrow(size: 9, color: brand.textMuted)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 28, color: context.brand.border);
}

class _PlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlayButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.atlantico, AppColors.atlanticoClaro],
          ),
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: AppColors.atlantico.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(label,
            style: AppTextStyles.displaySection(size: 18, color: Colors.white)
                .copyWith(letterSpacing: 2)),
      ),
    );
  }
}
