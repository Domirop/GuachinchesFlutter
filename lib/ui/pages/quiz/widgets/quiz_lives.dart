import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

/// Vidas del juego como **copas de vino** (metáfora de guachinche: vino +
/// quesitos). Copa llena = vida; copa vacía/atenuada = vida perdida. Se lee al
/// instante como un medidor. Animan al perderse (encogen + se desaturan).
class QuizLives extends StatelessWidget {
  final int lives;
  final int max;
  final double size;

  const QuizLives({
    super.key,
    required this.lives,
    this.max = 3,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: EdgeInsets.only(right: i == max - 1 ? 0 : 6),
            child: _Glass(alive: i < lives, size: size),
          ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  final bool alive;
  final double size;
  const _Glass({required this.alive, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: alive ? 1.0 : 0.82,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: alive ? 1.0 : 0.32,
        duration: const Duration(milliseconds: 320),
        child: Icon(
          alive ? Icons.wine_bar_rounded : Icons.wine_bar_outlined,
          size: size,
          color: alive ? AppColors.mojo : Colors.white,
          shadows: alive
              ? [
                  Shadow(
                    color: AppColors.mojo.withValues(alpha: 0.45),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
