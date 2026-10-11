import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/quiz/quiz_repository.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/ui/pages/login/login_screen.dart';
import 'package:guachinches/ui/pages/quiz/quiz_game_screen.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Invitación al juego «¿Cuánto sabes de Canarias?» (rediseño iOS 27).
/// Tarjeta blanca r28: antetítulo «Juego» + sello «Nuevo» girado −6°, título
/// 22/28, subtítulo, cápsula «Jugar» y la rueda de 7 quesitos (pop
/// escalonado + un temblor a 1,8 s).
///
/// Progreso: con sesión y partida activa, la rueda pinta los quesitos
/// conseguidos y «Llevas N de 7» (`QuizRepository.getActiveSession`). Sin
/// sesión o sin partida, rueda completa y sin pie.
/// Gating: con sesión → juego; sin sesión → login existente.
class QuizBanner extends StatefulWidget {
  /// Inyectable para tests.
  final QuizRepository? repository;

  const QuizBanner({super.key, this.repository});

  static Future<void> open(BuildContext context) async {
    Analytics.I.logEvent('quiz_banner_tap');
    final uid = await AppStorage.instance.read(key: 'userId');
    if (!context.mounted) return;
    if (uid != null && uid.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QuizGameScreen()),
      );
    } else {
      Analytics.I.logEvent('quiz_login_required');
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  State<QuizBanner> createState() => _QuizBannerState();
}

class _QuizBannerState extends State<QuizBanner> {
  /// Quesitos de la partida activa; null = desconocido / sin partida.
  int? _earned;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final repo = widget.repository ?? QuizRepository();
      final uid = await repo.currentUserId();
      if (uid == null || uid.isEmpty) {
        if (mounted && _earned != null) setState(() => _earned = null);
        return;
      }
      final session = await repo.getActiveSession();
      final earned = (session != null && session.isActive)
          ? session.wedges.length.clamp(0, 7)
          : null;
      if (mounted && earned != _earned) setState(() => _earned = earned);
    } catch (e) {
      AppLogger.warn('quiz-banner', 'progreso no disponible: $e');
    }
  }

  Future<void> _open() async {
    await QuizBanner.open(context);
    // Al volver de la partida (o del login) el progreso puede haber cambiado.
    if (mounted) _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: GmPressable(
        onTap: _open,
        pressedScale: 0.98,
        semanticsLabel: '¿Cuánto sabes de Canarias? Jugar',
        child: GmCard(
          radius: GmRadius.guide,
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [gm.accentSoft, gm.accentSoft.withValues(alpha: 0)],
                        stops: const [0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Juego',
                                  style: GmText.eyebrow(color: gm.accent)),
                              const _NewBadge(),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text('¿Cuánto sabes de Canarias?',
                              style: GmText.title2(color: gm.label)),
                          const SizedBox(height: 5),
                          Text(
                            'Pon a prueba tu canariedad y consigue los 7 quesitos.',
                            style: GmText.body(color: gm.label2),
                          ),
                          const SizedBox(height: 14),
                          GmCapsuleButton(
                            label: 'Jugar',
                            icon: GmIcons.play,
                            identifier: 'home-quiz-play',
                            onTap: _open,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 116,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QuesitosWheel(size: 112, earned: _earned),
                          if (_earned != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Llevas $_earned de 7',
                              maxLines: 1,
                              style: GmText.chip(color: gm.label2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -6 * math.pi / 180,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: GmColors.badgeRed,
          borderRadius: BorderRadius.circular(GmRadius.pill),
          boxShadow: const [
            BoxShadow(
              color: Color(0x8CD6362A),
              offset: Offset(0, 3),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        // Inside a Wrap the badge gets the full line width; widthFactor keeps it
        // hugging the label instead of stretching into a bar.
        child: const Center(
          widthFactor: 1,
          child: Text(
            'Nuevo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rueda de 7 quesitos del tablero. [earned] = quesitos conseguidos (los
/// demás se pintan al 24 %); `null` → todos a color (progreso desconocido).
class QuesitosWheel extends StatelessWidget {
  final double size;
  final int? earned;

  const QuesitosWheel({super.key, this.size = 112, this.earned});

  static const colors = [
    Color(0xFF0085C4),
    Color(0xFFFFC23D),
    Color(0xFFFF5A4E),
    Color(0xFFF39A2B),
    Color(0xFF34B25A),
    Color(0xFF14A394),
    Color(0xFF8B5CC7),
  ];

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return RepaintBoundary(
      child: GmOnce(
        // 7 pops (150 ms + 6×85 ms + 640 ms) y el temblor a 1,8 s (900 ms).
        duration: const Duration(milliseconds: 2700),
        builder: (_, t, __) {
          final ms = t * 2700;
          // Temblor de la rueda (wiggle) a partir de 1,8 s.
          final wt = ((ms - 1800) / 900).clamp(0.0, 1.0);
          final wiggle = gmKeyframes(wt, const [
            (0, 0), (0.2, -9), (0.45, 7), (0.7, -3), (0.88, 1), (1, 0)
          ]);
          final pops = List<double>.generate(7, (i) {
            final start = 150 + i * 85;
            return ((ms - start) / 640).clamp(0.0, 1.0);
          });
          return Transform.rotate(
            angle: wiggle * math.pi / 180,
            child: CustomPaint(
              size: Size.square(size),
              painter: _WheelPainter(
                gm: gm,
                pops: pops,
                earned: earned,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final GmColors gm;
  final List<double> pops;
  final int? earned;

  _WheelPainter({required this.gm, required this.pops, this.earned});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 112);
    const c = Offset(56, 56);
    canvas.drawCircle(c, 53, Paint()..color = gm.card);
    canvas.drawCircle(
        c,
        53,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    const sweep = 2 * math.pi / 7;
    for (var i = 0; i < 7; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: 50), start, sweep, false)
        ..close();
      // pop: scale .6 rotate −18° → reposo, curva muelle (con rebote).
      final p = GmMotion.spring.transform(pops[i]);
      final scale = 0.6 + 0.4 * p;
      final rot = (-18 * (1 - p)) * math.pi / 180;
      final mid = start + sweep / 2;
      final pivot = c + Offset(math.cos(mid), math.sin(mid)) * 27;
      final faded = earned != null && i >= earned!;
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(rot);
      canvas.scale(scale);
      canvas.translate(-pivot.dx, -pivot.dy);
      canvas.drawPath(
          path,
          Paint()
            ..color = QuesitosWheel.colors[i]
                .withValues(alpha: faded ? 0.24 : 1));
      canvas.drawPath(
          path,
          Paint()
            ..color = gm.card
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round);
      canvas.restore();
    }
    canvas.drawCircle(c, 17, Paint()..color = gm.card);
    canvas.drawCircle(
        c,
        17,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    if (earned != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$earned/7',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: gm.label,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => true;
}
