import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_lobby_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_ranking_view.dart';

/// Home del juego con submenú INICIO / RANKING. Inicio = lobby + partida en
/// curso + historial; Ranking = tabla de jugadores.
class QuizHomeView extends StatefulWidget {
  final QuizGameState state;
  final VoidCallback onPlay;
  final ValueChanged<QuizSession> onResume;
  final VoidCallback onClose;
  final VoidCallback onHowTo;
  final VoidCallback onLoadRanking;

  const QuizHomeView({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onResume,
    required this.onClose,
    required this.onHowTo,
    required this.onLoadRanking,
  });

  @override
  State<QuizHomeView> createState() => _QuizHomeViewState();
}

class _QuizHomeViewState extends State<QuizHomeView> {
  int _tab = 0;

  void _select(int i) {
    setState(() => _tab = i);
    if (i == 1 &&
        widget.state.ranking.isEmpty &&
        !widget.state.rankingLoading) {
      widget.onLoadRanking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                QuizGlassCircleButton(
                    icon: Icons.close_rounded, onTap: widget.onClose),
                const Spacer(),
                QuizGlassCircleButton(
                    icon: Icons.help_outline_rounded, onTap: widget.onHowTo),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Segmented(index: _tab, onChanged: _select),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                QuizLobbyView(
                  state: widget.state,
                  onPlay: widget.onPlay,
                  onResume: widget.onResume,
                  onHowTo: widget.onHowTo,
                ),
                QuizRankingView(state: widget.state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.glassDark,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            _Seg(label: 'INICIO', active: index == 0, onTap: () => onChanged(0)),
            _Seg(
                label: 'RANKING',
                active: index == 1,
                onTap: () => onChanged(1)),
          ],
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.atlantico : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.atlantico.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(label,
              style: AppTextStyles.displaySection(
                  size: 13,
                  color: active
                      ? Colors.white
                      : AppColors.crema.withValues(alpha: 0.6))),
        ),
      ),
    );
  }
}
