import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  /// Escala única de radios: xs mini-pills · sm chips · md cards ·
  /// lg wrappers/sheets · pill cápsulas · full stadium/círculos.
  static const double xs   = 8;
  static const double sm   = 12;
  static const double md   = 16;
  static const double lg   = 22;
  static const double pill = 32;

  /// Totalmente redondo (stadium en rectángulos, círculo en cuadrados).
  /// Estilo liquid-glass iOS 27: botones flotantes y de compartir SIEMPRE así.
  static const double full = 999;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft() => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 22,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> accent(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
