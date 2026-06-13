import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  /// Escala única de radios: xs mini-pills · sm chips · md cards ·
  /// lg wrappers/sheets · pill cápsulas y campos redondos.
  static const double xs   = 8;
  static const double sm   = 12;
  static const double md   = 16;
  static const double lg   = 22;
  static const double pill = 32;
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
