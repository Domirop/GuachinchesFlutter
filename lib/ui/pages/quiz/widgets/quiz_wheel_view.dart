import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/quiz/quiz_models.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_glass.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_lives.dart';
import 'package:guachinches/ui/pages/quiz/widgets/quiz_wedges.dart';

/// Ruleta de 7 sectores. Al entrar pide girar ([onNeedSpin]); cuando el cubit
/// fija [landed], anima el giro (varias vueltas + aterrizaje spring) y al
/// terminar avisa con [onSettled] para abrir la pregunta.
class QuizWheelView extends StatefulWidget {
  final List<QuizCategory> categories;
  final QuizCategory? landed;
  final int lives;
  final int score;
  final Set<String> owned;
  final VoidCallback onNeedSpin;
  final VoidCallback onSettled;
  final VoidCallback onExit;

  const QuizWheelView({
    super.key,
    required this.categories,
    required this.landed,
    required this.lives,
    required this.score,
    required this.owned,
    required this.onNeedSpin,
    required this.onSettled,
    required this.onExit,
  });

  @override
  State<QuizWheelView> createState() => _QuizWheelViewState();
}

class _QuizWheelViewState extends State<QuizWheelView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _angle;
  bool _requested = false;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _angle = const AlwaysStoppedAnimation(0);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onSettled();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRequest());
  }

  void _maybeRequest() {
    if (!_requested && widget.landed == null) {
      _requested = true;
      widget.onNeedSpin();
    } else if (widget.landed != null) {
      _startSpin();
    }
  }

  @override
  void didUpdateWidget(QuizWheelView old) {
    super.didUpdateWidget(old);
    if (old.landed == null && widget.landed != null) _startSpin();
  }

  void _startSpin() {
    if (_spinning || widget.landed == null || widget.categories.isEmpty) return;
    _spinning = true;
    final n = widget.categories.length;
    final sweep = 2 * math.pi / n;
    final i = widget.categories.indexWhere((c) => c.slug == widget.landed!.slug);
    final target = i < 0 ? 0 : i;
    final end = 4 * 2 * math.pi - (target * sweep + sweep / 2);
    _angle = Tween<double>(begin: 0, end: end).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    HapticFeedback.mediumImpact();
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = widget.categories.map((c) => c.color).toList();
    final names = widget.categories.map((c) => c.name).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                QuizGlassCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: widget.onExit,
                    size: 38),
                const SizedBox(width: 12),
                QuizLives(lives: widget.lives),
                const Spacer(),
                Text('${widget.score}',
                    style: AppTextStyles.displaySection(
                        size: 20, color: brand.textPrimary)),
                const SizedBox(width: 4),
                Text('PTS',
                    style: AppTextStyles.eyebrow(
                        size: 10,
                        color: brand.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            // Progreso de quesitos (claro)
            QuizWedgesStrip(categories: widget.categories, owned: widget.owned),
            const Spacer(),
            Text('GIRA LA RULETA',
                style: AppTextStyles.eyebrow(
                    size: 12, color: AppColors.atlanticoClaro)),
            const SizedBox(height: 24),
            // Rueda + puntero
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _angle.value,
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: _WheelPainter(colors: colors, labels: names),
                      ),
                    ),
                  ),
                  // Eje central glass (deja entrever los colores de la rueda)
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: brand.glass,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: brand.border,
                              width: 2),
                        ),
                        child: Icon(Icons.casino_rounded,
                            color: brand.textPrimary, size: 26),
                      ),
                    ),
                  ),
                  // Puntero (arriba)
                  Positioned(
                    top: -2,
                    child: CustomPaint(
                      size: const Size(28, 22),
                      painter: _PointerPainter(brand.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Color> colors;
  final List<String> labels;
  _WheelPainter({required this.colors, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final n = colors.length;
    if (n == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sweep = 2 * math.pi / n;

    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep,
        true,
        Paint()..color = colors[i],
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withValues(alpha: 0.18),
      );
    }
    // Borde exterior
    canvas.drawCircle(
      center,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.colors != colors;
}

class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(p, Colors.black, 4, false);
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
