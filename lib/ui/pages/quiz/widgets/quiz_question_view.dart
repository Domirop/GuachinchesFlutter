import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/quiz/quiz_game_cubit.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_lives.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Pantalla de pregunta: cabecera con la categoría (color/icono/isla), anillo
/// de temporizador, vidas + puntos, enunciado y 4 opciones glass. En [revealing]
/// resalta la correcta (verde) y la elegida si falló (mojo) + explicación.
class QuizQuestionView extends StatelessWidget {
  final QuizQuestion question;
  final List<QuizCategory> categories;
  final Set<String> owned;
  final int secondsLeft;
  final int lives;
  final int score;
  final bool revealing;
  final int? selectedIndex;
  final QuizAnswerResult? result;
  final ValueChanged<int> onAnswer;

  const QuizQuestionView({
    super.key,
    required this.question,
    required this.categories,
    required this.owned,
    required this.secondsLeft,
    required this.lives,
    required this.score,
    required this.revealing,
    required this.selectedIndex,
    required this.result,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final color = question.color;
    final warn = secondsLeft <= QuizGameCubit.warningSeconds;
    return SafeArea(
      child: Column(
        children: [
          // Cabecera de categoría
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Color.alphaBlend(Colors.black26, color)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    QuizLives(lives: lives, size: 22),
                    const Spacer(),
                    Text('$score',
                        style: AppTextStyles.displaySection(
                            size: 18, color: Colors.white)),
                    const SizedBox(width: 3),
                    Text('PTS',
                        style: AppTextStyles.eyebrow(
                            size: 9,
                            color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 12),
                QuizWedgesStrip(categories: categories, owned: owned),
              ],
            ),
          ),
          // Banda categoría + temporizador
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.22),
                  child: Icon(quizCategoryIcon(question.icon),
                      color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question.categoryName.toUpperCase(),
                          style: AppTextStyles.displaySection(
                              size: 13, color: AppColors.crema)),
                      Text(question.island,
                          style: AppTextStyles.eyebrow(
                              size: 9,
                              color: AppColors.crema.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                _TimerRing(secondsLeft: secondsLeft, warn: warn),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Enunciado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              question.question,
              style: AppTextStyles.displaySection(size: 20, color: AppColors.crema)
                  .copyWith(height: 1.25, letterSpacing: 0.2),
            ),
          ),
          const SizedBox(height: 20),
          // Opciones
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _Option(
                label: question.options[i],
                index: i,
                state: _stateFor(i),
                onTap: revealing ? null : () => onAnswer(i),
              ),
            ),
          ),
          // Reveal: explicación + puntos
          if (revealing && result != null) _RevealBar(result: result!),
        ],
      ),
    );
  }

  _OptState _stateFor(int i) {
    if (!revealing || result == null) {
      return selectedIndex == i ? _OptState.picked : _OptState.idle;
    }
    if (i == result!.correctIndex) return _OptState.correct;
    if (i == selectedIndex) return _OptState.wrong;
    return _OptState.dim;
  }
}

enum _OptState { idle, picked, correct, wrong, dim }

class _Option extends StatelessWidget {
  final String label;
  final int index;
  final _OptState state;
  final VoidCallback? onTap;

  const _Option({
    required this.label,
    required this.index,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.glassDark;
    Color border = Colors.white.withValues(alpha: 0.12);
    Color fg = AppColors.crema;
    IconData? trailing;
    Color? trailingColor;
    double opacity = 1;

    switch (state) {
      case _OptState.idle:
        break;
      case _OptState.picked:
        border = AppColors.atlanticoClaro;
        break;
      case _OptState.correct:
        bg = AppColors.laurisilva.withValues(alpha: 0.18);
        border = AppColors.laurisilva;
        trailing = Icons.check_circle_rounded;
        trailingColor = AppColors.laurisilva;
        break;
      case _OptState.wrong:
        bg = AppColors.mojo.withValues(alpha: 0.16);
        border = AppColors.mojo;
        trailing = Icons.cancel_rounded;
        trailingColor = AppColors.mojo;
        break;
      case _OptState.dim:
        opacity = 0.45;
        break;
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(letter,
                    style: AppTextStyles.displaySection(
                        size: 12, color: AppColors.crema)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.ui(
                        size: 14, color: fg, weight: FontWeight.w500)),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: trailingColor, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final int secondsLeft;
  final bool warn;
  const _TimerRing({required this.secondsLeft, required this.warn});

  @override
  Widget build(BuildContext context) {
    final color = warn ? AppColors.mojo : AppColors.atlanticoClaro;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: (secondsLeft / QuizGameCubit.questionSeconds).clamp(0, 1),
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text('$secondsLeft',
              style: AppTextStyles.displaySection(size: 15, color: color)),
        ],
      ),
    );
  }
}

class _RevealBar extends StatelessWidget {
  final QuizAnswerResult result;
  const _RevealBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final ok = result.isCorrect;
    final color = ok ? AppColors.laurisilva : AppColors.mojo;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 18 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded,
                  color: color, size: 20),
              const SizedBox(width: 8),
              Text(ok ? '¡CORRECTO!' : 'CASI…',
                  style: AppTextStyles.displaySection(size: 14, color: color)),
              const Spacer(),
              if (result.points > 0)
                Text('+${result.points}',
                    style: AppTextStyles.displaySection(
                        size: 16, color: AppColors.sol)),
              if (result.newWedge) ...[
                const SizedBox(width: 8),
                const Text('🧀', style: TextStyle(fontSize: 16)),
              ],
            ],
          ),
          if (result.explanation != null &&
              result.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(result.explanation!,
                style: AppTextStyles.editorial(
                    size: 13, color: AppColors.crema.withValues(alpha: 0.8))),
          ],
        ],
      ),
    );
  }
}
