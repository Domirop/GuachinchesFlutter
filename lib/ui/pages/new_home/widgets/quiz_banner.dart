import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/ui/pages/login/login_screen.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';
import 'package:guachinches/ui/pages/quiz/quiz_game_screen.dart';

/// Banner-invitación al juego "¿Cuánto sabes de Canarias?" en el Home.
/// Gradiente Atlántico, título Oswald, los 7 colores de quesito y CTA JUGAR.
/// Gating: con sesión → juego; sin sesión → login existente.
class QuizBanner extends StatelessWidget {
  const QuizBanner({super.key});

  static Future<void> open(BuildContext context) async {
    Analytics.I.logEvent('quiz_banner_tap');
    final uid = await AppStorage.instance.read(key: 'userId');
    if (!context.mounted) return;
    if (uid != null && uid.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizGameScreen()),
      );
    } else {
      Analytics.I.logEvent('quiz_login_required');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GestureDetector(
        onTap: () => QuizBanner.open(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF003D5C), AppColors.atlantico, Color(0xFF339ED0)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.atlantico.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('JUEGO',
                      style: AppTextStyles.eyebrow(
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sol,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('NUEVO',
                        style: AppTextStyles.eyebrow(
                            size: 9, color: AppColors.ink)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('¿CUÁNTO SABES\nDE CANARIAS?',
                  style: AppTextStyles.displayHero(size: 26, color: Colors.white)
                      .copyWith(height: 1.05)),
              const SizedBox(height: 6),
              Text('Pon a prueba tu canariedad y consigue los 7 quesitos',
                  style: AppTextStyles.editorial(
                      size: 13, color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Teaser de los 7 quesitos.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < kQuizWedgeColors.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                              right: i == kQuizWedgeColors.length - 1 ? 0 : 5),
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kQuizWedgeColors[i],
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // CTA JUGAR
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.crema,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('JUGAR',
                            style: AppTextStyles.displaySection(
                                size: 13, color: AppColors.atlanticoOscuro)),
                        const SizedBox(width: 4),
                        const Icon(Icons.play_arrow_rounded,
                            size: 18, color: AppColors.atlanticoOscuro),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
