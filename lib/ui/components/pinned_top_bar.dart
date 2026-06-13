import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';

/// Estilo del botón circular de la barra superior anclada.
/// - [darkGlass]: cristal oscuro + icono blanco. Para cabeceras sobre foto.
/// - [lightSolid]: crema sólida + borde + icono tinta. Para cabeceras sobre
///   fondos claros (gradientes crema, pantallas light-theme).
enum PinnedBarVariant { darkGlass, lightSolid }

/// Botón circular reutilizable de las barras de detalle (back / share / fav…).
/// Unifica el antiguo `FloatingCircleButton` de restaurant_detail y añade la
/// variante clara para pantallas con fondo crema.
class PinnedCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final PinnedBarVariant variant;
  final Color? iconColor;
  final String? identifier;

  const PinnedCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.variant = PinnedBarVariant.darkGlass,
    this.iconColor,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = variant == PinnedBarVariant.darkGlass;
    final gesture = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassDark : AppColors.cremaSoft,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : AppColors.borderCreamMd,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.ink.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 17,
          color: iconColor ?? (isDark ? Colors.white : AppColors.ink),
        ),
      ),
    );
    final content = identifier != null
        ? Semantics(identifier: identifier!, button: true, child: gesture)
        : gesture;
    // El blur solo aporta en la variante glass (sobre foto).
    if (!isDark) return content;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: content,
      ),
    );
  }
}

/// Barra superior **anclada**: botón de volver (izquierda) + acciones
/// (derecha), montada en un `Stack` POR ENCIMA del contenido scrollable para
/// que permanezca fija aunque se haga scroll — el patrón estándar de las apps.
///
/// Uso típico:
/// ```dart
/// Stack(children: [
///   CustomScrollView(...),
///   PinnedTopBar(
///     onBack: () => Navigator.of(context).maybePop(),
///     actions: [PinnedCircleButton(icon: Icons.ios_share_rounded, onTap: ...)],
///   ),
/// ])
/// ```
class PinnedTopBar extends StatelessWidget {
  /// Si es null no se pinta el botón de volver (p.ej. pantallas tab raíz).
  final VoidCallback? onBack;

  /// Acciones ancladas a la derecha (share, favorito, filtro…). Normalmente
  /// [PinnedCircleButton]s.
  final List<Widget> actions;

  final PinnedBarVariant variant;
  final String? backIdentifier;

  const PinnedTopBar({
    super.key,
    this.onBack,
    this.actions = const [],
    this.variant = PinnedBarVariant.darkGlass,
    this.backIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Row(
        children: [
          if (onBack != null)
            PinnedCircleButton(
              icon: Icons.arrow_back_ios_new,
              onTap: onBack!,
              variant: variant,
              identifier: backIdentifier,
            ),
          const Spacer(),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            actions[i],
          ],
        ],
      ),
    );
  }
}
