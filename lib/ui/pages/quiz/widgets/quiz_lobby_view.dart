import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Lobby del juego: título, los 7 quesitos con tu progreso, tu nivel, puntos y
/// mejor racha, y el botón JUGAR. Dark-glass inmersivo.
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
    final colors = cats.isNotEmpty
        ? cats.map((c) => c.color).toList()
        : kQuizWedgeColors;
    final mastered = stats?.categoriesMastered.toSet() ?? <String>{};
    final owned = cats.isNotEmpty
        ? cats.map((c) => mastered.contains(c.slug)).toList()
        : List<bool>.filled(7, false);
    final ownedCount = owned.where((e) => e).length;
    final loading = state.phase == QuizPhase.loading && stats == null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            // Top bar
            Row(
              children: [
                _CircleBtn(icon: Icons.close_rounded, onTap: onClose),
                const Spacer(),
                _CircleBtn(icon: Icons.help_outline_rounded, onTap: onHowTo),
              ],
            ),
            const Spacer(flex: 2),
            Text(
              'EL RETO DE LOS',
              style: AppTextStyles.eyebrow(size: 12, color: AppColors.atlanticoClaro),
            ),
            const SizedBox(height: 6),
            Text(
              '7 QUESITOS',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHero(size: 40, color: AppColors.crema),
            ),
            const SizedBox(height: 8),
            Text(
              'Pon a prueba tu canariedad',
              style: AppTextStyles.editorial(
                  size: 14, color: AppColors.crema.withValues(alpha: 0.6)),
            ),
            const Spacer(flex: 2),
            // Anillo de quesitos
            QuizWedgesRing(
              colors: colors,
              owned: owned,
              size: 210,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$ownedCount',
                      style: AppTextStyles.displayHero(
                          size: 44, color: AppColors.crema)),
                  Text('DE 7',
                      style: AppTextStyles.eyebrow(
                          size: 11,
                          color: AppColors.crema.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const Spacer(flex: 2),
            // Stats row
            _StatsRow(stats: stats, loading: loading),
            const SizedBox(height: 24),
            // JUGAR
            _PlayButton(onTap: onPlay),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onHowTo,
              child: Text('¿Cómo se juega?',
                  style: AppTextStyles.ui(
                      size: 13,
                      color: AppColors.crema.withValues(alpha: 0.6),
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic stats; // QuizStats?
  final bool loading;
  const _StatsRow({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final rankName = stats?.rank?.name ?? 'Gofio';
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
          _Stat(label: 'PUNTOS', value: loading ? '—' : '$points'),
          _Divider(),
          _Stat(label: 'MEJOR RACHA', value: loading ? '—' : '$bestStreak'),
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
              style: AppTextStyles.displaySection(size: 16, color: AppColors.crema)),
          const SizedBox(height: 3),
          Text(label,
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
