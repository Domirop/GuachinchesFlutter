import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_state.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_lives.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_lobby_view.dart';

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

class _QuizGameScaffold extends StatelessWidget {
  const _QuizGameScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF15263A), AppColors.base],
          ),
        ),
        child: BlocBuilder<QuizGameCubit, QuizGameState>(
          builder: (context, state) {
            final cubit = context.read<QuizGameCubit>();
            switch (state.phase) {
              case QuizPhase.idle:
              case QuizPhase.loading:
                return QuizLobbyView(
                  state: state,
                  onPlay: cubit.startGame,
                  onClose: () => Navigator.of(context).maybePop(),
                  onHowTo: () => _showRules(context),
                );
              case QuizPhase.error:
                return _ErrorView(
                  message: state.error ?? 'Algo salió mal',
                  onRetry: cubit.loadLobby,
                  onClose: () => Navigator.of(context).maybePop(),
                );
              default:
                // Ruleta · pregunta · victoria/derrota → próxima entrega.
                return _GameplayPlaceholder(state: state, cubit: cubit);
            }
          },
        ),
      ),
    );
  }
}

/// Placeholder honesto mientras se construye la jugabilidad (ruleta + pregunta
/// + victoria/derrota). Ya muestra el HUD real (vidas + puntos) de la sesión.
class _GameplayPlaceholder extends StatelessWidget {
  final QuizGameState state;
  final QuizGameCubit cubit;
  const _GameplayPlaceholder({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                QuizLives(lives: state.lives),
                const Spacer(),
                Text('${state.score}',
                    style: AppTextStyles.displaySection(
                        size: 20, color: AppColors.crema)),
                const SizedBox(width: 4),
                Text('PTS',
                    style: AppTextStyles.eyebrow(
                        size: 10,
                        color: AppColors.crema.withValues(alpha: 0.5))),
              ],
            ),
            const Spacer(),
            Icon(Icons.casino_rounded,
                size: 64, color: AppColors.atlanticoClaro.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text('¡Partida creada!',
                style:
                    AppTextStyles.displaySection(size: 18, color: AppColors.crema)),
            const SizedBox(height: 8),
            Text(
              'La ruleta y las preguntas llegan en la próxima entrega.\nQuesitos: ${state.wedges.length}/7',
              textAlign: TextAlign.center,
              style: AppTextStyles.editorial(
                  size: 14, color: AppColors.crema.withValues(alpha: 0.6)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: cubit.quit,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.atlantico, width: 1.4),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('VOLVER AL LOBBY',
                    style: AppTextStyles.displaySection(
                        size: 13, color: AppColors.atlanticoClaro)),
              ),
            ),
          ],
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, color: AppColors.crema),
              ),
            ),
            const Spacer(),
            Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.crema.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No se pudo cargar el juego',
                style:
                    AppTextStyles.displaySection(size: 16, color: AppColors.crema)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.ui(
                    size: 13, color: AppColors.crema.withValues(alpha: 0.5))),
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
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.elevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
    ),
    builder: (_) => Padding(
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('CÓMO SE JUEGA',
              style:
                  AppTextStyles.displaySection(size: 16, color: AppColors.crema)),
          const SizedBox(height: 16),
          _rule('🎡', 'Gira la ruleta y responde una pregunta de esa categoría.'),
          _rule('🧀', 'Acierta para ganar el quesito de cada isla. Reúne los 7.'),
          _rule('🍷', 'Tienes 3 vidas. Fallar o quedarte sin tiempo resta una.'),
          _rule('⏱️', '20 segundos por pregunta. Cuanto antes aciertes, más puntos.'),
          _rule('🔥', 'Encadena aciertos para multiplicar tu puntuación.'),
        ],
      ),
    ),
  );
}

Widget _rule(String emoji, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: AppTextStyles.ui(
                    size: 13, color: AppColors.crema.withValues(alpha: 0.75))),
          ),
        ],
      ),
    );
