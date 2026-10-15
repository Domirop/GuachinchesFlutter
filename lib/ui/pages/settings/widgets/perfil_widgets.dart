import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Piezas del grupo Perfil (tableros TabPerfil, PerfilMiCuenta,
/// PerfilMisResenas y Guardados). Leen [GmColors]; candidatas a subir a
/// `lib/ui/theme` si otra pantalla las necesita (filas agrupadas tipo
/// Ajustes, hoja con asa, aviso flotante, botón destructivo).

// ── Iconos que no están en GmIcons (copiados del tablero) ───────────────────

class PerfilIcons {
  PerfilIcons._();

  static String _stroke(String inner, {double width = 2.2}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$width" stroke-linecap="round" '
      'stroke-linejoin="round">$inner</svg>';

  static final mail = _stroke(
      '<rect x="3.5" y="5.5" width="17" height="13" rx="3"/><path d="M4.5 7l7.5 6 7.5-6"/>');
  static final moon =
      _stroke('<path d="M19.5 14.6A8 8 0 019.4 4.5a8 8 0 1010.1 10.1z"/>');
  static final doc = _stroke(
      '<path d="M7 3.5h7l4 4v13H7z"/><path d="M14 3.5v4h4M9.5 12h6M9.5 15.5h6"/>');
  static final lock = _stroke(
      '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V8a4 4 0 018 0v2.5"/>');
  static final logout = _stroke(
      '<path d="M14 4h4a2 2 0 012 2v12a2 2 0 01-2 2h-4"/><path d="M10 16l-4-4 4-4M6 12h10"/>');
  static final trash =
      _stroke('<path d="M5 7h14M10 7V5h4v2M7 7l1 13h8l1-13"/>');
  static final help = _stroke(
      '<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.4a2.5 2.5 0 014.8.9c0 1.7-2.4 2-2.4 3.7"/>'
      '<circle cx="12" cy="16.8" r=".6" fill="currentColor"/>');
  static final person = _stroke(
      '<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20c1.3-3.6 4.1-5.5 7.5-5.5s6.2 1.9 7.5 5.5"/>');
  static final clock =
      _stroke('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>');
  static final share = _stroke(
      '<path d="M12 3v12M7 8l5-5 5 5"/><path d="M5 13v6a2 2 0 002 2h10a2 2 0 002-2v-6"/>');
  static final pencil = _stroke(
      '<path d="M4 20l1-4.5L16 4.5a2.1 2.1 0 013 3L8 18.5z"/><path d="M14 6.5l3 3"/>');
  static final close = _stroke('<path d="M6 6l12 12M18 6L6 18"/>', width: 2.6);
  static final restart =
      _stroke('<path d="M4 12a8 8 0 102.4-5.7"/><path d="M4 4.5v4h4"/>');

  /// Logo de Apple (relleno `currentColor`).
  static const apple =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 17 20" fill="currentColor">'
      '<path d="M14.1 10.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8 1.6 0 2 .8 3.4.8 1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9-.1 0-2.7-1-2.7-4.1z"/>'
      '<path d="M11.6 3c.7-.9 1.2-2 1.1-3.2-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.1 1.1.1 2.3-.6 3-1.5z"/></svg>';

  /// «G» de Google (sus colores de marca, igual de día y de noche).
  static const google =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4a4.6 4.6 0 01-2 3v2.5h3.2c1.9-1.7 3-4.3 3-7.3z" fill="#4285F4"/>'
      '<path d="M12 22c2.7 0 5-.9 6.6-2.4l-3.2-2.5c-.9.6-2 1-3.4 1-2.6 0-4.8-1.8-5.6-4.1H3.1v2.6A10 10 0 0012 22z" fill="#34A853"/>'
      '<path d="M6.4 14c-.2-.6-.3-1.3-.3-2s.1-1.4.3-2V7.4H3.1a10 10 0 000 9.2z" fill="#FBBC05"/>'
      '<path d="M12 5.9c1.5 0 2.8.5 3.8 1.5l2.9-2.9A10 10 0 003.1 7.4L6.4 10c.8-2.3 3-4.1 5.6-4.1z" fill="#EA4335"/></svg>';
}

/// Colores del grupo que no están en [GmColors].
class PerfilColors {
  PerfilColors._();

  /// Relleno rojo suave del botón «Solicitar eliminación» y del icono.
  static Color closedSoft(GmColors gm) =>
      gm.isDark ? const Color(0x29FF6B5E) : const Color(0x1AC0352B);

  /// Segmento elegido del control «Tema».
  static Color segOn(GmColors gm) =>
      gm.isDark ? const Color(0x29F3EEE4) : const Color(0xFFFFFFFF);

  /// Fondo suave del corazón (vacío de Guardados).
  static const heartSoft = Color(0x1FFF3B5C);

  /// Interruptor encendido (verde iOS).
  static const switchOn = Color(0xFF34C759);

  /// Velo bajo las hojas.
  static const barrier = Color(0x52000000);
}

// ── Títulos ─────────────────────────────────────────────────────────────────

/// Título grande 34/41 con antetítulo y subtítulo opcionales.
class PerfilLargeTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? eyebrow;

  const PerfilLargeTitle(this.title, {super.key, this.subtitle, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[eyebrow!, const SizedBox(height: 2)],
          Semantics(
            header: true,
            child: Text(title, style: GmText.largeTitle(color: gm.label)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: GmText.body(color: gm.label2)),
          ],
        ],
      ),
    );
  }
}

