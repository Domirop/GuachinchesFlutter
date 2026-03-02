import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/menu/menu.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_page.dart';

const String kSurveyOnboarding2026Key = 'surveyOnboarding2026Shown';

class SurveyOnboarding extends StatefulWidget {
  final List<Widget> screens;

  SurveyOnboarding({Key? key, required this.screens}) : super(key: key);

  @override
  _SurveyOnboardingState createState() => _SurveyOnboardingState();
}

class _SurveyOnboardingState extends State<SurveyOnboarding>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  final _storage = const FlutterSecureStorage();

  static const Color _bg = Color.fromRGBO(25, 27, 32, 1);
  static const Color _card = Color.fromRGBO(35, 37, 44, 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _markSeen();
  }

  Future<void> _markSeen() async {
    await _storage.write(key: kSurveyOnboarding2026Key, value: 'true');
  }

  void _done() {
    GlobalMethods().pushAndReplacement(
      context,
      Menu(widget.screens, selectedItem: 0),
    );
  }

  Future<void> _goVote() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SurveyInAppPage()),
    );
    if (mounted) _done();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Fondo con gradiente azul sutil
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.1,
                  colors: [
                    Color.fromRGBO(0, 100, 160, 0.28),
                    Color.fromRGBO(25, 27, 32, 1),
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Botón cerrar
          Positioned(
            top: topPadding + 12,
            right: 16,
            child: GestureDetector(
              onTap: _done,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ),
          ),

          // Contenido principal
          FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Icono trofeo con glow
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GlobalMethods.blueColor.withOpacity(0.12),
                          boxShadow: [
                            BoxShadow(
                              color: GlobalMethods.blueColor.withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: GlobalMethods.blueColor,
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Badge edición
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: GlobalMethods.blueColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: GlobalMethods.blueColor.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          'EDICIÓN 2026',
                          style: TextStyle(
                            color: GlobalMethods.blueColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Título
                      const Text(
                        'Premios\nDonde Comer\nCanarias',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'SF Pro Display',
                          height: 1.12,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtítulo
                      Text(
                        'Tu voto decide quiénes son\nlos mejores guachinches de Canarias',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                          fontFamily: 'SF Pro Display',
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Categorías
                      Row(
                        children: [
                          _categoryCard(
                            icon: Icons.home_outlined,
                            label: 'Guachinche\nTradicional',
                          ),
                          const SizedBox(width: 12),
                          _categoryCard(
                            icon: Icons.restaurant_outlined,
                            label: 'Guachinche\nModerno',
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Divider sutil
                      Divider(
                        color: Colors.white.withOpacity(0.07),
                        thickness: 1,
                      ),
                      const SizedBox(height: 16),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalMethods.blueColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _goVote,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_vote_outlined,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text(
                                '¡Quiero votar!',
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

                      // Saltar
                      TextButton(
                        onPressed: _done,
                        child: Text(
                          'Quizás más tarde',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.38),
                            fontSize: 15,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlobalMethods.blueColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: GlobalMethods.blueColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
