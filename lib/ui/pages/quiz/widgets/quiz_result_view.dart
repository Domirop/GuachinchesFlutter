import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Fin de partida. Victoria → conquista de isla (elegir → conquistar → posible
/// ascenso de tier). Derrota → resumen + reintentar.
class QuizResultView extends StatefulWidget {
  final QuizGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;
  final ValueChanged<String> onConquer;

  const QuizResultView({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onClose,
    required this.onConquer,
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
  void didUpdateWidget(QuizResultView old) {
    super.didUpdateWidget(old);
    // Vuelve a lanzar confeti al ascender de tier.
    if (widget.state.conquerResult?.promoted == true &&
        old.state.conquerResult?.promoted != true) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _share() {
    Analytics.I.logEvent('quiz_share', {'won': _won});
    final pts = widget.state.session?.score ?? 0;
    final text = _won
        ? '¡He ganado en "¿Cuánto sabes de Canarias?" con $pts puntos y conquisto islas! ¿Te atreves? — Dónde Comer Canarias'
        : 'Estoy jugando a "¿Cuánto sabes de Canarias?" en Dónde Comer Canarias. ¿Cuánto sabes tú?';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(child: _won ? _wonBody(context) : _lostBody(context)),
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

  // ── Victoria + conquista ────────────────────────────────────────────────────

  Widget _wonBody(BuildContext context) {
    final brand = context.brand;
    final st = widget.state;
    final conquest = st.conquest;
    final result = st.conquerResult;
    final tier = conquest?.tier ?? 1;
    final tColor = quizTierColor(tier);

    Widget body;
    if (result != null) {
      body = _ConquestDone(result: result, onPlayAgain: widget.onPlayAgain);
    } else if (conquest != null && conquest.remaining.isNotEmpty) {
      body = _IslandPicker(
        conquest: conquest,
        busy: st.conquering,
        onConquer: widget.onConquer,
      );
    } else {
      body = _SimpleVictory(onPlayAgain: widget.onPlayAgain);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: QuizGlassCircleButton(
                icon: Icons.close_rounded, onTap: widget.onClose),
          ),
          const SizedBox(height: 6),
          Text('¡PLENO!',
              style: AppTextStyles.displayHero(size: 38, color: AppColors.sol)),
          Text(
            '7 quesitos · ${st.session?.score ?? 0} pts',
            style: AppTextStyles.editorial(size: 14, color: brand.textSecondary),
          ),
          if (conquest != null) ...[
            const SizedBox(height: 8),
            _TierChip(tier: tier, color: tColor, conquest: conquest),
          ],
          const SizedBox(height: 12),
          Expanded(child: body),
          TextButton(
            onPressed: _share,
            child: Text('Compartir',
                style: AppTextStyles.ui(
                    size: 13,
                    color: brand.textSecondary,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Derrota ─────────────────────────────────────────────────────────────────

  Widget _lostBody(BuildContext context) {
    final brand = context.brand;
    final st = widget.state;
    final s = st.session;
    final wedges = (s?.wedges ?? const []).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: QuizGlassCircleButton(
                icon: Icons.close_rounded, onTap: widget.onClose),
          ),
          const Spacer(),
          Text('FIN DE LA PARTIDA',
              style:
                  AppTextStyles.displayHero(size: 30, color: brand.textPrimary)),
          const SizedBox(height: 6),
          Text('Te quedaste sin vidas. ¡La próxima conquistas isla!',
              textAlign: TextAlign.center,
              style: AppTextStyles.editorial(
                  size: 14, color: brand.textSecondary)),
          const SizedBox(height: 24),
          QuizGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                _Stat(label: 'QUESITOS', value: '$wedges/7'),
                _Stat(label: 'PUNTOS', value: '${s?.score ?? 0}'),
                _Stat(label: 'MEJOR RACHA', value: '${s?.bestStreak ?? 0}'),
              ],
            ),
          ),
          const Spacer(),
          _FilledBtn(label: 'REINTENTAR', onTap: widget.onPlayAgain),
        ],
      ),
    );
  }
}

// ── Selector de isla a conquistar ──────────────────────────────────────────────

class _IslandPicker extends StatelessWidget {
  final QuizConquest conquest;
  final bool busy;
  final ValueChanged<String> onConquer;
  const _IslandPicker({
    required this.conquest,
    required this.busy,
    required this.onConquer,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final color = quizTierColor(conquest.tier);
    final remaining = conquest.remaining;
    return Column(
      children: [
        Text('ELIGE TU ISLA A CONQUISTAR',
            style: AppTextStyles.displaySection(size: 14, color: color)),
        const SizedBox(height: 4),
        Text('Has ganado: reclama una isla del mapa.',
            style: AppTextStyles.ui(size: 12, color: brand.textMuted)),
        const SizedBox(height: 14),
        Expanded(
          child: AbsorbPointer(
            absorbing: busy,
            child: Opacity(
              opacity: busy ? 0.5 : 1,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final isl in remaining)
                    GestureDetector(
                      onTap: () => onConquer(isl.slug),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                              color.withValues(alpha: 0.18), brand.glass),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: color.withValues(alpha: 0.6), width: 1.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flag_rounded, size: 16, color: color),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(isl.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.displaySection(
                                      size: 12, color: brand.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Conquista hecha (+ ascenso) ────────────────────────────────────────────────

class _ConquestDone extends StatelessWidget {
  final QuizConquerResult result;
  final VoidCallback onPlayAgain;
  const _ConquestDone({required this.result, required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final conquest = result.conquest;
    final color = quizTierColor(conquest.tier);
    final islandName = conquest.islands
        .firstWhere((i) => i.slug == result.island,
            orElse: () => QuizIsland(slug: result.island, name: result.island))
        .name;
    return Column(
      children: [
        const Spacer(),
        Icon(Icons.flag_circle_rounded, size: 64, color: color),
        const SizedBox(height: 10),
        Text('${islandName.toUpperCase()}\nCONQUISTADA',
            textAlign: TextAlign.center,
            style: AppTextStyles.displaySection(size: 20, color: brand.textPrimary)
                .copyWith(height: 1.1)),
        const SizedBox(height: 8),
        Text('${conquest.conqueredCount}/${conquest.total} islas en ${conquest.tierName}',
            style: AppTextStyles.ui(size: 13, color: brand.textSecondary)),
        if (result.promoted) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Text('⭐  ¡ASCIENDES A ${conquest.tierName.toUpperCase()}!',
                style: AppTextStyles.displaySection(size: 14, color: color)),
          ),
        ],
        const Spacer(),
        _FilledBtn(label: 'JUGAR OTRA VEZ', onTap: onPlayAgain),
      ],
    );
  }
}

class _SimpleVictory extends StatelessWidget {
  final VoidCallback onPlayAgain;
  const _SimpleVictory({required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      children: [
        const Spacer(),
        Icon(Icons.workspace_premium_rounded,
            size: 64, color: AppColors.sol),
        const SizedBox(height: 10),
        Text('¡Has conquistado todas las islas!',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.displaySection(size: 16, color: brand.textPrimary)),
        const Spacer(),
        _FilledBtn(label: 'JUGAR OTRA VEZ', onTap: onPlayAgain),
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  final int tier;
  final Color color;
  final QuizConquest conquest;
  const _TierChip(
      {required this.tier, required this.color, required this.conquest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
          '${conquest.tierName.toUpperCase()} · ${conquest.conqueredCount}/${conquest.total}',
          style: AppTextStyles.eyebrow(size: 10, color: color)),
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
                  AppTextStyles.displayHero(size: 22, color: brand.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.eyebrow(size: 9, color: brand.textMuted)),
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
        width: double.infinity,
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