/// Botón «Volver» de las pantallas que cuelgan del Perfil.
class PerfilBackButton extends StatelessWidget {
  final String identifier;
  const PerfilBackButton({super.key, required this.identifier});

  @override
  Widget build(BuildContext context) => GmToolbarButton(
        icon: GmIcons.chevronLeft,
        light: true,
        semanticLabel: 'Volver',
        identifier: identifier,
        onTap: () => Navigator.of(context).maybePop(),
      );
}

// ── Lista agrupada estilo Ajustes ───────────────────────────────────────────

/// Grupo: antetítulo (13/18 · 600) + tarjeta r24 con filas separadas.
class PerfilGroup extends StatelessWidget {
  final String? caption;
  final List<Widget> rows;
  final int riseIndex;
  final String? identifier;

  const PerfilGroup({
    super.key,
    this.caption,
    required this.rows,
    this.riseIndex = 0,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Container(height: 1, color: gm.sep),
        ));
      }
      children.add(rows[i]);
    }
    return GmRise(
      index: riseIndex,
      trigger: GmTrigger.mount,
      child: Semantics(
        identifier: identifier,
        container: identifier != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (caption != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Semantics(
                  header: true,
                  child:
                      Text(caption!, style: GmText.eyebrow(color: gm.label2)),
                ),
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: gm.card,
                borderRadius: BorderRadius.circular(GmRadius.card),
                boxShadow: gm.shadow1,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono de fila: cuadrado 30 r9 con tinte.
class PerfilIconTile extends StatelessWidget {
  final String? icon;
  final Widget? child;
  final Color background;
  final Color? color;

  const PerfilIconTile({
    super.key,
    this.icon,
    this.child,
    required this.background,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: child ?? GmIcon(icon!, size: 18, color: color ?? gm.label),
      ),
    );
  }
}

/// Fila agrupada (≥ 58): icono, título 17/22, subtítulo 13/18 y chevron.
class PerfilRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final String? identifier;
  final Color? titleColor;

  const PerfilRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.chevron = true,
    this.onTap,
    this.identifier,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: gm.fill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GmText.body17(
                                color: titleColor ?? gm.label,
                                w: FontWeight.w500)
                            .copyWith(height: 22 / 17, letterSpacing: -0.3),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
                if (chevron && onTap != null) ...[
                  const SizedBox(width: 10),
                  GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interruptor verde iOS.
class PerfilSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const PerfilSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) => CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: PerfilColors.switchOn,
      );
}

/// Control segmentado a lo ancho (Tema: Claro · Oscuro · Sistema).
class PerfilSegmented<T> extends StatelessWidget {
  final List<(T value, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String identifierPrefix;

  const PerfilSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.identifierPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: gm.fill,
        borderRadius: BorderRadius.circular(GmRadius.pill),
      ),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: Semantics(
                identifier: '$identifierPrefix-$label'.toLowerCase(),
                button: true,
                selected: v == value,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: reduced ? 0 : 200),
                    curve: GmMotion.ease,
                    constraints: const BoxConstraints(minHeight: 38),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: v == value
                          ? PerfilColors.segOn(gm)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(GmRadius.pill),
                      boxShadow: v == value && !gm.isDark
                          ? const [
                              BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1)),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: v == value ? gm.label : gm.label2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bloque plano de esqueleto (sin barrido).
class PerfilSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const PerfilSkeleton(
      {super.key, this.width, required this.height, this.radius = 10});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GmColors.of(context).fill,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ── Botones ─────────────────────────────────────────────────────────────────

/// Cápsula destructiva roja `#D6362A` (52 de alto) de las hojas de
/// confirmación. Solo para acciones irreversibles.
class PerfilDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? identifier;

  const PerfilDangerButton({
    super.key,
    required this.label,
    this.onTap,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: onTap != null,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GmColors.badgeRed,
            borderRadius: BorderRadius.circular(GmRadius.pill),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x8C961E14),
                  offset: Offset(0, 8),
                  blurRadius: 18,
                  spreadRadius: -8),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón a todo lo ancho de las hojas (52): primario o secundario suave.
class PerfilWideButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool secondary;
  final String? identifier;
  final Widget? leading;

  const PerfilWideButton({
    super.key,
    required this.label,
    this.onTap,
    this.secondary = false,
    this.identifier,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    if (!secondary) {
      return SizedBox(
        width: double.infinity,
        child: GmCapsuleButton(
          label: label,
          onTap: onTap,
          height: 52,
          fontSize: 17,
          identifier: identifier,
          leading: leading,
        ),
      );
    }
    return PerfilSoftButton(
      label: label,
      onTap: onTap,
      identifier: identifier,
      leading: leading,
      height: 52,
      fontSize: 17,
      expand: true,
    );
  }
}

