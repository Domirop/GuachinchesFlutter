import 'package:flutter/material.dart';

/// Tokens del rediseño iOS 27 ("Cálido, vivo y muy iOS").
///
/// Fuente: `guachinches-coordination/design/rediseno-ios27/` (themes.js,
/// shared.css y el tablero Sistema). Día = claro (lienzo arena + tarjetas
/// blanco puro), Noche = oscuro. Se eligen por `Theme.brightness`, así siguen
/// el selector de tema de Ajustes sin tocar `BrandColors`.
///
/// Uso: `final gm = GmColors.of(context);`
@immutable
class GmColors {
  final Color canvas;
  final Color card;
  final Color bandCard;
  final Color band;
  final Color bandInk;
  final Color fill;
  final Color label;
  final Color label2;
  final Color sep;
  final Color accent;
  final Color accentSoft;
  final Color green;
  final Color greenText;
  final Color glass;
  final Color glassEdge;
  final Color glassInk;
  final Color photoGlass;
  final Color photoEdge;
  final Color photoInk;
  final Color wineEdge;
  final Color volcFill;
  final Color volcInk;
  final Color edgeFade0;
  final Color edgeFade1;

  /// Fundido superior bajo la barra de estado (InicioScroll · edgeTop).
  final Color edgeTop0;
  final Color edgeTop1;

  /// e1 · tarjeta: filo 1 px + sombra cálida.
  final List<BoxShadow> shadow1;

  /// e2 · flotante: pósters, barra, botones.
  final List<BoxShadow> shadow2;

  final bool isDark;

  const GmColors._({
    required this.canvas,
    required this.card,
    required this.bandCard,
    required this.band,
    required this.bandInk,
    required this.fill,
    required this.label,
    required this.label2,
    required this.sep,
    required this.accent,
    required this.accentSoft,
    required this.green,
    required this.greenText,
    required this.glass,
    required this.glassEdge,
    required this.glassInk,
    required this.photoGlass,
    required this.photoEdge,
    required this.photoInk,
    required this.wineEdge,
    required this.volcFill,
    required this.volcInk,
    required this.edgeFade0,
    required this.edgeFade1,
    required this.edgeTop0,
    required this.edgeTop1,
    required this.shadow1,
    required this.shadow2,
    required this.isDark,
  });

  // ── Invariantes ───────────────────────────────────────────────────────────
  static const wine = Color(0xFF2A0E14);
  static const gold = Color(0xFFC9A96B);
  static const cream = Color(0xFFF2E8D5);
  static const creamHi = Color(0xFFFFF6E6);
  static const star = Color(0xFFC98200);
  static const heart = Color(0xFFFF3B5C);
  static const atlantico = Color(0xFF0085C4);
  static const badgeRed = Color(0xFFD6362A);

