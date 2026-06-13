import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

/// Botón OAuth (Google / Apple) reutilizable. Extraído de `login_screen.dart`
/// para poder usarlo también en el último paso del onboarding sin duplicar el
/// diseño ni los logos.
class OAuthButton extends StatefulWidget {
  final bool isDark;
  final bool isGoogleButton;
  final bool loading;
  final bool disabled;
  final VoidCallback? onTap;
  final String label;

  const OAuthButton({
    super.key,
    required this.isDark,
    required this.isGoogleButton,
    required this.label,
    this.loading = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  State<OAuthButton> createState() => _OAuthButtonState();
}

class _OAuthButtonState extends State<OAuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.disabled ? 0.4 : (widget.loading ? 0.9 : 1.0);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _pressCtrl.reverse() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _pressCtrl.forward();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Opacity(
          opacity: opacity,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0x26000000), // rgba(0,0,0,0.15)
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.atlantico),
                    ),
                  )
                else if (widget.isGoogleButton)
                  const GoogleLogo()
                else
                  const AppleLogo(color: AppColors.ink),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: AppTextStyles.ui(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo "G" oficial de Google (asset SVG de la marca, no redibujado).
/// `assets/images/google_g_logo.svg` se extrae del set oficial de branding de
/// "Sign in with Google" — no alterar colores ni proporciones (brand guidelines).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/google_g_logo.svg',
      width: 20,
      height: 20,
    );
  }
}

/// Logo Apple oficial (marca "Sign in with Apple", asset PNG recortado a su
/// bounding box con clear-space original). `color` lo tinta (negro sobre botón
/// claro; blanco si algún día se usa botón oscuro) vía blend mode.
class AppleLogo extends StatelessWidget {
  final Color color;
  const AppleLogo({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/apple_logo.png',
      height: 20,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
