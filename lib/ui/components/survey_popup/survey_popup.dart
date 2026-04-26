import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_page.dart';

class SurveyPopup {
  static bool _shownThisSession = false;

  /// Muestra el popup una sola vez por sesión de la app.
  static void showIfNeeded(BuildContext context, {VoidCallback? onVoted}) {
    if (_shownThisSession) return;
    _shownThisSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => _SurveyPopupSheet(onVoted: onVoted),
      );
    });
  }
}

class _SurveyPopupSheet extends StatelessWidget {
  final VoidCallback? onVoted;

  const _SurveyPopupSheet({this.onVoted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(28, 30, 38, 1),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // Botón cerrar
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white38, size: 16),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Column(
              children: [
                // Icono con glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: GlobalMethods.blueColor.withOpacity(0.4),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            GlobalMethods.blueColor.withOpacity(0.25),
                            GlobalMethods.blueColor.withOpacity(0.08),
                          ],
                        ),
                        border: Border.all(
                          color: GlobalMethods.blueColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: GlobalMethods.blueColor,
                        size: 36,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: GlobalMethods.blueColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: GlobalMethods.blueColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'PREMIOS DONDE COMER CANARIAS 2026',
                    style: TextStyle(
                      color: GlobalMethods.blueColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Título
                const Text(
                  '¿Cuál es tu\nguachinche favorito?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'SF Pro Display',
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Vota y decide quiénes merecen\nlos premios de este año.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 14,
                    fontFamily: 'SF Pro Display',
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 28),

                // Categorías en fila
                Row(
                  children: [
                    _chip(Icons.home_outlined, 'Tradicional'),
                    const SizedBox(width: 10),
                    _chip(Icons.restaurant_outlined, 'Moderno'),
                  ],
                ),

                const SizedBox(height: 28),

                // Botón principal
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalMethods.blueColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SurveyInAppPage(onVoted: onVoted),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_vote_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Votar ahora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Ahora no',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 14,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),

                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(38, 41, 51, 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GlobalMethods.blueColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: GlobalMethods.blueColor, size: 15),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