  /// Botón cápsula primario: degradado Atlántico con brillo superior.
  static const accentFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0079B5), Color(0xFF00669B)],
  );

  static const day = GmColors._(
    canvas: Color(0xFFF8F4EC),
    card: Color(0xFFFFFFFF),
    bandCard: Color(0xFFFFFFFF),
    band: Color(0xFFEFE4CD),
    bandInk: Color(0xFF7A5A20),
    fill: Color(0x126E501E), // rgba(110,80,30,0.07)
    label: Color(0xFF1F1A14),
    label2: Color(0xFF6E6253),
    sep: Color(0x1C5A4018), // rgba(90,64,24,0.11)
    accent: Color(0xFF006FA3),
    accentSoft: Color(0x1C0085C4), // rgba(0,133,196,0.11)
    green: Color(0xFF2FBF5B),
    greenText: Color(0xFF1E7A42),
    glass: Color(0xBDFFFFFF), // 0.74
    glassEdge: Color(0xE6FFFFFF), // 0.9
    glassInk: Color(0xFF1F1A14),
    photoGlass: Color(0xCCFFFFFF), // 0.80
    photoEdge: Color(0xE6FFFFFF),
    photoInk: Color(0xFF1F1A14),
    wineEdge: Color(0x00C9A96B),
    volcFill: Color(0xFFE9DCC2),
    volcInk: Color(0xFF1F1A14),
    edgeFade0: Color(0x00F8F4EC),
    edgeFade1: Color(0xF0F8F4EC),
    edgeTop0: Color(0xF5F8F4EC), // .96
    edgeTop1: Color(0xE6F8F4EC), // .9
    // 0 0 0 1px rgba(90,64,24,.06), 0 1px 2px rgba(90,64,24,.06),
    // 0 10px 24px -10px rgba(90,64,24,.22)
    shadow1: [
      BoxShadow(color: Color(0x0F5A4018), spreadRadius: 1),
      BoxShadow(
          color: Color(0x0F5A4018), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
          color: Color(0x385A4018),
          offset: Offset(0, 10),
          blurRadius: 24,
          spreadRadius: -10),
    ],
    // 0 0 0 .5px rgba(90,64,24,.10), 0 2px 6px rgba(60,40,10,.08),
    // 0 16px 36px -12px rgba(60,40,10,.34)
    shadow2: [
      BoxShadow(color: Color(0x1A5A4018), spreadRadius: 0.5),
      BoxShadow(
          color: Color(0x143C280A), offset: Offset(0, 2), blurRadius: 6),
      BoxShadow(
          color: Color(0x573C280A),
          offset: Offset(0, 16),
          blurRadius: 36,
          spreadRadius: -12),
    ],
    isDark: false,
  );

  static const night = GmColors._(
    canvas: Color(0xFF0A141B),
    card: Color(0xFF13212B),
    bandCard: Color(0xFF1A2B37),
    band: Color(0xFF0F1C25),
    bandInk: Color(0xFFC9A96B),
    fill: Color(0x14C8E1F5), // rgba(200,225,245,0.08)
    label: Color(0xFFF3EEE4),
    label2: Color(0xA3F3EEE4), // 0.64
    sep: Color(0x1CC8E1F5),
    accent: Color(0xFF4DAEDB),
    accentSoft: Color(0x2E4DAEDB), // 0.18
    green: Color(0xFF30D158),
    greenText: Color(0xFF30D158),
    glass: Color(0xA816222C), // rgba(22,34,44,0.66)
    glassEdge: Color(0x1FFFFFFF),
    glassInk: Color(0xFFF3EEE4),
    photoGlass: Color(0x9E101A22), // 0.62
    photoEdge: Color(0x2EFFFFFF),
    photoInk: Color(0xFFF3EEE4),
    wineEdge: Color(0x47C9A96B), // 0.28
    volcFill: Color(0xFF22323D),
    volcInk: Color(0xFFF3EEE4),
    edgeFade0: Color(0x000A141B),
    edgeFade1: Color(0xF00A141B),
    edgeTop0: Color(0xF50A141B),
    edgeTop1: Color(0xE60A141B),
    shadow1: [
      BoxShadow(color: Color(0x0DFFFFFF), spreadRadius: 1),
      BoxShadow(
          color: Color(0xB3000000),
          offset: Offset(0, 12),
          blurRadius: 28,
          spreadRadius: -12),
    ],
    shadow2: [
      BoxShadow(color: Color(0x1AFFFFFF), spreadRadius: 0.5),
      BoxShadow(
          color: Color(0xCC000000),
          offset: Offset(0, 18),
          blurRadius: 40,
          spreadRadius: -12),
    ],
    isDark: true,
  );

  static GmColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : day;
}

/// Radios concéntricos: interior = exterior − margen.
class GmRadius {
  GmRadius._();
  static const double card = 24; // tarjeta de sitio
  static const double photo = 18; // foto dentro de tarjeta (24 − 6)
  static const double guide = 28; // guía / póster / quiz / canarismo
  static const double guidePhoto = 22;
  static const double poster = 28;
  static const double tile = 22;
  static const double hero = 26; // hero de especialidades
  static const double listIcon = 14;
  static const double pill = 999;
}

/// Márgenes del sistema.
class GmSpace {
  GmSpace._();
  static const double gutter = 16; // márgenes laterales
  static const double titleInset = 20; // títulos de sección
  static const double section = 40; // entre secciones
  static const double cardGap = 12;
}

