import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Pestaña INICIO: partida en curso (si la dejaste a medias), JUGAR (nueva
/// partida, siempre de cero), tu perfil persistente (nivel, puntos totales,
/// partidas ganadas, mejores marcas) y un preview neutral de las 7 categorías.
///
/// Los quesitos NO se muestran aquí como colección: son el tablero de cada
/// partida y solo se ven jugando.
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
    final cats = state.categories;
    final active = state.activeSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        // Partida en curso (solo si la dejaste a medias)
        if (active != null) ...[
          _ActiveGameCard(
            session: active,
            categories: cats,
            onResume: () => onResume(active),
          ),
          const SizedBox(height: 20),
        ],
        Center(
          child: Text('PON A PRUEBA TU CANARIEDAD',
              style: AppTextStyles.eyebrow(
                  size: 11, color: AppColors.atlanticoClaro)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('¿CUÁNTO SABES\nDE CANARIAS?',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHero(size: 32, color: brand.textPrimary)
                  .copyWith(height: 1.04)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Reúne un quesito de cada isla con 3 vidas. Cada partida empieza de cero.',
            textAlign: TextAlign.center,
            style: AppTextStyles.editorial(
                size: 13, color: brand.textSecondary),
          ),
        ),
        const SizedBox(height: 18),
        _PlayButton(
            label: active != null ? 'NUEVA PARTIDA' : 'JUGAR', onTap: onPlay),
        const SizedBox(height: 24),
        // Perfil persistente
        _ProfileCard(stats: state.stats),
        const SizedBox(height: 24),
        // Preview neutral de categorías
        Text('A QUÉ TE ENFRENTAS',
            style:
                AppTextStyles.displaySection(size: 13, color: brand.textPrimary)),
        const SizedBox(height: 12),
        if (cats.isNotEmpty)
          QuizCategoriesPreview(categories: cats)
        else
          const _PreviewSkeleton(),
        const SizedBox(height: 18),
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

class _ProfileCard extends StatelessWidget {
  final QuizStats? stats;
  const _ProfileCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final rank = stats?.rank;
    final rankName = rank?.name ?? 'Gofio';
    final next = rank?.next;
    final gamesWon = rank?.gamesWon ?? 0;
    final hint = next == null
        ? 'Nivel máximo'
        : 'A ${(next.at - gamesWon).clamp(0, 99)} ${(next.at - gamesWon) == 1 ? 'partida' : 'partidas'} de ${next.name}';

    return QuizGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sol.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.sol.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.military_tech_rounded,
                    color: AppColors.sol, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TU NIVEL',
                      style: AppTextStyles.eyebrow(
                          size: 9,
                          color: brand.textMuted)),
                  const SizedBox(height: 2),
                  Text(rankName.toUpperCase(),
                      style: AppTextStyles.displaySection(
                          size: 18, color: brand.textPrimary)),
                ],
              ),
              const Spacer(),
              Flexible(
                child: Text(hint,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.ui(
                        size: 11,
                        color: AppColors.atlanticoClaro,
                        weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: brand.border),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'PUNTOS', value: '${stats?.totalPoints ?? 0}'),
              _Stat(label: 'GANADAS', value: '${stats?.gamesWon ?? 0}'),
              _Stat(label: 'MEJOR RACHA', value: '${stats?.bestStreak ?? 0}'),
              _Stat(label: 'MEJOR PUNT.', value: '${stats?.bestScore ?? 0}'),
            ],
          ),
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
              style: AppTextStyles.eyebrow(
                  size: 8, color: brand.textMuted)),
        ],
      ),
    );
  }
}

class _ActiveGameCard extends StatelessWidget {
  final QuizSession session;
  final List<QuizCategory> categories;
  final VoidCallback onResume;
  const _ActiveGameCard({
    required this.session,
    required this.categories,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return QuizGlassCard(
      tint: AppColors.atlantico.withValues(alpha: 0.16),
      borderColor: AppColors.atlantico.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded,
                  color: AppColors.atlanticoClaro, size: 20),
              const SizedBox(width: 8),
              Text('PARTIDA EN CURSO',
                  style: AppTextStyles.eyebrow(
                      size: 11, color: AppColors.atlanticoClaro)),
              const Spacer(),
              Text('${session.score} pts',
                  style: AppTextStyles.displaySection(
                      size: 14, color: brand.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${session.wedges.length}/7 quesitos · ${session.lives} vidas',
              style: AppTextStyles.ui(
                  size: 12, color: brand.textSecondary)),
          const SizedBox(height: 12),
          if (categories.isNotEmpty)
            QuizWedgesStrip(
                categories: categories, owned: session.wedges.toSet()),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onResume,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.atlantico,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text('CONTINUAR',
                  style: AppTextStyles.displaySection(
                      size: 14, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();
  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            width: 90,
            height: 32,
            decoration: BoxDecoration(
              color: brand.glass,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
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
