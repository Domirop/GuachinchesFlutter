import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Tarjeta de estado del rediseño (`state_card` de los tableros): dibujo,
/// título 20/25 · 700, texto 15/21 secundario y botones opcionales.
///
/// Candidata a `lib/ui/theme/` (hay copias privadas en Descubrir, Visitas…).
class GmStateCard extends StatelessWidget {
  final String? identifier;
  final Widget art;
  final String title;
  final String text;
  final Widget? action;

  /// Anuncia el cambio (errores).
  final bool liveRegion;

  const GmStateCard({
    super.key,
    this.identifier,
    required this.art,
    required this.title,
    required this.text,
    this.action,
    this.liveRegion = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      liveRegion: liveRegion,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              art,
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GmText.poster(color: gm.label),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GmText.body(color: gm.label2).copyWith(height: 21 / 15),
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Volcán mascota contento (100 × 70): el de [GmSadVolcano] con la boca en
/// sonrisa (`HAPPY_VOLCANO` de los tableros). Candidato a `lib/ui/theme/`.
class GmHappyVolcano extends StatelessWidget {
  final double width;
  const GmHappyVolcano({super.key, this.width = 100});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size(width, width * 0.7),
          painter: _HappyVolcanoPainter(GmColors.of(context)),
        ),
      );
}

class _HappyVolcanoPainter extends CustomPainter {
  final GmColors gm;
  _HappyVolcanoPainter(this.gm);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 70);
    final body = Path()
      ..moveTo(6, 68)
      ..lineTo(34, 34)
      ..cubicTo(37, 30.6, 40, 29.9, 42.6, 31.8)
      ..lineTo(46.9, 34.8)
      ..cubicTo(50.1, 37, 53.5, 37, 56.7, 34.8)
      ..lineTo(61, 31.8)
      ..cubicTo(63.6, 29.9, 66.6, 30.6, 69.6, 34)
      ..lineTo(94, 68)
      ..close();
    canvas.drawPath(body, Paint()..color = gm.volcFill);
    canvas.drawPath(
        body,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final ink = Paint()..color = gm.volcInk;
    canvas.drawCircle(const Offset(42.5, 50), 2.8, ink);
    canvas.drawCircle(const Offset(57.5, 50), 2.8, ink);
    canvas.drawPath(
      Path()
        ..moveTo(45, 57)
        ..quadraticBezierTo(50, 60.8, 55, 57),
      Paint()
        ..color = gm.volcInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HappyVolcanoPainter old) => old.gm != gm;
}