/// Rampa tipográfica SF (sin `fontFamily`: hereda la del sistema).
/// Tamaños/interlineado tal cual el tablero Sistema (px → pt).
class GmText {
  GmText._();

  static TextStyle _s(double size, double line, FontWeight w,
          {double ls = 0, Color? color, FontStyle? style}) =>
      TextStyle(
        fontSize: size,
        height: line / size,
        fontWeight: w,
        letterSpacing: ls,
        color: color,
        fontStyle: style,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// Display 46/52 · 800 (palabra del canarismo).
  static TextStyle display({Color? color}) =>
      _s(46, 52, FontWeight.w800, ls: -1.4, color: color);

  /// Título grande 34/41 · 800 (ficha).
  static TextStyle largeTitle({Color? color}) =>
      _s(34, 41, FontWeight.w800, ls: -0.9, color: color);

  /// Título 2 · 22/28 · 700 (secciones, quiz).
  static TextStyle title2({Color? color}) =>
      _s(22, 28, FontWeight.w700, ls: -0.45, color: color);

  /// Póster 20/25 · 700.
  static TextStyle poster({Color? color}) =>
      _s(20, 25, FontWeight.w700, ls: -0.45, color: color);

  /// Tarjeta de sitio 16/21 · 600.
  static TextStyle cardTitle({Color? color}) =>
      _s(16, 21, FontWeight.w600, ls: -0.3, color: color);

  /// Título de guía 17/22 · 600.
  static TextStyle guideTitle({Color? color}) =>
      _s(17, 22, FontWeight.w600, ls: -0.35, color: color);

  /// Cuerpo 15/20 · 400.
  static TextStyle body({Color? color, FontWeight w = FontWeight.w400}) =>
      _s(15, 20, w, color: color);

  /// Cuerpo 17/23 (búsqueda, textos destacados).
  static TextStyle body17({Color? color, FontWeight w = FontWeight.w400}) =>
      _s(17, 23, w, ls: w == FontWeight.w400 ? 0 : -0.3, color: color);

  /// Subtítulo 14/19.
  static TextStyle sub({Color? color, FontWeight w = FontWeight.w400}) =>
      _s(14, 19, w, color: color);

  /// Antetítulo · plato 13/18 · 600.
  static TextStyle eyebrow({Color? color, FontWeight w = FontWeight.w600}) =>
      _s(13, 18, w, color: color);

  /// Meta de tarjeta 13/18 · 400.
  static TextStyle meta({Color? color}) =>
      _s(13, 18, FontWeight.w400, color: color);

  /// Chip sobre foto 12/16 · 600.
  static TextStyle chip({Color? color, FontWeight w = FontWeight.w600}) =>
      _s(12, 16, w, color: color);

  /// Etiqueta de pestaña 10/12.
  static TextStyle tab({Color? color, FontWeight w = FontWeight.w600}) =>
      _s(10, 12, w, color: color);
}

/// Movimiento (tabla del tablero Sistema). Solo hay tres bucles: deriva de
/// nubes, borde «mar de nubes» y punto vivo. Todo lo demás se reproduce una
/// vez y se queda quieto; las entradas solo mueven `transform`.
class GmMotion {
  GmMotion._();

  /// Muelle (.34, 1.56, .64, 1) — pop, squash, quesitos.
  static const spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Asentar (.2, .8, .2, 1) — entradas, hojas.
  static const settle = Cubic(0.2, 0.8, 0.2, 1);

  /// Estándar (.4, 0, .2, 1) — brillos, chincheta.
  static const ease = Cubic(0.4, 0, 0.2, 1);

  static const rise = Duration(milliseconds: 520);
  static const riseStagger = Duration(milliseconds: 50);
  static const double riseDistance = 14;
  static const wedge = Duration(milliseconds: 640);
  static const wedgeStagger = Duration(milliseconds: 85);
  static const letter = Duration(milliseconds: 700);
  static const letterStagger = Duration(milliseconds: 70);
  static const tabSquash = Duration(milliseconds: 820);
  static const livePing = Duration(milliseconds: 3200);
  static const billowA = Duration(seconds: 46);
  static const billowB = Duration(seconds: 70);

  /// `true` si el sistema pide reducir movimiento → estado final, sin animar.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
