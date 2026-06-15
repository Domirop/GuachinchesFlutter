import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';
import 'package:guachinches/ui/pages/quiz/quiz_sound.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_home_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_question_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_result_view.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wheel_view.dart';

/// Pantalla inmersiva del juego "¿Cuánto sabes de Canarias?". Aloja el
/// [QuizGameCubit] y conmuta el cuerpo según la fase. Fondo dark de 4 capas.
class QuizGameScreen extends StatelessWidget {
  const QuizGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizGameCubit(QuizRepository())..loadLobby(),
      child: const _QuizGameScaffold(),
    );
  }
}

class _QuizGameScaffold extends StatefulWidget {
  const _QuizGameScaffold();

  @override
  State<_QuizGameScaffold> createState() => _QuizGameScaffoldState();
}

class _QuizGameScaffoldState extends State<_QuizGameScaffold> {
  final QuizSound _sound = QuizSound();
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    _sound.dispose();
    super.dispose();
  }

  /// Al entrar en reveal: suena acierto/fallo y, tras ~2.2 s, pasa de turno.
  void _onPhase(BuildContext context, QuizGameState state) {
    if (state.phase == QuizPhase.revealing) {
      (state.result?.isCorrect ?? false) ? _sound.correct() : _sound.fail();
      _revealTimer?.cancel();
      _revealTimer = Timer(const Duration(milliseconds: 2200), () {
        if (mounted) context.read<QuizGameCubit>().continueAfterReveal();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: Container(
        decoration: quizBackground(context),
        child: BlocConsumer<QuizGameCubit, QuizGameState>(
          listenWhen: (p, c) => p.phase != c.phase,
          listener: _onPhase,
          builder: (context, state) {
            final cubit = context.read<QuizGameCubit>();
            switch (state.phase) {
              case QuizPhase.idle:
              case QuizPhase.loading:
                return QuizHomeView(
                  state: state,
                  onPlay: cubit.startGame,
                  onResume: cubit.resumeGame,
                  onClose: () => Navigator.of(context).maybePop(),
                  onHowTo: () => _showRules(context),
                  onLoadRanking: cubit.loadRanking,
                );
              case QuizPhase.error:
                return _ErrorView(
                  message: state.error ?? 'Algo salió mal',
                  onRetry: cubit.loadLobby,
                  onClose: () => Navigator.of(context).maybePop(),
                );
              case QuizPhase.spinning:
                return QuizWheelView(
                  categories: state.categories,
                  landed: state.landed,
                  lives: state.lives,
                  score: state.score,
                  owned: state.wedges.toSet(),
                  onNeedSpin: cubit.spin,
                  onSettled: cubit.onSpinSettled,
                  onExit: () => _confirmExit(context, cubit),
                );
              case QuizPhase.question:
              case QuizPhase.revealing:
                final q = state.question;
                if (q == null) return const SizedBox.shrink();
                return QuizQuestionView(
                  question: q,
                  categories: state.categories,
                  owned: state.wedges.toSet(),
                  secondsLeft: state.secondsLeft,
                  lives: state.lives,
                  score: state.score,
                  revealing: state.phase == QuizPhase.revealing,
                  selectedIndex: state.selectedIndex,
                  result: state.result,
                  onAnswer: cubit.answer,
                  onExit: () => _confirmExit(context, cubit),
                );
              case QuizPhase.won:
              case QuizPhase.lost:
                return QuizResultView(
                  state: state,
                  onPlayAgain: cubit.restart,
                  onClose: () => Navigator.of(context).maybePop(),
                );
            }
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: QuizGlassCircleButton(
                  icon: Icons.close_rounded, onTap: onClose),
            ),
            const Spacer(),
            Icon(Icons.wifi_off_rounded, size: 48, color: brand.textMuted),
            const SizedBox(height: 16),
            Text('No se pudo cargar el juego',
                style: AppTextStyles.displaySection(
                    size: 16, color: brand.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(size: 13, color: brand.textMuted)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.atlantico,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('Reintentar',
                    style:
                        AppTextStyles.ui(size: 14, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

void _showRules(BuildContext context) {
  final brand = context.brand;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: brand.elevated.withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: brand.border)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: brand.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('CÓMO SE JUEGA',
                  style: AppTextStyles.displaySection(
                      size: 16, color: brand.textPrimary)),
              const SizedBox(height: 16),
              _rule(context, '🎡',
                  'Gira la ruleta y responde una pregunta de esa categoría.'),
              _rule(context, '🧀',
                  'Acierta para ganar el quesito de cada isla. Reúne los 7.'),
              _rule(context, '🍷',
                  'Tienes 3 vidas. Fallar o quedarte sin tiempo resta una.'),
              _rule(context, '⏱️',
                  '20 segundos por pregunta. Cuanto antes aciertes, más puntos.'),
              _rule(context, '🔥',
                  'Encadena aciertos para multiplicar tu puntuación.'),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _rule(BuildContext context, String emoji, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: AppTextStyles.ui(
                    size: 13, color: context.brand.textSecondary)),
          ),
        ],
      ),
    );

/// Confirmación al salir de una partida en curso: seguir, salir (continuable)
/// o abandonar (se pierde).
void _confirmExit(BuildContext context, QuizGameCubit cubit) {
  final brand = context.brand;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: brand.elevated.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: brand.border)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 20 + MediaQuery.of(sheetCtx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: brand.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('SALIR DE LA PARTIDA',
                  style: AppTextStyles.displaySection(
                      size: 16, color: brand.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Si sales, podrás continuarla luego. Si la abandonas, la pierdes.',
                style:
                    AppTextStyles.ui(size: 13, color: brand.textSecondary),
              ),
              const SizedBox(height: 18),
              _SheetAction(
                label: 'SEGUIR JUGANDO',
                filled: true,
                onTap: () => Navigator.of(sheetCtx).pop(),
              ),
              const SizedBox(height: 10),
              _SheetAction(
                label: 'SALIR · CONTINÚO LUEGO',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  cubit.leaveToLobby();
                },
              ),
              const SizedBox(height: 10),
              _SheetAction(
                label: 'ABANDONAR PARTIDA',
                danger: true,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  cubit.abandonAndLeave();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SheetAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;
  const _SheetAction({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.mojo : AppColors.atlantico;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.atlantico : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: filled ? null : Border.all(color: color.withValues(alpha: 0.6), width: 1.4),
        ),
        child: Text(label,
            style: AppTextStyles.displaySection(
                size: 13, color: filled ? Colors.white : color)),
      ),
    );
  }
}
