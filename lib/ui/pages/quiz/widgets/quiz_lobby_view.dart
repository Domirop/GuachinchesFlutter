import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Lobby del juego: título, leyenda CLARA de los 7 quesitos (qué tienes / qué
/// te falta), tu nivel, puntos y mejor racha, y JUGAR. Dark-glass DCC.
class QuizLobbyView extends StatelessWidget {
  final QuizGameState state;
  final VoidCallback onPlay;
  final VoidCallback onClose;
  final VoidCallback onHowTo;

  const QuizLobbyView({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onClose,
    required this.onHowTo,
  });

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final cats = state.categories;
    final owned = stats?.categoriesMastered.toSet() ?? <String>{};
    final ownedCount = cats.where((c) => owned.contains(c.slug)).length;

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _CircleBtn(icon: Icons.close_rounded, onTap: onClose),
                const Spacer(),
                _CircleBtn(icon: Icons.help_outline_rounded, onTap: onHowTo),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('EL RETO DE LOS',
                        style: AppTextStyles.eyebrow(
                            size: 12, color: AppColors.atlanticoClaro)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('7 QUESITOS',
                        style: AppTextStyles.displayHero(
                            size: 40, color: AppColors.crema)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text('Pon a prueba tu canariedad',
                        style: AppTextStyles.editorial(
                            size: 14,
                            color: AppColors.crema.withValues(alpha: 0.6))),
                  ),
                  const SizedBox(height: 24),
                  // Cabecera de progreso
                  Row(
                    children: [
                      Text('TUS QUESITOS',
                          style: AppTextStyles.displaySection(
                              size: 13, color: AppColors.crema)),
                      const Spacer(),
                      Text('$ownedCount/7',
                          style: AppTextStyles.displaySection(
                              size: 14, color: AppColors.atlanticoClaro)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Leyenda clara (la corrección principal)
                  if (cats.isNotEmpty)
                    QuizWedgesLegend(categories: cats, owned: owned)
                  else
                    _LegendSkeleton(),
                  const SizedBox(height: 20),
                  // Stats
                  _StatsRow(stats: stats),
                ],
              ),
            ),
          ),
          // JUGAR fijo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: _PlayButton(onTap: onPlay),
          ),
          TextButton(
            onPressed: onHowTo,
            child: Text('¿Cómo se juega?',
                style: AppTextStyles.ui(
                    size: 13,
                    color: AppColors.crema.withValues(alpha: 0.6),
                    weight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _LegendSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            height: 54,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final QuizStats? stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rankName = stats?.rank.name ?? 'Gofio';
    final points = stats?.totalPoints ?? 0;
    final bestStreak = stats?.bestStreak ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _Stat(label: 'TU NIVEL', value: rankName),
          _Divider(),
          _Stat(label: 'PUNTOS', value: '$points'),
          _Divider(),
          _Stat(label: 'MEJOR RACHA', value: '$bestStreak'),
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
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displaySection(
                  size: 16, color: AppColors.crema)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.eyebrow(
                  size: 9, color: AppColors.crema.withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
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
        child: Text('JUGAR',
            style: AppTextStyles.displaySection(size: 18, color: Colors.white)
                .copyWith(letterSpacing: 2)),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: AppColors.crema, size: 20),
      ),
    );
  }
}
