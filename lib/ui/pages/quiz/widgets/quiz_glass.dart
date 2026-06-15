import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Atmósfera DCC del juego, **theme-aware**: crema en modo claro, dark en modo
/// oscuro (sigue `context.brand` como el resto de la app). Un glow Atlántico
/// muy sutil arriba da profundidad sin romper ninguno de los dos temas.
BoxDecoration quizBackground(BuildContext context) {
  final brand = context.brand;
  return BoxDecoration(
    gradient: RadialGradient(
      center: const Alignment(0, -0.7),
      radius: 1.3,
      colors: [
        Color.alphaBlend(
            AppColors.atlantico.withValues(alpha: 0.07), brand.base),
        brand.base,
      ],
    ),
  );
}

/// Tarjeta liquid-glass del juego: blur + glass del tema (crema/dark) + borde y
/// sombra. Estética iOS 26 del resto de la app.
class QuizGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final Color? borderColor;

  const QuizGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadius.lg,
    this.tint,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? brand.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? brand.border),
            boxShadow: AppShadows.soft(),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Botón circular glass (cerrar, ayuda, atrás) — theme-aware.
class QuizGlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const QuizGlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: brand.glass,
              shape: BoxShape.circle,
              border: Border.all(color: brand.borderStrong),
            ),
            child: Icon(icon, color: brand.textPrimary, size: size * 0.46),
          ),
        ),
      ),
    );
  }
}
