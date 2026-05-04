import 'package:flutter/material.dart';

/// Tokens de color para la nueva home.
/// No usamos negro puro: 4 capas de oscuro (base/surface/elevated/overlay).
class AppColors {
  AppColors._();

  // Atlántico
  static const atlantico       = Color(0xFF0085C4);
  static const atlanticoOscuro = Color(0xFF006FA3);
  static const atlanticoClaro  = Color(0xFF339ED0);
  static const atlanticoTenue  = Color(0xFFCCE9F6);
  static const profundo        = Color(0xFF003D5C);

  // Dark mode — 4 capas
  static const base     = Color(0xFF0A0F14); // fondo app
  static const surface  = Color(0xFF111820); // cards
  static const elevated = Color(0xFF1A2535); // modals/sheets
  static const overlay  = Color(0xFF243348); // tab bar glass

  // Crema y tinta
  static const crema       = Color(0xFFF2E8D5);
  static const cremaOscura = Color(0xFFE8DBC4); // --cream-dark
  static const cremaSoft   = Color(0xFFF8F1E2); // --cream-soft
  static const ink         = Color(0xFF1A0D00);
  static const inkSoft     = Color(0xFF4A3A2A); // texto secundario en light
  static const inkMuted    = Color(0xFF7A6A58); // texto terciario en light
  static const arena       = Color(0xFFD4A96A);

  // Acentos semánticos
  static const laurisilva = Color(0xFF00A878); // abierto
  static const mojo       = Color(0xFFE8521A); // urgente
  static const sol        = Color(0xFFF5B700); // rating
  static const tierra     = Color(0xFF8B4513); // guachinches

  // Glass
  static const glassBlue  = Color(0xD10085C4);
  static const glassDark  = Color(0xA60A0F14);
  static const glassTab   = Color(0xB80A0F14);
  static const glassSheet = Color(0xD10A0F14);
  static const glassCream = Color(0x8CF2E8D5); // rgba(242,232,213,0.55) — light glass

  // Bordes — design system
  static const borderCream    = Color(0x141A0D00); // rgba(26,13,0,0.08)
  static const borderCreamMd  = Color(0x261A0D00); // rgba(26,13,0,0.15)
  static const borderDark     = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const borderDarkMd   = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const borderDarkLg   = Color(0x26FFFFFF); // rgba(255,255,255,0.15)

  /// Tinte RGBA superpuesto a la foto del hero por hora del día (0-23).
  static const Map<int, Color> hourTints = {
    0:  Color(0xCC02050A), 1:  Color(0xCC02050A),
    2:  Color(0xCC02050A), 3:  Color(0xCC02050A),
    4:  Color(0xB3280F05), 5:  Color(0x8C3C1400),
    6:  Color(0x73501E00), 7:  Color(0x40321200),
    8:  Color(0x26140800), 9:  Color(0x14050300),
    10: Color(0x0D030200), 11: Color(0x0D030200),
    12: Color(0x0FFFC832), 13: Color(0x14FFC832),
    14: Color(0x12FFB41E), 15: Color(0x17DC5A05),
    16: Color(0x24DC5A05), 17: Color(0x38C84B00),
    18: Color(0x52AA3200), 19: Color(0x595A143C),
    20: Color(0x8008082D), 21: Color(0x9904042A),
    22: Color(0xAD02021C), 23: Color(0xB802021C),
  };

  /// Opacidad del starfield por hora.
  static const Map<int, double> starOpacity = {
    0: 1.0,  1: 1.0,  2: 1.0,  3: 1.0,
    4: 0.4,  5: 0.15, 6: 0.05, 7: 0.0,
    8: 0.0,  9: 0.0,  10: 0.0, 11: 0.0,
    12: 0.0, 13: 0.0, 14: 0.0, 15: 0.0,
    16: 0.0, 17: 0.0, 18: 0.0,
    19: 0.12, 20: 0.55, 21: 0.72, 22: 0.87, 23: 0.95,
  };

  static Color tintForHour(int hour) =>
      hourTints[hour.clamp(0, 23)] ?? Colors.transparent;

  static double starsForHour(int hour) =>
      starOpacity[hour.clamp(0, 23)] ?? 0.0;
}
