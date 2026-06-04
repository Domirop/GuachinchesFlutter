import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

/// Piezas visuales compartidas por la card del home y la pantalla de detalle
/// del Canarismo del día: el gradiente "atlántico → ámbar", la greca canaria
/// decorativa y la marca de agua con la inicial de la palabra.

/// Gradiente del hero/banner del canarismo: azul profundo → atlántico → ámbar
/// cálido (diagonal). Evoca mar canario + calidez de guachinche.
const LinearGradient kCanarismoGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0E4A66),
    AppColors.atlantico,
    Color(0xFFB97A2E),
  ],
  stops: [0.0, 0.52, 1.0],
);

/// Paleta de gradientes para los avatares de los canarismos anteriores.
/// Se elige de forma determinista por la palabra (mismo color siempre).
const List<List<Color>> _kAvatarGradients = [
  [Color(0xFFE0A23C), Color(0xFF9C6519)], // ámbar / arena
  [Color(0xFF8B4513), Color(0xFF5C2E0D)], // tierra / guachinche
  [Color(0xFF1F8F6B), Color(0xFF0C5A41)], // laurisilva
  [Color(0xFF2E97CC), Color(0xFF0A5680)], // atlántico
  [Color(0xFFD4632A), Color(0xFF8F3A12)], // mojo
];

List<Color> canarismoAvatarGradient(String word) {
  final i = (word.hashCode & 0x7fffffff) % _kAvatarGradients.length;
  return _kAvatarGradients[i];
}

/// Inicial de la palabra en mayúscula (para marcas de agua y avatares).
String canarismoInitial(String word) =>
    word.isNotEmpty ? word[0].toUpperCase() : '?';

/// Banda decorativa con la greca canaria (rombos enlazados). Se pinta sobre el
/// gradiente, normalmente al borde inferior del hero.
class GrecaBand extends StatelessWidget {
  final Color color;
  final double height;

  const GrecaBand({
    super.key,
    this.color = const Color(0x66D4A96A),
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _GrecaPainter(color)),
    );
  }
}

class _GrecaPainter extends CustomPainter {
  final Color color;
  const _GrecaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final midY = size.height / 2;
    final h = size.height * 0.42; // medio-alto del rombo
    final step = h * 2.6;

    // Línea base que enlaza los rombos.
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      stroke..color = color.withOpacity(0.5),
    );

    for (double cx = step / 2; cx < size.width + step; cx += step) {
      final path = Path()
        ..moveTo(cx, midY - h)
        ..lineTo(cx + h, midY)
        ..lineTo(cx, midY + h)
        ..lineTo(cx - h, midY)
        ..close();
      canvas.drawPath(path, stroke..color = color);
      canvas.drawCircle(Offset(cx, midY), 1.1, dot);
    }
  }

  @override
  bool shouldRepaint(_GrecaPainter old) => old.color != color;
}
