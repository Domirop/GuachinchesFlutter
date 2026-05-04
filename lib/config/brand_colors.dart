import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

/// Tokens dependientes de tema (cambian entre light/dark).
/// Acentos invariantes (atlantico, mojo, sol, laurisilva, tierra, arena)
/// se siguen usando vía `AppColors.X` desde cualquier sitio.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  // Capas de fondo
  final Color base;     // fondo app
  final Color surface;  // cards, list items, inputs
  final Color elevated; // sheets, modals
  final Color overlay;  // popovers, tab bar

  // Texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Glass + bordes
  final Color glass;
  final Color border;
  final Color borderStrong;

  const BrandColors({
    required this.base,
    required this.surface,
    required this.elevated,
    required this.overlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glass,
    required this.border,
    required this.borderStrong,
  });

  static const dark = BrandColors(
    base: AppColors.base,
    surface: AppColors.surface,
    elevated: AppColors.elevated,
    overlay: AppColors.overlay,
    textPrimary: AppColors.crema,
    textSecondary: Color(0x8CF2E8D5), // crema 55%
    textMuted: Color(0x4DF2E8D5),     // crema 30%
    glass: AppColors.glassDark,
    border: AppColors.borderDark,
    borderStrong: AppColors.borderDarkMd,
  );

  static const light = BrandColors(
    base: AppColors.crema,
    surface: AppColors.cremaSoft,
    elevated: AppColors.cremaOscura,
    overlay: AppColors.cremaOscura,
    textPrimary: AppColors.ink,
    textSecondary: AppColors.inkSoft,
    textMuted: AppColors.inkMuted,
    glass: AppColors.glassCream,
    border: AppColors.borderCream,
    borderStrong: AppColors.borderCreamMd,
  );

  @override
  BrandColors copyWith({
    Color? base,
    Color? surface,
    Color? elevated,
    Color? overlay,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? glass,
    Color? border,
    Color? borderStrong,
  }) {
    return BrandColors(
      base: base ?? this.base,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      overlay: overlay ?? this.overlay,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      glass: glass ?? this.glass,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      base: Color.lerp(base, other.base, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
    );
  }
}

extension BrandColorsContext on BuildContext {
  BrandColors get brand =>
      Theme.of(this).extension<BrandColors>() ?? BrandColors.dark;
}
