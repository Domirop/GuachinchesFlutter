import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// Barra de acción inferior de las pantallas de detalle.
///
/// Dos modos:
/// - **Clásico** (`floating: false`): barra opaca `brand.base` con primario
///   atlántico + botón secundario sólido. Lo usa la visita.
/// - **Flotante liquid-glass** (`floating: true`): sin fondo (el contenido se ve
///   detrás vía `extendBody`), botones secundarios en cristal. Si se pasa
///   `phone`, a los 60 s aparece un botón "Llamar" que se expande de derecha a
///   izquierda y luego "suena" (vibración periódica del icono) para destacar.
class BottomCtaBar extends StatefulWidget {
  final VoidCallback onPrimary;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final IconData secondaryIcon;
  final String? primaryIdentifier;
  final String? secondaryIdentifier;

  /// Estilo flotante cristal (sin barra opaca detrás).
  final bool floating;

  /// Teléfono del negocio. Si no es null y `floating`, habilita el botón
  /// "Llamar" tras 60 s de permanencia en la pantalla.
  final String? phone;

  const BottomCtaBar({
    super.key,
    required this.onPrimary,
    this.primaryLabel = 'CÓMO LLEGAR ›',
    this.onSecondary,
    this.secondaryIcon = Icons.ios_share,
    this.primaryIdentifier,
    this.secondaryIdentifier,
    this.floating = false,
    this.phone,
  });

  @override
  State<BottomCtaBar> createState() => _BottomCtaBarState();
}

class _BottomCtaBarState extends State<BottomCtaBar>
    with TickerProviderStateMixin {
  /// Tras este tiempo mirando el local, ofrecemos llamar.
  static const _callAfter = Duration(seconds: 60);

  Timer? _callTimer;

  late final AnimationController _expandCtrl; // expansión derecha→izquierda
  late final AnimationController _ringCtrl; // "suena el teléfono"
  late final Animation<double> _ringAngle;

  bool get _callEnabled =>
      widget.floating &&
      widget.phone != null &&
      widget.phone!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    // Sacudida corta + pausa larga → "ring" periódico, llamativo pero no pesado.
    _ringAngle = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 0.22)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.22, end: -0.22), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.22, end: 0.16), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.16, end: -0.16), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 14), // pausa
    ]).animate(_ringCtrl);

    _expandCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_ringCtrl.isAnimating) {
        _ringCtrl.repeat();
      }
    });

    if (_callEnabled) {
      _callTimer = Timer(_callAfter, () {
        if (!mounted) return;
        _expandCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _expandCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final p = widget.phone;
    if (p == null) return;
    final sanitized = p.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);
    try {
      await launchUrl(uri);
    } catch (_) {
      // Sin dialer (p.ej. simulador): no-op.
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.floating ? _buildFloating(context) : _buildClassic(context);
  }

  // ── Flotante liquid-glass ───────────────────────────────────────────────
  Widget _buildFloating(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 10),
      child: Row(
        children: [
          Expanded(child: _primaryPill(context, floating: true)),
          if (widget.onSecondary != null) ...[
            const SizedBox(width: 10),
            _GlassIconButton(
              icon: widget.secondaryIcon,
              onTap: widget.onSecondary!,
              identifier: widget.secondaryIdentifier,
            ),
          ],
          // "RESERVA YA": pill que se expande de derecha a izquierda; el icono
          // de teléfono "suena" para destacar la conversión.
          if (_callEnabled)
            SizeTransition(
              axis: Axis.horizontal,
              axisAlignment: 1.0,
              sizeFactor: CurvedAnimation(
                  parent: _expandCtrl, curve: Curves.easeOutCubic),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 10),
                  _ReservePill(onTap: _call, ringAngle: _ringAngle),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Clásico (opaco) ─────────────────────────────────────────────────────
  Widget _buildClassic(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: context.brand.base,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
      child: Row(
        children: [
          Expanded(child: _primaryPill(context, floating: false)),
          if (widget.onSecondary != null) ...[
            const SizedBox(width: 8),
            _SolidIconButton(
              icon: widget.secondaryIcon,
              onTap: widget.onSecondary!,
              identifier: widget.secondaryIdentifier,
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryPill(BuildContext context, {required bool floating}) {
    final btn = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.atlantico,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        elevation: floating ? 6 : 0,
        shadowColor: floating
            ? AppColors.atlantico.withOpacity(0.45)
            : Colors.transparent,
      ),
      onPressed: widget.onPrimary,
      child: Text(
        widget.primaryLabel,
        style: AppTextStyles.displaySection(size: 11)
            .copyWith(color: Colors.white, letterSpacing: 1.0),
      ),
    );
    if (widget.primaryIdentifier != null) {
      return Semantics(
          identifier: widget.primaryIdentifier!, button: true, child: btn);
    }
    return btn;
  }
}

/// Botón icono en cristal (liquid glass) — flotante, sin fondo opaco.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? identifier;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final child = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: brand.glass,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: brand.border, width: 0.8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: brand.textPrimary),
          ),
        ),
      ),
    );
    if (identifier != null) {
      return Semantics(identifier: identifier!, button: true, child: child);
    }
    return child;
  }
}

/// Pill "RESERVA YA" en cristal atlántico — la conversión. El icono de teléfono
/// "suena" (rotación) mientras está visible para llamar la atención.
class _ReservePill extends StatelessWidget {
  final VoidCallback onTap;
  final Animation<double> ringAngle;

  const _ReservePill({required this.onTap, required this.ringAngle});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'restaurant-detail-call-button',
      button: true,
      label: 'Reserva ya',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.atlantico.withOpacity(0.18),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: AppColors.atlantico.withOpacity(0.5), width: 0.8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RepaintBoundary: el icono "suena" en bucle; lo aislamos en
                  // su capa para no repintar la píldora en cada frame.
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: ringAngle,
                      builder: (_, child) => Transform.rotate(
                          angle: ringAngle.value, child: child),
                      child: const Icon(Icons.phone_rounded,
                          size: 19, color: AppColors.atlantico),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RESERVA YA',
                    style: AppTextStyles.displaySection(size: 11).copyWith(
                        color: AppColors.atlantico, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón icono sólido (modo clásico).
class _SolidIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? identifier;

  const _SolidIconButton(
      {required this.icon, required this.onTap, this.identifier});

  @override
  Widget build(BuildContext context) {
    final gesture = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.brand.surface,
          border: Border.all(color: context.brand.borderStrong),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: context.brand.textPrimary),
      ),
    );
    if (identifier != null) {
      return Semantics(identifier: identifier!, button: true, child: gesture);
    }
    return gesture;
  }
}
