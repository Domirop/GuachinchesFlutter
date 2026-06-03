import 'package:flutter/material.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Bloque skeleton con shimmer de **barrido diagonal**: una banda de brillo
/// recorre el bloque de esquina a esquina en bucle mientras llegan los datos
/// del backend (en vez de un simple pulso de opacidad).
///
/// Todos los [ShimmerBox] comparten duración y arrancan en su initState, así
/// el barrido se ve coherente entre las piezas de una misma card. Es
/// brand-aware: tinta sobre `textPrimary` con alpha bajo, legible en claro y
/// oscuro.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.brand.textPrimary;
    final baseColor = base.withValues(alpha: 0.06);
    final highlight = base.withValues(alpha: 0.16);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor, highlight, baseColor],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideGradient(_controller.value),
          ),
        ),
      ),
    );
  }
}

/// Desplaza el gradiente de `-1.5·ancho` a `+1.5·ancho` para que la banda de
/// brillo entre y salga del bloque en cada ciclo, produciendo el barrido.
class _SlideGradient extends GradientTransform {
  final double t; // 0..1

  const _SlideGradient(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = (t * 3 - 1.5) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}
