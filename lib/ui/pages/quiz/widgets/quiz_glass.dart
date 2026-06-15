import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';

/// Atmósfera DCC del juego: dark base #0A0F14 con un glow Atlántico profundo
/// arriba (sin negro puro ni teal genérico). Las tarjetas glass flotan encima.
const BoxDecoration quizBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
    colors: [
      Color(0xFF0C1A28), // atlántico profundo muy oscuro
      AppColors.base, // #0A0F14
      Color(0xFF080C10), // base un punto más hondo abajo
    ],
  ),
);

/// Tarjeta liquid-glass del juego: blur + tinte glass-dark + borde y realce
/// superior (estética iOS 26 del resto de la app).
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? AppColors.glassDark,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Botón circular glass (cerrar, ayuda, atrás) — blur + glass-dark + realce.
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
              color: AppColors.glassDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: AppColors.crema, size: size * 0.46),
          ),
        ),
      ),
    );
  }
}