/// Cápsula secundaria (relleno `accentSoft`, texto `accent`). Como
/// GmSoftCapsuleButton, pero el texto parte en dos líneas con letra grande
/// en vez de desbordar. Candidata a sustituirlo en `lib/ui/theme`.
class PerfilSoftButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? identifier;
  final Widget? leading;
  final double height;
  final double fontSize;
  final bool expand;
  final EdgeInsetsGeometry padding;

  const PerfilSoftButton({
    super.key,
    required this.label,
    this.onTap,
    this.identifier,
    this.leading,
    this.height = 44,
    this.fontSize = 15,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final enabled = onTap != null;
    return Semantics(
      identifier: identifier,
      button: true,
      enabled: enabled,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: Container(
          width: expand ? double.infinity : null,
          constraints: BoxConstraints(minHeight: height),
          padding: padding.add(const EdgeInsets.symmetric(vertical: 6)),
          decoration: BoxDecoration(
            color: gm.accentSoft,
            borderRadius: BorderRadius.circular(GmRadius.pill),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: enabled ? gm.accent : gm.label2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de actividad pequeño (exportar, entrar). Con «reducir
/// movimiento» se queda quieto.
class PerfilSpinner extends StatelessWidget {
  final Color color;
  final double size;
  const PerfilSpinner({super.key, required this.color, this.size = 17});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          strokeCap: StrokeCap.round,
          color: color,
          value: GmMotion.reduced(context) ? 0.75 : null,
        ),
      );
}

// ── Hoja con asa ────────────────────────────────────────────────────────────

/// Abre una hoja del grupo (lienzo, r32, asa). Devuelve lo que haga `pop`.
Future<T?> showPerfilSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      barrierColor: PerfilColors.barrier,
      builder: (ctx) => _PerfilSheetFrame(child: builder(ctx)),
    );

class _PerfilSheetFrame extends StatelessWidget {
  final Widget child;
  const _PerfilSheetFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 30,
                offset: Offset(0, -10)),
          ],
        ),
        padding: EdgeInsets.only(bottom: media.padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: gm.sep,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Contenido de una hoja de confirmación: disco con icono, título, texto,
/// una píldora opcional y las acciones apiladas.
class PerfilConfirmSheet extends StatelessWidget {
  final String icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String text;
  final List<Widget> actions;
  final String? identifier;

  const PerfilConfirmSheet({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.text,
    required this.actions,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      scopesRoute: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: iconBackground, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: GmIcon(icon, size: 26, color: iconColor),
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              header: true,
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: GmText.title2(color: gm.label)),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GmText.body(color: gm.label2).copyWith(height: 21 / 15),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Aviso flotante (deshacer, error) ────────────────────────────────────────

/// Cápsula de cristal abajo (52): texto + acción. La posiciona quien la usa.
class PerfilToast extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? identifier;

  const PerfilToast({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      liveRegion: true,
      container: true,
      child: GmGlass(
        borderRadius: BorderRadius.circular(GmRadius.pill),
        tint: gm.glass,
        edge: gm.glassEdge,
        shadow: gm.shadow2,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(18, 6, actionLabel == null ? 18 : 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.body(color: gm.glassInk, w: FontWeight.w500),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 8),
                  PerfilSoftButton(
                    label: actionLabel!,
                    onTap: onAction,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    identifier:
                        identifier == null ? null : '$identifier-action',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra [PerfilToast] con una entrada corta desde abajo.
class PerfilToastSlot extends StatelessWidget {
  final PerfilToast? toast;
  const PerfilToastSlot({super.key, this.toast});

  @override
  Widget build(BuildContext context) {
    final reduced = GmMotion.reduced(context);
    return AnimatedSwitcher(
      duration: Duration(milliseconds: reduced ? 0 : 260),
      switchInCurve: GmMotion.settle,
      switchOutCurve: GmMotion.ease,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position:
              Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: toast == null
          ? const SizedBox.shrink()
          : KeyedSubtree(key: ValueKey(toast!.message), child: toast!),
    );
  }
}

// ── Estados ─────────────────────────────────────────────────────────────────

/// Tarjeta de estado (vacío / error): ilustración, título, texto y acción.
class PerfilStateCard extends StatelessWidget {
  final String identifier;
  final Widget art;
  final String title;
  final String text;
  final Widget? action;

  const PerfilStateCard({
    super.key,
    required this.identifier,
    required this.art,
    required this.title,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmRise(
      index: 2,
      trigger: GmTrigger.mount,
      child: Semantics(
        identifier: identifier,
        container: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: GmCard(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  art,
                  const SizedBox(height: 10),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: GmText.poster(color: gm.label)),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style:
                        GmText.body(color: gm.label2).copyWith(height: 21 / 15),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 16),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Volcán mascota contento (100 × 70): el de error con la sonrisa.
class PerfilHappyVolcano extends StatelessWidget {
  final double width;
  const PerfilHappyVolcano({super.key, this.width = 96});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size(width, width * 0.7),
          painter: _HappyVolcanoPainter(GmColors.of(context)),
        ),
      );
}

class _HappyVolcanoPainter extends CustomPainter {
  final GmColors gm;
  _HappyVolcanoPainter(this.gm);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 70);
    final body = Path()
      ..moveTo(6, 68)
      ..lineTo(34, 34)
      ..cubicTo(37, 30.6, 40, 29.9, 42.6, 31.8)
      ..lineTo(46.9, 34.8)
      ..cubicTo(50.1, 37, 53.5, 37, 56.7, 34.8)
      ..lineTo(61, 31.8)
      ..cubicTo(63.6, 29.9, 66.6, 30.6, 69.6, 34)
      ..lineTo(94, 68)
      ..close();
    canvas.drawPath(body, Paint()..color = gm.volcFill);
    canvas.drawPath(
        body,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final ink = Paint()..color = gm.volcInk;
    canvas.drawCircle(const Offset(42.5, 50), 2.8, ink);
    canvas.drawCircle(const Offset(57.5, 50), 2.8, ink);
    canvas.drawPath(
      Path()
        ..moveTo(45, 57)
        ..quadraticBezierTo(50, 60.8, 55, 57),
      Paint()
        ..color = gm.volcInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HappyVolcanoPainter old) => old.gm != gm;
}

/// Pie: volcán pequeño + «Dónde Comer Canarias 4.6.0» + «Hecho en Canarias».
class PerfilFooter extends StatelessWidget {
  final String versionLabel;
  const PerfilFooter({super.key, required this.versionLabel});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'perfil-footer',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: [
            const PerfilHappyVolcano(width: 46),
            const SizedBox(height: 8),
            Text(versionLabel,
                textAlign: TextAlign.center,
                style: GmText.eyebrow(color: gm.label2)),
            Text('Hecho en Canarias',
                textAlign: TextAlign.center,
                style: GmText.meta(color: gm.label2)),
          ],
        ),
      ),
    );
  }
}

/// Logo SVG multicolor (Google) o de un color (Apple).
class PerfilLogo extends StatelessWidget {
  final String svg;
  final double width;
  final double height;
  final Color? color;
  const PerfilLogo(this.svg,
      {super.key, required this.width, required this.height, this.color});

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        svg,
        width: width,
        height: height,
        theme:
            color == null ? const SvgTheme() : SvgTheme(currentColor: color!),
        excludeFromSemantics: true,
      );
}
