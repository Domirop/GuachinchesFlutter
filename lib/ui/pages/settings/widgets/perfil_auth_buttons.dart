import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/settings/widgets/perfil_widgets.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Proveedor de los botones de entrada del Perfil sin sesión.
enum PerfilAuthKind { apple, google }

/// «Continuar con Apple» (negro de día, blanco de noche, como pide Apple) y
/// «Continuar con Google» (tarjeta con filo). 52 de alto, a todo lo ancho.
class PerfilAuthButton extends StatelessWidget {
  final PerfilAuthKind kind;
  final bool loading;
  final VoidCallback? onTap;
  final String identifier;

  const PerfilAuthButton({
    super.key,
    required this.kind,
    required this.identifier,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final apple = kind == PerfilAuthKind.apple;
    final bg = apple ? (gm.isDark ? Colors.white : Colors.black) : gm.card;
    final ink = apple ? (gm.isDark ? Colors.black : Colors.white) : gm.label;
    final label = apple
        ? 'Continuar con Apple'
        : (loading ? 'Conectando con Google…' : 'Continuar con Google');
    final logo = loading
        ? PerfilSpinner(color: ink, size: 18)
        : apple
            ? PerfilLogo(PerfilIcons.apple, width: 18, height: 20, color: ink)
            : const PerfilLogo(PerfilIcons.google, width: 20, height: 20);
    final enabled = onTap != null;

    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedOpacity(
          opacity: enabled || loading ? 1 : 0.5,
          duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 160),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              border: apple ? null : Border.all(color: gm.sep),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                logo,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: ink,
                    ),
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
