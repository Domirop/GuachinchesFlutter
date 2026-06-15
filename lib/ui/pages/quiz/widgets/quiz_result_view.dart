import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Pantalla de fin de partida: victoria (¡Pleno!) con confeti o derrota.
class QuizResultView extends StatefulWidget {
  final QuizGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;

  const QuizResultView({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onClose,
  });

  @override
  State<QuizResultView> createState() => _QuizResultViewState();
}

class _QuizResultViewState extends State<QuizResultView> {
  late final ConfettiController _confetti;

  bool get _won => widget.state.phase == QuizPhase.won;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    if (_won) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _share() {
    Analytics.I.logEvent('quiz_share', {'won': _won});
    final s = widget.state.session;
    final pts = s?.score ?? 0;
    final text = _won
        ? '¡He conseguido los 7 quesitos en "¿Cuánto sabes de Canarias?" con $pts puntos! ¿Te atreves? — Dónde Comer Canarias'
        : 'Estoy jugando a "¿Cuánto sabes de Canarias?" en Dónde Comer Canarias. ¿Cuánto sabes tú?';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final st = widget.state;
    final s = st.session;
    final colors =
        st.categories.isNotEmpty ? st.categories.map((c) => c.color).toList() : kQuizWedgeColors;
    final wedges = (s?.wedges ?? const []).toSet();
    final owned = st.categories.isNotEmpty
        ? st.categories.map((c) => wedges.contains(c.slug)).toList()
        : List<bool>.filled(7, _won);

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: QuizGlassCircleButton(
                      icon: Icons.close_rounded, onTap: widget.onClose),
                ),
                const Spacer(),
                Text(_won ? '¡PLENO!' : 'FIN DE LA PARTIDA',
                    style: AppTextStyles.displayHero(
                        size: _won ? 44 : 30,
                        color: _won ? AppColors.sol : brand.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  _won
                      ? 'Has reunido los 7 quesitos. ¡Eres un fenómeno!'
                      : 'No pasa nada, los guanches también caían. Otra vez será.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.editorial(
                      size: 14, color: brand.textSecondary),
                ),
                const SizedBox(height: 28),
                QuizWedgesRing(
                  colors: colors,
                  owned: owned,
                  size: 180,
                  center: Text(_won ? '7/7' : '${wedges.length}/7',
                      style: AppTextStyles.displayHero(
                          size: 30, color: brand.textPrimary)),
                ),
                const SizedBox(height: 28),
                // Stats de la partida
                QuizGlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      _Stat(label: 'PUNTOS', value: '${s?.score ?? 0}'),
                      _Stat(
                          label: 'MEJOR RACHA', value: '${s?.bestStreak ?? 0}'),
                      _Stat(
                          label: 'TOTAL',
                          value: '${st.stats?.totalPoints ?? s?.score ?? 0}'),
                    ],
                  ),
                ),
                if (_won && st.leveledUp && st.stats != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.sol.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: AppColors.sol.withValues(alpha: 0.5)),
                    ),
                    child: Text('⭐  ¡Ya eres ${st.stats!.rank.name}!',
                        style: AppTextStyles.displaySection(
                            size: 14, color: AppColors.sol)),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(
                          label: 'COMPARTIR',
                          icon: Icons.ios_share_rounded,
                          onTap: _share),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _FilledBtn(
                          label: _won ? 'JUGAR OTRA VEZ' : 'REINTENTAR',
                          onTap: widget.onPlayAgain),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_won)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              gravity: 0.25,
              colors: kQuizWedgeColors,
            ),
          ),
      ],
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
              style:
                  AppTextStyles.displayHero(size: 24, color: brand.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.eyebrow(
                  size: 9, color: brand.textMuted)),
        ],
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.atlantico, AppColors.atlanticoClaro]),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(label,
            style: AppTextStyles.displaySection(size: 14, color: Colors.white)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: brand.border),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: brand.textPrimary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.displaySection(
                    size: 12, color: brand.textPrimary)),
          ],
        ),
      ),
    );
  }
}
