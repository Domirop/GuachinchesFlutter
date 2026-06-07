import 'package:flutter/material.dart';
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

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.57,
        1.57,
        false,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.18);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 1.0, 1.57,
        false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.57, 1.0,
        false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -0.57, 1.57,
        false, paint);

    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.62, paint);
    final rect = Rect.fromLTWH(center.dx - radius * 0.02,
        center.dy - radius * 0.28, radius * 0.78, radius * 0.28);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppleLogo extends StatelessWidget {
  final Color color;
  const AppleLogo({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 22,
      child: CustomPaint(painter: _AppleLogoPainter(color: color)),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  final Color color;
  const _AppleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.18);
    path.cubicTo(w * 0.7, h * 0.18, w * 0.95, h * 0.36, w * 0.95, h * 0.6);
    path.cubicTo(w * 0.95, h * 0.84, w * 0.78, h * 1.0, w * 0.62, h * 1.0);
    path.cubicTo(w * 0.55, h * 1.0, w * 0.5, h * 0.96, w * 0.5, h * 0.96);
    path.cubicTo(w * 0.5, h * 0.96, w * 0.45, h * 1.0, w * 0.38, h * 1.0);
    path.cubicTo(w * 0.22, h * 1.0, w * 0.05, h * 0.84, w * 0.05, h * 0.6);
    path.cubicTo(w * 0.05, h * 0.36, w * 0.3, h * 0.18, w * 0.5, h * 0.18);
    path.close();

    final leaf = Path();
    leaf.moveTo(w * 0.5, h * 0.18);
    leaf.cubicTo(w * 0.5, h * 0.18, w * 0.6, h * 0.0, w * 0.72, h * 0.06);
    leaf.cubicTo(w * 0.72, h * 0.06, w * 0.6, h * 0.14, w * 0.5, h * 0.18);
    leaf.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
