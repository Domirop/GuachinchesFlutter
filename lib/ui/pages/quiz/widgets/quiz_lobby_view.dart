import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Pestaña INICIO: partida en curso (si la hay), reto de los 7 quesitos con tu
/// progreso claro, tu nivel/puntos/racha, JUGAR y tus últimas partidas.
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
    final stats = state.stats;
    final cats = state.categories;
    final owned = stats?.categoriesMastered.toSet() ?? <String>{};
    final ownedCount = cats.where((c) => owned.contains(c.slug)).length;
    final active = state.activeSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        // Partida en curso
        if (active != null) ...[
          _ActiveGameCard(
            session: active,
            categories: cats,
            onResume: () => onResume(active),
          ),
          const SizedBox(height: 20),
        ],
        // Hero
        Center(
          child: Text('EL RETO DE LOS',
              style: AppTextStyles.eyebrow(
                  size: 11, color: AppColors.atlanticoClaro)),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text('7 QUESITOS',
              style: AppTextStyles.displayHero(size: 34, color: AppColors.crema)),
        ),
        const SizedBox(height: 16),
        _PlayButton(
            label: active != null ? 'NUEVA PARTIDA' : 'JUGAR', onTap: onPlay),
        const SizedBox(height: 24),
        // Progreso claro
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
        if (cats.isNotEmpty)
          QuizWedgesLegend(categories: cats, owned: owned)
        else
          const _LegendSkeleton(),
        const SizedBox(height: 20),
        _StatsRow(stats: stats),
        // Historial
        if (state.history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('ÚLTIMAS PARTIDAS',
              style:
                  AppTextStyles.displaySection(size: 13, color: AppColors.crema)),
          const SizedBox(height: 10),
          for (final h in state.history)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryRow(summary: h),
            ),
        ],
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onHowTo,
            child: Text('¿Cómo se juega?',
                style: AppTextStyles.ui(
                    size: 13,
                    color: AppColors.crema.withValues(alpha: 0.6),
                    weight: FontWeight.w600)),
          ),
        ),
      ],
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
                      size: 14, color: AppColors.crema)),
            ],
          ),
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

class _HistoryRow extends StatelessWidget {
  final QuizSessionSummary summary;
  const _HistoryRow({required this.summary});

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
    final color = won ? AppColors.laurisilva : AppColors.crema;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(won ? Icons.emoji_events_rounded : Icons.flag_rounded,
              color: won ? AppColors.sol : AppColors.crema.withValues(alpha: 0.5),
              size: 20),
          const SizedBox(width: 10),
          Text(won ? '¡Pleno!' : 'Partida',
              style: AppTextStyles.ui(
                  size: 13, color: color, weight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text('· ${summary.wedges.length}/7 🧀',
              style: AppTextStyles.ui(
                  size: 12, color: AppColors.crema.withValues(alpha: 0.5))),
          const Spacer(),
          Text(_date(summary.endedAt),
              style: AppTextStyles.ui(
                  size: 11, color: AppColors.crema.withValues(alpha: 0.4))),
          const SizedBox(width: 10),
          Text('${summary.score}',
              style: AppTextStyles.displaySection(
                  size: 14, color: AppColors.crema)),
        ],
      ),
    );
  }
}

class _LegendSkeleton extends StatelessWidget {
  const _LegendSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 7; i++)
          Container(
            height: 54,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
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
    return QuizGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
