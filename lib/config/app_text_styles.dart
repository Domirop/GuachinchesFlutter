import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tres familias: display (Oswald), editorial (Merriweather italic), ui (Inter).
/// Las TTF se declaran en pubspec.yaml bajo assets/fonts/.
///
/// Escala tipográfica canónica de la app:
///   Hero        (~32 pt) — [displayHero] — único por viewport, solo en ParallaxHero.
///   Section headline (~18 pt) — [displaySection] con [sectionHeadlineSize] — banners y callouts.
///   Eyebrow     (~10 pt) — [eyebrow] — labels secundarios sobre-sección.
class AppTextStyles {
  AppTextStyles._();

  /// Tamaño mínimo permitido (Apple Human Interface Guidelines).
  /// Cualquier helper aplica este suelo automáticamente.
  static const double minSize = 11.0;

  /// Tamaño canónico para titulares de sección (banners, callouts).
  /// Nivel intermedio entre el Hero (~32) y los eyebrows (~10).
  static const double sectionHeadlineSize = 18.0;

  static double _clamp(double s) => math.max(minSize, s);

  static const _display = 'Oswald';
  static const _editorial = 'Merriweather';
  static const _ui = 'Inter';

  /// Color por defecto del texto. ThemeCubit lo actualiza en cada cambio de modo:
  /// - dark mode → AppColors.crema
  /// - light mode → AppColors.ink
  static Color defaultTextColor = AppColors.crema;

  /// Para textos secundarios/muted con opacity sobre el lienzo.
  /// dark → crema con opacity / light → ink-soft / ink-muted
  static Color get _eyebrowColor =>
      defaultTextColor == AppColors.crema
          ? AppColors.crema.withOpacity(0.55)
          : AppColors.inkSoft;

  static Color get _editorialColor =>
      defaultTextColor == AppColors.crema
          ? AppColors.crema.withOpacity(0.65)
          : AppColors.inkSoft;

  static Color get _mutedColor =>
      defaultTextColor == AppColors.crema
          ? AppColors.crema.withOpacity(0.45)
          : AppColors.inkMuted;

  // Helper: para variable fonts (Oswald) hay que setear el eje 'wght'
  // además del fontWeight. Sin fontVariations, el render queda en Regular.
  static List<FontVariation> _wght(double w) => [FontVariation('wght', w)];

  // Display (Oswald)
  static TextStyle displayHero({
    double size = 32,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) =>
      TextStyle(
        fontFamily: _display,
        fontWeight: weight,
        fontVariations: _wght(weight.value.toDouble()),
        fontSize: _clamp(size),
        height: 1.0,
        letterSpacing: -0.48,
        color: color ?? defaultTextColor,
      );

  static TextStyle displaySection({double size = 13, Color? color}) => TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w700,
        fontVariations: _wght(700),
        fontSize: _clamp(size),
        letterSpacing: 1.4,
        color: color ?? defaultTextColor,
      );

  static TextStyle eyebrow({double size = 11, Color? color}) => TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w600,
        fontVariations: _wght(600),
        fontSize: _clamp(size),
        letterSpacing: 1.6,
        color: color ?? _eyebrowColor,
      );

  static TextStyle chipLabel({double size = 11, Color? color}) => TextStyle(
        fontFamily: _display,
        fontWeight: FontWeight.w700,
        fontVariations: _wght(700),
        fontSize: _clamp(size),
        letterSpacing: 0.8,
        color: color ?? defaultTextColor,
      );

  // Editorial (Merriweather italic)
  static TextStyle editorial({double size = 11, Color? color}) => TextStyle(
        fontFamily: _editorial,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
        fontSize: _clamp(size),
        height: 1.35,
        color: color ?? _editorialColor,
      );

  // UI (Inter)
  static TextStyle ui({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _ui,
        fontWeight: weight,
        fontSize: _clamp(size),
        letterSpacing: letterSpacing,
        color: color ?? defaultTextColor,
      );

  static TextStyle muted({double size = 11, Color? color}) => TextStyle(
        fontFamily: _ui,
        fontWeight: FontWeight.w400,
        fontSize: _clamp(size),
        color: color ?? _mutedColor,
      );
}
